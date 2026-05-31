# Naming Registry & Type Mapping

This registry ensures consistency between the Database (PostgreSQL), the Go Domain (Entities), and the External API (JSON).

## Client Entity
| Concept | Database Table/Column | Go Field (GORM) | API JSON Key | Type |
| :--- | :--- | :--- | :--- | :--- |
| ID | `clients.id` | `ID` | `id` | `uint64` / `number` |
| Name | `clients.name` | `Name` | `name` | `string` |
| Email | `clients.email` | `Email` | `email` | `string` |
| Address | `clients.address` | `Address` | `address` | `string` |
| Deleted At | `clients.deleted_at` | `DeletedAt` | - | `gorm.DeletedAt` |

## Invoice Entity
| Concept | Database Table/Column | Go Field (GORM) | API JSON Key | Type |
| :--- | :--- | :--- | :--- | :--- |
| ID | `invoices.id` | `ID` | `id` | `uint64` |
| Client ID | `invoices.client_id` | `ClientID` | `client_id` | `uint64` |
| Amount | `invoices.amount` | `Amount` | `amount` | `float64` |
| Due Date | `invoices.due_date` | `DueDate` | `due_date` | `time.Time` / `ISO 8601` |

## Error Mapping
| Internal Domain Error | HTTP Status Code | Response Code |
| :--- | :--- | :--- |
| `ErrNotFound` | 404 Not Found | `NOT_FOUND` |
| `ErrUnauthorized` | 401 Unauthorized | `UNAUTHORIZED` |
| `ErrValidation` | 400 Bad Request | `INVALID_INPUT` |
