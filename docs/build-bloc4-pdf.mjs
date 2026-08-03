import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sourcePath = resolve(root, 'docs/bloc-4-maintenance-operationnelle.md');
const outDir = resolve(root, 'docs/pdf');
const htmlPath = resolve(outDir, 'bloc-4-maintenance-operationnelle.html');
const pdfPath = resolve(outDir, 'bloc-4-maintenance-operationnelle.pdf');

const browserCandidates = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
];

const browserPath = browserCandidates.find((candidate) => existsSync(candidate));

if (!browserPath) {
  throw new Error('No Chrome or Edge executable found to render the PDF.');
}

const escapeHtml = (value) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

const inlineMarkdown = (value) =>
  escapeHtml(value)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');

const renderTable = (rows) => {
  const parsedRows = rows.map((row) =>
    row
      .trim()
      .replace(/^\|/, '')
      .replace(/\|$/, '')
      .split('|')
      .map((cell) => inlineMarkdown(cell.trim())),
  );
  const [header, , ...body] = parsedRows;
  return [
    '<table>',
    '<thead><tr>',
    ...header.map((cell) => `<th>${cell}</th>`),
    '</tr></thead>',
    '<tbody>',
    ...body.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join('')}</tr>`),
    '</tbody></table>',
  ].join('');
};

const markdownToHtml = (markdown) => {
  const lines = markdown.split(/\r?\n/);
  const html = [];
  let paragraph = [];
  let list = [];
  let code = [];
  let table = [];
  let inCode = false;

  const flushParagraph = () => {
    if (paragraph.length) {
      html.push(`<p>${inlineMarkdown(paragraph.join(' '))}</p>`);
      paragraph = [];
    }
  };

  const flushList = () => {
    if (list.length) {
      html.push(`<ul>${list.map((item) => `<li>${inlineMarkdown(item)}</li>`).join('')}</ul>`);
      list = [];
    }
  };

  const flushTable = () => {
    if (table.length) {
      html.push(renderTable(table));
      table = [];
    }
  };

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.startsWith('```')) {
      if (inCode) {
        html.push(`<pre><code>${escapeHtml(code.join('\n'))}</code></pre>`);
        code = [];
        inCode = false;
      } else {
        flushParagraph();
        flushList();
        flushTable();
        inCode = true;
      }
      continue;
    }

    if (inCode) {
      code.push(line);
      continue;
    }

    if (!line.trim()) {
      flushParagraph();
      flushList();
      flushTable();
      continue;
    }

    if (line.trim() === '---') {
      flushParagraph();
      flushList();
      flushTable();
      html.push('<div class="section-divider"></div>');
      continue;
    }

    if (/^\|.*\|$/.test(line.trim())) {
      flushParagraph();
      flushList();
      table.push(line);
      continue;
    }

    flushTable();

    const heading = line.match(/^(#{1,4})\s+(.*)$/);
    if (heading) {
      flushParagraph();
      flushList();
      const level = heading[1].length;
      html.push(`<h${level}>${inlineMarkdown(heading[2])}</h${level}>`);
      continue;
    }

    const bullet = line.match(/^\s*-\s+(.*)$/);
    if (bullet) {
      flushParagraph();
      list.push(bullet[1]);
      continue;
    }

    paragraph.push(line.trim());
  }

  flushParagraph();
  flushList();
  flushTable();

  return html.join('\n');
};

