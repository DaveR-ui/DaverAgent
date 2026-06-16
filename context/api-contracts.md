# API Contracts

All endpoints follow REST conventions under `/api/v1`.

## Base URL

```
http://localhost:8080/api/v1
```

## Authentication

- **Method**: Bearer token (JWT)
- **Header**: `Authorization: Bearer <access_token>`
- **Login**: `POST /api/v1/auth/login` with `{"email": "...", "password": "..."}`
- **Refresh**: `POST /api/v1/auth/refresh` with `{"refresh_token": "..."}`
- **Token response**:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": { "id": "...", "username": "...", "email": "...", "role": "admin" }
}
```

## Roles

| Role | Read | Write | Delete |
|------|------|-------|--------|
| `admin` | Yes | Yes | Yes |
| `manager` | Yes | Yes | No |
| `user` | Yes | No | No |

## Response Format

### Success — Single Entity
```json
{
  "id": 1,
  "name": "Example",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

### Success — Paginated List
```json
{
  "items": [...],
  "total": 42,
  "page": 1,
  "page_size": 10,
  "total_pages": 5
}
```
Note: The items key varies by entity (e.g., `powders`, `clients`, `fire_extinguishers`, `items`).

### Success — Delete
- Status: `204 No Content`
- Body: empty

### Success — Message
```json
{ "message": "invoice marked as paid" }
```

### Error
```json
{ "error": "Item not found" }
```

## HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| `200 OK` | Success | GET, PUT, PATCH |
| `201 Created` | Created | POST (returns entity) |
| `204 No Content` | Deleted | DELETE |
| `400 Bad Request` | Invalid input | JSON binding failure, invalid ID format |
| `401 Unauthorized` | Auth failure | Missing/invalid/expired token |
| `403 Forbidden` | Insufficient permissions | Role check failed |
| `404 Not Found` | Entity not found | `ErrNotFoundItem` |
| `409 Conflict` | Duplicate entity | `ErrAlreadyExists` (e.g., duplicate email) |
| `500 Internal Server Error` | Unexpected error | Catch-all for unhandled errors |

## Error Messages (Domain Constants)

| Constant | Message | HTTP Code |
|----------|---------|-----------|
| `ErrNotFoundItem` | `"Item not found"` | 404 |
| `ErrAlreadyExists` | `"Item already exists"` | 409 |
| `ErrInvalidInput` | `"Invalid input"` | 400 |
| `ErrDatabaseConnectionFailed` | `"Database connection failed"` | 500 |

## Pagination Query Parameters

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `page` | int | 1 | - | Page number (1-indexed) |
| `page_size` | int | 10 | 100 | Items per page |
| `search` | string | "" | - | Search filter (entity-specific fields) |

## Endpoints

### Auth
| Method | Path | Auth | Roles | Description |
|--------|------|------|-------|-------------|
| POST | `/auth/login` | No | - | Login, returns JWT tokens |
| POST | `/auth/register` | No | - | Register new user |
| POST | `/auth/refresh` | No | - | Refresh access token |
| GET | `/auth/me` | Yes | Any | Get current user info |
| POST | `/auth/users` | Yes | admin | Create privileged user |
| POST | `/auth/logout` | No | - | Logout (revoke refresh token) |

### Clients
| Method | Path | Auth | Roles | Description |
|--------|------|------|-------|-------------|
| GET | `/clients` | Yes | Any | List clients (paginated) |
| GET | `/clients/tax-conditions` | Yes | Any | List tax conditions |
| GET | `/clients/:id` | Yes | Any | Get client by ID |
| POST | `/clients` | Yes | manager, admin | Create client |
| PUT | `/clients/:id` | Yes | manager, admin | Update client |
| DELETE | `/clients/:id` | Yes | admin | Delete client |

### Invoices
| Method | Path | Auth | Roles | Description |
|--------|------|------|-------|-------------|
| GET | `/invoices` | Yes | Any | List invoices (paginated) |
| GET | `/invoices/types` | Yes | Any | List invoice types |
| POST | `/invoices` | Yes | manager, admin | Create invoice |
| PUT | `/invoices/:id` | Yes | manager, admin | Update invoice |
| DELETE | `/invoices/:id` | Yes | admin | Delete invoice |
| PATCH | `/invoices/:id/pay` | Yes | manager, admin | Mark as paid |

### Fire Extinguishers
| Method | Path | Auth | Roles | Description |
|--------|------|------|-------|-------------|
| GET | `/fire-extinguishers` | Yes | Any | List (paginated) |
| GET | `/fire-extinguishers/:id` | Yes | Any | Get by ID |
| POST | `/fire-extinguishers` | Yes | manager, admin | Create |
| PUT | `/fire-extinguishers/:id` | Yes | manager, admin | Update |
| DELETE | `/fire-extinguishers/:id` | Yes | admin | Delete |

### Powders
| Method | Path | Auth | Roles | Description |
|--------|------|------|-------|-------------|
| GET | `/powders` | Yes | Any | List (paginated) |
| GET | `/powders/:id` | Yes | Any | Get by ID |
| POST | `/powders` | Yes | manager, admin | Create |
| PUT | `/powders/:id` | Yes | manager, admin | Update |
| DELETE | `/powders/:id` | Yes | admin | Delete |

## CORS

Configured via `config.yaml`:
```yaml
CORS:
  ALLOW_ORIGIN: "http://localhost:3000,http://localhost:5173"
  ALLOW_METHODS: "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  ALLOW_HEADERS: "Origin, Content-Type, Accept, Authorization"
```

## Health Check
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Returns `{"status": "ok"}` |
