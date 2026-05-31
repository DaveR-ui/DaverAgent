---
name: context-reductor
description: Analyzes prompts and project structure to identify the minimal set of modules, files, and dependencies that form the scope of a problem. Use when you need to define boundaries and focus areas before development work begins.
license: MIT
metadata:
  audience: developers
  workflow: scope-definition
---

## What I Do

- **Identify relevant modules** that are in scope for the given prompt
- **Define boundaries** between what is IN scope and what is OUT of scope
- **List key files** that will need to be read or modified
- **Map dependencies** between modules to understand impact
- **Reduce noise** by filtering out unrelated parts of the codebase

## When to Use Me

Use this skill when:
- A prompt has been enhanced and you need to define the scope of work
- You want to know which modules/files are relevant to a task
- You need to establish clear boundaries before starting development
- You want to avoid scope creep by explicitly defining exclusions

## Scope Analysis Process

1. **Receive input**: Enhanced prompt (from canonical-prompter) + project context (from project.md)
2. **Parse requirements**: Extract entities, features, and areas mentioned in the prompt
3. **Map to modules**: Identify which project modules correspond to the requirements
4. **Trace dependencies**: Find upstream and downstream dependencies
5. **Define boundaries**: Explicitly state what is IN and OUT of scope
6. **Output**: Return a structured scope definition

## Scope Definition Template

```markdown
## Scope Definition

### Problem Summary
[Brief summary of what needs to be solved]

### In-Scope Modules
| Module | Description | Why In Scope |
|--------|-------------|--------------|
| [Module name] | [What it does] | [Connection to the problem] |

### Out-of-Scope (Explicit Exclusions)
| Module/Area | Why Out of Scope |
|-------------|------------------|
| [Module name] | [Reason for exclusion] |

### Key Files
| File | Purpose | Action Needed |
|------|---------|---------------|
| [path/to/file] | [What it contains] | [read/modify/create] |

### Dependencies
- **Upstream**: [Modules this work depends on]
- **Downstream**: [Modules that depend on this work]

### Risk Areas
- [Areas where changes could have unexpected side effects]
- [Legacy code or technical debt to be aware of]

### Assumptions
- [Any assumptions made during scope definition]
```

## Module Identification Rules

1. **Direct mention**: If the prompt explicitly mentions a module or feature, it's in scope
2. **Functional dependency**: If a module provides functionality needed by the task, it's in scope
3. **Data dependency**: If a module owns data that will be modified, it's in scope
4. **UI/UX boundary**: If the task affects user interface, include the relevant UI modules
5. **API boundary**: If the task affects APIs, include the relevant endpoint and handler modules

## Boundary Definition Guidelines

### Always define OUT of scope:
- Features or modules not affected by the change
- Future improvements that could be confused with current work
- Related but separate concerns

### Be specific:
- Use actual module names from the project
- Reference actual file paths when possible
- Avoid vague descriptions like "other stuff"

## Examples

### Input
```
Enhanced Prompt: Add user profile picture upload functionality
Project: Go backend with React frontend, uses PostgreSQL, S3 for file storage
```

### Output
```markdown
## Scope Definition

### Problem Summary
Implement user profile picture upload, storage, and display functionality.

### In-Scope Modules
| Module | Description | Why In Scope |
|--------|-------------|--------------|
| User Service | Manages user data | Needs to store profile picture URL |
| File Upload Handler | Handles multipart uploads | Core upload functionality |
| S3 Integration | Cloud storage client | Stores the actual image files |
| Profile Component (Frontend) | Displays user profile | Shows and allows uploading picture |
| User API Endpoints | REST API for user operations | New endpoint for picture upload |

### Out-of-Scope (Explicit Exclusions)
| Module/Area | Why Out of Scope |
|-------------|------------------|
| User Authentication | Not affected by profile pictures |
| Image Processing/Thumbnails | Out of scope for MVP |
| Other User Profile Fields | Only picture is in scope |
| Admin User Management | Admin features not affected |

### Key Files
| File | Purpose | Action Needed |
|------|---------|---------------|
| internal/domain/user.go | User entity definition | Modify - add ProfilePictureURL field |
| internal/service/user_service.go | User business logic | Modify - add upload method |
| internal/transport/http/handler/user_handler.go | User HTTP handlers | Modify - add upload endpoint |
| internal/transport/http/router.go | Route definitions | Modify - register upload route |
| src/components/Profile.tsx | Profile UI component | Modify - add picture upload UI |
| src/services/userApi.ts | Frontend API calls | Modify - add upload function |

### Dependencies
- **Upstream**: S3 client configuration, Authentication middleware (for user context)
- **Downstream**: Profile display components, User list components (if they show avatars)

### Risk Areas
- File size limits and validation
- S3 bucket permissions and CORS configuration
- Existing user data migration (null profile pictures)

### Assumptions
- S3 bucket already exists and is configured
- Users can only upload one profile picture (not a gallery)
- Image validation will be basic (file type and size only)
```
