# Data Model

## Property__c

Stores rentable real estate inventory.

| Field | Type | Notes |
| --- | --- | --- |
| Name | Text | Property name |
| Address__c | Text | Required |
| City__c | Text | Required |
| State__c | Text | Required |
| Postal_Code__c | Text | Required |
| Country__c | Text | Required |
| Type__c | Picklist | Residential, Commercial |
| Furnishing_Status__c | Picklist | Furnished, Semi-Furnished, Unfurnished |
| Status__c | Picklist | Available, Occupied |
| Rent__c | Currency | Required |
| Description__c | Long Text | Required |
| Location__c | Geolocation | Populated by geocoding |

Property images are Salesforce Files linked through `ContentDocumentLink`.

## Tenant__c

Stores tenant contact details. A tenant can be associated with many lease agreements.

| Field | Type |
| --- | --- |
| Name | Text |
| Phone__c | Phone |
| Email__c | Email |

## Lease_Agreement__c

Connects one tenant to one property for a lease term.

| Field | Type | Notes |
| --- | --- | --- |
| Name | Auto Number | Lease identifier |
| Tenant__c | Lookup(Tenant__c) | Required |
| Property__c | Lookup(Property__c) | Required |
| Terms__c | Long Text | Lease terms |
| Agreed_Monthly_Rent__c | Currency | Required |
| Start_Date__c | Date | Required |
| End_Date__c | Date | Required and must be after start date |
| Status__c | Picklist | Draft, Active, Expired, Terminated |

## Vendor__c

Stores maintenance vendor details.

| Field | Type |
| --- | --- |
| Name | Text |
| Phone__c | Phone |
| Email__c | Email |

## Maintenance_Request__c

Tracks service requests and the assigned vendor.

| Field | Type | Notes |
| --- | --- | --- |
| Name | Auto Number | Request identifier |
| Property__c | Lookup(Property__c) | Required |
| Vendor__c | Lookup(Vendor__c) | Auto-assigned when blank |
| Status__c | Picklist | Open, In Progress, Completed, Cancelled |
| Description__c | Long Text | Request details |
