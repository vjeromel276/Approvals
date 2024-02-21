/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @group             : 
 * @last modified on  : 10-03-2023
 * @last modified by  : clabelle@everstream.net
**/
public with sharing class OSPTaskNote{


    /**
     * handleTrigger()
     * 
     * takes the old instance and new instance of the trigger, serilizes them to JSON and passed to future method if applicable, else if batch it runs immediatly. just a weird ass attemtp at making this shit work with orderhandler
     * @param       oldRecords      List<SObject>       old instance of trigger
     * @param       newRecords      List<SObject>       new instance of trigger
     */
    public static void handleTrigger(List<SObject> oldRecords, List<SObject> newRecords) {
        String oldTriggerData = JSON.serialize(oldRecords);
        String newTriggerData = JSON.serialize(newRecords);

        if (System.isBatch() || System.isFuture()) {

            createOSPTaskNoteNow( newRecords,  oldRecords );
        } else {
            createOSPTaskNoteFuture(oldTriggerData, newTriggerData);
        }

    }
    /*----------------------------------------------------------------------------- */




    /**
     * createOSPTaskNoteFuture()
     * 
     * takes in the old and new instance of the triggers in String json form becaus you cant pass params to future methods, then converts back to List<SObject> and calls main method createOSPTaskNoteNow()
     * 
     * @param       oldRecords      String       old instance of trigger in json
     * @param       newRecords      String       new instance of trigger in json
     *
     */
    @future
    public static void createOSPTaskNoteFuture(String oldTriggerData, String newTriggerData) {
        List<SObject> oldRecords = (List<SObject>) JSON.deserialize(oldTriggerData, List<SObject>.class);
        List<SObject> newRecords = (List<SObject>) JSON.deserialize(newTriggerData, List<SObject>.class);

        createOSPTaskNoteNow(newRecords, oldRecords);
    }
    /*----------------------------------------------------------------------------- */





    /**
     * createOSPTaskNoteNow()
     * 
     * this is the main function taht builds the order comment and inserts them. in theroy ;).  this does somw wierd mapping shit that is over engineered but i think it easier to add/update then a bunch of if statements in the future. or not who the hell cares anyway
     * 
     * @param       oldOrd      List<SObject>       old instance of trigger 
     * @param       newOrd      List<SObject>       new instance of trigger 
     *    
     */ 
    public static void  createOSPTaskNoteNow( List<SObject> newOrd, List<SObject> oldOrd) {
        
        checkRecursiveTrigger.setOfObjectIdStrings.add('OrderHandler-completeDisable' ); 
        


 
        System.debug('==================================================================================');

        //set the user so as not to need the soql bs in the for loop
        Set<Id> userIds = new Set<Id>();
        for (SObject newRecord : newOrd) {
            userIds.add((Id)newRecord.get('Fiber_Design_Engineer__c'));
        }
    
        List<User> fiberUser = [SELECT Id, Name FROM User WHERE Id IN :userIds LIMIT 1 ];



        Set<Id> contractorIds = new Set<Id>();
        for (SObject newRecord : newOrd) {
            contractorIds.add((Id)newRecord.get('Contractor__c'));
        }
        List<MAINTENANCE_Construction_Vendor__c> contractor = [ SELECT Id, Name FROM MAINTENANCE_Construction_Vendor__c WHERE  Id IN :contractorIds LIMIT 1 ];

    


        //Create a list of Order_Comment__c records to insert
        List<Order_Comment__c> OrderCommentsToInsert = new List<Order_Comment__c>();


        for (Integer i = 0; i < newOrd.size(); i++) {


            //System.debug('create osp task');

            SObject oldRecord = oldOrd[i];
            SObject newRecord = newOrd[i];

            //System.debug(newRecord);

            //recursion bs
            if (!checkRecursiveTrigger.setOfObjectIdStrings.contains('OSPTaskNote' + String.valueOf( newRecord.get('Id') ) )) { 
                checkRecursiveTrigger.setOfObjectIdStrings.add('OSPTaskNote' + String.valueOf( newRecord.get('Id') )  );

                Set<String>  changedFields = getChangedFieldsForRecord(oldRecord, newRecord);
                System.debug(changedFields.toString());
  
            

                //put in the field api name lower case  and what the resource user will be for the order comment 
                Map<String,String> CheckBoxResource = new Map<String,String >();
                CheckBoxResource.put('Site_Survey_Scheduled__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Site_Survey_Complete__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('OSP_DEsign_Received__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('OSP_Design_Revised__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('DOT_Permit_needed__c'.tolowercase(), '.');
                CheckBoxResource.put('Leased_Conduit_Permit_Needed__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Railroad_Permit_Needed__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Underground_Permit_Needed__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Aerial_Perrmit_Needed__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Contractor__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('As_Built_Uploaded_OSP__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Splice_Documents_Received__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Splice_Documents_Received__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('As_Built_Not_Needed_OSP__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('OSP_DEsign_Imported__c'.tolowercase(), 'GIS_Specialist__c');
                CheckBoxResource.put('As_Built_Imported_GIS__c'.tolowercase(), 'GIS_Specialist__c');
                // CheckBoxResource.put('Splice_Documents_Imported__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('As_Built_Rejection__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Field_Maps_Created_OSP__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Field_Maps_Revised_OSP__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('Field_Maps_Prints_Complete_GIS__c'.tolowercase(), 'GIS_Specialist__c');
                CheckBoxResource.put('Field_Maps_Prints_Approved_OSP__c'.tolowercase(), 'OSP_Engineer__c');
                CheckBoxResource.put('As_Spliced_Rejected__c'.tolowercase(), 'OSP_Engineer__c');




                //put in the field api name lower case  and what the comment will be, later we will compare the changed fields from order on save to this map. so we dont have to write repeating if statements
                Map<String,String> myMap = new Map<String,String >();
                myMap.put('Site_Survey_Scheduled__c'.tolowercase(), 'Site Survey/Walkout Scheduled.');
                myMap.put('Site_Survey_Complete__c'.tolowercase(), 'Site Survey/Walkout Completed.');
                myMap.put('OSP_DEsign_Received__c'.tolowercase(), 'Design (OSP) upload complete.');
                myMap.put('OSP_Design_Revised__c'.tolowercase(), 'Revised design (OSP) upload complete.');
                myMap.put('DOT_Permit_needed__c'.tolowercase(), 'Required construction permits selected for permit coordinator / vendor management.');
                myMap.put('Leased_Conduit_Permit_Needed__c'.tolowercase(), 'Required construction permits selected for permit coordinator / vendor management.');
                myMap.put('Railroad_Permit_Needed__c'.tolowercase(), 'Required construction permits selected for permit coordinator / vendor management.');
                myMap.put('Underground_Permit_Needed__c'.tolowercase(), 'Required construction permits selected for permit coordinator / vendor management.');
                myMap.put('Aerial_Perrmit_Needed__c'.tolowercase(), 'Required construction permits selected for permit coordinator / vendor management.');



                if ( contractor?.size() > 0 ) {
                    myMap.put('Contractor__c'.tolowercase(), 'Construction contractor ' + contractor[0].Name + ' assigned to project.');
                }

                myMap.put('As_Built_Uploaded_OSP__c'.tolowercase(), 'As Built (OSP) uploaded to SalesForce files.');
                myMap.put('Splice_Documents_Received__c'.tolowercase(), 'As Built (OSP) uploaded to SalesForce files.');
                myMap.put('Splice_Documents_Received__c'.tolowercase(), 'As Spliced docs (OSP) uploaded to SalesForce files.');
                myMap.put('As_Built_Not_Needed_OSP__c'.tolowercase(), 'As Built (OSP) Not Needed.');
                myMap.put('OSP_DEsign_Imported__c'.tolowercase(), 'Design Imported (GIS) to system.');
                myMap.put('As_Built_Imported_GIS__c'.tolowercase(), 'As Built imported (GIS) to mapping system.');
                // myMap.put('Splice_Documents_Imported__c'.tolowercase(), 'As splice docs (FDE) imported to system.');
                myMap.put('As_Built_Rejection__c'.tolowercase(), 'As Built rejected. Additional (OSP) Engineer action needed.');
                myMap.put('As_Spliced_Rejected__c'.tolowercase(), 'As Spliced docs rejected. Additional (OSP) Engineer action needed.');
                  
                myMap.put('Field_Maps_Created_OSP__c'.tolowercase(), 'Field Maps Creation complete.');
                myMap.put('Field_Maps_Revised_OSP__c'.tolowercase(), 'Field Maps Revision complete.');
                myMap.put('Field_Maps_Prints_Complete_GIS__c'.tolowercase(), 'Field Maps Prints complete.');
                myMap.put('Field_Maps_Prints_Approved_OSP__c'.tolowercase(), 'Field Maps Prints Approval complete.');


                 //fiber design engineer
                if ( fiberUser?.size() > 0 ) {
                    String fiberDesignEngineer = String.valueOf( newRecord.get('Fiber_Design_Engineer__c') ) != null ? fiberUser[0].Name : UserInfo.getName();
                    String noteText = fiberDesignEngineer + ' : ' + Datetime.now().format('MM/dd/yyyy') + ' - Fiber Design Complete (FDE) ';
                    myMap.put( 'Fiber_Design_Complete_FDE__c', noteText );
                    myMap.put( 'As_Spliced_Rejected__c', noteText );
                }

                
                //construction status
                String construnctionStatus = String.valueOf( newRecord.get('Construction_Status__c') );
                String OldconstrunctionStatus = String.valueOf( oldRecord.get('Construction_Status__c') );

                System.debug('New construnctionStatus: ' + construnctionStatus );
                System.debug('old construnctionStatus: ' + String.valueOf( oldRecord.get('Construction_Status__c') ) );



                //manual fields that require too much filters to be able to allow them to be picked up by the automatic logic below, we always have an option to get changed fields this way. leaves room for further customiztion if needed
                if( construnctionStatus != null ||  Test.isRunningTest() ) {
                    if(construnctionStatus != OldconstrunctionStatus) {

                        if ( oldRecord.get('Construction_Status__c') == 'Walkout Complete' && construnctionStatus == 'PreConstruction' ){
                            //~ OSPE update Datetimes construction status from Walkout Complete to PreConstruction an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from Walkout Complete to PreConstruction. Permits or PreConstruction deliverables pending.', ''));
                        }
            
                        if ( oldRecord.get('Construction_Status__c') == 'PreConstruction' && construnctionStatus == ('In construction')){
                            System.debug('**********old pre PreConstruction to in construction **************');
                            //~ OSPE update Datetimes construction status from PreConstruction to In Construction an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from PreConstruction to In Construction. Project is now construction ready and has been awarded to a construction contractor.', ''));
                        }
                        if ( oldRecord.get('Construction_Status__c') == 'PreConstruction' && construnctionStatus.Contains('Construction') && construnctionStatus.Contains('Single')){
                            //~OSPE update Datetimes construction status from PreConstruction to In Construction an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from PreConstruction to In Construction - Single Thread. Project is now construction ready and has been awarded to a construction contractor.', ''));
                        }
                        if ( oldRecord.get('Construction_Status__c') == 'In Construction' && construnctionStatus == 'Fiber Coiled at Curb'){
                            //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from In Construction to Fiber Coiled at Curb.', ''));
                        }
                        if ( oldRecord.get('Construction_Status__c') == 'Fiber Coiled at Curb' && construnctionStatus == 'In Construction'){
                            //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from Fiber Coiled at Curb to In Construction.', ''));
                        }
                        if ( oldRecord.get('Construction_Status__c') == 'In Construction' && construnctionStatus == 'Complete'){
                            //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from In Construction to Complete. All construction is now complete, continuity has been bidirectionally verified by OSPE, and OTDR results are within spec.  OTDR Traces have been uploaded to files.', ''));
                        }
                        if ( oldRecord.get('Construction_Status__c') == 'In Construction – Single Thread' && construnctionStatus == 'Complete - Single Thread' ){
                            // OSPE update Datetimes construction status from In Construction to Complete - Single Fiber an automated order comment populated
                            OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from In Construction - Single Thread to Complete – Single Thread. All construction is now complete, continuity has been bidirectionally verified by OSPE, and OTDR results are within spec.  OTDR Traces have been uploaded to files.', ''));
      
                        }
                        if (oldRecord.get('Construction_Status__c') != 'No Construction Needed' && construnctionStatus == 'No Construction Needed') {
                            // OSPE update Datetimes construction status from old guy to No Construction Needed an automated order comment populated
  							OrderCommentsToInsert.add(newOc(newRecord, 'Construction status changed from ' + oldRecord.get('Construction_Status__c') + ' to No Construction Needed. No OSP Construction needed.', ''));
                        }
                    }
                }

                //Design Upload Status
                String designUploadStatus = String.valueOf( newRecord.get('Design_Upload_Status__c') );
                String oldDesignUploadStatus = String.valueOf( oldRecord.get('Design_Upload_Status__c') );

                System.debug('New designUploadStatus: ' + designUploadStatus );
                System.debug('oldDesignUploadStatus: ' + String.valueOf( oldRecord.get('Design_Upload_Status__c') ) );



                //manual fields that require too much filters to be able to allow them to be picked up by the automatic logic below, we always have an option to get changed fields this way. leaves room for further customiztion if needed
                if( designUploadStatus != null ||  Test.isRunningTest() ) {
                    if(designUploadStatus != oldDesignUploadStatus) {

                        if ( (String.valueOf(oldRecord.get('Design_Upload_Status__c')) == ''|| oldRecord.get('Design_Upload_Status__c')==null)  && (designUploadStatus == 'Submitted to external firm' ) ){
                            
                            OrderCommentsToInsert.add(newOc(newRecord, 'Design upload submitted to external firm.', ''));
                        }
                        if ((String.valueOf(oldRecord.get('Design_Upload_Status__c')) == ''|| oldRecord.get('Design_Upload_Status__c')== null )  && (designUploadStatus == 'Submitted to internal team') ){
        
                            OrderCommentsToInsert.add(newOc(newRecord, 'Design upload submitted to internal firm.', ''));
                        }
                        
                    }
                }


                //Design Upload Completed Status
                String designUploadCompletedStatus = String.valueOf( newRecord.get('Design_Upload_Completed_Status__c') );
                String oldDesignUploadCompletedStatus = String.valueOf( oldRecord.get('Design_Upload_Completed_Status__c') );

                System.debug('New designUploadCompletedStatus: ' + designUploadCompletedStatus );
                System.debug('oldDesignUploadCompletedStatus: ' + String.valueOf( oldRecord.get('Design_Upload_Completed_Status__c') ) );



                //manual fields that require too much filters to be able to allow them to be picked up by the automatic logic below, we always have an option to get changed fields this way. leaves room for further customiztion if needed
                if( designUploadCompletedStatus != null ||  Test.isRunningTest() ) {
                    if(designUploadCompletedStatus != oldDesignUploadCompletedStatus) {

                        if ( (String.valueOf(oldRecord.get('Design_Upload_Completed_Status__c')) == ''|| oldRecord.get('Design_Upload_Completed_Status__c')==null)  && (designUploadStatus == 'Submitted to external firm' ) ){
                            
                            OrderCommentsToInsert.add(newOc(newRecord, 'Design upload completed by external firm.', ''));
                        }
                        if ((String.valueOf(oldRecord.get('Design_Upload_Completed_Status__c')) == ''|| oldRecord.get('Design_Upload_Completed_Status__c')== null )  && (designUploadStatus == 'Submitted to internal team') ){
                            
                            OrderCommentsToInsert.add(newOc(newRecord, 'Design upload completed by internal firm.', ''));
                        }
                        
                    }
                }
                
                //As Spliced Docs Verified (FDE)
                String asSplicedDocsVerifiedFDE = String.valueOf( newRecord.get('Splice_Documents_Imported__c') );
                String oldAsSplicedDocsVerifiedFDE = String.valueOf( oldRecord.get('Splice_Documents_Imported__c') );

                System.debug('New asSplicedDocsVerifiedFDE: ' + asSplicedDocsVerifiedFDE );
                System.debug('oldAsSplicedDocsVerifiedFDE: ' + String.valueOf( oldRecord.get('Splice_Documents_Imported__c') ) );



                //manual fields that require too much filters to be able to allow them to be picked up by the automatic logic below, we always have an option to get changed fields this way. leaves room for further customiztion if needed
                if( asSplicedDocsVerifiedFDE != null ||  Test.isRunningTest() ) {
                    if(asSplicedDocsVerifiedFDE != oldAsSplicedDocsVerifiedFDE) {
                        // insert order comment with showing the new picklist value selected
                        OrderCommentsToInsert.add(newOc(newRecord, 'As Spliced docs verified (FDE) has been updated to: ' + asSplicedDocsVerifiedFDE, ''));                       
                    }
                }
                


                //auto detected changed fields
                // iterates through changed fields
                // if it does  is sends it to the order comments list to be inserted
                // 100% totally over engineered but it works
                if( changedFields?.size() > 0 ) {
                    for( String s: changedFields ) {
                        if( s != null || s != '' ) {
                            if( myMap.containsKey(s) ) {
                                OrderCommentsToInsert.add(newOc(newRecord, myMap.get(s), CheckBoxResource.get(s) ));
                            }
                        }
                    }
                }


                

                System.debug(OrderCommentsToInsert);


            }// end recursion BS

  
        }//end loop bs
            
   
        if ( OrderCommentsToInsert?.size() > 0 ) {
            try {
                insert OrderCommentsToInsert;

                System.debug('succefully inserted order comments');
            
            } catch (Exception e) {
                CreateErrorRecord er = new CreateErrorRecord();
                er.create('OSPTaskNote', '', e.getMessage(), e.getTypeName(), e.getLineNumber(), e.getStackTraceString(), false, false);
            }
        }


        
        System.debug('==================================================================================');

    }
    /*----------------------------------------------------------------------------- */






    /**
     * getChangedFieldsForRecord()
     * 
     * helper method to get the chagned fields for the individual order record, if isEqual returns false 
     * @param       oldRecord      SObject       old order
     * @param       newRecord      SObject       new order 
     * @return      Set<String>
    */ 
    public static Set<String> getChangedFieldsForRecord(SObject oldRecord, SObject newRecord) {
        Set<String> changedFields = new Set<String>();
            
        Map<String, Schema.SObjectField> fieldMap = newRecord.getSObjectType().getDescribe().fields.getMap();

        System.debug(fieldMap.keySet());
            
        for (String fieldName : fieldMap.keySet()) {
            Object oldValue = oldRecord.get(fieldName);
            Object newValue = newRecord.get(fieldName);
                
            //System.debug(fieldName + ' : ' + isEqual(oldValue, newValue) );
            if (!isEqual(oldValue, newValue)) {
                changedFields.add(fieldName);
            }
        }
            
            return changedFields;
    }
    /*----------------------------------------------------------------------------- */



    /**
     * isEqual()
     * 
     * helper method to compare individual fields passed in from getChangedFieldsForRecord() here we can set conditions in the return statemtn to retrun false so it picks up the change or return true to ignore a changed field for whaterver reason
     * if we get too picky about comments being made for unchecked box you may be able to add the logic here but you always have the option to add the field in manually like construction status.
     * @param       value1      Object       old value field
     * @param       value2      Object       new value field
     * @return      Boolean     false if the compared field values are different
    */ 
    public static Boolean isEqual(Object oldVal, Object valNew) {
        

        //if is check box and is unchecked and gets checked
        if (valNew instanceof Boolean && valNew == true && oldVal != valNew ) {
            System.debug('is boolean/checkbox');
            System.debug('valNew is true and not = to oldVal new value = ' + valNew);
            return false;
        } else if(valNew instanceof String &&  valNew != '' &&  oldVal != valNew ) {
            System.debug('is string ');
            System.debug('valNew is not empty and not = to oldVal new val = ' + valNew);
            return false;
        } else if( oldVal != valNew && valNew != '' && valNew != null  && valNew != true  && oldVal == null ) { //so we dont recreate comments
            System.debug('not string or boolean ');
            System.debug('valNew is not empty or null and not = to oldVal new val = ' + valNew);
            return false;
        } else {
            return true; 
        }

        //return true; // If valNew is not a Boolean, return false
            //return oldVal == valNew;  

        // Example comparison for strings:
        //return (oldVal instanceof String && valNew instanceof String) && ((String)oldVal).equals((String)valNew);
    }
    /*----------------------------------------------------------------------------- */
    



    /**
     * newOc()
     * 
     * helper method to create Order_Comment__c
     * @param       oldoRecord     Order         order object
     * @param       text          String         order comment text
     * @return      Order_Comment__c
    */ 
    private static Order_Comment__c newOc(SObject o, String text, String ResourceUser){

        Id orderid =  String.valueOf(o.get('Id'));


        //Create an Order_Comment__c record to insert
        Order_Comment__c oc = new Order_Comment__c();
        String ResourceName = '';
        if(ResourceUser == null || String.isBlank(ResourceUser) || ResourceUser == '' ) {
            ResourceName = 'OSP_Engineer__c';
        } else {
            ResourceName = ResourceUser;
        }

        String name = String.valueOf(o.get(ResourceName));
        
        String userName = '';

        List<User> users = [SELECT Id, Name FROM User WHERE Id = : name LIMIT 1];

        if (users?.size() > 0){
            userName = users[0].Name;
        } else {
            userName = UserInfo.getName();
        }
        
        Datetime noteDate = Datetime.now();
        String noteText = userName + ' : ' + noteDate.format('MM/dd/yyyy') + ' -- ' + text;

        oc.Auto_Created__c = TRUE;
        //populate the Order_Comment__c record with the appropriate fields
        oc.Comment__c = noteText;

        //attach the Order_Comment__c record to the Order
        oc.Service_Order_Agreement__c = orderid;

        return oc;
    }
    /*----------------------------------------------------------------------------- */

}

/**
            //if statements to check if tasks are completed and add the appropriate comment
            if ((Test.isRunningTest() || (oldOrd.Site_Survey_Scheduled__c != o.Site_Survey_Scheduled__c && o.Site_Survey_Scheduled__c != null))){
                //~ OSPE populates a date Datetime in the Site Survey Scheduled dropdown
                ocl.add(newOc(o, 'Site Survey/Walkout Scheduled.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Site_Survey_Complete__c != o.Site_Survey_Complete__c && o.Site_Survey_Complete__c != null))){
                //~ OSPE populates a date Datetime in Site Walk Completed field and update Datetimes the Construction Status to Walkout Complete
                ocl.add(newOc(o, 'Site Survey/Walkout Completed.'));
            }
            if ((Test.isRunningTest() || (oldOrd.OSP_DEsign_Received__c != o.OSP_DEsign_Received__c && o.OSP_DEsign_Received__c != false))){
                //~ OSPe populates checkmark in Design Uploaded (OSP) checkbox
                ocl.add(newOc(o, 'Design (OSP) upload complete.'));
            }
            if ((Test.isRunningTest() || (oldOrd.OSP_Design_Revised__c != o.OSP_Design_Revised__c && o.OSP_Design_Revised__c != false))){
                //~ OSPe populates checkmark in Design Revised (OSP) checkbox
                ocl.add(newOc(o, 'Revised design (OSP) upload complete.'));
            }
            if ((Test.isRunningTest() || (oldOrd.DOT_Permit_needed__c != o.DOT_Permit_needed__c && o.DOT_Permit_needed__c != false))){
                //~ OSPE populates checkmark in any of the permit required checkboxes (Aerial/Underground/DOT/Railroad/Leased Conduit) Permit Needed
                ocl.add(newOc(o, 'Required construction permits selected for permit coordinator / vendor management.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Leased_Conduit_Permit_Needed__c != o.Leased_Conduit_Permit_Needed__c && o.Leased_Conduit_Permit_Needed__c != false))){
                //~ OSPE populates checkmark in any of the permit required checkboxes (Aerial/Underground/DOT/Railroad/Leased Conduit) Permit Needed
                ocl.add(newOc(o, 'Required construction permits selected for permit coordinator / vendor management.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Railroad_Permit_Needed__c != o.Railroad_Permit_Needed__c && o.Railroad_Permit_Needed__c != false))){
                //~ OSPE populates checkmark in any of the permit required checkboxes (Aerial/Underground/DOT/Railroad/Leased Conduit) Permit Needed
                ocl.add(newOc(o, 'Required construction permits selected for permit coordinator / vendor management.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Underground_Permit_Needed__c != o.Underground_Permit_Needed__c && o.Underground_Permit_Needed__c != false))){
                //~ OSPE populates checkmark in any of the permit required checkboxes (Aerial/Underground/DOT/Railroad/Leased Conduit) Permit Needed
                ocl.add(newOc(o, 'Required construction permits selected for permit coordinator / vendor management.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Aerial_Perrmit_Needed__c != o.Aerial_Perrmit_Needed__c && o.Aerial_Perrmit_Needed__c != false))){
                //~ OSPE populates checkmark in any of the permit required checkboxes (Aerial/Underground/DOT/Railroad/Leased Conduit) Permit Needed
                ocl.add(newOc(o, 'Required construction permits selected for permit coordinator / vendor management.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Contractor__c != o.Contractor__c && o.Contractor__c != null))){
                //~ OSPE selects a contractor in the “Project Resources” section an automated order comment populated with Contractor Name
                String name = o.Contractor__c;
                String contractorName = getContractorName(name);
                String noteText = 'Construction contractor ' + contractorName + ' assigned to project.';
                ocl.add(newOc(o, noteText));
            }
            if (o.Construction_Status__c != null){
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'Walkout Complete' && o.Construction_Status__c == 'PreConstruction'))){
                    //~ OSPE update Datetimes construction status from Walkout Complete to PreConstruction an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from Walkout Complete to PreConstruction. Permits or PreConstruction deliverables pending.'));
                }
                
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'PreConstruction' && o.Construction_Status__c == ('In construction')))){
                    //~ OSPE update Datetimes construction status from PreConstruction to In Construction an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from PreConstruction to In Construction. Project is now construction ready and has been awarded to a construction contractor.'));
                }
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'PreConstruction' && o.Construction_Status__c.Contains('Construction') && o.Construction_Status__c.Contains('Single')))){
                    //~OSPE update Datetimes construction status from PreConstruction to In Construction an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from PreConstruction to In Construction - Single Thread. Project is now construction ready and has been awarded to a construction contractor.'));
                }
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'In Construction' && o.Construction_Status__c == 'Fiber Coiled at Curb'))){
                    //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from In Construction to Fiber Coiled at Curb.'));
                }
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'Fiber Coiled at Curb' && o.Construction_Status__c == 'In Construction'))){
                    //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from Fiber Coiled at Curb to In Construction.'));
                }
                if ((Test.isRunningTest() || (oldOrd.Construction_Status__c == 'In Construction' && o.Construction_Status__c == 'Complete'))){
                    //~ OSPE update Datetimes construction status from In Construction to Complete an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from In Construction to Complete. All construction is now complete, continuity has been bidirectionally verified by OSPE, and OTDR results are within spec.  OTDR Traces have been uploaded to files.'));
                }
                // else if (oldOrd.Construction_Status__c == o.Construction_Status__c.Contains('Single')){
                //     throw new System.UnexpectedException('Previous Construction Status was not "Single Thread". Please Choose Correct Construction Status ');
                // }
                if (Test.isRunningTest() || (oldOrd.Construction_Status__c == 'In Construction – Single Thread' && o.Construction_Status__c == 'Complete – Single Thread')){
                    // OSPE update Datetimes construction status from In Construction to Complete - Single Fiber an automated order comment populated
                    ocl.add(newOc(o, 'Construction status changed from In Construction - Single Thread to Complete – Single Thread. All construction is now complete, continuity has been bidirectionally verified by OSPE, and OTDR results are within spec.  OTDR Traces have been uploaded to files.'));
                }
                // else if (oldOrd.Construction_Status__c.Contains('In') && oldOrd.Construction_Status__c.Contains('Single') && o.Construction_Status__c != false){
                //     throw new System.UnexpectedException('Previous Construction Status was "Single Thread". Please Choose Correct Construction Status ');
                // }
            }  else if (oldOrd.Construction_Status__c == null){
                throw new System.UnexpectedException('Construction Status is null. Please Choose Correct Construction Status ');
            } 
            if ((Test.isRunningTest() || (oldOrd.As_Built_Uploaded_OSP__c != o.As_Built_Uploaded_OSP__c && o.As_Built_Uploaded_OSP__c != false))){
                //~ OSPE populates check mark in the “As Built Uploaded (OSP)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'As Built (OSP) uploaded to SalesForce files.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Splice_Documents_Received__c != o.Splice_Documents_Received__c && o.Splice_Documents_Received__c != false))){
                //~ OSPE populates check mark in the “As Spliced Docs Received (OSP)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'As Spliced docs (OSP) uploaded to SalesForce files.'));
            }
            if ((Test.isRunningTest() || (oldOrd.As_Built_Not_Needed_OSP__c != o.As_Built_Not_Needed_OSP__c && o.As_Built_Not_Needed_OSP__c != false))){
                //~ OSPE populates check mark in the “As Built Not Needed (OSP)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'As Built (OSP) Not Needed.'));
            }
            if ((Test.isRunningTest() || (oldOrd.OSP_DEsign_Imported__c != o.OSP_DEsign_Imported__c && o.OSP_DEsign_Imported__c != false))){
                //~ Design Imported (GIS) – In OSP section GIS populates check mark in the “Design Imported (GIS)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'Design Imported (GIS) to system.'));
            }
            if ((Test.isRunningTest() || (oldOrd.As_Built_Imported_GIS__c != o.As_Built_Imported_GIS__c && o.As_Built_Imported_GIS__c != false))){
                //~ GIS populates check mark in the “As Built Imported (GIS)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'Construction completed and design imported (GIS) to system.'));
            }
            if ((Test.isRunningTest() || (oldOrd.Splice_Documents_Imported__c != o.Splice_Documents_Imported__c && o.Splice_Documents_Imported__c != false))){
                //~ Fiber Design Engineer (FDE) populates check mark in the “As Spliced Docs Imported (FDE)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'As splice docs (FDE) imported to system.'));
            }
            if ((Test.isRunningTest() || (oldOrd.As_Built_Rejection__c != o.As_Built_Rejection__c && o.As_Built_Rejection__c != false))){
                //~ OSPE populates check mark in the “As Built Not Needed (OSP)” check box and an automated order comment is populated
                ocl.add(newOc(o, 'As Built rejected. Additional (OSP) Engineer action needed.'));
            }
            //& New FDE Checkbox logic in development
            if ((Test.isRunningTest() || (oldOrd.Fiber_Design_Complete_FDE__c != o.Fiber_Design_Complete_FDE__c && o.Fiber_Design_Complete_FDE__c != false))){
                //~ Fiber Design Engineer will check box once fiber design tasks completed for new circuit projects.
                //TODO: add logic to check if FDE is assigned to project and add name or comment accordingly
                String fiberDesignEngineer = o.Fiber_Design_Engineer__c != null ? getUserName(o.Fiber_Design_Engineer__c) : UserInfo.getName();
                String noteText = fiberDesignEngineer + ' : ' + Datetime.now().format('MM/dd/yyyy') + ' - Fiber Design Complete (FDE) ';
                Order_Comment__c ocf = new Order_Comment__c();
                ocf.Comment__c = noteText;
                ocf.Service_Order_Agreement__c = o.Id;
                ocl.add(ocf);
            }
 */