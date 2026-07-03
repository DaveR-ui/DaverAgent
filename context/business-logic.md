# Business Logic: VAT and Document Management

This document explains the core business rules for VAT (IVA), tax conditions, and invoicing document management within the system.

## 1. Tax Conditions (TaxCondition)
Every **Client** must have a `TaxCondition` (e.g., "Responsable Inscripto", "Consumidor Final"). This determines how the system interacts with the client regarding taxes and which invoice types are allowed.

### DefaultInvoiceTypeID Property
Each `TaxCondition` includes a `DefaultInvoiceTypeID`. This field defines the default **Invoice Type** (Comprobante) that should be automatically selected or validated when issuing an invoice.

**Business Logic (Argentina Context):**
- **Responsable Inscripto**: Defaults to **Factura A**.
- **Consumidor Final**, **Monotributista**, **Exento**: Defaults to **Factura B**.

**Automation & Validation:**
1.  **Frontend Automation**: When a user selects a client, the UI checks the client's `TaxCondition.DefaultInvoiceTypeID` to pre-select the appropriate invoice type.
2.  **Backend Validation**: The system prevents issuing a "Factura A" to a "Consumidor Final", ensuring fiscal compliance.

## 2. Document Types (InvoiceType)
Defines the different documents that can be issued (e.g., Invoice A, Invoice B, Delivery Note).

- **Attributes**:
    - `InternalCode`: Used for system identification (e.g., 'FAC', 'REM').
    - `Letter`: The identifying letter (A, B, R, X) required for display and printing.
    - `RequiresCuit`: If true, the system must ensure the client has a valid Tax ID (CUIT) before issuing.
    - `AffectsStock`: If true, issuing this document triggers stock or inventory updates.
    - `LastNumber`: Keeps track of the sequence for this document type.

## 3. Smart Selection Logic
1. **Location**: User enters postal code -> System fills Location (Localidad) and District (Partido).
2. **Invoicing**: User selects Client -> System looks up `TaxCondition` -> System pre-selects the `DefaultInvoiceType`.

## 4. Seeding
Initial business relationships and default types are hardcoded and initialized via seeding logic in `internal/domain/db` (or `cmd/db/seeds.go` as referenced in older docs).