const markdown = readFileSync(sourcePath, 'utf8')
  .replace(/^# Dossier de validation - Bloc 4/m, '# Dossier de validation - Bloc 4')
  .replace(/Projet : Anonym\s+?/m, '')
  .replace(/Candidat : Lukas Bouhlel\s+?/m, '')
  .replace(/Version présentée : v1\.0\.0-bloc4\s+?/m, '')
  .replace(/Date : 7 juillet 2026\s+?/m, '');

const content = markdownToHtml(markdown);

const html = `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Dossier de validation - Bloc 4 - Anonym</title>
  <style>
    @page {
      size: A4;
      margin: 8mm 8mm 8mm 8mm;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      color: #182235;
      font-family: Arial, Helvetica, sans-serif;
      font-size: 8.45pt;
      line-height: 1.22;
      background: #ffffff;
    }

    .cover {
      min-height: 281mm;
      display: flex;
      flex-direction: column;
      justify-content: center;
      color: #f8fbff;
      background:
        linear-gradient(135deg, rgba(18, 28, 45, .97), rgba(15, 118, 110, .88)),
        linear-gradient(90deg, #172033, #0f766e);
      padding: 22mm;
      page-break-after: always;
    }

    .cover .label {
      color: #ccfbf1;
      font-size: 10pt;
      font-weight: 700;
      letter-spacing: .08em;
      text-transform: uppercase;
    }

    .cover h1 {
      margin: 8mm 0 4mm;
      color: #ffffff;
      font-size: 31pt;
      line-height: 1.05;
      border: 0;
      page-break-after: auto;
    }

    .cover h2 {
      margin: 0 0 12mm;
      color: #99f6e4;
      font-size: 18pt;
      border: 0;
    }

    .cover p {
      max-width: 145mm;
      color: #ecfeff;
      font-size: 10.6pt;
      line-height: 1.35;
    }

    .meta {
      display: grid;
      grid-template-columns: 38mm 1fr;
      gap: 3mm 6mm;
      width: 100%;
      margin-top: 10mm;
      padding-top: 9mm;
      border-top: 1pt solid rgba(255,255,255,.32);
      font-size: 10.2pt;
    }

    .meta strong {
      color: #99f6e4;
    }

    h1 {
      margin: 0 0 3.4mm;
      padding: 3.2mm 4mm;
      color: #111827;
      font-size: 17.2pt;
      line-height: 1.12;
      border-left: 4pt solid #0f766e;
      background: #e8f5f3;
      page-break-after: avoid;
    }

    h2 {
      margin: 3.7mm 0 2mm;
      color: #111827;
      font-size: 12pt;
      line-height: 1.18;
      page-break-after: avoid;
    }

    h3 {
      margin: 2.8mm 0 1.3mm;
      color: #0f766e;
      font-size: 9.7pt;
      line-height: 1.18;
      page-break-after: avoid;
    }

    p {
      margin: 0 0 1.6mm;
    }

    ul {
      margin: .5mm 0 1.8mm 4mm;
      padding-left: 4mm;
    }

    li {
      margin-bottom: .45mm;
    }

    table {
      width: 100%;
      margin: 1.8mm 0 2.4mm;
      border-collapse: collapse;
      page-break-inside: avoid;
      font-size: 7.15pt;
      background: #ffffff;
    }

    th {
      background: #dcefeb;
      color: #111827;
      font-weight: 700;
    }

    th, td {
      border: .6pt solid #c8d6df;
      padding: 1.05mm 1.25mm;
      vertical-align: top;
    }

    code {
      padding: .15mm .75mm;
      border-radius: 1.6mm;
      background: #eef2f7;
      color: #0f172a;
      font-family: Consolas, "Courier New", monospace;
      font-size: 7.7pt;
    }

    pre {
      margin: 1.6mm 0;
      padding: 2mm;
      background: #101827;
      color: #f8fafc;
      border-radius: 1.7mm;
      white-space: pre-wrap;
      font-size: 7.2pt;
      page-break-inside: avoid;
    }

    pre code {
      padding: 0;
      background: transparent;
      color: inherit;
    }

    strong {
      color: #115e59;
    }

    .section-divider {
      height: .9mm;
      margin: 3.3mm 0 2.5mm;
      border-radius: 99mm;
      background: linear-gradient(90deg, #0f766e, #94a3b8, transparent);
    }

    .content {
      background: #ffffff;
    }
  </style>
</head>
<body>
  <section class="cover">
    <div class="label">Bloc 4 - Dossier de validation</div>
    <h1>Anonym</h1>
    <h2>Maintenir l'application logicielle en condition opérationnelle</h2>
    <p>Dossier écrit compact, compatible avec un dépôt Canvas : supervision, traitement des anomalies, maintenance, journal de version et collaboration support.</p>
    <div class="meta">
      <strong>Candidat</strong><span>Lukas Bouhlel</span>
      <strong>Version</strong><span>v1.0.0-bloc4</span>
      <strong>Date</strong><span>7 juillet 2026</span>
      <strong>Périmètre</strong><span>Backend Express, frontend React, application Flutter, MySQL, Docker, VPS, CI/CD et supervision.</span>
    </div>
  </section>
  <main class="content">
    ${content}
  </main>
</body>
</html>`;

if (!existsSync(outDir)) {
  mkdirSync(outDir, { recursive: true });
}

writeFileSync(htmlPath, html, 'utf8');

execFileSync(browserPath, [
  '--headless',
  '--disable-gpu',
  '--no-pdf-header-footer',
  `--print-to-pdf=${pdfPath}`,
  htmlPath,
], { stdio: 'inherit' });

console.log(`HTML generated: ${htmlPath}`);
console.log(`PDF generated: ${pdfPath}`);
