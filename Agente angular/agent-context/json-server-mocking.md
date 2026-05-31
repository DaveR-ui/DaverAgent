---
last_updated: 2026-02-26
status: complete
ai_optimized: yes
tags: [json-server, mock, api, testing, routes, middleware]
---

# json-server Mocking Standards

This document covers critical pitfalls and rules when working with the `json-server` implementation in this project (`mocks/mock-routes.json`, `mocks/middleware.js`, and `mocks/data.json`).

## 🚨 CRITICAL: Mocking POST Requests (Middleware)

By default, json-server expects RESTful conventions. In our project, many POST requests are used for querying data. The `mocks/middleware.js` converts POST/PUT/DELETE requests to GET.

### The Array Filtering Pitfall

**Problem:** If your mock data in `data.json` is an **Array** (e.g., `[]`), json-server treats it as a REST collection. If the middleware copies the POST body to `req.query`, **json-server will attempt to filter the array** using those query parameters.
If the items in the array do not perfectly match the fields in the POST body, json-server returns an empty array `[]`.

**✅ Correct Middleware Pattern:**
When converting POST to GET for general mock retrieval, clear the query parameters to prevent unwanted filtering of mock arrays.

```javascript
// ✅ mocks/middleware.js
if (req.method === "POST" || req.method === "PUT" || req.method === "DELETE") {
  // Clear query to prevent json-server from filtering arrays by POST body fields
  req.query = {}; 
  req.method = "GET";
}
```

**❌ Anti-Pattern (DO NOT USE):**
```javascript
// ❌ WRONG: Copies POST body to query, causing json-server to filter array mocks
req.query = req.body; 
```

> **Note:** If the mock data is an **Object** `{}` instead of an Array `[]`, json-server returns it as-is without filtering, which hides this bug until you try to mock an array.

## 🔀 Route Matching Rules (`mock-routes.json`)

The project uses `express-urlrewrite` under the hood for `mock-routes.json`. 

### The `*` Wildcard Pitfall

**Problem:** The `*` wildcard matches **exactly one path segment**. It does NOT span multiple directories.

**❌ Anti-Pattern:**
```json
// URL: /api/workflow/Resource/administration/npd/project/list
"/*/administration/npd/project/list": "/cross-env-projects" 
```
*Why it fails:* The `*` matches `api`. The next segment in the URL is `workflow`, but the route expects `administration`. This results in a 404.

**✅ Correct Pattern:**
You must provide exact segments or use multiple wildcards for the exact depth.

```json
// Match exactly the depth of the URL
"/*/workflow/Resource/administration/*/project/list": "/cross-env-projects"
```

## 🛠️ Data Concatenation (`concat-json.js`)

Mock data is stored in individual files inside `mocks/data/` (e.g., `ena-list.json`).
- These files are combined into a single `mocks/data.json` by `concat-json.js` before json-server starts.
- **Syntax Errors are Silent Killers:** If an individual JSON file has a syntax error (e.g., trailing comma, missing bracket), `concat-json.js` will catch the error, log it, and **skip the file**. 
- If your routes suddenly return 404s, always check the terminal output of `npm run mock` for JSON parse errors from the concater.
