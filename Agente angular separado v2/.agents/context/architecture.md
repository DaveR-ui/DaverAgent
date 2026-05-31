# Architecture Documentation

This document describes the architecture of the `goland-api` project. It is intended to guide agents and developers in understanding the system structure and ensuring infrastructure integrity. For environment or runtime issues, consult [.agent/context/docker-strategy.md](./docker-strategy.md).

## 1. High-Level Overview

The project follows a **Layered Architecture** (inspired by Clean Architecture/Hexagonal Architecture principles), separating concerns into distinct layers.

**Data Flow:**
`Request` -> **Transport** (HTTP) -> **Service** (Business Logic) -> **Repository** (Data Access) -> **Database**

## 2. Directory Structure

- **`cmd/server/`**: Application entry point (`main.go`). Handles configuration, database connection, dependency injection, and server startup. `go run cmd/server/main.go`.
- **`internal/domain/`**: Contains core business entities (Models) and Interface definitions (Contracts). This layer has **no external dependencies** (except `context`).
- **`internal/repository/`**: Implementation of repository interfaces defined in `domain`. Handles direct database interactions using GORM.
- **`internal/service/`**: Contains business logic (Use Cases). Orchestrates operations between Repositories and other services.
- **`internal/transport/http/`**: HTTP Handlers and Routing (using Gin). Adapts external HTTP requests to internal Service calls.
- **`config.yaml`**: Configuration file managed by Viper.

## 3. Key Components & Implementation Details

### 3.1 Domain Layer (`internal/domain`)
- **Responsibility**: Defines *what* the system is (Entities) and *how* external data layers must behave (Interfaces).
- **Rules**:
    - Must NOT import other internal packages (avoid cyclical dependencies).
    - Defines `Repository` interfaces (e.g., `ClientesRepo`).
    - Uses strict typing.
- **Errors**: Domain-specific errors must be defined as constants within the same file as the corresponding model (e.g., `internal/domain/credentials_model.go`).

### 3.2 Repository Layer (`internal/repository`)
- **Responsibility**: Implements `domain.Repository` interfaces.
- **Technology**: Uses `gorm.io/gorm` for PostgreSQL interactions.
- **Rules**:
    - Must return domain models or errors.
    - Context (`ctx`) must be propagated to database calls.
    - **Agent Check**: Verify that methods match the interface signature exactly and handle DB errors.

### 3.3 Service Layer (`internal/service`)
- **Responsibility**: Implements business rules.
- **Rules**:
    - Accepts Repository interfaces via dependency injection (constructor injection).
    - Should not know about HTTP details (headers, status codes).

### 3.4 Transport Layer (`internal/transport/http`)
- **Responsibility**: HTTP adaptation.
- **Technology**: `github.com/gin-gonic/gin`.
- **Rules**:
    - Parses JSON bodies.
    - Validates inputs.
    - Calls Services.
    - Formats Responses.
- **Routes**: All routes must be defined in `internal/transport/http/router.go` and organized into versioned groups (e.g., `/api/v1`). Routes requiring authentication must use the `AuthMiddleware()`.

### 3.5 Infrastructure & wiring (`cmd/server/main.go`)
- **Responsibility**: Wiring it all together.
- **Pattern**: Manual Dependency Injection.

## 4. Agent Validation Guidelines

To ensure infrastructure is "well-made", an agent should verify:

1.  **Dependency Inversion**: Services must depend on *Interfaces* (defined in `domain`), not concrete `repository` structs.
2.  **Configuration**: Critical implementation details (DB URLs, Ports) must come from Viper config, not hardcoded.
3.  **Context Propagation**: Every function from Transport down to Repository MUST accept and pass `context.Context`.
4.  **Error Handling**: Errors should be returned up the stack. Repositories should not panic.
5.  **Database Migration**: New tables must be added to the `TablesToMigrate` slice in `internal/domain/models.go`. `AutoMigrate` is executed in `cmd/server/main.go` using this list.

## 5. Technology Stack
- **Language**: Go 1.24
- **Web Framework**: Gin
- **ORM**: GORM
- **Database**: PostgreSQL
- **Config**: Viper
