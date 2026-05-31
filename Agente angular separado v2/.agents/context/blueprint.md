# Blueprint - Technical Vision

This file describes the "Strategic Truth" of the project from a high-level technical perspective.

## General Vision
- **System Purpose**: (e.g., Core management system for services and billing).
- **Tech Stack**: Language, Frameworks, and key versions.
- **External Services**: Integrations with 3rd party APIs, Email, Cloud Storage, etc.

## Infrastructure and Persistence
- **Runtime**: Docker-based environment. See `context/docker-strategy.md` for image architecture and automation.
- **Database**: PostgreSQL (GORM). Seeding logic and JSON data handled via `internal/domain/db`.
- **Conceptual ERD**: Mapping details in `context/naming-registry.md`.
- **Dev Tools**: pgAdmin 4 (pre-configured via `tmp/serverconfig.json`).

## Current Status
- **Environment**: Development (Pre-production).
- **Persistence Policy**: Tables can be dropped and recreated as needed for schema evolution (No backward compatibility required).
- **Operational**: Core management system for services and billing is under active development.
