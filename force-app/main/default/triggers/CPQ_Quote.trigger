/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @group             : 
 * @last modified on  : 05-05-2022
 * @last modified by  : clabelle@everstream.net
**/
trigger CPQ_Quote on SBQQ__Quote__c (before update, before insert, before delete) {
    System.debug('start - CPQ_Quote');
    if (Trigger.isDelete) {
        System.debug('delete - CPQ_Quote');
        for (SBQQ__Quote__c q : Trigger.old) {
            List<Sales_Cost_Estimate__c> incompleteEstimates = [SELECT Id, Status__c 
                                                                FROM Sales_Cost_Estimate__c 
                                                                WHERE CPQ_Quote__c = :q.Id];
            
            List<Sales_Cost_Estimate__c> deleteEstimates = new List<Sales_Cost_Estimate__c>();
            for (Sales_Cost_Estimate__c est : incompleteEstimates) {
                if (est.Status__c.equals('Not Started') || est.Status__c.equals('Information Requested') || est.Status__c.equals('Design Rejected')) {
                    deleteEstimates.add(est);
                }
            }
            
            if (deleteEstimates!= null && deleteEstimates.size() > 0) {
                Database.delete(deleteEstimates);
            }
        }
    } else {
        for (SBQQ__Quote__c newQuote : Trigger.new) {
            System.debug('checkRecursiveTrigger.setOfObjectIdStrings = '+checkRecursiveTrigger.setOfObjectIdStrings);
            if (!checkRecursiveTrigger.setOfObjectIds.contains(newQuote.Id) && !checkRecursiveTrigger.setOfObjectIdStrings.contains('bypass_CPQ_Quote')) {
                checkRecursiveTrigger.setOfObjectIds.add(newQuote.Id);
                System.debug('run update/insert - CPQ_Quote');
                
                SBQQ.TriggerControl.disable();
                Boolean primaryChanged = false;
                
                Opportunity[] opp = [SELECT ID, Referring_Vendor_Agent__c, AccountId, OwnerId, StageName, SBQQ__PrimaryQuote__c, DateTime_Stamp_SOLD_Status__c FROM Opportunity WHERE ID = :newQuote.SBQQ__Opportunity2__c LIMIT 1];
                
                if (opp != null && opp.size() > 0) {
                    checkRecursiveTrigger.setOfObjectIds.add(opp[0].Id);
                }
                
                if (Trigger.isInsert) {
                    if (newQuote.isClone()) {
                        newQuote.SBQQ__Status__c = 'Created';
                        newQuote.Approval_Not_Required__c = false;
                        newQuote.ApprovalStatus__c = NULL;
                        newQuote.SubmittedDate__c = NULL;
                        newQuote.SubmittedUser__c = NULL;
                        newQuote.Customer_Signed_Quote__c = false;
                    }
                    
                    newQuote.SBQQ__WatermarkShown__c = true;
                    newQuote.SBQQ__Primary__c = true;
                    
                    opp[0].SBQQ__PrimaryQuote__c = newQuote.Id;
                    update opp[0];
                    
                    if (opp[0] != null && opp[0].Referring_Vendor_Agent__c != null) {
                        newQuote.SBQQ__Account__c = opp[0].AccountId;
                        newQuote.SBQQ__SalesRep__c = opp[0].OwnerId;
                        
                        Agent__c a = [SELECT ID, Residual_Planned__c, SPIF_Planned__c, Upfront_Planned__c FROM Agent__c WHERE ID = :opp[0].Referring_Vendor_Agent__c LIMIT 1];
                        
                        if (a != null) {
                            String residualString = a.Residual_Planned__c;
                            String upfrontString = a.Upfront_Planned__c;
                            
                            Decimal residual;
                            try {
                                residualString = residualString.replaceAll('[^\\d.]', '');
                                residual = Decimal.valueOf(residualString);
                            } catch (Exception e) {
                                residual = 0;
                            }
                            
                            Decimal upfront;
                            try {
                                upfrontString = upfrontString.replaceAll('[^\\d.]', '');
                                upfront = Decimal.valueOf(upfrontString);
                            } catch (Exception e) {
                                upfront = 0;
                            }
                            
                            if (residual != null) {
                                newQuote.Agent_Residual_Perc__c = residual;
                            }
                            if (upfront != null) {
                                newQuote.Agent_Upfront__c = upfront;
                            }
                            
                            newQuote.Agent__c = a.Id;
                        }
                    }
                } else { //update
                    newQuote.SBQQ__OrderByQuoteLineGroup__c = true;
                    
                    SBQQ__Quote__c oldQuote = Trigger.oldMap.get(newQuote.Id);
                    String subTerm = newQuote.Term__c;
                    String oldSubTerm = oldQuote.Term__c;
                    
                    if (newQuote.SBQQ__Opportunity2__c != null && newQuote.SBQQ__Primary__c) {
                        //update primary quote on the opportunity
                        boolean updateOpp = true;//false;
                        
                        if (opp[0] != null && opp.size() > 0) {
                            if (opp[0].SBQQ__PrimaryQuote__c == null || !opp[0].SBQQ__PrimaryQuote__c.equals(newQuote.Id)) {
                                opp[0].SBQQ__PrimaryQuote__c = newQuote.Id;
                                
                                primaryChanged = true;
                                updateOpp = true;
                            }
                            if (opp[0].StageName.equals('Opportunity Identified')) {
                                opp[0].StageName = 'In Progress';
                                updateOpp = true;
                            }
                            
                            if (updateOpp) {
                                update opp[0];
                            }
                        }
                    }
                    
                    System.debug('newQuote.Term__c=' + newQuote.Term__c);
                    System.debug('newQuote.ROI__c=' + newQuote.ROI__c);
                    System.debug('subTerm=' + subTerm);
                    System.debug('oldSubTerm=' + oldSubTerm);
                    
                    if (newQuote.Term__c != null) {
                        if (!subTerm.equals(oldSubTerm) || newQuote.ROI__c == null) {//Term Changed
                            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Term__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :newQuote.Id];
                            List<SBQQ__QuoteLine__c> updatequoteLines = new List<SBQQ__QuoteLine__c>();
                            for (SBQQ__QuoteLine__c ql : quoteLines) {
                                checkRecursiveTrigger.setOfObjectIds.add(ql.Id);
                                if (ql.Term__c != newQuote.Term__c) {
                                    ql.Term__c = newQuote.Term__c;
                                    updatequoteLines.add(ql);
                                }
                            }
                            
                            if (updatequoteLines != NULL && updatequoteLines.size() > 0) {
                                update updatequoteLines;
                            }
                            
                            Integer subTermInt = 1;
                            
                            try {subTermInt = Integer.valueOf(subTerm);} catch (Exception e) {}
                            
                            System.debug('newQuote.Numerical_Term__c=' + newQuote.Numerical_Term__c);
                            System.debug('before update - newQuote.ROI__c=' + newQuote.ROI__c);
                            
                            ROI__c [] roi = [SELECT ID, Sales_Rep_ROI__c,Term__c,Term_Numerical_Value__c FROM ROI__c WHERE Term_Numerical_Value__c <= :newQuote.Numerical_Term__c ORDER BY Term_Numerical_Value__c DESC LIMIT 1];
                            if (roi.size() > 0) {
                                newQuote.ROI__c = roi[0].Id;
                            }
                            
                            System.debug('after update - newQuote.ROI__c=' + newQuote.ROI__c);
                        }
                    }
                    
                    if (newQuote.ApprovalStatus__c != null && newQuote.ApprovalStatus__c.equals('Pending') && !newQuote.SBQQ__Status__c.equals('Pending Approval')) {
                        newQuote.SBQQ__Status__c = 'Pending Approval';
                    }
                    
                    if (newQuote.ApprovalStatus__c != null && newQuote.ApprovalStatus__c.equals('Approved') && !newQuote.SBQQ__Status__c.equals('Approved')) {
                        newQuote.SBQQ__Status__c = 'Approved';
                    }
                    
                    if (!newQuote.Approval_Will_Be_Required__c && newQuote.SBQQ__Status__c.equals('Approved') && (newQuote.ApprovalStatus__c == null || !newQuote.ApprovalStatus__c.equals('Approved'))) {
                        newQuote.Approval_Not_Required__c = true;
                        newQuote.ApprovalStatus__c = 'Approved';
                        newQuote.SubmittedDate__c = System.today();
                        newQuote.SubmittedUser__c = UserInfo.getUserId();
                    }
                    
                    if (!newQuote.SBQQ__Status__c.equals('Pending Approval') && !newQuote.SBQQ__Status__c.equals('Approved')) {
                        newQuote.ApprovalStatus__c = NULL;
                        newQuote.SubmittedDate__c = NULL;
                        newQuote.SubmittedUser__c = NULL;
                    }
                    
                    if (!oldQuote.SBQQ__Status__c.equals('Pending Approval') && newQuote.SBQQ__Status__c.equals('Pending Approval')) {
                        List<Sales_Cost_Estimate__c> allEstimates = [SELECT Id, Status__c FROM Sales_Cost_Estimate__c WHERE CPQ_Quote__c = :newQuote.Id];
                        Integer totalEstimates = 0;
                        Integer completeEstimates = 0;
                        
                        if (allEstimates != null && allEstimates.size() > 0) {
                            totalEstimates = allEstimates.size();
                            for (Sales_Cost_Estimate__c tempEst : allEstimates) {
                                if (tempEst.Status__c.equals('Complete')) {
                                    completeEstimates++;
                                }
                            }
                        }
                        
                        if (!Test.isRunningTest() && (totalEstimates == 0 || totalEstimates != completeEstimates)) {
                            newQuote.addError('The cost estimates are not complete. You cannot approve this quote without estimates!');
                        }
                    }
                    
                    if (newQuote.SBQQ__Status__c.equals('Cost Pending') && newQuote.SBQQ__LineItemCount__c == 0) {
                        newQuote.addError('You must have locations and products in order to generate a cost estimate.');
                    } else if (newQuote.SBQQ__Status__c.equals('Cost Pending') && !oldQuote.SBQQ__Status__c.equals('Cost Pending')) {
                        //run secondary method to generate the necessary cost estimates (if required)
                        CPQ_QuoteEstimateCreation.createQuoteEstimates(newQuote);
                    } else if (newQuote.SBQQ__Status__c.equals('Approved') && !oldQuote.SBQQ__Status__c.equals('Approved')) {
                        List<Sales_Cost_Estimate__c> allEstimates = [SELECT Id, Status__c FROM Sales_Cost_Estimate__c WHERE CPQ_Quote__c = :newQuote.Id AND CPQ_Quote_Line_Group__c != NULL];
                        Integer totalEstimates = 0;
                        Integer completeEstimates = 0;
                        
                        if (allEstimates != null && allEstimates.size() > 0) {
                            totalEstimates = allEstimates.size();
                            for (Sales_Cost_Estimate__c tempEst : allEstimates) {
                                if (tempEst.Status__c.equals('Complete')) {
                                    completeEstimates++;
                                }
                            }
                        }
                        
                        if (!Test.isRunningTest() && (totalEstimates == 0 || totalEstimates != completeEstimates)) {
                            newQuote.addError('The cost estimates are not complete. You cannot approve this quote without estimates!');
                        }
                        
                        if (newQuote.SBQQ__ExpirationDate__c == null || newQuote.SBQQ__ExpirationDate__c < date.today()) {
                            newQuote.SBQQ__ExpirationDate__c = date.today().addDays(30);
                        }
                        
                        boolean updateOpp = true;//false;
                        
                        if (opp != null && opp.size() > 0) {
                            if (opp[0].StageName == NULL || opp[0].StageName.equals('Opportunity Identified') || opp[0].StageName.equals('In Progress')) {
                                opp[0].StageName = 'Quote Presented';
                                updateOpp = true;
                            }
                            
                            if (updateOpp) {
                                update opp[0];
                            }
                        }
                    }
                    
                    if (newQuote.SBQQ__Status__c.equals('Approved') && newQuote.Customer_Signed_Quote__c) {
                        if (!opp[0].StageName.contains('Sold') && !opp[0].StageName.contains('Closed')) {
                            if (opp[0].SBQQ__PrimaryQuote__c == NULL || !opp[0].SBQQ__PrimaryQuote__c.equals(newQuote.Id)) {
                                newQuote.SBQQ__Primary__c = true;
                                opp[0].SBQQ__PrimaryQuote__c = newQuote.Id;
                                update opp[0];
                            }

                            //only update the Close Date and the Sold timestamp if they haven't been set already
                            if(opp[0].DateTime_Stamp_SOLD_Status__c == NULL) { 
                              opp[0].DateTime_Stamp_SOLD_Status__c = System.today();
                              opp[0].CloseDate = System.today();
                              opp[0].StageName = 'Sold: SOF Requires Activation';

                              update opp[0];
                            }
                        }
                        
                        if (!System.isFuture()) {
                            CPQ_Quotes.copyPdfCommentsFromQuoteToOrder(newQuote.Id);
                        }
                    }
                    
                    if (oldQuote.SBQQ__Status__c.equals('Waiting for Information') && newQuote.SBQQ__Status__c.equals('Cost Pending')) {
                        List<Sales_Cost_Estimate__c> sces = [SELECT ID, Status__c FROM Sales_Cost_Estimate__c WHERE CPQ_Quote__c = :newQuote.Id AND Status__c = 'Information Requested'];
                        if (sces != null && sces.size() > 0) {
                            for (Sales_Cost_Estimate__c sce : sces) {
                                sce.Status__c = 'Engineering Design';
                                
                                checkRecursiveTrigger.setOfObjectIds.add(sce.Id);
                            }
                            
                            update sces;
                        }
                    }
                }
                
                //Fill in the billing account if only one exists. If none exist, OSS will create one automatically. If more than one exists, the user will have to select.
                if (newQuote.Account_Active_Billing_Account_Count__c == 1 && newQuote.SBQQ__Account__c != NULL && newQuote.Billing_Account__c == NULL) {
                    Billing_Invoice__c[] bi = [SELECT Id FROM Billing_Invoice__c WHERE Account__c = :newQuote.SBQQ__Account__c AND Disabled__c = FALSE LIMIT 1];
                    
                    if (bi != NULL && bi.size() > 0) {
                        newQuote.Billing_Account__c = bi[0].Id;
                    }
                } else if (newQuote.Account_Active_Billing_Account_Count__c == 0 && newQuote.SBQQ__Account__c != NULL && newQuote.Billing_Account__c == NULL) {
                    newQuote.Create_New_Billing_Account_When_Sold__c = TRUE;
                }
                
                if (primaryChanged && !System.isFuture() && !System.isBatch()) {
                    CPQ_UpdateQuoteCostInfoFromSCE.updateCostsFuture(newQuote.Id, null, null, false);
                }
                SBQQ.TriggerControl.enable();
            }
        }
    }
}