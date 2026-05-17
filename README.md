# Real Estate Property Management System

Assessment-ready Salesforce DX implementation for a real estate property management mini project.

## Features

- Property management with required address, type, status, rent, description, geocoded location, and required Salesforce Files images.
- Server-side property pagination with 25 records per page.
- Filters by price range, availability, furnishing status, and nearby distance in km.
- Deployable Lightning app-page tabs for property management, tenant management, lease management, vendor management, maintenance, and dashboard views.
- Tenant management, where one tenant can rent multiple properties through lease agreements.
- Tenant property assignment flow that creates draft lease agreements and follow-up tasks to generate the final lease.
- Lease agreement management with PDF download using `jsPDF`, manual email to tenant, and scheduled 30-day and 1-day expiry reminders.
- Vendor management and maintenance requests with automatic least-workload vendor assignment.
- Dashboard support for expiring leases, maintenance requests by status, and occupancy rate.
- Apex unit tests designed to cover bulk behavior and callout/email/scheduler paths.

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for the object and relationship model.

## Deploy

```bash
sf org login web --alias real-estate-dev
sf project deploy start --target-org real-estate-dev
sf org assign permset --name Real_Estate_Manager --target-org real-estate-dev
```

Or run the bundled post-deploy script after metadata deploy:

```powershell
.\scripts\postDeploy.ps1 -TargetOrg "RealEstate Demo"
```

After deployment, open the **Real Estate Property Management** app. The app includes these custom workspace tabs:

- Property Management
- Tenant Management
- Lease Agreement Management
- Vendor Management
- Maintenance Management
- Real Estate Dashboard

## Geocoding Setup

Create a Named Credential named `Google_Geocoding` with this URL:

```text
https://maps.googleapis.com
```

Set the custom label `Google_Maps_API_Key` to your Google Maps Platform API key. `GeocodingService.buildEndpoint` appends that key to Google Geocoding API requests. Apex tests use mocks and do not call the live API.

This setup is required before using the custom property creation flow or the property record map. When a record has no saved coordinates, the record map geocodes the property address, saves `Location__c`, and then renders the map.

## jsPDF Setup

The project includes `jspdf.umd.min.js` as the static resource `jsPDF`. The LWC `leaseAgreementActions` imports it from `@salesforce/resourceUrl/jsPDF`.

## Sample Data

Load data after deployment:

```bash
sf data import tree --plan data/RealEstatePlan.json --target-org real-estate-dev
```

For property images, open a property record and upload files, or use the `propertyCreate` LWC.

## Scheduled Reminders

Run this once in anonymous Apex:

```apex
System.schedule('Lease reminders daily', '0 0 8 * * ?', new LeaseReminderScheduler());
```

With Salesforce CLI:

```bash
sf apex run --file scripts/scheduleLeaseReminders.apex --target-org real-estate-dev
```

## Tests

```bash
sf apex run test --target-org real-estate-dev --test-level RunLocalTests --code-coverage --wait 20
```

## Demo Flow

1. Assign `Real_Estate_Manager`.
2. Create vendors from Vendor Management, then create tenants and properties.
3. Create a property with one or more images using `propertyCreate`.
4. Open the property record and verify `propertyRecordMap` and `propertyImages`.
5. Use `propertyList` filters and pagination.
6. Create lease agreements, open the tenant record to verify assigned properties, and use PDF download/email actions.
7. Create maintenance requests and verify the request list shows property, vendor, status, and description.
8. Review dashboard metrics through `reportingDashboard`.
