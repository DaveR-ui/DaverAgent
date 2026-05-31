# Project Information

## Overview
- **Project Name**: [Project Name]
- **Description**: [Brief description of the project]

## Technology Stack
- **Backend Language**: [e.g., Go 1.21, Node.js 20, Python 3.11]
- **Frontend Framework**: [e.g., React 18, Vue 3, Angular 17, None]
- **Database**: [e.g., PostgreSQL 15, MySQL 8, MongoDB 6]
- **ORM/Query Builder**: [e.g., GORM, Prisma, SQLAlchemy]
- **Testing Framework**: [e.g., testify, Jest, pytest]

## Architecture
- **Pattern**: [e.g., Onion/Clean Architecture, MVC, Microservices]
- **Backend Structure**:
  - `internal/domain/` - Domain models and interfaces
  - `internal/repository/` - Data access layer
  - `internal/service/` - Business logic
  - `internal/transport/http/` - HTTP handlers and routing
- **Frontend Structure**:
  - `src/components/` - UI components
  - `src/services/` - API service calls
  - `src/pages/` - Page/route components

## Commands

### Development
```bash
# Start backend
make run
# or
go run cmd/main.go

# Start frontend
npm run dev
# or
cd frontend && npm run dev
```

### Testing
```bash
# Run all tests
make test
# or
go test ./...

# Run tests with coverage
make test-coverage
# or
go test -cover ./...

# Run specific test
go test ./internal/service/ -run TestFunctionName
```

### Database
```bash
# Start local database
docker-compose up -d db
# or
make db-start

# Run migrations
make migrate-up
# or
go run cmd/migrate/main.go up

# Seed database
make db-seed
# or
go run cmd/seed/main.go
```

### Build
```bash
# Build backend
make build
# or
go build -o bin/app cmd/main.go

# Build frontend
npm run build
```

## Environment Variables
```bash
# Database
DATABASE_URL=postgres://user:pass@localhost:5432/dbname

# API
API_PORT=8080
API_BASE_URL=http://localhost:8080

# Frontend
VITE_API_URL=http://localhost:8080/api
```

## Key Conventions
- [Naming conventions]
- [Error handling patterns]
- [API response format]
- [Git branching strategy]

## Useful Links
- [API Documentation]
- [Database Schema]
- [Architecture Diagrams]
