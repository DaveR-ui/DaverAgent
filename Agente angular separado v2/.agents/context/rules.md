# Development Rules and Standards

Non-negotiable rules to maintain high quality and security in the backend.

## Documentation Language
- **Rule**: All documentation, code comments, and project-related files MUST be written in **ENGLISH**.

## Code Standards
- **Naming**: CamelCase vs snake_case, interface prefixes, etc.
- **Lints & Formatting**: Required tools and configurations.
- **Documentation**: Commenting standard (Godoc, JSDoc).

## Error Handling and Logs
- Custom error structures.
- Log levels (Info, Warn, Error, Debug).
- Context in logs (RequestID, userID).

## Security
- **Auth**: JWT, OAuth2, token management.
- **Validation**: Input validation libraries (Zod, Go Validator).
- **Sanitization**: SQL Injection and XSS prevention.

## Testing
- Coverage requirements.
- Test naming and location.
- Mocks vs Real DBs in integration tests.

## Database and Migrations
- **Non-Production Status**: The application is currently in development and NOT in production.
- **Rule**: Backward compatibility between database schema changes is NOT required at this stage. Tables can be dropped and recreated from scratch to maintain a clean schema. This rule will be removed when the project moves to production.

## Seeding and Testing Data
- **Rule**: All new domain entities MUST have a corresponding seed logic and JSON data file(s) organized in `internal/domain/jsons/` (and subfolders if applicable) for future testing and environment setup.
