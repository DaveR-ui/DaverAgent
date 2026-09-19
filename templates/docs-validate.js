#!/usr/bin/env node
'use strict';
/*
 * DaverAgent documentation validator — DERIVED from `documentation-onrails`
 * validate.js (v1.4, snapshot 2026-09-12), adapted to a `docs/`-rooted consumer
 * corpus. This is NOT the upstream file and is NOT auto-loaded by the global
 * agent system; copy it into a project as <project>/docs/validate.js.
 *
 * Usage:
 *   node validate.js [--root <dir>] [--write]
 *
 *   --root   corpus root (default: the directory containing this script, i.e. the
 *            project's docs/ after copying the script there)
 *   --write  regenerate the `index` and `tags` regions of the EXISTING index.md /
 *            tag-index.md, write-if-diff. A missing artifact is never created;
 *            it stays a `stale-generated-index` error.
 *
 * Output: one finding per line `path:line — check-name: message`, then
 * `N error(s), M warning(s) — files scanned: K`. Exit 1 iff there is at least
 * one error. Warnings never fail the run.
 *
 * Checks shipped (adapted subset of onrails' catalog; see the README/guidelines):
 *   ERRORS    metadata-outside-contract, non-kebab-case-name, duplicate-ids,
 *             dangling-related-target, dangling-link, stale-generated-index,
 *             secret-in-prose
 *   WARNINGS  no-h1, category-mismatch-folder, orphan-note, missing-from-entry
 *
 * Deliberate divergences vs onrails are declared and machine-checked in
 * `templates/docs-conformance.json` (against
 * `templates/docs-conformance.schema.json`), which is the SINGLE
 * declared-divergence authority. Notable entries, summarized here:
 *   - `orphan-note` is a WARNING, not an error — a fresh corpus legitimately
 *     starts disconnected.
 *   - the registration check is named `missing-from-entry` (onrails calls it
 *     `missing-from-hub`) and is a WARNING, not an error; it is rooted at the
 *     docs/ entry point `project.md` instead of the root README.md.
 *   - the docs/-rooted `index.md` is generated alongside `tag-index.md` (both
 *     carry marker-delimited regions). onrails also generates an `index.md`, so
 *     the divergence is the docs/-rooted *serialization* (entry `project.md`
 *     instead of README.md; labels/counters), not the artifact's existence —
 *     see the `index-serialization` entry in the register.
 * Omitted (documented): near-duplicate-body (taste-level; needs a tokenizer).
 */

const fs = require('fs');
const path = require('path');

// ----------------------------- configuration ------------------------------

const argv = process.argv.slice(2);
function opt(name) {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : null;
}
const WRITE = argv.includes('--write');
const ROOT = path.resolve(opt('--root') || __dirname);
const DASH = '\u2014'; // — in output; written as an escape so the source is pure ASCII
const ELL = '\u2026';  // … in secret redaction sketches

const STATUS_ENUM = new Set(['draft', 'active', 'superseded', 'expired']);
// Context-doc contract (onrails 02 §4): 5 required + 2 optional.
const CTX_REQUIRED = ['last_updated', 'status', 'description', 'tags', 'version'];
const CTX_OPTIONAL = ['related', 'moved_from'];
// Note-family contract (onrails 02 §1): 7 required + 3 optional.
const NOTE_REQUIRED = ['id', 'category', 'tags', 'aliases', 'related', 'version', 'status'];
const NOTE_OPTIONAL = ['supersedes', 'expires_at', 'moved_from'];
const ENTRY_EXTRA = 'doc_language';
const CTX_SCALARS = new Set(['last_updated', 'status', 'description', 'version', ENTRY_EXTRA]);
const NOTE_SCALARS = new Set(['id', 'category', 'version', 'status', 'supersedes', 'expires_at']);
const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const SKIP_DIRS = new Set(['.git', 'node_modules', 'diagrams', '.agent-backups']);

