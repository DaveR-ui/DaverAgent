# SKILL: API Endpoint Factory
name: api-endpoint-factory
description: Use this skill to create, modify, or delete API endpoints and their associated domain logic.

## Mandatory Architecture
We follow a 4-layer Onion Architecture:
1. **Domain** (`internal/domain/`): Pure logic and interfaces.
2. **Infrastructure/Repository** (`internal/repository/`): DB logic (`gorm`).
3. **Usecase/Service** (`internal/service/`): Business rules connecting Domain and Infra.
4. **Transport/Handler** (`internal/transport/http/`): Routing and Request/Response mapping.

## Operational Steps
1. **Model & Interface**: Define the struct and the interface in `internal/domain/`.
2. **Repository**: Implement data access in `internal/repository/`.
3. **Service**: Implement the usecase in `internal/service/`.
4. **Handler**: Create the controller in `internal/transport/http/handler/`.
5. **Route**: Register the route in `internal/transport/http/router.go`.

## Naming Standards
*   **Request Structs**: `Create[Entity]Request`
*   **Response Structs**: `[Entity]Response`
*   **Internal Errors**: Map internal errors to HTTP status codes in the Handler.

## Contextual Knowledge
- Refer to `.agent/context/api-contracts.md` for JSON naming.
- Refer to `.agent/context/rules.md` for error handling policies.
