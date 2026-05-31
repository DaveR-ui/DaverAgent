# Invoices API Contracts

## Models

### InvoiceType
`'Factura A' | 'Factura B' | 'Factura C' | 'Remito' | 'Recibo' | 'Presupuesto' | 'Nota de Crédito'| 'Nota de Débito'`

### InvoicePayment
```typescript
export interface InvoicePayment {
  id: number;
  client_id: number;
  invoice_number: string;
  issue_date: string; // "YYYY-MM-DD"
  invoice_type: InvoiceType;
  total_amount: number;
  is_paid: boolean;
  invoice_notes?: string;
  payment_notes?: string;
  created_at: string;
  updated_at: string;
  client?: Client;
}
```

### ListInvoicesResponse
```typescript
export interface ListInvoicesResponse {
  items: InvoicePayment[]
  total: number
  page: number
  page_size: number
  total_pages: number
}
```

## Endpoints
- **GET** `/api/v1/invoices`: List invoices/payments (paginated).
- **POST** `/api/v1/invoices`: Record a new invoice.
- **PUT** `/api/v1/invoices/:id`: Update invoice details.
- **PATCH** `/api/v1/invoices/:id/pay`: Mark an invoice as paid.
- **DELETE** `/api/v1/invoices/:id`: Delete an invoice record.
