# project.md Policy

## Two-Tier Structure

| Tier | Location | Content |
|------|----------|---------|
| **Source** | `projects/{project_id}/project.md` | Faithful copy of repo's `.opencode/project.md` with review metadata header. Updated when repo changes. |
| **Sessions copy** | `sessions/{human_id}/{project_id}/project.md` | Condensed version for fast context loading. |

## Sessions Copy Contains

1. **Overview** - project name, ID, description
2. **Technology Stack** - single-line per category
3. **Architecture** - 3-line summary (pattern, data flow, structure)
4. **Project Slang** - inferred from codebase with confidence levels (High/Medium/Low)
5. **Key Skills** - list of available skills
6. **Additional Notes** - pointers to key documentation files
7. **Review metadata** - Last Reviewed, Next Review Due, Cadence

## Review Cadence

- Default: **monthly (~30 days)**
- Review earlier if:
  - Repo's `.opencode/project.md` changed materially
  - Architecture or base technology changed
  - Current task needs context not covered by the snapshot
