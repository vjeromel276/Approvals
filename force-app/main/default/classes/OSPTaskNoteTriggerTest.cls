@isTest(SeeAllData = true)
public with sharing class OSPTaskNoteTriggerTest{
    public OSPTaskNoteTriggerTest(){

        // Create a test Construction Vendor
        MAINTENANCE_Construction_Vendor__c vendor = new MAINTENANCE_Construction_Vendor__c(Id = 'a1M4P00000EWIflUAH');
        // Create a test Order
        Id testOrderId = '8013g000000TCfmAAG';
        // query test order by Id
        Order oldTestOrder = [SELECT Id, OSP_Engineer__c, Fiber_Design_Complete_FDE__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c
                              FROM Order
                              WHERE Id = :testOrderId
                              LIMIT 1];
        oldTestOrder.OSP_Engineer__c = null;
        oldTestOrder.Site_Survey_Scheduled__c = null;
        oldTestOrder.Site_Survey_Complete__c = null;
        oldTestOrder.OSP_DEsign_Received__c = false;
        oldTestOrder.OSP_Design_Revised__c = false;
        oldTestOrder.DOT_Permit_needed__c = false;
        oldTestOrder.Leased_Conduit_Permit_Needed__c = false;
        oldTestOrder.Railroad_Permit_Needed__c = false;
        oldTestOrder.Underground_Permit_Needed__c = false;
        oldTestOrder.Aerial_Perrmit_Needed__c = false;
        oldTestOrder.Contractor__c = vendor.Id;
        oldTestOrder.Construction_Status__c = 'Walkout Complete';
        oldTestOrder.As_Built_Uploaded_OSP__c = false;
        oldTestOrder.Splice_Documents_Received__c = false;
        oldTestOrder.As_Built_Not_Needed_OSP__c = false;
        oldTestOrder.OSP_DEsign_Imported__c = false;
        oldTestOrder.As_Built_Imported_GIS__c = false;
        // oldTestOrder.Splice_Documents_Imported__c = false;
        oldTestOrder.As_Built_Rejection__c = false;
        oldTestOrder.Fiber_Design_Complete_FDE__c = false;
        // Update test order
        update oldTestOrder;
    }

    @isTest
    static void testCreateOSPTaskNote(){
        User u = new User();
        u.Id = UserInfo.getUserId();
        Id testOrderId = '8013g000000TCfmAAG';

        Order oldTestOrder = [SELECT Id, OSP_Engineer__c, Fiber_Design_Complete_FDE__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c
                              FROM Order
                              WHERE Id = :testOrderId
                              LIMIT 1];
                              
        Test.startTest();
        // update order fields
        oldTestOrder.OSP_Engineer__c = u.Id;
        oldTestOrder.Site_Survey_Scheduled__c = Date.today();
        oldTestOrder.Site_Survey_Complete__c = Date.today();

        // Update test order
        // update oldTestOrder;
        Test.stopTest();
    }

}