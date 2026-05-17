@IsTest
public class RealEstateTestDataFactory {
    public static Property__c buildProperty(String nameSuffix) {
        return new Property__c(
            Name = 'Property ' + nameSuffix,
            Address__c = '100 Main Street',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Furnished',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'Well maintained property'
        );
    }

    public static Tenant__c createTenant() {
        Tenant__c tenant = new Tenant__c(Name = 'Test Tenant', Phone__c = '9999999999', Email__c = 'tenant@example.com');
        insert tenant;
        return tenant;
    }

    public static Vendor__c createVendor(String nameSuffix) {
        Vendor__c vendor = new Vendor__c(Name = 'Vendor ' + nameSuffix, Phone__c = '8888888888', Email__c = 'vendor' + nameSuffix + '@example.com');
        insert vendor;
        return vendor;
    }

    public static Property__c createProperty(String nameSuffix) {
        Property__c propertyRecord = buildProperty(nameSuffix);
        propertyRecord.Location__Latitude__s = 13.0827;
        propertyRecord.Location__Longitude__s = 80.2707;
        propertyRecord.Latitude__c = 13.0827;
        propertyRecord.Longitude__c = 80.2707;
        insert propertyRecord;
        return propertyRecord;
    }

    public static Lease_Agreement__c createLease(Property__c propertyRecord, Tenant__c tenant, Date endDate) {
        Lease_Agreement__c agreement = new Lease_Agreement__c(
            Property__c = propertyRecord.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Standard one-year terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = endDate,
            Status__c = 'Active'
        );
        insert agreement;
        return agreement;
    }
}
