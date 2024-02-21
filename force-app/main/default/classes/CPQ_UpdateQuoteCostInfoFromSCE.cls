/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @group             : 
 * @last modified on  : 03-28-2023
 * @last modified by  : clabelle@everstream.net
**/
global without sharing class CPQ_UpdateQuoteCostInfoFromSCE {
    public CPQ_UpdateQuoteCostInfoFromSCE() {
        
    }
    
    public static void updateCosts(Id qIn, Id qlgIn, Id sceIn, boolean updateQuote, boolean updateOppy) {
        updateCostsFuture(qIn, qlgIn, sceIn, updateQuote, updateOppy);
    }
    
    @Future
    public static void updateCostsFuture(Id qIn, Id qlgIn, Id sceIn, boolean updateQuote, boolean updateOppy) {
        Map<Id,SBQQ__QuoteLineGroup__c> quoteGroupMap = updateCostsRun(qIn, qlgIn, sceIn, updateQuote, updateOppy);

        if (quoteGroupMap != NULL && quoteGroupMap.size() > 0) {
            Integer MAX_ATTEMPTS = 3;
            Integer attempts = MAX_ATTEMPTS;
            while (attempts > 0) {
                try {
                    attempts--;
                    update quoteGroupMap.values();
                    attempts = 0;
                } catch (System.DmlException dmlEx) {
                    if (!dmlEx.getMessage().contains('UNABLE_TO_LOCK_ROW')) { 
                        attempts = 0;  // exit on any other exception
                        throw dmlEx;  // throw exception after MAX_ATTEMPTS
                    }
                }
            }
        }
    }

    public static void updateCosts(Id qIn, Id qlgIn, Id sceIn, boolean updateQuote) {//old, don't use
        updateCostsFuture(qIn, qlgIn, sceIn, updateQuote, true);
        
    }
     
    @Future
    public static void updateCostsFuture(Id qIn, Id qlgIn, Id sceIn, boolean updateQuote) {//old, don't use
        Map<Id,SBQQ__QuoteLineGroup__c> quoteGroupMap = updateCostsRun(qIn, qlgIn, sceIn, updateQuote, true);
        
        if (quoteGroupMap != NULL && quoteGroupMap.size() > 0) {
            Integer MAX_ATTEMPTS = 3;
            Integer attempts = MAX_ATTEMPTS;
            while (attempts > 0) {
                try {
                    attempts--;
                    update quoteGroupMap.values();
                    attempts = 0;
                } catch (System.DmlException dmlEx) {
                    if (!dmlEx.getMessage().contains('UNABLE_TO_LOCK_ROW')) { 
                        attempts = 0;  // exit on any other exception
                        throw dmlEx;  // throw exception after MAX_ATTEMPTS
                    }
                }
            }
        }
    }
    
    public static Map<Id,SBQQ__QuoteLineGroup__c> updateCostsRun(Id qIn, Id qlgIn, Id sceIn, boolean updateQuote, boolean updateOppy) {
        SBQQ__Quote__c[] qte;
        
        Map<Id,SBQQ__QuoteLineGroup__c> quoteGroupMap = null;
        SBQQ__QuoteLineGroup__c qlg;
        
        System.debug('CPQ_UpdateQuoteCostInfoFromSCE.updateCosts');
        
        checkRecursiveTrigger.setOfObjectIds.add(qIn);
        
        if (qlgIn != null) {
            checkRecursiveTrigger.setOfObjectIds.add(qlgIn);
        }
        
        qte = [SELECT Id, SBQQ__Status__c, SBQQ__Account__c, ROI__c, ROI__r.Sales_Rep_ROI__c, SBQQ__Opportunity2__c, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE ID = :qIn];
        
        if (qte != null && qte.size() > 0) {
            quoteGroupMap = new Map<Id,SBQQ__QuoteLineGroup__c>();

            if (qte[0].SBQQ__Account__c != null) {
                checkRecursiveTrigger.setOfObjectIds.add(qte[0].SBQQ__Account__c);
            }
            
            Opportunity opp = null;
            
            if (qte[0].SBQQ__Opportunity2__c != null) {
                opp = new Opportunity(Id = qte[0].SBQQ__Opportunity2__c);
            }
            
            List<Sales_Cost_Estimate__c> quoteCostEstimates = [SELECT Cost_Total_1C_Cost__c, Cost_Construction__c, Cost_Equipment__c, Estimate_Location__c, Early_Term_Fee_Reimbursement__c, 
                                                                     Quote_Vendor_Total_Cost__c, Quote_Vendor_MRC__c, Quote_Vendor_NRC__c, CPQ_Quote__c, CPQ_Quote__r.SBQQ__Primary__c, 
                                                                     OSP_Design_Comments__c, Sales_Cost_Engineering_Notes__c, Quote_Vendor_ID__c, CPQ_Quote_Line_Group__c,//replaced Notes_from_Sales_Engineering__c with Sales_Cost_Engineering_Notes__c
                                                                     Solutions_Engineer_Notes__c,
                                                                     Address_A__c, Address_Z__c
                                                                     FROM Sales_Cost_Estimate__c WHERE CPQ_Quote__c = :qte[0].Id
                                                                     AND Status__c = 'Complete' AND CPQ_Quote_Line_Group__c != NULL];
            
            Decimal constructionCost = 0;
            Decimal equipmentCost = 0;
            String aggregatedOSPComments = null;
            String aggregatedSolutionEngineerNotes = null;
            String aggregatedEngineeringNotes = null;
            List<String> ospCommentList = new List<String>();
            List<String> solutionEngineerNoteList = new List<String>();
            List<String> engCommentList = new List<String>();
            Set<String> uniqueCostSet = new Set<String>();
            
            
            if (quoteCostEstimates != null && quoteCostEstimates.size() > 0) {
                for (Sales_Cost_Estimate__c e : quoteCostEstimates) {
                    /*if (e.Cost_Construction__c != null && e.CPQ_Quote__r.SBQQ__Primary__c) {
                        constructionCost = constructionCost + e.Cost_Construction__c;
                    }
                    if (e.Cost_Equipment__c != null && e.CPQ_Quote__r.SBQQ__Primary__c) {
                        equipmentCost = equipmentCost + e.Cost_Equipment__c;
                    }*/
                    
                    if (quoteGroupMap.containsKey(e.CPQ_Quote_Line_Group__c)) {
                        //get existing group
                        qlg = quoteGroupMap.get(e.CPQ_Quote_Line_Group__c);
                    } else {
                        //create new group reference
                        qlg = new SBQQ__QuoteLineGroup__c(id = e.CPQ_Quote_Line_Group__c, On_Off_Net_Pricing__c = 'On Net', Unique_On_Net_Build_Cost__c = 0,
                                                          Off_Net_Total_Cost__c = 0, Off_Net_Vendor__c = NULL, Cost_Total_1C_Cost__c = 0, 
                                                          Vendor_MRC__c = 0, Vendor_NRC__c = 0, ROI_Payback_Months__c = qte[0].ROI__r.Sales_Rep_ROI__c,
                                                          Cost_Construction_Cost__c = 0, Cost_Equipment_Cost__c = 0, Early_Term_Fee_Reimbursement__c = 0);
                    }
                    
                    if (e.Cost_Total_1C_Cost__c != null) {
                        qlg.Cost_Total_1C_Cost__c = qlg.Cost_Total_1C_Cost__c + e.Cost_Total_1C_Cost__c;
                        
                        String uniqueCostString = NULL;
                        if (e.Address_A__c != NULL) {
                            uniqueCostString = e.Address_A__c;
                        } else {
                            uniqueCostString = e.Address_Z__c;
                        }
                        uniqueCostString = uniqueCostString + String.valueOf(e.Cost_Total_1C_Cost__c);
                        System.debug('uniqueCostString = ' + uniqueCostString);
                        
                        if (!uniqueCostSet.contains(uniqueCostString)) {
                            qlg.Unique_On_Net_Build_Cost__c = qlg.Unique_On_Net_Build_Cost__c + e.Cost_Total_1C_Cost__c;
                            uniqueCostSet.add(uniqueCostString);
                        }
                    }
                    if (e.Quote_Vendor_Total_Cost__c != null) {
                        qlg.Off_Net_Total_Cost__c = qlg.Off_Net_Total_Cost__c + e.Quote_Vendor_Total_Cost__c;
                    }
                    if (e.Quote_Vendor_MRC__c != null) {
                        qlg.Vendor_MRC__c = qlg.Vendor_MRC__c + e.Quote_Vendor_MRC__c;
                    }
                    if (e.Quote_Vendor_NRC__c != null) {
                        qlg.Vendor_NRC__c = qlg.Vendor_NRC__c + e.Quote_Vendor_NRC__c;
                    }

                    if (qlg.Cost_Construction_Cost__c == NULL) {
                        qlg.Cost_Construction_Cost__c = 0;
                    }
                    
                    if (qlg.Cost_Equipment_Cost__c == NULL) {
                        qlg.Cost_Equipment_Cost__c = 0;
                    }

                    if (qlg.Early_Term_Fee_Reimbursement__c == NULL) {
                        qlg.Early_Term_Fee_Reimbursement__c = 0;
                    }

                    qlg.Cost_Construction_Cost__c = qlg.Cost_Construction_Cost__c + e.Cost_Construction__c;
                    qlg.Cost_Equipment_Cost__c = qlg.Cost_Equipment_Cost__c + e.Cost_Equipment__c;

                    if (e.Early_Term_Fee_Reimbursement__c != NULL) {
                        qlg.Early_Term_Fee_Reimbursement__c = qlg.Early_Term_Fee_Reimbursement__c + e.Early_Term_Fee_Reimbursement__c;
                    }
                    
                    qlg.Off_Net_Vendor__c = e.Quote_Vendor_ID__c; //sets the off net vendor to the last one, which would be the z loc est if there are two.
                                                                  //When no vendor is selected, it sets to null, then the default of Everstream overrides later
                    
                    quoteGroupMap.put(e.CPQ_Quote_Line_Group__c, qlg);
                    
                    if (e.CPQ_Quote__r.SBQQ__Primary__c) {
                        if (e.OSP_Design_Comments__c != NULL) {
                            ospCommentList.add(e.OSP_Design_Comments__c);
                        }

                        if (e.Solutions_Engineer_Notes__c != NULL) {
                            solutionEngineerNoteList.add(e.Solutions_Engineer_Notes__c);
                        }

                        if (e.Sales_Cost_Engineering_Notes__c != NULL) {
                            //replaced Notes_from_Sales_Engineering__c with Sales_Cost_Engineering_Notes__c
                            engCommentList.add(e.Sales_Cost_Engineering_Notes__c);
                        }
                    }
                }
            }
            
            for (SBQQ__QuoteLineGroup__c g : quoteGroupMap.values()) {
                /*If there is no on net build cost, or it's below 3k, and the off net cost is present, set the quote group 
                to Off Net in order to keep sales from potentially screwing up a quote.*/
                if ((g.Cost_Total_1C_Cost__c == 0 || g.Cost_Total_1C_Cost__c < 3000) && g.Off_Net_Total_Cost__c > 0) {
                    g.On_Off_Net_Pricing__c = 'Off Net';
                    quoteGroupMap.put(g.id, g);
                }
            }
            
            if ((updateQuote == NULL || updateQuote) && qte[0].SBQQ__Status__c != 'Cost Returned' && !qte[0].SBQQ__Status__c.contains('Approv')) {
                qte[0].SBQQ__Status__c = 'Cost Returned';
                qte[0].Customer_Signed_Quote__c = FALSE;
                
                update qte[0];
            }
            
            if (opp != null && updateOppy) {
                Integer maxLengthLarge = 500;
                Integer maxLengthSmall = 255;

                /*   Combine all individual notes into one giant string.   */
                /*   Remove all HTML encoding from the massive string.   */
                /*   Truncate the string down to the size of the field it will go into.   */
                /*   Set the values from the massive strings into their respective fields.   */
                if (ospCommentList != null && ospCommentList.size() > 0) {
                    aggregatedOSPComments = String.join(ospCommentList, ' | ');
                    aggregatedOSPComments = aggregatedOSPComments.replaceAll('<[^>]+>','');
                    
                    if (aggregatedOSPComments.length() > maxLengthLarge) {
                        aggregatedOSPComments = aggregatedOSPComments.abbreviate(maxLengthLarge);
                    }

                    opp.OSP_Design_Comments__c = aggregatedOSPComments;
                }

                if (engCommentList != null && engCommentList.size() > 0) {
                    aggregatedEngineeringNotes = String.join(engCommentList, ' | ');
                    aggregatedEngineeringNotes = aggregatedEngineeringNotes.replaceAll('<[^>]+>','');

                    if (aggregatedEngineeringNotes.length() > maxLengthSmall) {
                        aggregatedEngineeringNotes = aggregatedEngineeringNotes.abbreviate(maxLengthSmall);
                    }

                    opp.Notes_from_Sales_Engineering__c = aggregatedEngineeringNotes;
                }

                if (solutionEngineerNoteList != null && solutionEngineerNoteList.size() > 0) {
                    aggregatedSolutionEngineerNotes = String.join(solutionEngineerNoteList, ' | ');
                    aggregatedSolutionEngineerNotes = aggregatedSolutionEngineerNotes.replaceAll('<[^>]+>','');

                    if (aggregatedSolutionEngineerNotes.length() > maxLengthLarge) {
                        aggregatedSolutionEngineerNotes = aggregatedSolutionEngineerNotes.abbreviate(maxLengthLarge);
                    }

                    opp.Solutions_Engineering_Notes__c = aggregatedSolutionEngineerNotes;
                }

                
                opp.Cost_Construction__c = constructionCost;
                opp.Cost_Equipment__c = equipmentCost;
                
                checkRecursiveTrigger.setOfObjectIds.add(opp.Id);
                update opp;
            }
        }

        return quoteGroupMap;
    }
}