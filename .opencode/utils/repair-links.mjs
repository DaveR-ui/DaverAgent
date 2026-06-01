import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve, dirname, relative, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '../..');

// Accept target directory as CLI argument, default to project root
const targetDir = process.argv[2] ? resolve(process.argv[2]) : projectRoot;

const EXCLUDED_DIRS = ['cache-session', 'node_modules', '.git', 'dist', 'build', '.next'];

/**
 * Recursively collect all .md files.
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
 * Build a map of filename -> absolute path(s).
 */
function buildFileMap(mdFiles) {
  const map = new Map();
  for (const file of mdFiles) {
    const name = basename(file);
    if (!map.has(name)) map.set(name, []);
    map.get(name).push(file);
  }
  return map;
}

/**
 * Remove fenced code blocks from content, preserving line count
 * so line-based processing stays aligned.
 */
function stripFencedCodeBlocks(content) {
  return content.replace(/```[\s\S]*?```/g, (match) => {
    return match.replace(/[^\n]/g, '');
  });
}

/**
 * Remove inline code spans from a line.
 */
function stripInlineCode(line) {
  return line.replace(/`[^`]*`/g, '');
}

const mdFiles = collectMdFiles(targetDir);
const fileMap = buildFileMap(mdFiles);

console.log(`Scanning: ${relative(projectRoot, targetDir) || targetDir}`);
console.log(`Found ${mdFiles.length} markdown file(s).\n`);

let totalFixed = 0;
let totalAmbiguous = 0;

for (const file of mdFiles) {
  const rawContent = readFileSync(file, 'utf-8');
  const cleanedContent = stripFencedCodeBlocks(rawContent);
  const cleanedLines = cleanedContent.split('\n');

  let modified = false;
  let result = rawContent;

  // Process lines in reverse order so replacements don't shift earlier line numbers
  for (let i = cleanedLines.length - 1; i >= 0; i--) {
    const line = stripInlineCode(cleanedLines[i]);
    const linkRegex = /(?<!!)\[([^\]]*)\]\(([^)]+)\)/g;
    let match;
    while ((match = linkRegex.exec(line)) !== null) {
      const rawPath = match[2].trim();
      if (/^https?:\/\//.test(rawPath) || rawPath.startsWith('#')) continue;

      const [pathPart, anchorPart] = rawPath.split('#');
      const cleanPath = pathPart.trim();
      if (!cleanPath) continue;

      const sourceDir = dirname(file);
      const resolved = resolve(sourceDir, cleanPath);

      if (existsSync(resolved)) continue;

      // Link is broken, try to find the file by name
      const fileName = basename(cleanPath);
      const candidates = fileMap.get(fileName) || [];

      if (candidates.length === 1) {
        const targetPath = candidates[0];
        const newRelativePath = relative(sourceDir, targetPath).replace(/\\/g, '/');
        const newLink = anchorPart ? `${newRelativePath}#${anchorPart}` : newRelativePath;
        console.log(`Fixed: ${relative(targetDir, file)}:${i + 1} -> [${match[1]}](${newLink})`);
        totalFixed++;
        modified = true;
        // Replace in the original content (on the original line)
        const originalLine = rawContent.split('\n')[i];
        const newLine = originalLine.replace(match[0], `[${match[1]}](${newLink})`);
        result = result.split('\n').map((l, idx) => idx === i ? newLine : l).join('\n');
      } else if (candidates.length > 1) {
        console.warn(`Ambiguous: ${fileName} in ${relative(targetDir, file)}:${i + 1}. Candidates: ${candidates.map(c => relative(targetDir, c)).join(', ')}`);
        totalAmbiguous++;
      }
    }
  }

  if (modified) {
    writeFileSync(file, result, 'utf-8');
  }
}

console.log(`\nDone! Fixed: ${totalFixed}, Ambiguous: ${totalAmbiguous}`);
