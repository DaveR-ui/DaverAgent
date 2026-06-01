import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '../..');

// Accept target directory as CLI argument, default to project root
const targetDir = process.argv[2] ? resolve(process.argv[2]) : projectRoot;

const EXCLUDED_DIRS = ['cache-session', 'node_modules', '.git', 'dist', 'build', '.next'];

/**
 * Recursively collect all .md files under a directory, skipping excluded dirs.
 */
function collectMdFiles(dir, base = dir) {
  const results = [];
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      const relName = relative(base, fullPath).split(/[\\/]/)[0];
      if (EXCLUDED_DIRS.includes(relName)) continue;
      results.push(...collectMdFiles(fullPath, base));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      results.push(fullPath);
    }
  }
  return results;
}

/**
 * Remove fenced code blocks (```...```) from content so links inside them
 * are not parsed as real links.
 */
function stripFencedCodeBlocks(content) {
  return content.replace(/```[\s\S]*?```/g, (match) => {
    return match.replace(/[^\n]/g, '');
  });
}

/**
 * Remove inline code spans (`...`) from a single line so backtick-wrapped
 * link-like text is ignored.
 */
function stripInlineCode(line) {
  return line.replace(/`[^`]*`/g, '');
}

/**
 * Extract markdown links [text](path) from file content.
 * Returns array of { line, linkPath }.
 * Skips: images ![alt](path), external URLs, anchor-only links,
 *         links inside fenced code blocks, and links inside inline code.
 */
function extractLinks(content) {
  const links = [];
  const cleaned = stripFencedCodeBlocks(content);
  const lines = cleaned.split('\n');
  const linkRegex = /(?<!!)\[([^\]]*)\]\(([^)]+)\)/g;

  for (let i = 0; i < lines.length; i++) {
    const line = stripInlineCode(lines[i]);
    let match;
    linkRegex.lastIndex = 0;
    while ((match = linkRegex.exec(line)) !== null) {
      const rawPath = match[2].trim();
      if (/^https?:\/\//.test(rawPath)) continue;
      if (rawPath.startsWith('#')) continue;
      const cleanPath = rawPath.split(/\s+"?/)[0].trim();
      links.push({ line: i + 1, linkPath: cleanPath });
    }
  }
  return links;
}

/**
 * Resolve a link path relative to the source file's directory.
 */
function resolveLink(sourceFile, linkPath) {
  const sourceDir = dirname(sourceFile);
  const pathOnly = linkPath.split('#')[0];
  if (!pathOnly) return null;
  return resolve(sourceDir, pathOnly);
}

// Main
console.log(`Scanning: ${relative(projectRoot, targetDir) || targetDir}`);
const mdFiles = collectMdFiles(targetDir);
console.log(`Found ${mdFiles.length} markdown file(s).\n`);

const brokenLinks = [];

for (const file of mdFiles) {
  const content = readFileSync(file, 'utf-8');
  const links = extractLinks(content);
  for (const { line, linkPath } of links) {
    const resolved = resolveLink(file, linkPath);
    if (!resolved) continue;
    if (!existsSync(resolved)) {
      brokenLinks.push({
        source: relative(targetDir, file),
        line,
        linkPath,
      });
    }
  }
}

if (brokenLinks.length === 0) {
  console.log('All internal links are valid.');
  process.exit(0);
} else {
  console.log(`Found ${brokenLinks.length} broken link(s):\n`);
  for (const { source, line, linkPath } of brokenLinks) {
    console.log(`  ${source}:${line} -> ${linkPath}`);
  }
  process.exit(1);
}
