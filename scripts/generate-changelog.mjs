import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);

const getArg = (name) => {
  const index = args.indexOf(name);
  return index === -1 ? '' : args[index + 1] || '';
};

const hasArg = (name) => args.includes(name);

const version = getArg('--version');
const fromRefInput = getArg('--from');
const toRef = getArg('--to') || 'HEAD';
const releaseDate = getArg('--date') || new Date().toISOString().slice(0, 10);
const dryRun = hasArg('--dry-run');
const replaceExisting = hasArg('--replace');

if (!/^v\d+\.\d+\.\d+/.test(version)) {
  throw new Error('Usage: node scripts/generate-changelog.mjs --version v1.0.6 [--from v1.0.5] [--to HEAD] [--date YYYY-MM-DD] [--dry-run] [--replace]');
}

const root = resolve(new URL('..', import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1'));
const changelogPath = resolve(root, 'CHANGELOG.md');

const git = (gitArgs) =>
  execFileSync('git', gitArgs, {
    cwd: root,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trim();

const getLatestSemverTag = () => {
  if (fromRefInput) return fromRefInput;

  const tags = git(['tag', '--list', 'v[0-9]*', '--sort=-v:refname'])
    .split(/\r?\n/)
    .map((tag) => tag.trim())
    .filter(Boolean)
    .filter((tag) => tag !== version);

  return tags[0] || '';
};

const previousRef = getLatestSemverTag();
const range = previousRef ? `${previousRef}..${toRef}` : toRef;

const rawLog = git([
  'log',
  '--reverse',
  '--pretty=format:%H%x1f%s%x1f%b%x1e',
  range,
]);

const records = rawLog
  .split('\x1e')
  .map((entry) => entry.trim())
  .filter(Boolean)
  .map((entry) => {
    const [hash, subject, body = ''] = entry.split('\x1f');
    return { hash, shortHash: hash.slice(0, 8), subject: subject.trim(), body: body.trim() };
  });

if (!records.length) {
  throw new Error(`No commits found in range ${range}. Refusing to generate an empty release section.`);
}

const normalizeTitle = (value) =>
  value
    .replace(/^Merge pull request #\d+ from [^\n]+/i, '')
    .replace(/^Merge branch [^\n]+/i, '')
    .trim();

const prEntries = [];
const seenPrs = new Set();
const commitEntries = [];

for (const record of records) {
  const prMatch = record.subject.match(/^Merge pull request #(\d+) from ([^\s]+)/i);

  if (prMatch) {
    const number = prMatch[1];
    if (!seenPrs.has(number)) {
      seenPrs.add(number);
      const title = normalizeTitle(record.body) || prMatch[2].split('/').pop() || record.subject;
      prEntries.push({
        number,
        title,
        branch: prMatch[2],
        shortHash: record.shortHash,
      });
    }
    continue;
  }

  if (!record.subject.startsWith('Merge branch')) {
    commitEntries.push(record);
  }
}

const classify = (text) => {
  const value = text.toLowerCase();

  if (/s[eé]cur|vulnerab|csrf|auth|token|dependenc|snyk|audit|helmet|ssl|tls/.test(value)) {
    return 'Sécurité';
  }

  if (/fix|corr|bug|persist|repair|resolve|hotfix|rollback|health|uploads/.test(value)) {
    return 'Corrigé';
  }

  if (/doc|readme|bloc|changelog|swagger|jsdoc/.test(value)) {
    return 'Documentation';
  }

  if (/add|ajout|create|mise en place|prometheus|alertmanager|monitor|metric|grafana|test|coverage/.test(value)) {
    return 'Ajouté';
  }

  return 'Changé';
};

const grouped = new Map([
  ['Ajouté', []],
  ['Corrigé', []],
  ['Sécurité', []],
  ['Documentation', []],
  ['Changé', []],
]);

for (const entry of [...prEntries, ...commitEntries]) {
  const text = 'number' in entry ? entry.title : entry.subject;
  const group = classify(text);
  const line = 'number' in entry
    ? `- PR #${entry.number} - ${entry.title} (\`${entry.shortHash}\`)`
    : `- \`${entry.shortHash}\` - ${entry.subject}`;
  grouped.get(group).push(line);
}

const sectionParts = [
  `## ${version} - ${releaseDate}`,
  '',
];

for (const [heading, lines] of grouped.entries()) {
  if (!lines.length) continue;
  sectionParts.push(`### ${heading}`, ...lines, '');
}

if (prEntries.length) {
  sectionParts.push(
    '### Pull Requests déployées',
    ...prEntries.map((entry) => `- PR #${entry.number} - ${entry.title} depuis \`${entry.branch}\` (\`${entry.shortHash}\`)`),
    '',
  );
}

if (previousRef) {
  sectionParts.push('### Périmètre Git', `- Changements inclus depuis \`${previousRef}\` jusqu’à \`${toRef}\`.`, '');
}

const generatedSection = sectionParts.join('\n').trimEnd();
const existing = readFileSync(changelogPath, 'utf8');
const versionRegex = new RegExp(`^## ${version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b[\\s\\S]*?(?=^## v\\d+\\.\\d+\\.\\d+|(?![\\s\\S]))`, 'm');

let nextChangelog;

if (versionRegex.test(existing)) {
  if (!replaceExisting) {
    throw new Error(`CHANGELOG.md already contains ${version}. Use --replace to regenerate this section.`);
  }
  nextChangelog = existing.replace(versionRegex, `${generatedSection}\n\n`);
} else {
  const firstReleaseMatch = existing.match(/^## v\d+\.\d+\.\d+.*$/m);
  if (firstReleaseMatch?.index !== undefined) {
    nextChangelog = `${existing.slice(0, firstReleaseMatch.index)}${generatedSection}\n\n${existing.slice(firstReleaseMatch.index)}`;
  } else {
    nextChangelog = `${existing.trimEnd()}\n\n${generatedSection}\n`;
  }
}

if (dryRun) {
  console.log(generatedSection);
} else {
  writeFileSync(changelogPath, nextChangelog, 'utf8');
  console.log(`CHANGELOG.md updated for ${version}.`);
}
