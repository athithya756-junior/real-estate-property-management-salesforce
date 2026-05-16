trigger LeaseAgreementTrigger on Lease_Agreement__c (after insert) {
    LeaseAgreementService.handleAfterInsert(Trigger.new);
}
