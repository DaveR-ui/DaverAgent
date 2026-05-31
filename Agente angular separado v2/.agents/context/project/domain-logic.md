---
last_updated: 2026-05-09
description: Domain encyclopedia for Matafuegos Necochea. Business concepts, extinguisher types, and operational processes.
tags: [domain, business-logic, matafuegos, necochea, extinguishers]
---

# 🧯 Domain Encyclopedia: Matafuegos Necochea

This document defines the business domain of the application to provide agents with the necessary context beyond the technical code.

## 🏢 Business Context
**Matafuegos Necochea** (by Dacar Enterprise Software) is a management system for fire extinguisher maintenance, testing, and sales.

## 🛠️ Core Concepts

| Term | Definition | Key Data Point |
| :--- | :--- | :--- |
| **Extintor (Matafuegos)** | The primary asset. Identified by a unique internal number or QR. | Type, Capacity, Brand. |
| **Recarga** | Annual maintenance service involving recharging the agent. | Last Recharge Date. |
| **PH (Prueba Hidráulica)** | High-pressure test performed every 5 years to verify cylinder integrity. | PH Expiry Date. |
| **Dotación** | The set of extinguishers required for a specific location based on fire load. | Location, Square meters. |
| **Tarjeta de Control** | Official municipal/provincial card required for every legal extinguisher. | Card Number. |
| **Oblea** | The sticker provided by the regulatory body (DPS) confirming validity. | Oblea Number, Year. |

## 🧪 Extinguisher Types (Classes of Fire)

1.  **ABC (Polvo)**: Tri-class powder for solids, liquids, and electrical fires. Most common.
2.  **BC (CO2)**: Carbon Dioxide for electrical and liquid fires. Leaves no residue.
3.  **K (Acetato de Potasio)**: For kitchen fires (fats and oils).
4.  **A (Agua / Espuma)**: For wood, paper, and cloth. No electrical.

## 🔄 Operational Lifecycles

### Maintenance Flow
1.  **Retiro**: Pickup from client location.
2.  **Taller**: Inspection, recharge, and/or PH.
3.  **Entrega**: Return and placement at client location.
4.  **Control**: Monthly or quarterly visual inspection.

### Expiry Management
- **Annual**: All extinguishers must be recharged/checked every 12 months.
- **Quinquennial**: PH test required every 5 years.

## 🚨 Critical Business Rules
- **No Extinguisher Left Behind**: A client location must never have zero coverage during maintenance (substitution extinguishers are required).
- **Traceability**: Every action (Recharge, PH) must be linked to a specific Extinguisher ID and Technician.
- **Compliance**: Standards follow IRAM and provincial DPS (Dirección de Prevención Ciudadana) regulations.
