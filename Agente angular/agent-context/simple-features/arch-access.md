---
last_updated: 2026-06-06
description: signal architecture deep-dive for the access modal — why computed, linkedSignal, and signal were chosen, and how they form a reactive dependency tree
tags: [component, access-modal, signals, computed, linkedSignal, architecture, reactive-tree]
---

# Access Modal — Signal Architecture Report

## Purpose
This document explains **why** each signal primitive (`signal`, `computed`, `linkedSignal`, `httpResource`, `rxResource`) was chosen in `access-modal.component.ts`, and how they connect as a **reactive dependency tree** where downstream values automatically recalculate when upstream sources change [2].

## 1. Signal Inventory
The component contains **29 reactive state entries** organized into five categories [3]:

| Category | Count | Primitives |
| :--- | :--- | :--- |
| Source state (mutable, user-driven) | 5 | signal |
| Remote data (async, server-driven) | 5 | httpResource, rxResource |
| Derived immutable state | 16 | computed |
| Derived mutable state | 3 | linkedSignal |
| Store-backed signals | 1 | store.selectSignal |

## 2. Why signal?
`signal()` is used for **atomic, user-mutable state** that has no upstream reactive dependency [4]. These are leaf inputs set directly by user interaction or lifecycle hooks [5].

| Signal | Type | Purpose |
| :--- | :--- | :--- |
| `crossEnvProjectFilterRequested` | `signal(false)` | Toggle for cross-env project filter mode. |
| `crossEnvEnable` | `signal(true)` | Feature flag gate from LaunchDarkly. |
| `removeObjectFlag` | `signal(true)` | Feature flag for project removal. |
| `removedProjects` | `signal<GoogleIamResponse[]>([])` | Tracks projects removed from the original snapshot. |
| `hasPendingChanges` | `signal(false)` | Dirty flag for the form. |

## 3. Why computed?
`computed()` is used for **derived immutable state** — values calculated from other signals that cannot be set directly [5].

### 3.1 Platform branching
Determines Azure vs GCP flow based on the dialog input [6].
*   `isAzureResource`: Root branch derived from `data.result()?.resourceTypeId`.
*   `platformLabel` / `projectEntityLabel`: Returns 'Azure/Subscription' or 'GCP/Project'.

### 3.2 Security gate chain
Forms a **linear pipeline** that gates all downstream loading [7].
*   `hasSuccessfulSecurityCheck`: Gate based on `!isLoading && !error`.
*   `isSecurityBlocked`: Hard stop if the backend prevents editing.

### 3.3 Selector UI state
Drives the appearance and behavior of the project selector [8].
*   `projectInventory`: Picks which resource provides the selector options.
*   `projectSelectorOptions`: Inventory minus already-selected projects [9].

### 3.4 Alert composition
*   `globalAlert`: Single source of truth for all modal banners (loading > error > blocked > empty) [10].

## 4. Why linkedSignal?
Used for **derived mutable state** — values computed from upstream sources that can also be **mutated locally** [11].

### 4.1 projects — the central working selection
*   **Why**: The user adds/removes projects locally, but the selection must **reset** if `resourceData` reloads [12].
*   **Design**: Declaratively derives from sources but allows `.update()` calls.

### 4.2 projectTabSelectedIndex — active accordion tab
*   **Why**: Must recalculate to stay in bounds when `projects` changes, but allows manual user selection via `.set()` [13].

## 5. Why httpResource / rxResource?
Built-in primitives for reactive data-fetching that expose `.value()`, `.isLoading()`, and `.error()` as signals [14].
*   `securityCheck`: First handshake handshake to verify edit permissions.
*   `resourceData`: Initial project/account snapshot.
*   `objectAccessData`: ENA/demand metadata for the form.

## 6. Reactive Dependency Tree
Arrows flow **top-down**: a parent signal is read by its children. When any node changes, all descendants recalculate automatically [15].

