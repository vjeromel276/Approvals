/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @group             : 
 * @last modified on  : 12-09-2022
 * @last modified by  : clabelle@everstream.net
**/
trigger CPQ_QuoteLineGroup on SBQQ__QuoteLineGroup__c (before insert, before update, before delete) {
    System.debug('start - CPQ_QuoteLineGroup');
    if (Trigger.isDelete) {
        System.debug('delete - CPQ_QuoteLineGroup');
        for (SBQQ__QuoteLineGroup__c qlg : Trigger.old) {
            List<Sales_Cost_Estimate__c> incompleteEstimates = [SELECT Id, Status__c 
                                                                FROM Sales_Cost_Estimate__c 
                                                                WHERE ((CPQ_Quote__c = :qlg.SBQQ__Quote__c AND CPQ_Quote_Line_Group__c = NULL) 
                                                                OR (CPQ_Quote_Line_Group__c = :qlg.Id))];
            
            List<Sales_Cost_Estimate__c> deleteEstimates = new List<Sales_Cost_Estimate__c>();
            for (Sales_Cost_Estimate__c est : incompleteEstimates) {
                if (est.Status__c.equals('Not Started') || est.Status__c.equals('Information Requested') || est.Status__c.equals('Design Rejected')) {
                    deleteEstimates.add(est);
                }
            }
            
            if (deleteEstimates!= null && deleteEstimates.size() > 0) {
                Database.delete(deleteEstimates);
            }
            
            if (deleteEstimates != null && incompleteEstimates != null && incompleteEstimates.size() == deleteEstimates.size()) {
                checkRecursiveTrigger.setOfObjectIds.add(qlg.SBQQ__Quote__c);
                SBQQ__QuoteLine__c[] lines = [SELECT ID FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :qlg.SBQQ__Quote__c];
                
                if (lines == null || lines.size() == 0) {
                    Database.update(new SBQQ__Quote__c(Id = qlg.SBQQ__Quote__c, SBQQ__LineItemsGrouped__c = false));
                }
            }
        }
    } else {
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> quoteLineGroupIds = new Set<Id>();
        Set<Id> addressIds = new Set<Id>();

        for (SBQQ__QuoteLineGroup__c qlg : Trigger.new) {
            quoteIds.add(qlg.SBQQ__Quote__c);
            quoteLineGroupIds.add(qlg.Id);
            addressIds.add(qlg.Address_A__c);
            addressIds.add(qlg.Address_Z__c);
        }

        Map<Id, SBQQ__Quote__c> quoteRecords = NULL;
        Map<Id, SBQQ__QuoteLine__c> quoteLineRecords = NULL;
        Map<Id, Address__c> addressRecords = NULL;

        if (quoteIds != NULL && quoteIds.size() > 0) {
            quoteRecords = new Map<ID, SBQQ__Quote__c>([SELECT ID, Dimension_4_Market_from_First_Location__c, ROI__c, ROI__r.Director_ROI__c, ROI__r.Sales_Rep_ROI__c, ROI__r.VP_ROI__c FROM SBQQ__Quote__c WHERE ID IN :quoteIds]);
        }

        if (addressIds != NULL && addressIds.size() > 0) {
            addressRecords = new Map<ID, Address__c>([SELECT ID, Output_Document_Address__c, Output_Document_Address_Without_Headend__c, Address__c FROM Address__c WHERE ID IN :addressIds]);
        }

        if (quoteLineGroupIds != NULL && quoteLineGroupIds.size() > 0) {
            quoteLineRecords = new Map<ID, SBQQ__QuoteLine__c>([SELECT ID, SBQQ__Number__c, SBQQ__ProductFamily__c, SBQQ__Group__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Group__c IN :quoteLineGroupIds ORDER BY SBQQ__Number__c ASC]);
        }
        
        for (SBQQ__QuoteLineGroup__c qlg : Trigger.new) {
            if (!checkRecursiveTrigger.setOfObjectIds.contains(qlg.Id) && !checkRecursiveTrigger.setOfObjectIdStrings.contains('bypass_CPQ_QuoteLineGroup')) {
                checkRecursiveTrigger.setOfObjectIds.add(qlg.Id);
                System.debug('run update/insert - CPQ_QuoteLineGroup');
                
                if (qlg.SBQQ__Source__c != null && (qlg.CreatedDate == null || (System.now().getTime()-qlg.CreatedDate.getTime())/1000 <= 7)) {
                    System.debug('Block Trigger for Initial Cloning.');
                } else {
                    SBQQ.TriggerControl.disable();
                    
                    System.debug('qlg.ROI_Payback_Months__c=' + qlg.ROI_Payback_Months__c);
                    
                    if (qlg.Id != NULL && qlg.SBQQ__Description__c != NULL) {
                        SBQQ__QuoteLineGroup__c oldGroup = Trigger.oldMap.get(qlg.ID);
                        if (oldGroup != NULL) {
                            if ((oldGroup.Address_A__c != qlg.Address_A__c) || (oldGroup.Address_Z__c != qlg.Address_Z__c)) {
                                qlg.SBQQ__Description__c = NULL;
                            }
                        }
                    }

                    if (qlg.Data_Load_Source__c != NULL && qlg.Data_Load_Source__c.equals('Neustar')) {
                        if (qlg.Selected_Headend_Type__c == NULL && qlg.Address_A__c != NULL && qlg.Address_A__c.equals('aD84P000000XfNCSA0')) {
                            qlg.Selected_Headend_Type__c = 'Internet';
                            qlg.SBQQ__Description__c = NULL;
                        } else {
                            qlg.Selected_Headend_Type__c = 'NNI';
                            qlg.SBQQ__Description__c = NULL;
                        }
                    }

                    if (qlg.SBQQ__Description__c == NULL || qlg.Name == NULL || qlg.Name.startsWith('aCP')) {
                        Address__c addrA = NULL;
                        Address__c addrZ = NULL;
                        System.debug('addressRecords = ' + addressRecords);

                        if (addressRecords != null && addressRecords.size() > 0) {
                            for (Address__c a : addressRecords.values()) {
                                if (qlg.Address_A__c == a.Id) {
                                    addrA = a;
                                }
                                
                                if (qlg.Address_Z__c == a.Id) {
                                    addrZ = a;
                                }

                                System.debug(a.Id + ' -- ' + qlg.Address_A__c);
                                System.debug(a.Id + ' -- ' + qlg.Address_Z__c);
                            }
                            
                            if (addrA != NULL && addrZ != NULL) {
                                if (qlg.Selected_Headend_Type__c != null && (qlg.Selected_Headend_Type__c.contains('NNI') || qlg.Selected_Headend_Type__c.contains('Internet') || qlg.Selected_Headend_Type__c.contains('Voice'))) {
                                    qlg.SBQQ__Description__c = '<div>A Location: ' + addrA.Output_Document_Address__c + '<br/>Z Location: ' + addrZ.Output_Document_Address_Without_Headend__c + '</div>';
                                } else {
                                    qlg.SBQQ__Description__c = '<div>A Location: ' + addrA.Output_Document_Address_Without_Headend__c + '<br/>Z Location: ' + addrZ.Output_Document_Address_Without_Headend__c + '</div>';
                                }

                                if (qlg.Name == NULL || qlg.Name.startsWith('aCP')) {
                                    qlg.Name = addrZ.Address__c;
                                }
                            } else {
                                qlg.SBQQ__Description__c = NULL;
                            }
                        } else {
                            qlg.SBQQ__Description__c = NULL;
                        }
                    }

                    if (Trigger.isUpdate) {
                        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
                        if (quoteLineRecords != NULL && quoteLineRecords.size() > 0) {
                            for (SBQQ__QuoteLine__c l : quoteLineRecords.values()) {
                                if (l.SBQQ__Group__c.equals(qlg.Id)) {
                                    lines.add(l);
                                }
                            }
                        }
                        
                        if (lines != NULL && lines.size() > 0) {
                            qlg.First_Line_in_Group__c = lines.get(0).SBQQ__Number__c;
                            qlg.Group_Product_Family__c = lines.get(0).SBQQ__ProductFamily__c;
                            qlg.Group_Has_Multiple_Product_Families__c = FALSE;
                            
                            for (SBQQ__QuoteLine__c l : lines) {
                                if (l.SBQQ__ProductFamily__c != NULL && l.SBQQ__ProductFamily__c != qlg.Group_Product_Family__c) {
                                    qlg.Group_Has_Multiple_Product_Families__c = TRUE;
                                }
                            }
                        }
                    }
                    
                    SBQQ__Quote__c quote = quoteRecords.get(qlg.SBQQ__Quote__c);

                    if (quote != null && quote.Dimension_4_Market_from_First_Location__c == NULL && qlg.Dimension_4_From_Address_Z__c != NULL) {
                        checkRecursiveTrigger.setOfObjectIds.add(quote.Id);
                        quote.Dimension_4_Market_from_First_Location__c = qlg.Dimension_4_From_Address_Z__c;
                        update quote;
                    }

                    if (quote != null && quote.ROI__c != null && 
                        quote.ROI__r.Director_ROI__c != null && 
                        quote.ROI__r.Sales_Rep_ROI__c != null) {
                            
                        System.debug('qlg.ROI_Payback_Months__c=' + qlg.ROI_Payback_Months__c);
                        System.debug('quote[0].ROI__r.Sales_Rep_ROI__c=' + quote.ROI__r.Sales_Rep_ROI__c);
                        System.debug('quote[0].ROI__r.Director_ROI__c=' + quote.ROI__r.Director_ROI__c);
                        
                        System.debug('qlg.ROI_Payback_Months__c > quote[0].ROI__r.Sales_Rep_ROI__c='+String.valueOf(qlg.ROI_Payback_Months__c > quote.ROI__r.Sales_Rep_ROI__c));
                        System.debug('qlg.ROI_Payback_Months__c > quote[0].ROI__r.Director_ROI__c='+String.valueOf(qlg.ROI_Payback_Months__c > quote.ROI__r.Director_ROI__c));
                        
                        if (qlg.ROI_Payback_Months__c > quote.ROI__r.Sales_Rep_ROI__c) {
                            qlg.Requires_Director_ROI_Approval__c = 1; } else { qlg.Requires_Director_ROI_Approval__c = 0;
                        }
                        
                        if (qlg.ROI_Payback_Months__c > quote.ROI__r.Director_ROI__c) {
                            qlg.Requires_VP_ROI_Approval__c = 1; } else { qlg.Requires_VP_ROI_Approval__c = 0;
                        }
                        
                        if (qlg.ROI_Payback_Months__c > quote.ROI__r.VP_ROI__c) {
                            qlg.Requires_CRO_ROI_Approval__c = 1; } else { qlg.Requires_CRO_ROI_Approval__c = 0;
                        }
                    } else {
                        qlg.Requires_Director_ROI_Approval__c = 1;  qlg.Requires_VP_ROI_Approval__c = 1;    qlg.Requires_CRO_ROI_Approval__c = 1;
                    }
                    
                    SBQQ.TriggerControl.enable();
                }
            }
        }
    }
}