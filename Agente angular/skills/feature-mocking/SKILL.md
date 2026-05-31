---
name: feature-mocking
description: Guidelines for managing mock API routes and data using json-server.
---

# Feature Mocking Skill

This project uses `json-server` for local development. Every new API call must have a corresponding mock entry to support `npm run mock`.

## 📁 Key Files
- `mocks/mock-routes.json`: Maps URL patterns to json-server endpoints.
- `mocks/data.json`: The main data store.
- `mocks/data/*.json`: Individual data files aggregated by `mocks/concat-json.js`.

## 🚀 How to Add a Mock Entry
1. **Define the Response Data**: Add a new key to `mocks/data.json`.
2. **Register the Route**: Add a mapping in `mocks/mock-routes.json`.

### Example: Adding a User Details API
**1. Update `mocks/data.json`:**
```json
{
  "user-details": { "id": "123", "name": "John Doe", "role": "Admin" }
}
```

**2. Update `mocks/mock-routes.json`:**
```json
{
  "/*/users/123": "/user-details"
}
```

## 🔍 Path Matching Rules
- `/*/`: Matches any single segment.
- `/**`: Matches multiple segments.
- `?*`: Matches query parameters.
