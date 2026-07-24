# Protocol: Prompt Pre-processor (Step 0a)

Deterministic keyword extraction that runs BEFORE the `interpreter` subagent (Step 0) on every prompt. It costs zero LLM tokens and gives the interpreter a first-pass map of the prompt's terms against the project docs.

## Location and invocation

Script: `.opencode/scripts/extract-keywords.sh` (pure bash + `grep`/`sed`/`awk`/`tr`; no `jq`, python, or node dependency).

From the repo root, via PowerShell or any POSIX shell:

```powershell
echo "arreglar lost est" | bash .opencode/scripts/extract-keywords.sh
```

```bash
bash .opencode/scripts/extract-keywords.sh "fix the authview filters"
```

The script resolves `docs/project.md` and `docs/context/README.md` relative to its own location, so it works from any cwd.

## Input contract

- argv (all args joined with spaces) wins over stdin.
- If neither carries content, the prompt is empty — the script still emits valid JSON with empty arrays.

## Processing rules

1. Lowercase the prompt.
2. Keep `[a-z0-9]`; every other byte becomes a separator (ASCII-only extraction, `LC_ALL=C`).
3. Split into terms; drop terms shorter than 3 chars; dedupe preserving first-seen order.
4. For each term, run a case-insensitive substring `grep -F` against `docs/project.md` and `docs/context/README.md`, capped at 8 matches per term total.
5. Extract candidate slice ids: any Slices-table row in `docs/project.md` that mentions a term contributes its backtick-quoted slice id(s) from the first column.

## Output contract

A single JSON object on stdout:

```json
{
  "raw_prompt": "arreglar lost est",
  "extracted_terms": ["arreglar", "lost", "est"],
  "matches": {
    "arreglar": [],
    "lost": ["docs/project.md:93: | `data-requests` | Data requests list grids, ..."],
    "est": ["docs/project.md:93: ...", "docs/context/README.md:33: ..."]
  },
  "candidates": ["testing", "data-requests"]
}
```

- `raw_prompt` is passed through verbatim (JSON-escaped) so the interpreter still sees the human's original language.
- `matches` values are `"path:line: content"` strings.
- `candidates` is deduplicated.

## Exit-code contract

**The script ALWAYS exits 0.** Empty matches, missing docs files, and empty input are all valid states, not errors. The pre-processor must never fail the pipeline. If the script itself is unavailable, delivery skips Step 0a and the interpreter reconciles vocabulary on its own (its `grep`/`glob` tools cover the same ground).

## How it feeds Step 0

Delivery runs the script, then invokes the `interpreter` subagent with the raw prompt plus this keyword packet. The interpreter treats the packet as the starting point for its mandatory vocabulary reconciliation: it verifies the packet's candidates against the Slices table and fills the gaps the deterministic pass missed (typos, aliases, non-ASCII terms, semantic matches a substring grep cannot see).

## Portability notes

- Runs on Git Bash and WSL. On Windows PowerShell 5.1, `bash` resolves to one of those; invoke with the `bash <script>` form shown above.
- The file MUST keep LF line endings. If a checkout converts it to CRLF, re-save with LF.
- PowerShell 5.1 pipes to native commands with an ASCII-default encoding; for prompts with accents, prefer running inside the bash session rather than piping from PowerShell.

## Known limitations

- ASCII-only: accented characters act as separators, so a term like `señal` never reaches the docs as one token. The interpreter recovers these semantically.
- Substring matching over-matches by design (e.g. `est` matches `test`, `request`). Recall is deterministic; precision is the interpreter's job.
- No stemming, no typo tolerance, no semantic ranking.

## Manual test

```powershell
echo "arreglar lost est" | bash .opencode/scripts/extract-keywords.sh
```

Expected: valid JSON on stdout, exit code 0, `extracted_terms` containing `arreglar`, `lost`, `est`.
