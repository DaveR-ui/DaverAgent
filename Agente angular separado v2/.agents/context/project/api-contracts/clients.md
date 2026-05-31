# Clients API Contracts

## Models

### Client
```typescript
export interface Client {
  id: number;
  name: string;
  address: string;
  postal_code: string;
  localidad: string;
  partido: string;
  phone: string;
  email: string;
  notes: string;
  iva: string;
  cuit: string;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string;
}
```

### ListClientsResponse
```typescript
export interface ListClientsResponse {
  clients: Client[]
  total: number
  page: number
  page_size: number
  total_pages: number
}
```

## Endpoints
- **GET** `/api/v1/clients`: List clients (paginated).
- **GET** `/api/v1/clients/:id`: Get client details.
- **POST** `/api/v1/clients`: Create a new client.
- **PUT** `/api/v1/clients/:id`: Update an existing client.
- **DELETE** `/api/v1/clients/:id`: Soft delete a client.
