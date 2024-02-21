trigger OSPTaskNoteTrigger on Order(before update ){
   /* Set<Id> userIds = new Set<Id>();
    Set<Id> contractorIds = new Set<Id>();

    for (Order oldOrder : Trigger.old){
        Order newOrder = Trigger.newMap.get(oldOrder.Id);
        userIds.add(newOrder.OSP_Engineer__c);
        userIds.add(newOrder.Fiber_Design_Engineer__c);
        contractorIds.add(newOrder.Contractor__c);

        // Query Users and Contractors
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name
                                                   FROM User
                                                   WHERE Id IN:userIds]);

        Map<Id, MAINTENANCE_Construction_Vendor__c> contractorMap = new Map<Id, MAINTENANCE_Construction_Vendor__c>([SELECT Id, Name
                                                                                                                     FROM MAINTENANCE_Construction_Vendor__c
                                                                                                                     WHERE Id IN:contractorIds]);

        // Order newOrder = Trigger.newMap.get(oldOrder.Id);

        if (Disabled_Triggers__c.getValues('OSPTaskNoteTrigger') == null || Disabled_Triggers__c.getValues('OSPTaskNoteTrigger').Disabled__c == false){
            //*OSPTaskNOtes
            if (oldOrder != null){
                String lastComment = OSPTaskNote.createOSPTaskNote(newOrder, oldOrder, userMap, contractorMap);
                if (Test.isRunningTest() || lastComment != NULL){
                    newOrder.Last_Order_Comment__c = lastComment;
                    newOrder.Last_Order_Comment_Date__c = System.today();
                }
            }
        }
    }*/
}