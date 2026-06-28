# Protocol: Documentation Maintenance

Conventions for validating and maintaining documentation health. Checks broken links, code-doc consistency, duplicate content, content placement, and dead references.

## Inputs

1. **Documentation root** — directory containing markdown files to validate
2. **Code root** (optional) — directory containing source code for consistency checks
3. **Project context** from the project entry point (see `.opencode/conventions.md` for module structure reference)

## Validation phases

### Phase 1: Structural validation (automated)

Run link validation to check documentation health:

1. **Internal link scan** — scan all `.md` files for broken internal links (relative paths that do not resolve).
2. **Auto-repair** — fix unambiguous broken links where the target filename matches exactly one candidate.
3. **Report ambiguous** — list links that could not be auto-repaired (multiple candidates or no match).

Note: dedicated link-validation scripts (e.g., `validate-links.mjs`, `repair-links.mjs`) are not yet provided. This phase can be performed manually or with a custom script until tooling is added.

### Phase 2: Semantic validation (LLM-driven)

#### 2.1 Code-doc consistency

For each documentation file:

1. Extract named entities: module names, function names, class names, endpoint paths, config keys.
2. Cross-reference with actual code files.
3. Flag entities mentioned in docs but not found in code (stale references).
4. Flag entities in code not mentioned in docs (undocumented features).

#### 2.2 Duplicate content detection

1. Compare content across documentation files.
2. Identify sections with significant overlap (>60% similarity).
3. Flag duplicates and suggest which file should be the source of truth.
4. Note: some duplication is intentional (e.g., quickstart in README + detailed guide).

#### 2.3 Content placement verification

1. For each doc file, assess if its content belongs there.
2. Check against project structure conventions:
   - API docs should be in API-related files, not general READMEs
   - Setup instructions should be in setup/deployment docs
   - Architecture decisions should be in architecture docs
3. Flag misplaced content with suggested destination.

#### 2.4 Dead reference detection

1. Find references to files, directories, or components that no longer exist.
2. Check for references to removed features or deprecated modules.
3. Flag outdated version numbers or release references.

### Phase 3: External validation (optional, on request)

1. **External URL liveness** — check if http/https URLs in docs are still accessible.
2. **API endpoint verification** — verify documented API endpoints exist and respond.
3. **Dependency version check** — verify referenced package versions are current.

## Output template

```markdown
## Documentation Validation Report

### Summary
- **Files scanned**: [count]
- **Total issues**: [count]
- **Critical**: [count]
- **Warnings**: [count]
- **Info**: [count]

### Phase 1: Structural Validation

#### Broken Internal Links
| Source File | Line | Broken Link | Status |
|-------------|------|-------------|--------|
| [file.md] | [N] | [broken/path] | ❌ broken |
| [file.md] | [N] | [old/path] | ✅ auto-fixed → [new/path] |
| [file.md] | [N] | [ambiguous] | ⚠️ ambiguous: [candidates] |

#### Link Repair Summary
- **Auto-fixed**: [count]
- **Ambiguous (manual review needed)**: [count]
- **Still broken**: [count]

### Phase 2: Semantic Validation

#### Code-Doc Consistency
| Doc File | Reference | Type | Status | Notes |
|----------|-----------|------|--------|-------|
| [file.md] | [functionName] | function | ❌ not found in code | Stale reference |
| [file.md] | [modulePath] | module | ✅ exists | |
| [file.md] | [newFeature] | feature | ⚠️ undocumented | Exists in code, not in docs |

#### Duplicate Content
| Files Involved | Overlapping Content | Recommendation |
|----------------|---------------------|----------------|
| [file1.md], [file2.md] | [description of overlap] | Keep in [file1.md], remove from [file2.md] or cross-reference |

#### Content Placement
| File | Misplaced Content | Suggested Destination |
|------|-------------------|----------------------|
| [file.md] | [description] | [other-file.md] |

#### Dead References
| Doc File | Reference | What It Points To | Status |
|----------|-----------|-------------------|--------|
| [file.md] | [reference] | [file/component] | ❌ no longer exists |

### Phase 3: External Validation (if requested)

#### External URLs
| Doc File | URL | Status | Notes |
|----------|-----|--------|-------|
| [file.md] | https://... | ✅ alive | |
| [file.md] | https://... | ❌ 404 | Page not found |

### Recommendations
1. [Priority action item]
2. [Secondary action item]
3. [Maintenance suggestion]
```

## Severity classification

| Level | Criteria | Action |
|-------|----------|--------|
| **CRITICAL** | Broken links, references to non-existent code, dead file references | Fix immediately |
| **WARNING** | Duplicate content, misplaced info, ambiguous links, undocumented features | Review and fix |
| **INFO** | External links to verify, stylistic suggestions, minor inconsistencies | Optional improvement |

## Script integration

Phase 1 (structural validation) is designed to be automated with link-validation scripts. Until dedicated scripts are provided, this phase can be performed manually by scanning `.md` files for broken relative links.

When scripts are available, they should:
- Scan all `.md` files in the target directory.
- Exclude: `node_modules`, `.git`, cache directories.
- Output broken links with file:line references.
- Auto-repair links where the filename matches exactly one candidate.
- Report ambiguous cases (multiple files with same name).

## Usage patterns

- **Quick check (links only)**: Run Phase 1 (structural validation) and report results.
- **Full validation**: Run structural + semantic phases. Include code-doc consistency check against the code directory.
- **After code changes**: Validate documentation after changes to a module/feature. Focus on code-doc consistency for the changed areas.
- **Maintenance mode**: Run full validation including external URL checks. Generate a complete health report.

## Notes

- Phase 1 (structural) is fast and deterministic — always run it.
- Phase 2 (semantic) requires LLM analysis — use when thoroughness is needed.
- Phase 3 (external) is optional and slower — only run on request.
- The scripts are reusable utilities — they can also be called directly from CI/CD.
- Some duplication in docs is acceptable (e.g., README summary + detailed guide) — use judgment.
- Code-doc consistency checks should be scoped to relevant modules, not the entire codebase.
