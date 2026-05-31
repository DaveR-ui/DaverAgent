---
tags: [discovery-wizard, wizard, workflow, angular, feature, onboarding]
---

# Discovery Wizard: Technical & Functional Overview

This document serves as a guide for AI agents and developers to understand the architecture and flow of the Discovery Wizard within the Data Platform Services.

## Functional Goal

The Discovery Wizard is designed to guide users through a series of questions to determine the appropriate data foundation services, estimated duration for setup, and required approvals for their projects.

## Core Components & Data Flow

### 1. `DiscoveryWizardPageService` (The Orchestrator)

- **Data Fetching:** Uses `rxResource` to fetch groups and questions from `/api/workflow/Discovery/GetDiscoveryPhaseWizard`.
- **State Management:**
  - `selectedAnswers`: A signal storing the user's progress.
  - `duration` & `approvals`: Reactive signals calculated based on user selections.
  - `wizardResource`: The source of truth for the wizard structure, providing `isLoading()` for UI feedback.
- **Persistence:** `sendAnswers()` logs the recommendations and user intent to the backend.

### 2. UI Structure (`DiscoveryWizardPageComponent`)

- **Main Form:** `app-dw-main-form` handles the interactive question-answer flow.
- **Real-time Feedback:** `app-dw-time-approvals` (right column) shows the impact of answers on project timelines.
- **Summary:** `app-dw-accordeon` allows users to review their current progress.
- **Outcome:** `app-recommendation-guide` is the final step where a PDF report can be generated.

### 3. PDF Generation (`RecommendationGuideComponent`)

- **Tool:** `html2pdf.js`.
- **Dynamic Rendering:** Since the PDF is generated from the DOM, components like `DwMyResponesComponent` and `DWTimeAndApprovalsComponent` are created dynamically using `ViewContainerRef`.
- **Critical Note:** Always call `changeDetectorRef.detectChanges()` after creating dynamic components to ensure data is rendered before the PDF capture occurs.

## Key Interaction Patterns (Inspired by Access Modal)

Like the `AccessSelectorDialogComponent`, the wizard uses:

- **Signal-based reactivity:** Every UI update is driven by changes in signals.
- **Declarative Fetching:** Prefer `rxResource` over manual `Observable` subscriptions. Treat `httpResource` as legacy compatibility only.
- **Cache Strategy:** Results are stored in signals to maintain UI state across navigation steps.

## Backend Integration

- **Gateway Workflow URL:** Base URL for all wizard-related requests.
- **Enalist/Dropdowns:** Projects and environments often fetch additional metadata (like ENA lists) dynamically to populate selectors.

---

_Note: This document is optimized for AI context injection._
