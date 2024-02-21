@isTest(SeeAllData = true)
public with sharing class OSPTaskNoteTest{



    testMethod static void one() {


        MAINTENANCE_Construction_Vendor__c[] vendor = [SELECT Id, Name from MAINTENANCE_Construction_Vendor__c limit 1 ];

        Order[] oldTestOrder = [SELECT Id, OSP_Engineer__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, As_Built_Rejection__c FROM Order LIMIT 1];
        // Order[] oldTestOrder = [SELECT Id, OSP_Engineer__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c FROM Order LIMIT 1];
    
    
        if ( oldTestOrder?.size() > 0 ) {
            for( Order o :oldTestOrder ) {
                o.OSP_Engineer__c = null;
                o.Site_Survey_Scheduled__c = null;
                o.Site_Survey_Complete__c = null;
                o.OSP_DEsign_Received__c = false;
                o.OSP_Design_Revised__c = false;
                o.DOT_Permit_needed__c = false;
                o.Leased_Conduit_Permit_Needed__c = false;
                o.Railroad_Permit_Needed__c = false;
                o.Underground_Permit_Needed__c = false;
                o.Aerial_Perrmit_Needed__c = false;
                o.Contractor__c = vendor[0].Id;
                o.Construction_Status__c = 'Walkout Complete';
                o.As_Built_Uploaded_OSP__c = false;
                o.Splice_Documents_Received__c = false;
                o.As_Built_Not_Needed_OSP__c = false;
                o.OSP_DEsign_Imported__c = false;
                o.As_Built_Imported_GIS__c = false;
                // o.Splice_Documents_Imported__c = false;
                o.As_Built_Rejection__c = false;
            }
        }

        
        if ( oldTestOrder?.size() > 0 ) {
            try {
                update oldTestOrder;

                System.debug('succefully inserted order comments');
            
            } catch (Exception e) {
                System.debug(e);
            }
        }
        List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Order.Construction_Status__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			//pickListValuesList.add(pickListVal.getLabel());
            oldTestOrder[0].Construction_Status__c = pickListVal.getLabel();
            try {
                update oldTestOrder;

                System.debug('succefully inserted order comments');
            
            } catch (Exception e) {
                System.debug(e);
            }
		}     
    
    
    }




   /* public OSPTaskNoteTest(){
        // Create a test User
        User u = new User();
        u.Id = UserInfo.getUserId();
        // Create a test Construction Vendor
        MAINTENANCE_Construction_Vendor__c vendor = new MAINTENANCE_Construction_Vendor__c(Id = 'a1M4P00000EWIflUAH');
        // Create a test Order
        Id testOrderId = '8013g000000TCfmAAG';
        // query test order by Id
        Order oldTestOrder = [SELECT Id, OSP_Engineer__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c
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
        oldTestOrder.Splice_Documents_Imported__c = false;
        oldTestOrder.As_Built_Rejection__c = false;
        // Update test order
        update oldTestOrder;
    }

    @isTest
    static void testCreateOSPTaskNote(){
        User u = new User();
        u.Id = UserInfo.getUserId();
        Id testOrderId = '8013g000000TCfmAAG';

        Order oldTestOrder = [SELECT Id, OSP_Engineer__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c
                              FROM Order
                              WHERE Id = :testOrderId
                              LIMIT 1];

        Order newTestOrder = [SELECT Id, OSP_Engineer__c, Site_Survey_Scheduled__c, Site_Survey_Complete__c, OSP_DEsign_Received__c, OSP_Design_Revised__c, DOT_Permit_needed__c, Leased_Conduit_Permit_Needed__c, Railroad_Permit_Needed__c, Underground_Permit_Needed__c, Aerial_Perrmit_Needed__c, Contractor__c, Construction_Status__c, As_Built_Uploaded_OSP__c, As_Built_Not_Needed_OSP__c, OSP_DEsign_Imported__c, As_Built_Imported_GIS__c, Splice_Documents_Imported__c, As_Built_Rejection__c
                              FROM Order
                              WHERE Id = :testOrderId
                              LIMIT 1];

        // Create copy of oldTestOrder to udate its fields
        newTestOrder.OSP_Engineer__c = u.Id;
        newTestOrder.Site_Survey_Scheduled__c = Date.today();
        newTestOrder.Site_Survey_Complete__c = Date.today();
        // newTestOrder.OSP_DEsign_Received__c = true;
        // newTestOrder.OSP_Design_Revised__c = true;
        // newTestOrder.DOT_Permit_needed__c = true;
        // newTestOrder.Leased_Conduit_Permit_Needed__c = true;
        // newTestOrder.Railroad_Permit_Needed__c = true;
        // newTestOrder.Underground_Permit_Needed__c = true;
        // newTestOrder.Aerial_Perrmit_Needed__c = true;
        // newTestOrder.Contractor__c = vendor.Id;
        // newTestOrder.Construction_Status__c = 'PreConstruction';
        // newTestOrder.As_Built_Uploaded_OSP__c = true;
        // newTestOrder.Splice_Documents_Received__c = true;
        // newTestOrder.As_Built_Not_Needed_OSP__c = true;
        // newTestOrder.OSP_DEsign_Imported__c = true;
        // newTestOrder.As_Built_Imported_GIS__c = true;
        // newTestOrder.Splice_Documents_Imported__c = true;
        // newTestOrder.As_Built_Rejection__c = true;

        // Update test order
        //update newTestOrder;

        // Creat OSP Task Note
        String comment = OSPTaskNote.createOSPTaskNote(newTestOrder, oldTestOrder);
        System.debug('comment: ' + comment);
    }*/

}