### 6.1 Dependency chains summarized
*   **Security Gate**: `securityCheck` → `hasSuccessfulSecurityCheck` → `securityState` → `isSecurityBlocked` [16].
*   **Main Flow**: `resourceData` → `projects` → `projectTabSelectedIndex` → `projectHeader`.
*   **ENA Flow**: `objectAccessData` → `mergedObjectAccessData` → `enaListByProject`.

## 7. Design Principles
1.  **Computed for read-only, linkedSignal for read-write**: Use `linkedSignal` if a value must reset when upstream changes but also needs local mutation [17].
2.  **No effect() for state synchronization**: Zero `effect()` calls are used for state management to avoid circular update risks [17, 18].
3.  **Resources as gate boundaries**: Returning `undefined` in a resource request function implements a **cascading pause** in the tree [18].
4.  **Single-writer principle**: Each piece of state has exactly one primary writer (auto-computation or specific user action) [19].
5.  **Template reads derived layer**: The template reads from `computed` or `linkedSignal` values, never raw resources, keeping it declarative [20].

## 8. What Would Break Without linkedSignal?
| Scenario | With linkedSignal | Without (plain signal) |
| :--- | :--- | :--- |
| **Backend reload** | `projects` auto-resets | Must manually sync (risk of loops) |
| **User interaction** | `projects.update()` works | Cannot reset on source change |
| **Azure sync** | Auto-reconciles inventory | Manual trigger logic required |

| Signal | Primitive | Mutable? | Auto-resets? | Reason |
| :--- | :--- | :---: | :---: | :--- |
| `crossEnvProjectFilterRequested` | signal | Yes | No | User toggle, no upstream dependency. |
| `crossEnvEnable` | signal | Yes | No | Set once from LaunchDarkly flag. |
| `removeObjectFlag` | signal | Yes | No | Set once from LaunchDarkly flag. |
| `removedProjects` | signal | Yes | No | Accumulator for removed items. |
| `hasPendingChanges` | signal | Yes | No | Dirty flag from form interaction. |
| `securityCheck` | httpResource | Auto | Auto | Server handshake; gates everything. |
| `resourceData` | httpResource | Auto | Auto | Initial project snapshot from server. |
| `objectAccessData` | rxResource | Auto | Auto | ENA/demand metadata from server. |
| `crossEnvProjects` | rxResource | Auto | Auto | GCP selector inventory from server. |
| `azureSubscriptions` | rxResource | Auto | Auto | Azure selector inventory from server. |
| `isAzureResource` | computed | No | No | Pure function of dialog input. |
| `isCrossEnvProjectFilterActive` | computed | No | No | Combines 3 signals into one boolean. |
| `hasSuccessfulSecurityCheck` | computed | No | No | Derives loading/error from resource. |
| `securityState` | computed | No | No | Safe value accessor behind gate. |
| `isSecurityBlocked` | computed | No | No | Extracts blocked flag. |
| `hasSecurityError` | computed | No | No | Error presence check. |
| `platformLabel` | computed | No | No | Azure/GCP string. |
| `projectEntityLabel` | computed | No | No | Subscription/Project string. |
| `selectorLabel` | computed | No | No | Search placeholder text. |
| `selectorIsLoading` | computed | No | No | Picks active resource loading state. |
| `projectInventory` | computed | No | No | Picks active inventory source. |
| `projectSelectorOptions` | computed | No | No | Inventory minus selected. |
| `projectHeader` | computed | No | No | Active tab header text. |
| `globalAlert` | computed | No | No | Priority-based alert composition. |
| `enaListByProject` | computed | No | No | ENA options grouped by project. |
| `accountDemandsMap` | computed | No | No | Demand availability per account. |
| `projects` | linkedSignal | Yes | Yes | Working selection; user-mutable, auto-resets. |
| `projectTabSelectedIndex` | linkedSignal | Yes | Yes | Active tab; user-settable, auto-corrects. |
| `mergedObjectAccessData` | linkedSignal | Yes | Yes | ENA merge; extended by GCP adds, auto-resets. |