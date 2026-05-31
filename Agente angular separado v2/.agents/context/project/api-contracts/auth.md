# Auth API Contracts

## Models

### User
```typescript
export interface User {
  id: string;
  email: string;
  username: string;
  role: string;
  created_at: string;
  updated_at: string;
  active: boolean;
}
```

### LoginResponse
```typescript
export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  user: User;
}
```

## Endpoints
- **POST** `/api/v1/auth/login`: Authenticates a user and returns tokens.
- **POST** `/api/v1/auth/logout`: Invalidates the current session.
- **GET** `/api/v1/users/me`: Retrieves current user profile.
