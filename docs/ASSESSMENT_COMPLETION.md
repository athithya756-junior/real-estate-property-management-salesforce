# Assessment Completion Checklist

This checklist maps the mini-project brief to the deployable project.

## Implemented in Source

- Real Estate Property Management Lightning app.
- App-page tabs for:
  - Property Management
  - Tenant Management
  - Lease Agreement Management
  - Maintenance Management
  - Real Estate Dashboard
- Custom objects and tabs for Property, Tenant, Lease Agreement, Vendor, and Maintenance Request.
- Permission set with app visibility, tab visibility, object CRUD, field access for deployable optional fields, and Apex class access.
- Property list with server-side pagination of 25 records per page.
- Property filters for rent, availability, furnishing status, and nearby distance.
- Custom property creation flow with mandatory image upload.
- Property geocoding and record-page map component.
- Tenant list view.
- Lease agreement list/create flow.
- Task creation when a lease agreement is created.
- Lease PDF download and email to tenant using jsPDF.
- Scheduled Apex class for 30-day and 1-day lease expiry reminders.
- Vendor and maintenance request objects.
- Automatic least-workload vendor assignment for maintenance requests.
- Dashboard LWC for leases expiring in 30 days, maintenance requests by status, and occupancy rate.
- Apex unit tests for the major server-side flows.
- Sample data import plan.

## Required Post-Deploy Org Setup

- Run the bundled post-deploy script after metadata deployment:

```powershell
.\scripts\postDeploy.ps1 -TargetOrg "RealEstate Demo"
```

Or run the steps separately:

- Assign the permission set:

```bash
sf org assign permset --name Real_Estate_Manager --target-org "RealEstate Demo"
```

- Create/configure the `Google_Geocoding` named credential with the Google Maps API endpoint and API key/secret. Salesforce does not deploy live secrets in source metadata.

- Schedule lease reminders:

```bash
sf apex run --file scripts/scheduleLeaseReminders.apex --target-org "RealEstate Demo"
```

- Import sample records:

```bash
sf data import tree --plan data/RealEstatePlan.json --target-org "RealEstate Demo"
```

- Run Apex tests and confirm at least 80% coverage:

```bash
sf apex run test --target-org "RealEstate Demo" --test-level RunLocalTests --code-coverage --wait 20
```

## Submission Items Outside Source

- Commit the final repository changes.
- Export or zip the repository.
- Record the demo video/screen recording.
