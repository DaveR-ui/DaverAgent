#!/usr/bin/env node
'use strict';
/*
 * DaverAgent documentation validator — DERIVED from `documentation-onrails`
 * validate.js (v1.4, snapshot 2026-09-12), adapted to a `docs/`-rooted consumer
 * corpus. This is NOT the upstream file and is NOT wired into the global agent
 * system; the per-project bootstrap copies it to <project>/docs/validate.js.
 *
 * Usage:
 *   node validate.js [--root <dir>] [--write]
 *
 *   --root   corpus root (default: the directory containing this script, i.e. the
 *            project's docs/ when shipped there by install-agent.ps1)
 *   --write  regenerate the `tags` region of tag-index.md (write-if-diff)
 *
 * Exit 1 iff there is at least one error. Warnings never fail the run.
 *
 * Checks shipped (adapted subset of onrails' catalog; see the README/guidelines):
 *   ERRORS    metadata-outside-contract, non-kebab-case-name, duplicate-ids,
 *             dangling-related-target, dangling-link, stale-generated-index,
 *             secret-in-prose
 *   WARNINGS  no-h1, category-mismatch-folder, orphan-note, missing-from-entry
 * Deliberate downgrades vs onrails: `orphan-note` and the hub-less protocols
 * registration check (`missing-from-entry` ≈ onrails' `missing-from-hub`) are
 * warnings, not errors — a fresh hub-less protocols folder legitimately has no
 * edges yet (onrails 01 §hub-less schema folders).
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
const DASH = '\u2014';

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
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const SKIP_DIRS = new Set(['.git', 'node_modules', 'diagrams', '.agent-backups']);

const errors = [];
const warnings = [];
const err = (rel, check, msg) => errors.push(`${rel} ${DASH} ${check}: ${msg}`);
const warn = (rel, check, msg) => warnings.push(`${rel} ${DASH} ${check}: ${msg}`);

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

function classify(rel) {
  const parts = rel.split('/');
  const base = parts[parts.length - 1];
  if (rel === 'project.md') return 'entry';
  if (rel === 'tag-index.md') return 'generated';
  if (/-index\.md$/.test(base)) return 'hub'; // onrails hub rule: any *-index.md
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
  const raw = fs.readFileSync(abs, 'utf8');
  const lines = raw.split(/\r?\n/);
  const fm = parseFrontmatter(lines);
  const bodyStart = fm ? fm.end + 1 : 0;
  const body = lines.slice(bodyStart);
  let h1 = null;
  for (const l of body) {
    if (/^#\s+\S/.test(l)) { h1 = l.replace(/^#\s+/, '').trim(); break; }
  }
  return { rel, abs, cls: classify(rel), lines, fm, entries: fm ? fm.entries : null, body, h1 };
}

// ----------------------------- checks --------------------------------------

const SLUG_ID = (rel) => rel.replace(/\.md$/, '').split('/').pop();

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
  if (!d.fm) { err(d.rel, 'metadata-outside-contract', `missing frontmatter block for ${d.cls}`); return; }
  const isNote = d.cls === 'note' || d.cls === 'hub';
  const required = isNote ? NOTE_REQUIRED : (d.cls === 'entry' ? [...CTX_REQUIRED, ENTRY_EXTRA] : CTX_REQUIRED);
  const optional = isNote ? NOTE_OPTIONAL : CTX_OPTIONAL;
  const scalars = isNote ? NOTE_SCALARS : CTX_SCALARS;
  const e = d.entries;
  const one = (k, ent, label) => {
    if (ent.kind === 'blank') return err(d.rel, 'metadata-outside-contract', `${label} key '${k}' is present but blank${label === 'optional' ? ' (omit it entirely)' : ''}`);
    const mustScalar = scalars.has(k) || k === 'description';
    if (mustScalar && ent.kind !== 'scalar') return err(d.rel, 'metadata-outside-contract', `key '${k}' must be a scalar`);
    if (!mustScalar && ent.kind !== 'list') return err(d.rel, 'metadata-outside-contract', `key '${k}' must be a list`);
    if (ent.kind !== 'scalar') return;
    const v = String(ent.value).trim();
    if (k === 'version' && !/^\d+(\.\d+)?(\.\d+)?$/.test(v)) err(d.rel, 'metadata-outside-contract', `version '${v}' is not a number`);
    if (k === 'id' && isNote && !SLUG_RE.test(v)) err(d.rel, 'metadata-outside-contract', `id '${v}' is not a slug`);
    if ((k === 'last_updated' || k === 'expires_at') && !DATE_RE.test(v)) err(d.rel, 'metadata-outside-contract', `${k} '${v}' is not YYYY-MM-DD`);
    if (k === 'status' && !STATUS_ENUM.has(v)) err(d.rel, 'metadata-outside-contract', `status '${v}' not in {draft, active, superseded, expired}`);
  };
  for (const k of required) {
    const ent = e.get(k);
    if (!ent) err(d.rel, 'metadata-outside-contract', `required key '${k}' is missing for ${d.cls}`);
    else one(k, ent, 'required');
  }
  for (const k of optional) { const ent = e.get(k); if (ent) one(k, ent, 'optional'); }
  for (const [k, ent] of e) {
    if (!required.includes(k) && !optional.includes(k)) err(d.rel, 'metadata-outside-contract', `key '${k}' is not part of the ${d.cls} contract`);
  }
}

function resolver(docs) {
  const index = new Map();
  for (const d of docs) {
    const stem = SLUG_ID(d.rel);
    const add = (k) => { const key = String(k).toLowerCase(); if (!index.has(key)) index.set(key, d.rel); };
    add(stem);
    if (d.entries && d.entries.has('id') && d.entries.get('id').kind === 'scalar') add(d.entries.get('id').value);
    if (d.entries && d.entries.has('aliases') && d.entries.get('aliases').kind === 'list') d.entries.get('aliases').items.forEach(add);
  }
  return (name) => index.get(String(name).trim().toLowerCase()) || null;
}

function stripFences(body) {
  const out = [];
  let fence = false;
  for (const l of body) {
    if (/^\s*```/.test(l)) { fence = !fence; continue; }
    if (!fence) out.push(l);
  }
  return out;
}

const SECRET_PATTERNS = [
  { name: 'AWS access key id', re: /AKIA[0-9A-Z]{16}/ },
  { name: 'private key block', re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
  { name: 'secret assignment', re: /(secret|password|passwd|token|api[_-]?key)\s*[:=]\s*['"][^'"]{8,}['"]/i },
  { name: 'hex token', re: /\b[0-9a-f]{32,}\b/ },
];

function checkSecrets(d) {
  // Scan the whole file (frontmatter included), only skipping fenced code.
  for (const l of stripFences(d.lines)) {
    for (const p of SECRET_PATTERNS) {
      if (p.re.test(l)) { err(d.rel, 'secret-in-prose', `possible ${p.name} (value redacted)`); break; }
    }
  }
}

function checkNoH1(d) {
  if (d.cls === 'generated') return;
  if (!d.h1) warn(d.rel, 'no-h1', 'document has no H1 heading outside code fences');
}

function checkGenerated(docs) {
  const abs = path.join(ROOT, 'tag-index.md');
  const raw = fs.readFileSync(abs, 'utf8');
  const whole = raw.match(/<!-- BEGIN GENERATED: tags -->[\s\S]*?<!-- END GENERATED: tags -->/);
  if (!whole) { err('tag-index.md', 'stale-generated-index', 'missing BEGIN/END GENERATED markers for region "tags"'); return; }
  if (!/<!-- snapshot: \d{4}-\d{2}-\d{2} -->/.test(whole[0])) {
    err('tag-index.md', 'stale-generated-index', 'generated region is missing a snapshot line');
    return;
  }
  const stripSnap = (s) => s.replace(/<!-- snapshot: \d{4}-\d{2}-\d{2} -->/g, '').trim();
  if (stripSnap(whole[0]) !== stripSnap(renderTagsRegion(docs))) {
    err('tag-index.md', 'stale-generated-index', 'generated region is out of date; run node docs/validate.js --write');
  }
}

function checkCategory(d) {
  if (d.cls !== 'note' && d.cls !== 'hub') return;
  const parts = d.rel.split('/');
  if (parts.length < 2) return;
  const folder = parts[parts.length - 2];
  const cat = d.entries && d.entries.get('category');
  if (cat && cat.kind === 'scalar' && String(cat.value).trim() !== folder) {
    warn(d.rel, 'category-mismatch-folder', `category '${cat.value}' does not match folder '${folder}'`);
  }
}

function checkDuplicateIds(docs) {
  const seen = new Map();
  for (const d of docs) {
    if (d.cls !== 'note' || !d.entries) continue;
    const id = d.entries.get('id');
    if (id && id.kind === 'scalar') {
      const k = String(id.value).trim();
      if (seen.has(k)) err(d.rel, 'duplicate-ids', `id '${k}' already used by ${seen.get(k)}`);
      else seen.set(k, d.rel);
    }
  }
}

function checkEdges(docs) {
  const resolve = resolver(docs);
  const inbound = new Map(docs.map((d) => [d.rel, 0]));
  for (const d of docs) {
    if (d.entries && d.entries.has('related')) {
      const ent = d.entries.get('related');
      if (ent.kind === 'list') {
        for (const t of ent.items) {
          if (t === '') continue;
          const hit = resolve(t);
          if (!hit) err(d.rel, 'dangling-related-target', `related target '${t}' does not resolve`);
          else if (hit !== d.rel) inbound.set(hit, (inbound.get(hit) || 0) + 1);
        }
      }
    }
    for (const rawLine of stripFences(d.body)) {
      const line = rawLine.replace(/`[^`]*`/g, ''); // inline code is not a link
      const mdLinks = [];
      const wikiLinks = [];
      let m;
      const re = /\[[^\]]*\]\(([^)]+)\)/g;
      while ((m = re.exec(line))) mdLinks.push(m[1]);
      const wiki = /\[\[([^\]]+)\]\]/g;
      while ((m = wiki.exec(line))) wikiLinks.push(m[1]);

      // wikilinks resolve through the id/stem/alias resolver (onrails), not the FS
      for (let token of wikiLinks) {
        token = token.trim();
        if (token === '') continue;
        const hit = resolve(token);
        if (!hit) err(d.rel, 'dangling-link', `wikilink '[[${token}]]' does not resolve`);
        else if (hit !== d.rel) inbound.set(hit, (inbound.get(hit) || 0) + 1);
      }

      // relative markdown links resolve as filesystem paths
      for (let target of mdLinks) {
        target = target.trim();
        if (/^(https?:|mailto:|#)/i.test(target)) continue;
        const clean = target.split('#')[0];
        if (clean === '') continue;
        if (clean.startsWith('/')) { err(d.rel, 'dangling-link', `absolute link '${target}'`); continue; }
        const abs = path.resolve(path.dirname(d.abs), clean);
        if (!fs.existsSync(abs)) err(d.rel, 'dangling-link', `link target '${target}' does not exist`);
        else {
          const rel = path.relative(ROOT, abs).split(path.sep).join('/');
          if (inbound.has(rel)) inbound.set(rel, inbound.get(rel) + 1);
        }
      }
    }
  }
  return inbound;
}

function checkOrphans(docs, inbound) {
  for (const d of docs) {
    if (d.cls !== 'note') continue;
    const rel = d.entries && d.entries.get('related');
    const hasRelated = rel && rel.kind === 'list' && rel.items.some((x) => x !== '');
    if (!hasRelated && (inbound.get(d.rel) || 0) === 0) {
      warn(d.rel, 'orphan-note', 'note has no related entries and no inbound links');
    }
  }
}

function checkRegistration(docs) {
  const project = docs.find((d) => d.rel === 'project.md');
  if (!project) return;
  const text = project.body.join('\n');
  for (const d of docs) {
    if (d.cls !== 'note' || !d.rel.startsWith('protocols/')) continue;
    const file = d.rel.split('/').pop();
    if (!text.includes(file) && !text.includes(d.rel)) {
      warn(d.rel, 'missing-from-entry', `not registered from docs/project.md (link it from the Context Index)`);
    }
  }
}

// ----------------------------- tag regeneration ---------------------------

function renderTagsRegion(docs) {
  const today = new Date().toISOString().slice(0, 10);
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
  const out = ['<!-- BEGIN GENERATED: tags -->', `<!-- snapshot: ${today} -->`];
  for (const tag of [...byTag.keys()].sort()) {
    out.push('', `## ${tag}`, '');
    out.push(...byTag.get(tag));
  }
  out.push('', '<!-- END GENERATED: tags -->');
  return out.join('\n');
}

function writeTags(docs) {
  const abs = path.join(ROOT, 'tag-index.md');
  if (!fs.existsSync(abs)) return false;
  const raw = fs.readFileSync(abs, 'utf8');
  const region = renderTagsRegion(docs);
  const re = /<!-- BEGIN GENERATED: tags -->[\s\S]*?<!-- END GENERATED: tags -->/;
  if (!re.test(raw)) return false;
  const next = raw.replace(re, region);
  if (next === raw) return false;
  fs.writeFileSync(abs, next, 'utf8');
  return true;
}

// ----------------------------- main ---------------------------------------

function main() {
  if (!fs.existsSync(ROOT)) {
    console.error(`docs-validate: root not found: ${ROOT}`);
    process.exit(1);
  }
  const rels = collect(ROOT, '', []).sort();
  const docs = rels.map(loadDoc);

  // Regenerate before validating, so `--write` reports the post-write state.
  if (WRITE) writeTags(docs);

  for (const d of docs) {
    checkNames(d);
    checkMetadata(d);
    checkSecrets(d);
    checkNoH1(d);
    checkCategory(d);
  }
  if (!fs.existsSync(path.join(ROOT, 'tag-index.md'))) {
    err('tag-index.md', 'stale-generated-index', 'generated artifact is missing');
  } else {
    checkGenerated(docs);
  }
  checkDuplicateIds(docs);
  const inbound = checkEdges(docs);
  checkOrphans(docs, inbound);
  checkRegistration(docs);

  for (const w of warnings) console.log(`warning: ${w}`);
  for (const e of errors) console.log(`error:   ${e}`);
  console.log(`\n${errors.length} error(s), ${warnings.length} warning(s) ${DASH} files scanned: ${docs.length} (root: ${ROOT})`);
  process.exit(errors.length > 0 ? 1 : 0);
}

main();