// Root generated artifacts: relative path -> region marker name + renderer.
// Renderers return the FULL region (markers + snapshot line + body).
const GENERATED_ARTIFACTS = [
  { rel: 'index.md', marker: 'index', render: renderIndexRegion },
  { rel: 'tag-index.md', marker: 'tags', render: renderTagsRegion },
];

// Note-classes in this consumer corpus (used by duplicate-ids, orphans, the
// registration check and the generated index id suffix).
function isNoteClass(d) { return d.cls === 'note' || d.cls === 'hub'; }

// ----------------------------- findings -----------------------------------

const errors = [];
const warnings = [];
// Finding shape: `${rel}:${line} — ${check}: ${msg}`; real lines where known.
const err = (rel, check, msg, line = 1) => errors.push(`${rel}:${line} ${DASH} ${check}: ${msg}`);
const warn = (rel, check, msg, line = 1) => warnings.push(`${rel}:${line} ${DASH} ${check}: ${msg}`);

// ----------------------------- helpers ------------------------------------

/** Strict `YYYY-MM-DD` with a sane month/day range (onrails isValidDate). */
function isValidDate(s) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(s));
  if (!m) return false;
  return m[2] >= 1 && m[2] <= 12 && m[3] >= 1 && m[3] <= 31;
}

function todayISO() {
  const d = new Date(), p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function ciCompare(a, b) { // case-insensitive alphabetical, code-point tie-break
  const la = a.toLowerCase(), lb = b.toLowerCase();
  return la < lb ? -1 : la > lb ? 1 : a < b ? -1 : a > b ? 1 : 0;
}

/** Boolean mask, true = line is inside a ```/~~~ fenced block. Fence content
 *  is EXEMPT from wikilink and secret scanning (the guidelines are full of
 *  example fences). The fence-toggle line itself counts as inside. */
function fenceMask(lines) {
  const mask = new Array(lines.length).fill(false);
  let open = false;
  for (let i = 0; i < lines.length; i++) {
    const t = lines[i].trim();
    if (t.startsWith('```') || t.startsWith('~~~')) { open = !open; mask[i] = true; continue; }
    mask[i] = open;
  }
  return mask;
}

/** [start, end) spans of inline code (backtick spans) on a SINGLE,
 *  already known-non-fenced line. A wikilink written inside such a span —
 *  `[[stem]]` — is a CITATION of the syntax, not a live link, so wikilink
 *  scanning skips it. Markdown links are NOT exempt (anti-smuggling rule). */
function inlineCodeSpans(line) {
  const spans = [];
  for (const m of line.matchAll(/`([^`]*)`/g)) spans.push([m.index, m.index + m[0].length]);
  return spans;
}

// ----------------------------- collection ---------------------------------

function collect(dir, base, out) {
  for (const name of fs.readdirSync(dir)) {
    const abs = path.join(dir, name);
    const rel = base ? `${base}/${name}` : name;
    const st = fs.statSync(abs);
    if (st.isDirectory()) {
      if (SKIP_DIRS.has(name)) continue;
      collect(abs, rel, out);
    } else if (name.endsWith('.md')) {
      out.push(rel);
    }
  }
  return out;
}

/** docs/-rooted classification. Order matters: project.md -> entry; root
 *  index.md/tag-index.md -> generated (BEFORE the hub rule); any *-index.md ->
 *  hub (note contract); context/ -> context-doc; everything else -> note. */
function classify(rel) {
  const parts = rel.split('/');
  const base = parts[parts.length - 1];
  if (rel === 'project.md') return 'entry';
  if (rel === 'index.md' || rel === 'tag-index.md') return 'generated';
  if (/-index\.md$/.test(base)) return 'hub';
  if (parts[0] === 'context') return 'context';
  return 'note';
}

// ----------------------------- frontmatter --------------------------------

function unquote(s) {
  const t = s.trim();
  if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) return t.slice(1, -1);
  return t;
}

function parseFrontmatter(lines) {
  if (lines.length === 0 || lines[0].trim() !== '---') return null;
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === '---') { end = i; break; }
  }
  if (end < 0) return null;
  const entries = new Map();
  let i = 1;
  while (i < end) {
    const raw = lines[i];
    const t = raw.trim();
    if (t === '' || t.startsWith('#')) { i++; continue; }
    const m = /^([^:\s][^:]*):\s*(.*)$/.exec(raw);
    if (!m) { i++; continue; }
    const key = m[1];
    const rest = m[2].trim();
    if (rest === '') {
      const items = [];
      let j = i + 1;
      while (j < end) {
        const s = lines[j].trim();
        if (!s.startsWith('-') || s.startsWith('#')) break;
        items.push(unquote(s.replace(/^-\s*/, '').trim()));
        j++;
      }
      entries.set(key, items.length ? { kind: 'list', items, line: i + 1 } : { kind: 'blank', line: i + 1 });
      i = j;
    } else if (rest.startsWith('[') && rest.endsWith(']')) {
      const inner = rest.slice(1, -1).trim();
      entries.set(key, { kind: 'list', items: inner === '' ? [] : inner.split(',').map((x) => unquote(x.trim())), line: i + 1 });
      i++;
    } else {
      entries.set(key, { kind: 'scalar', value: unquote(rest), line: i + 1 });
      i++;
    }
  }
  return { entries, end };
}

function loadDoc(rel) {
  const abs = path.join(ROOT, rel);
  const content = fs.readFileSync(abs, 'utf8');
  const lines = content.split(/\r?\n/);
  const fm = parseFrontmatter(lines);
  const bodyStart = fm ? fm.end + 1 : 0;
  const mask = fenceMask(lines);
  const entries = fm ? fm.entries : null;
  const idEnt = entries && entries.get('id');
  const alEnt = entries && entries.get('aliases');
  let h1 = null;
  for (let i = bodyStart; i < lines.length; i++) {
    if (!mask[i] && /^#\s+\S/.test(lines[i])) { h1 = lines[i].replace(/^#\s+/, '').trim(); break; }
  }
  const name = rel.slice(rel.lastIndexOf('/') + 1);
  return {
    rel,
    abs,
    content,
    lines,
    mask,
    fm,
    entries,
    id: idEnt && idEnt.kind === 'scalar' && idEnt.value ? String(idEnt.value).trim() : null,
    aliases: alEnt && alEnt.kind === 'list' ? alEnt.items.filter((x) => x !== '') : [],
    name,
    dir: rel.includes('/') ? rel.slice(0, rel.lastIndexOf('/')) : '',
    stem: name.replace(/\.md$/i, ''),
    cls: classify(rel),
    h1,
  };
}

// ----------------------------- checks -------------------------------------

function checkNames(d) {
  const parts = d.rel.split('/');
  const file = parts[parts.length - 1];
  if (file !== 'README.md' && !SLUG_RE.test(file.replace(/\.md$/, ''))) {
    err(d.rel, 'non-kebab-case-name', `'${file}' is not lowercase kebab-case`);
  }
  for (const seg of parts.slice(0, -1)) {
    if (!SLUG_RE.test(seg)) err(d.rel, 'non-kebab-case-name', `folder '${seg}' is not lowercase kebab-case`);
  }
}

function checkMetadata(d) {
  if (d.cls === 'generated') return;
  if (!d.fm) { err(d.rel, 'metadata-outside-contract', `missing frontmatter block for ${d.cls}`, 1); return; }
  const isNote = isNoteClass(d);
  const required = isNote ? NOTE_REQUIRED : (d.cls === 'entry' ? [...CTX_REQUIRED, ENTRY_EXTRA] : CTX_REQUIRED);
  const optional = isNote ? NOTE_OPTIONAL : CTX_OPTIONAL;
  const scalars = isNote ? NOTE_SCALARS : CTX_SCALARS;
  const e = d.entries;
  const one = (k, ent, label) => {
    if (ent.kind === 'blank') return err(d.rel, 'metadata-outside-contract', `${label} key '${k}' is present but blank${label === 'optional' ? ' (omit it entirely)' : ''}`, ent.line);
    const mustScalar = scalars.has(k) || k === 'description';
    if (mustScalar && ent.kind !== 'scalar') return err(d.rel, 'metadata-outside-contract', `key '${k}' must be a scalar`, ent.line);
    if (!mustScalar && ent.kind !== 'list') return err(d.rel, 'metadata-outside-contract', `key '${k}' must be a list`, ent.line);
    if (ent.kind !== 'scalar') return;
    const v = String(ent.value).trim();
    if (k === 'version' && !/^\d+(\.\d+)?(\.\d+)?$/.test(v)) err(d.rel, 'metadata-outside-contract', `version '${v}' is not a number`, ent.line);
    if (k === 'id' && isNote && !SLUG_RE.test(v)) err(d.rel, 'metadata-outside-contract', `id '${v}' is not a slug`, ent.line);
    if ((k === 'last_updated' || k === 'expires_at') && !isValidDate(v)) err(d.rel, 'metadata-outside-contract', `${k} '${v}' is not YYYY-MM-DD`, ent.line);
    if (k === 'status' && !STATUS_ENUM.has(v)) err(d.rel, 'metadata-outside-contract', `status '${v}' not in {draft, active, superseded, expired}`, ent.line);
  };
  for (const k of required) {
    const ent = e.get(k);
    if (!ent) err(d.rel, 'metadata-outside-contract', `required key '${k}' is missing for ${d.cls}`, 1);
    else one(k, ent, 'required');
  }
  for (const k of optional) { const ent = e.get(k); if (ent) one(k, ent, 'optional'); }
  for (const [k, ent] of e) {
    if (!required.includes(k) && !optional.includes(k)) err(d.rel, 'metadata-outside-contract', `key '${k}' is not part of the ${d.cls} contract`, ent.line);
  }
}

// Conservative patterns; prose AND frontmatter (frontmatter is NOT exempt);
// fenced blocks are exempt. Assignment key part is case-insensitive.
const SECRET_PATTERNS = [
  { kind: 'aws-access-key-id', re: /AKIA[0-9A-Z]{16}/g, val: (m) => m[0] },
  { kind: 'private-key-block', re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/g, val: (m) => m[0] },
  { kind: 'secret-assignment', re: /(api[_-]?key|token|secret|password|passwd)\s*[:=]\s*["']?([A-Za-z0-9+/=_\-.]{16,})["']?/gi, val: (m) => m[2] },
  { kind: 'hex-token', re: /(?<![0-9a-fA-F])[a-f0-9]{32,}(?![0-9a-fA-F])/g, val: (m) => m[0] },
];

function checkSecrets(d) {
  for (let i = 0; i < d.lines.length; i++) {
    if (d.mask[i]) continue;
    const line = d.lines[i];
    const reported = []; // spans already reported on this line (pattern precedence)
    for (const p of SECRET_PATTERNS) {
      p.re.lastIndex = 0;
      let m;
      while ((m = p.re.exec(line))) {
        const s = m.index, e = m.index + m[0].length;
        if (reported.some((t) => s < t[1] && e > t[0])) continue;
        reported.push([s, e]);
        // Redacted sketch ONLY: first 4 chars + ellipsis. The value itself
        // must never travel in a finding.
        err(d.rel, 'secret-in-prose', `${p.kind} detected (redacted: ${String(p.val(m)).slice(0, 4)}${ELL})`, i + 1);
      }
    }
  }
}

function checkNoH1(d) {
  if (d.cls === 'generated') return;
  if (!d.h1) warn(d.rel, 'no-h1', 'document has no H1 heading outside code fences');
}

function checkCategory(d) {
  if (!isNoteClass(d)) return;
  if (d.dir === '') return; // root-level notes: no folder to compare
  const cat = d.entries && d.entries.get('category');
  if (!cat || cat.kind !== 'scalar' || !cat.value) return;
  const v = String(cat.value).trim();
  if (v.toLowerCase() !== d.dir.toLowerCase()) {
    warn(d.rel, 'category-mismatch-folder', `category '${v}' does not match folder '${d.dir}/'`, cat.line);
  }
}

function checkDuplicateIds(docs) {
  const seen = new Map();
  for (const d of docs) {
    if (!isNoteClass(d) || !d.id) continue;
    const idEnt = d.entries && d.entries.get('id');
    if (seen.has(d.id)) err(d.rel, 'duplicate-ids', `id '${d.id}' already used by ${seen.get(d.id)}`, idEnt ? idEnt.line : 1);
    else seen.set(d.id, d.rel);
  }
}

/** One resolver, case-insensitive: a target string resolves to a file if it
 *  matches its id OR filename stem OR any alias OR the full relative path
 *  (markdown paths). Normalization: trim, lowercase, strip a trailing `.md`
 *  and a trailing `/`; first-wins over the collected order. */
function buildResolver(docs) {
  const byToken = new Map();
  const norm = (x) => String(x).trim().toLowerCase().replace(/\.md$/, '').replace(/\/$/, '');
  for (const d of docs) {
    const add = (tok) => { const k = norm(tok); if (k && !byToken.has(k)) byToken.set(k, d.rel); };
    add(d.rel); add(d.stem);
    if (d.id) add(d.id);
    for (const a of d.aliases) add(a);
  }
  return {
    resolve(token) {
      const rel = byToken.get(norm(token));
      return rel === undefined ? null : rel;
    },
  };
}

// ----------------------------- graph edges ---------------------------------

/** Builds out/inbound edge sets (related + wikilinks + resolvable relative
 *  markdown links, self-edges dropped) and mdOut (markdown-link-only, for the
 *  registration check), reporting dangling-related-target and dangling-link.
 *  Ignored: http(s)/mailto/data/ftp, pure #fragments; #fragment stripped before
 *  the existence check. Explicit ALL-CAPS name links are enforced literally;
 *  wikilinks inside inline code spans are citations, not links. Backticked
 *  markdown links stay live (anti-smuggling rule). */
function collectEdges(docs, resolver) {
  const out = new Map(), inbound = new Map(), mdOut = new Map();
  for (const d of docs) { out.set(d.rel, new Set()); inbound.set(d.rel, new Set()); mdOut.set(d.rel, new Set()); }
  const link = (from, to) => { if (to && to !== from) { out.get(from).add(to); inbound.get(to).add(from); } };
  const relSet = new Set(docs.map((d) => d.rel));

  for (const d of docs) {
    // related: semantic vocabulary, resolved through the ONE resolver.
    const rel = d.entries && d.entries.get('related');
    if (rel && rel.kind === 'list') {
      for (const item of rel.items) {
        if (!item) continue;
        const hit = resolver.resolve(item);
        if (!hit) err(d.rel, 'dangling-related-target', `related entry '${item}' resolves to no document (ids, stems and aliases all missed)`, rel.line);
        else link(d.rel, hit);
      }
    }
    if (d.cls === 'generated') continue; // artifact preambles are not link sources

    const start = d.fm ? d.fm.end + 1 : 0;
    for (let i = start; i < d.lines.length; i++) {
      if (d.mask[i]) continue; // EXEMPT inside fences
      const line = d.lines[i];

      // (a) wikilinks [[stem]] or [[stem|display]] — additionally skipped when
      // fully inside an inline code span: `[[stem]]` cites the syntax.
      const spans = inlineCodeSpans(line);
      for (const m of line.matchAll(/\[\[([^\[\]|\n]+)(?:\|[^\[\]\n]*)?\]\]/g)) {
        if (spans.some(([s, e]) => s <= m.index && m.index + m[0].length <= e)) continue;
        const token = m[1].trim();
        const hit = resolver.resolve(token);
        if (!hit) err(d.rel, 'dangling-link', `wikilink [[${token}]] resolves to no document`, i + 1);
        else link(d.rel, hit);
      }

      // (b) relative markdown links [t](path) — NOT inline-code exempt.
      for (const m of line.matchAll(/\[[^\]]*\]\(([^)\s]+)\)/g)) {
        let target = m[1].trim();
        if (!target || target.startsWith('#')) continue;
        if (/^(?:https?:|mailto:|data:|ftp:)/i.test(target)) continue;
        target = target.split('#')[0];
        if (!target) continue;
        const abs = path.resolve(ROOT, d.dir, target);
        if (!fs.existsSync(abs)) {
          err(d.rel, 'dangling-link', `markdown link target '${m[1].trim()}' does not exist`, i + 1);
          continue;
        }
        const relT = path.relative(ROOT, abs).split(path.sep).join('/');
        const hit = relSet.has(relT) ? relT : resolver.resolve(target);
        if (hit) { link(d.rel, hit); mdOut.get(d.rel).add(hit); }
      }
    }
  }
  return { inbound, out, mdOut };
}

/** A note-class file with ZERO non-self edges in BOTH directions. WARNING in
 *  this corpus (documented divergence). Context-docs and generated artifacts
 *  are exempt. */
function checkOrphans(docs, out, inbound) {
  for (const d of docs) {
    if (!isNoteClass(d)) continue;
    if (out.get(d.rel).size === 0 && inbound.get(d.rel).size === 0) {
      warn(d.rel, 'orphan-note', 'note has zero resolved non-self edges in both directions');
    }
  }
}

/** Registration, rooted at docs/project.md (onrails' checkHubMembership with
 *  the entry point renamed). For each note-class doc:
 *    - a hub must be a resolvable markdown-link target in project.md;
 *    - a note whose folder has a hub must be referenced BY THAT HUB;
 *    - otherwise (hub-less folder / root-level note) it must be a resolvable
 *      markdown link in project.md.
 *  Context-docs are exempt. WARNING in this corpus (documented downgrade). */
function checkRegistration(docs, out, mdOut) {
  const entryLinks = mdOut.get('project.md') || new Set();
  const hubByDir = new Map();
  for (const d of docs) if (d.cls === 'hub') hubByDir.set(d.dir, d);
  for (const d of docs) {
    if (!isNoteClass(d)) continue;
    if (d.cls === 'hub') {
      if (!entryLinks.has(d.rel)) {
        warn(d.rel, 'missing-from-entry', 'hub is not referenced by a resolvable markdown link in project.md');
      }
      continue;
    }
    const hub = hubByDir.get(d.dir);
    if (hub) {
      if (!out.get(hub.rel).has(d.rel)) {
        warn(d.rel, 'missing-from-entry', `note is not referenced by its hub ${hub.rel} (add it to the hub linked from project.md)`);
      }
    } else if (!entryLinks.has(d.rel)) {
      warn(d.rel, 'missing-from-entry', 'note sits in a hub-less folder and is not referenced by a resolvable markdown link in project.md');
    }
  }
}

// ----------------------------- generated regions ---------------------------

function classCounts(docs) {
  const c = { ctx: 0, note: 0, hub: 0 };
  for (const d of docs) {
    if (d.cls === 'entry' || d.cls === 'context') c.ctx++;
    else if (d.cls === 'hub') c.hub++;
    else if (d.cls === 'note') c.note++;
  }
  return c;
}

function treeLabel(d) {
  return { entry: 'context-doc (entry)', context: 'context-doc', generated: 'generated', hub: 'hub' }[d.cls] || 'note';
}

function idSuffix(d) { return isNoteClass(d) && d.id ? `, id: \`${d.id}\`` : ''; }

/** Body-to-region for index.md (markers + snapshot + body). Root files first:
 *  project.md then tag-index.md (index.md never lists itself); rest of the root
 *  sorted case-insensitively; then folders sorted, files sorted inside. */
function renderIndexRegion(docs) {
  const L = [];
  const c = classCounts(docs);
  L.push('## Generated index', '', '### Overview', '');
  L.push(`- Markdown files: ${docs.length}`); // total scanned = every walked .md incl. artifacts
  L.push(`- Context docs: ${c.ctx} | Notes: ${c.note} | Hubs: ${c.hub}`);
  L.push('', '### Tree', '');
  const fmt = (d, indent) => `${indent}- ${d.name} ${DASH} ${treeLabel(d)}${idSuffix(d)}`;
  for (const rel of ['project.md', 'tag-index.md']) {
    const d = docs.find((x) => x.rel === rel);
    if (d) L.push(fmt(d, ''));
  }
  const rootRest = docs.filter((d) => d.dir === '' && d.rel !== 'index.md' && d.rel !== 'project.md' && d.rel !== 'tag-index.md')
    .sort((a, b) => ciCompare(a.name, b.name));
  for (const d of rootRest) L.push(fmt(d, ''));
  const dirs = [...new Set(docs.filter((d) => d.dir !== '').map((d) => d.dir))].sort(ciCompare);
  for (const dir of dirs) {
    L.push(`- ${dir}/`);
    for (const d of docs.filter((x) => x.dir === dir).sort((a, b) => ciCompare(a.name, b.name))) {
      L.push(fmt(d, '  '));
    }
  }
  return renderRegion('index', L);
}

/** Body-to-region for tag-index.md: one line per distinct tag, tags sorted;
 *  refs sorted. Source = `tags` frontmatter of every scanned md that has
 *  frontmatter. */
function renderTagsRegion(docs) {
  const byTag = new Map();
  for (const d of docs) {
    if (d.cls === 'generated' || !d.entries) continue;
    const tags = d.entries.get('tags');
    if (!tags || tags.kind !== 'list') continue;
    const desc = d.entries.get('description');
    const label = desc && desc.kind === 'scalar' ? desc.value : (d.h1 || d.rel);
    for (const tag of tags.items) {
      if (!byTag.has(tag)) byTag.set(tag, []);
      byTag.get(tag).push(`- \`${d.rel}\` - ${label}`);
    }
  }
  const L = [];
  for (const tag of [...byTag.keys()].sort()) {
    L.push('', `## ${tag}`, '');
    L.push(...byTag.get(tag));
  }
  L.push('');
  return renderRegion('tags', L);
}

/** Wrap a rendered body in its marker pair plus the snapshot line. */
function renderRegion(marker, body) {
  return [
    `<!-- BEGIN GENERATED: ${marker} -->`,
    `<!-- snapshot: ${todayISO()} -->`,
    ...body,
    `<!-- END GENERATED: ${marker} -->`,
  ].join('\n');
}

const SNAPSHOT_RE = /^<!-- snapshot: \d{4}-\d{2}-\d{2} -->$/;

function extractRegion(lines, marker) {
  const b = lines.findIndex((l) => l.trim() === `<!-- BEGIN GENERATED: ${marker} -->`);
  const e = lines.findIndex((l) => l.trim() === `<!-- END GENERATED: ${marker} -->`);
  if (b < 0 || e <= b) return null;
  return { beginLine: b, endLine: e, body: lines.slice(b + 1, e) };
}

const stripSnapshots = (body) => body.filter((l) => !SNAPSHOT_RE.test(l.trim()));

/** Check every generated artifact. Missing file -> error; missing marker pair
 *  -> error; body mismatch after stripping the snapshot line from BOTH sides ->
 *  error. The snapshot line itself is OPTIONAL. */
function checkGeneratedRegions(docs) {
  for (const art of GENERATED_ARTIFACTS) {
    const d = docs.find((x) => x.rel === art.rel);
    if (!d) {
      err(art.rel, 'stale-generated-index', `generated artifact ${art.rel} is missing (create file + marker pair, then run: node docs/validate.js --write)`);
      continue;
    }
    const region = extractRegion(d.lines, art.marker);
    if (!region) {
      err(art.rel, 'stale-generated-index', `${art.rel} is missing its BEGIN/END GENERATED: ${art.marker} marker pair`);
      continue;
    }
    const rendered = extractRegion(art.render(docs).split('\n'), art.marker);
    const expected = rendered ? stripSnapshots(rendered.body).join('\n') : '';
    if (stripSnapshots(region.body).join('\n') !== expected) {
      err(art.rel, 'stale-generated-index',
        `${art.rel} "${art.marker}" region body is out of sync with the corpus (run: node docs/validate.js --write)`, region.beginLine + 1);
    }
  }
}

/** --write: regenerate regions IN EXISTING FILES ONLY (a missing artifact is
 *  never created). Write-if-diff on the full new bytes. First line inside the
 *  regenerated region: `<!-- snapshot: YYYY-MM-DD -->`; body-minus-date
 *  unchanged -> PRESERVE the existing date, else today. */
function regenerateRegions(docs) {
  for (const art of GENERATED_ARTIFACTS) {
    const d = docs.find((x) => x.rel === art.rel);
    if (!d) continue;
    const region = extractRegion(d.lines, art.marker);
    if (!region) continue; // no markers: cannot write safely — the check reports it
    const rendered = extractRegion(art.render(docs).split('\n'), art.marker);
    if (!rendered) continue;
    const body = stripSnapshots(rendered.body);
    let snapshot;
    if (stripSnapshots(region.body).join('\n') === body.join('\n')) {
      const old = region.body.find((l) => SNAPSHOT_RE.test(l.trim()));
      snapshot = old ? old.trim() : `<!-- snapshot: ${todayISO()} -->`;
    } else {
      snapshot = `<!-- snapshot: ${todayISO()} -->`;
    }
    const newLines = [
      ...d.lines.slice(0, region.beginLine + 1),
      snapshot,
      ...body,
      ...d.lines.slice(region.endLine),
    ];
    const eol = d.content.includes('\r\n') ? '\r\n' : '\n';
    const next = newLines.join(eol);
    if (next !== d.content) {
      fs.writeFileSync(path.join(ROOT, art.rel), next, 'utf8');
      process.stderr.write(`wrote: ${art.rel}\n`);
    }
  }
}

// ----------------------------- main ---------------------------------------

function main() {
  if (!fs.existsSync(ROOT)) {
    console.error(`docs-validate: root not found: ${ROOT}`);
    process.exit(1);
  }
  let docs = collect(ROOT, '', []).sort().map(loadDoc);

  // Regenerate before validating, so `--write` reports the post-write state.
  if (WRITE) {
    regenerateRegions(docs);
    docs = collect(ROOT, '', []).sort().map(loadDoc);
  }

  const resolver = buildResolver(docs);
  const { out, inbound, mdOut } = collectEdges(docs, resolver);

  for (const d of docs) {
    checkNames(d);
    checkMetadata(d);
    checkSecrets(d);
    checkNoH1(d);
    checkCategory(d);
  }
  checkDuplicateIds(docs);
  checkOrphans(docs, out, inbound);
  checkRegistration(docs, out, mdOut);
  checkGeneratedRegions(docs);

  for (const w of warnings) console.log(`warning: ${w}`);
  for (const e of errors) console.log(`error:   ${e}`);
  console.log(`\n${errors.length} error(s), ${warnings.length} warning(s) ${DASH} files scanned: ${docs.length} (root: ${ROOT})`);
  process.exit(errors.length > 0 ? 1 : 0);
}

main();
