---
name: doc-maintainer
description: Validates and maintains documentation health. Checks broken links, code-doc consistency, duplicate content, content placement, and dead references. Use when documentation quality needs to be verified or after code changes that may affect docs.
license: MIT
metadata:
  category: maintenance
  workflow: documentation-validation
  phase: standalone
---

## What I Do

- **Validate internal links** - find broken markdown links between documentation files
- **Repair broken links** - auto-fix unambiguous broken links by filename matching
- **Check code-doc consistency** - verify that module names, functions, endpoints mentioned in docs exist in actual code
- **Detect duplicate content** - find information repeated across multiple documentation files
- **Verify content placement** - ensure information lives in the correct file
- **Detect dead references** - find references to files, components, or modules that no longer exist
- **Output structured report** - severity-classified validation results

## When to Use Me

Use this skill when:
- User asks to validate or review documentation
- Code changes have been made and docs may be stale
- Before a release or milestone to ensure docs are healthy
- New documentation has been added and needs quality checks
- User reports confusion about where to find information

## Input Requirements

1. **Documentation root** - directory containing markdown files to validate
2. **Code root** (optional) - directory containing source code for consistency checks
3. **Project context** from `docs/project.md` (for module structure reference)

## Validation Process

### Phase 1: Structural Validation (Automated)

Run the link validation scripts:

1. **Internal link scan** - execute `validate-links.mjs` to find all broken internal links
2. **Auto-repair** - execute `repair-links.mjs` to fix unambiguous broken links
3. **Report ambiguous** - list links that could not be auto-repaired (multiple candidates)

Scripts location: `.opencode/utils/validate-links.mjs` and `.opencode/utils/repair-links.mjs`

### Phase 2: Semantic Validation (LLM-Driven)

#### 2.1 Code-Doc Consistency
For each documentation file:
1. Extract named entities: module names, function names, class names, endpoint paths, config keys
2. Cross-reference with actual code files
3. Flag entities mentioned in docs but not found in code (stale references)
4. Flag entities in code not mentioned in docs (undocumented features)

#### 2.2 Duplicate Content Detection
1. Compare content across documentation files
2. Identify sections with significant overlap (>60% similarity)
3. Flag duplicates and suggest which file should be the source of truth
4. Consider: some duplication is intentional (e.g., quickstart in README + detailed guide)

#### 2.3 Content Placement Verification
1. For each doc file, assess if its content belongs there
2. Check against project structure conventions:
   - API docs should be in API-related files, not general READMEs
   - Setup instructions should be in setup/deployment docs
   - Architecture decisions should be in architecture docs
3. Flag misplaced content with suggested destination

#### 2.4 Dead Reference Detection
1. Find references to files, directories, or components that no longer exist
2. Check for references to removed features or deprecated modules
3. Flag outdated version numbers or release references

### Phase 3: External Validation (Optional, on request)

1. **External URL liveness** - check if http/https URLs in docs are still accessible
2. **API endpoint verification** - verify documented API endpoints exist and respond
3. **Dependency version check** - verify referenced package versions are current

## Output Template

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

## Severity Classification

| Level | Criteria | Action |
|-------|----------|--------|
| **CRITICAL** | Broken links, references to non-existent code, dead file references | Fix immediately |
| **WARNING** | Duplicate content, misplaced info, ambiguous links, undocumented features | Review and fix |
| **INFO** | External links to verify, stylistic suggestions, minor inconsistencies | Optional improvement |

## Integration with Scripts

### validate-links.mjs
```bash
node .opencode/utils/validate-links.mjs
```
- Scans all `.md` files in the target directory
- Excludes: `node_modules`, `.git`, `cache-session`
- Outputs broken links with file:line references
- Exit code 0 = all good, 1 = broken links found

### repair-links.mjs
```bash
node .opencode/utils/repair-links.mjs
```
- Same scanning as validate-links
- Auto-repairs links where filename matches exactly one candidate
- Reports ambiguous cases (multiple files with same name)
- Processes in reverse order to preserve line numbers

### Adapting Scripts for This Project

Copy scripts from `Agente angular separado v2/.agents/utils/` to `.opencode/utils/`:
- Update the `agentsRoot` variable to point to the correct documentation root
- Ensure exclusion list matches project conventions

## Usage Patterns

### Quick Check (links only)
```
Run validate-links.mjs and report results.
```

### Full Validation
```
Run the complete doc-maintainer validation: structural + semantic.
Include code-doc consistency check against [code directory].
```

### After Code Changes
```
Validate documentation after changes to [module/feature].
Focus on code-doc consistency for the changed areas.
```

### Maintenance Mode
```
Run full validation including external URL checks.
Generate a complete health report.
```

## Notes

- Phase 1 (structural) is fast and deterministic - always run it
- Phase 2 (semantic) requires LLM analysis - use when thoroughness is needed
- Phase 3 (external) is optional and slower - only run on request
- The scripts are reusable utilities - they can also be called directly from CI/CD
- Some duplication in docs is acceptable (e.g., README summary + detailed guide) - use judgment
- Code-doc consistency checks should be scoped to relevant modules, not the entire codebase
