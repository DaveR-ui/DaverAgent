---
tags: [authviews, api, endpoints, wizard, http, gateway]
---

# Authview Wizard API Endpoints

All endpoints are relative to the `gatewayWorkflowUrl` defined in the application configuration.

## Resource & Navigation

### Search Datasets/Resources

- **URL:** `/api/workflow/resource/administration/${env}/${resourceTypeId}?filterName=${searchText}`
- **Method:** `GET`
- **Service:** `CloudResourcesService.getCloudResourcesFilteredByEnvironment`
- **Description:** Used in the `DatasetSelector` step to find the parent dataset for the authview.

### Get Dataset Tables

- **URL:** `/api/workflow/resource/administration/tables/${resourceId}`
- **Method:** `GET`
- **Service:** `CloudResourcesService.getDatasetTables`
- **Description:** Fetches all available tables for a selected dataset. Used in `TablesSelector`.

### Get Table Schemas

- **URL:** `/api/workflow/resource/administration/authview/${environment}/${resourceId}`
- **Method:** `POST`
- **Body:** `{ resourceTableList: string[], editMode: boolean }`
- **Service:** `AuthViewService.getTablesSchemas`
- **Description:** Retrieves the schema (columns and types) for the selected tables. Used in `SchemasSelector` and `FiltersSelector`.

## GCP / IAM Access

### List GCP Projects

- **URL:** `/api/workflow/resource/administration/${environment}/gcp?filterName=${searchText}`
- **Method:** `GET`
- **Service:** `CloudResourcesService.getGoogleCloudProjects`
- **Description:** Lists GCP projects for the environment. Used in `AccessSelector`.

### Get IAM Info

- **URL:** `/api/workflow/resource/administration/${cloudProjectSubscriptionId}/iam/${resourceName}/${environment}`
- **Method:** `GET`
- **Service:** `CloudResourcesService.getIAMGoogleCloudProjects`
- **Description:** Gets IAM roles and service accounts for a specific resource and cloud project. Used in `AccessSelector`.

## Wizard Actions (Submission)

### Create Authview

- **URL:** `/api/workflow/resource/administration/authview/${environment}`
- **Method:** `POST`
- **Service:** `AuthViewService.sendAuthViewData`
- **Description:** Final step for creating a new authview with all wizard data (tables, schemas, access, etc.).

### Update Authview (Edit)

- **URL:** `/api/workflow/resource/administration/authview/${environment}`
- **Method:** `PUT`
- **Service:** `AuthViewService.sendDataToEdit`
- **Description:** Updates an existing authview. Used when the wizard is launched via `onEdit`.

### Delete Authview/Resource

- **URL:** `/api/workflow/Resource/administration/DeleteResource/${resourceId}/${requestor}?comments=${comments}`
- **Method:** `DELETE`
- **Service:** `CloudResourcesService.removeSubscription`
- **Description:** Triggered from the grid buttons (not the wizard itself, but related to the authview lifecycle).
