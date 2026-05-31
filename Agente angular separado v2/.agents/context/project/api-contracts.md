---
last_updated: 2026-05-09
description: Index and quick reference for API contracts covering auth, clients, and invoices endpoints.
tags: [api, contracts, endpoints]
status: active
---

# API Contracts Index

This document serves as an index and quick reference for the project's API contracts. Detailed definitions of models and endpoints are located in feature-specific files.

## Feature Contracts
- [**Auth**](api-contracts/auth.md): Authentication and user profile management.
- [**Clients**](api-contracts/clients.md): Client management and listing.
- [**Invoices**](api-contracts/invoices.md): Invoice recording, payment tracking, and history.

## Core Endpoints Reference

### Auth
- `POST /api/v1/auth/login`
- `GET /api/v1/users/me`

### Clients
- `GET /api/v1/clients`
- `POST /api/v1/clients`
- `PUT /api/v1/clients/:id`

### Invoices
- `GET /api/v1/invoices`
- `POST /api/v1/invoices`
- `PATCH /api/v1/invoices/:id/pay`

---
*Related Documents*: [Project Rules (rules.md)](rules.md)
