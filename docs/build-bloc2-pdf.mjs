import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = resolve(dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const sourcePath = resolve(root, 'docs/bloc-2-dossier-validation.md');
const outDir = resolve(root, 'docs/pdf');
const htmlPath = resolve(outDir, 'bloc-2-dossier-validation.html');
const pdfPath = resolve(outDir, 'bloc-2-dossier-validation.pdf');
const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

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

    const proof = line.trim().match(/^\*\*((?:SCREEN|UML|SCHEMA|TABLEAU)[^*]*)\*\*/);
    if (proof) {
      flushParagraph();
      flushList();
      flushTable();
      const details = [];
      while (index + 1 < lines.length) {
        const nextLine = lines[index + 1].trim();
        if (
          !nextLine ||
          nextLine === '---' ||
          nextLine.startsWith('#') ||
          nextLine.startsWith('|') ||
          nextLine.startsWith('- ') ||
          /^\*\*((?:SCREEN|UML|SCHEMA|TABLEAU)[^*]*)\*\*/.test(nextLine)
        ) {
          break;
        }
        details.push(nextLine);
        index += 1;
      }
      const proofKind = proof[1].split(' ')[0].toLowerCase();
      html.push([
        `<aside class="proof proof-${proofKind}">`,
        `<div class="proof-label">${inlineMarkdown(proof[1])}</div>`,
        `<div class="proof-text">${inlineMarkdown(details.join(' '))}</div>`,
        '</aside>',
      ].join(''));
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
  .replace(/^# Dossier de validation - Bloc 2/m, '# Dossier de validation - Bloc 2')
  .replace(/Projet : Anonym\s+?/m, '')
  .replace(/Candidat : Lukas Bouhlel\s+?/m, '')
  .replace(/Version presentee : v1\.0\.0-bloc2\s+?/m, '')
  .replace(/Date : juin 2026\s+?/m, '');

const content = markdownToHtml(markdown);

const html = `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>Dossier de validation - Bloc 2 - Anonym</title>
  <style>
    @page {
      size: A4;
      margin: 9mm 9mm 9mm 9mm;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      color: #182235;
      font-family: Arial, Helvetica, sans-serif;
      font-size: 8.9pt;
      line-height: 1.28;
      background: #f4f7fb;
    }

    .cover {
      min-height: 279mm;
      display: flex;
      flex-direction: column;
      justify-content: center;
      color: #f8fbff;
      background:
        linear-gradient(135deg, rgba(18, 28, 45, .96), rgba(37, 99, 235, .88)),
        linear-gradient(90deg, #172033, #2563eb);
      padding: 22mm;
      page-break-after: always;
    }

    .cover .label {
      color: #dbeafe;
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
      color: #bfdbfe;
      font-size: 20pt;
      border: 0;
    }

    .meta {
      display: grid;
      grid-template-columns: 38mm 1fr;
      gap: 3mm 6mm;
      width: 100%;
      margin-top: 10mm;
      padding-top: 9mm;
      border-top: 1pt solid rgba(255,255,255,.32);
      font-size: 10.5pt;
    }

    .meta strong {
      color: #bfdbfe;
    }

    h1 {
      margin: 0 0 4mm;
      padding: 3.5mm 4mm;
      color: #111827;
      font-size: 18pt;
      line-height: 1.15;
      border-left: 4pt solid #2563eb;
      background: #eaf1fb;
      page-break-after: avoid;
    }

    h2 {
      margin: 4.4mm 0 2.4mm;
      color: #111827;
      font-size: 12.6pt;
      line-height: 1.2;
      page-break-after: avoid;
    }

    h3 {
      margin: 3.2mm 0 1.6mm;
      color: #2563eb;
      font-size: 10.2pt;
      line-height: 1.2;
      page-break-after: avoid;
    }

    p {
      margin: 0 0 2mm;
    }

    ul {
      margin: .7mm 0 2.2mm 4mm;
      padding-left: 4mm;
    }

    li {
      margin-bottom: .65mm;
    }

    table {
      width: 100%;
      margin: 2.2mm 0 3mm;
      border-collapse: collapse;
      page-break-inside: avoid;
      font-size: 7.7pt;
      background: #ffffff;
    }

    th {
      background: #dfe9f7;
      color: #111827;
      font-weight: 700;
    }

    th, td {
      border: .65pt solid #c9d2e2;
      padding: 1.25mm 1.55mm;
      vertical-align: top;
    }

    code {
      padding: .2mm 1mm;
      border-radius: 2mm;
      background: #eef2f7;
      color: #0f172a;
      font-family: Consolas, "Courier New", monospace;
      font-size: 8.4pt;
    }

    pre {
      margin: 2mm 0;
      padding: 2.4mm;
      background: #101827;
      color: #f8fafc;
      border-radius: 2mm;
      white-space: pre-wrap;
      font-size: 7.6pt;
      page-break-inside: avoid;
    }

    pre code {
      padding: 0;
      background: transparent;
      color: inherit;
    }

    strong {
      color: #0f3d75;
    }

    .proof {
      display: grid;
      grid-template-columns: 34mm 1fr;
      gap: 2mm;
      align-items: stretch;
      min-height: 14mm;
      margin: 1.6mm 0 2.4mm;
      border: .75pt solid #c9d7ec;
      border-left: 3pt solid #2563eb;
      background: #ffffff;
      page-break-inside: avoid;
    }

    .proof-label {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2mm;
      color: #0f3d75;
      font-size: 7.6pt;
      font-weight: 800;
      text-align: center;
      text-transform: uppercase;
      background: #eaf1fb;
    }

    .proof-text {
      display: flex;
      align-items: center;
      padding: 2mm 2.5mm;
      color: #32435f;
      font-size: 8.2pt;
    }

    .proof-uml,
    .proof-schema {
      border-left-color: #7c3aed;
    }

    .proof-uml .proof-label,
    .proof-schema .proof-label {
      color: #4c1d95;
      background: #f1eafe;
    }

    .proof-tableau {
      border-left-color: #0f766e;
    }

    .proof-tableau .proof-label {
      color: #115e59;
      background: #e6f5f3;
    }

    .section-divider {
      height: 1.2mm;
      margin: 4mm 0 3mm;
      border-radius: 99mm;
      background: linear-gradient(90deg, #2563eb, #94a3b8, transparent);
    }

    .content {
      padding: 0;
      counter-reset: h2;
      background: #ffffff;
    }
  </style>
</head>
<body>
  <section class="cover">
    <div class="label">Bloc 2 - Dossier de validation</div>
    <h1>Anonym</h1>
    <h2>Developpement, tests, securite, accessibilite et deploiement</h2>
    <p>Application sociale web et mobile orientee messagerie temps reel, confidentialite, supervision et deploiement continu.</p>
    <div class="meta">
      <strong>Candidat</strong><span>Lukas Bouhlel</span>
      <strong>Version</strong><span>v1.0.0-bloc2</span>
      <strong>Date</strong><span>Juin 2026</span>
      <strong>Perimetre</strong><span>Dossier principal limite a 30 pages maximum, hors annexes.</span>
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

execFileSync(chromePath, [
  '--headless',
  '--disable-gpu',
  '--no-pdf-header-footer',
  `--print-to-pdf=${pdfPath}`,
  htmlPath,
], { stdio: 'inherit' });

console.log(`PDF generated: ${pdfPath}`);
