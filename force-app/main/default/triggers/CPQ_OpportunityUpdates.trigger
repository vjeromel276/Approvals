trigger CPQ_OpportunityUpdates on Opportunity (before insert, before update) {
    SBQQ.TriggerControl.disable();
    
    List<Pricebook2> pb = [SELECT ID FROM Pricebook2 WHERE Name = 'Everstream' LIMIT 1]; //doesn't need a map

    
    List<ID> acctPL = new List<ID>();
    List<ID> oppyPL = new List<ID>();
    List<ID> agentPL = new List<ID>();
    for(Opportunity o: Trigger.New) {
        if(o.AccountID != NULL) {acctPL.add(o.AccountId);}
        oppyPL.add(o.ID);
        if(o.Referring_Vendor_Agent__c != NULL) {agentPL.add(o.Referring_Vendor_Agent__c);}
    }


    Account[] acnt = [SELECT Id, Contact_Count__c FROM Account WHERE ID IN :acctPL];
    List<Contact> contacts = [SELECT Id,AccountId FROM Contact WHERE AccountId IN :acctPL];
    List<SBQQ__Quote__c> relatedQuotes = [SELECT ID, SBQQ__Opportunity2__c FROM SBQQ__Quote__c  WHERE SBQQ__Opportunity2__c IN :oppyPL AND SBQQ__Opportunity2__c != NULL];
    List<Order> sof = [SELECT Id, OpportunityId FROM Order WHERE OpportunityId IN :oppyPL];
    List<Agent__c> a = [SELECT ID, Residual_Planned__c, Upfront_Planned__c FROM Agent__c WHERE ID IN :agentPL];
    List<Contract> applicableMSAContracts = [SELECT Id, ContractNumber, Contract_Record_Type_Ref__c, AccountId, Status 
            FROM Contract 
            WHERE Status = 'Activated' 
            AND Contract_Record_Type_Ref__c LIKE '%MSA%' 
            AND AccountId IN :acctPL];

    
    Map<ID, Account> accountMap = new Map<ID, Account>();
    for (Account a: acnt) {
        if(accountMap.get(a.Id) == NULL) {
            accountMap.put(a.Id, a);
        }
    }
    Map<ID, List<Contact>> acctToContactMap = new Map<ID, List<Contact>>();
    for(Contact c: contacts) {
        if(acctToContactMap.get(c.AccountId) == NULL) {
            acctToContactMap.put(c.AccountId, new List<Contact>());
        }
        acctToContactMap.get(c.AccountId).add(c);
    }
    Map<ID, List<SBQQ__Quote__c>> oppyToQuoteMap = new Map<ID, List<SBQQ__Quote__c>>();
    for(SBQQ__Quote__c q: relatedQuotes) {
        if(oppyToQuoteMap.get(q.SBQQ__Opportunity2__c) == NULL) {
            oppyToQuoteMap.put(q.SBQQ__Opportunity2__c, new List<SBQQ__Quote__c>());
        }
        oppyToQuoteMap.get(q.SBQQ__Opportunity2__c).add(q);
    }
    Map<ID, List<Order>> oppyToOrderMap = new Map<ID, List<Order>>();
    for(Order o: sof) {
        if(oppyToOrderMap.get(o.OpportunityId) == NULL) {
            oppyToOrderMap.put(o.OpportunityId, new List<Order>());
        }
        oppyToOrderMap.get(o.OpportunityId).add(o);
    }
    Map<ID, Contract> acctToContractMap = new Map<ID, Contract>();
    for(Contract c: applicableMSAContracts) {
        if(acctToContractMap.get(c.AccountId) == NULL || c.ContractNumber > acctToContractMap.get(c.AccountId).ContractNumber) {
            acctToContractMap.put(c.AccountId, c); 
        }
    }
    Map<ID, Agent__c> agentMap = new Map<ID, Agent__c>();
    for(Agent__c agnt: a) {
        agentMap.put(agnt.ID, agnt);
    }

    Set<SBQQ__Quote__c> quoteUpdates = new Set<SBQQ__Quote__c>();
    Set<Account> accountUpdates = new Set<Account>();


    for(Opportunity o: Trigger.New) {
        if (Disabled_Triggers__c.getValues('CPQ_OpportunityUpdates') == null || Disabled_Triggers__c.getValues('CPQ_OpportunityUpdates').Disabled__c == false) {
            if (!checkRecursiveTrigger.setOfObjectIdStrings.contains('Disable_CPQ_OpportunityUpdates')) {
                if (!checkRecursiveTrigger.setOfObjectIds.contains(o.Id)) {
                    checkRecursiveTrigger.setOfObjectIds.add(o.Id);
                    
                    if (Trigger.isInsert && o.SBQQ__Ordered__c) {
                        o.SBQQ__Ordered__c = FALSE;
                    }
                    
                    if (o.Amount != NULL && o.Amount > 0 && (o.HIDDEN_COUNT_OPP_PRODUCTS__c == NULL || o.HIDDEN_COUNT_OPP_PRODUCTS__c == 0)) {
                        o.Amount = 0;
                        o.StageName = 'Opportunity Identified';
                    }
                    
                    if (o.Sales_Agent_Notes__c != null && o.Sales_Agent_Notes__c.length() > 0) {
                        String abbrNotes = o.Sales_Agent_Notes__c.left(240);
                        if (o.Sales_Agent_Notes__c.length() > 240) {
                            abbrNotes = abbrNotes + ' | MORE ON OPP';
                        }
                        if (o.Sales_Agent_Notes_240__c == NULL || !o.Sales_Agent_Notes_240__c.equals(abbrNotes)) {
                            o.Sales_Agent_Notes_240__c = abbrNotes;
                        }
                    }
                    
                    //Find an applicable contract and apply it if one is missing
                    if (o.Related_New_MSA_Contract__c == null) {
                        /*
                        List<Contract> applicableMSAContracts = [SELECT Id, ContractNumber, Contract_Record_Type_Ref__c, AccountId 
                                                                 FROM Contract 
                                                                 WHERE Status = 'Activated' 
                                                                 AND Contract_Record_Type_Ref__c LIKE '%MSA%' 
                                                                 AND AccountId = :o.AccountId 
                                                                 ORDER BY ContractNumber DESC LIMIT 1];
                        */
                        if (acctToContractMap.get(o.AccountID) != null) {
                            o.Related_New_MSA_Contract__c = acctToContractMap.get(o.AccountID).Id;
                        }
                    }

                    if (!o.SBQQ__Ordered__c && o.Ordered_Custom__c) {
                        CPQ_OpportunityOrdered.markOppyOrderedFuture(o.Id);
                    }
                    
                    if (!o.SBQQ__Ordered__c) {//If it has not been ordered yet, continue.
                        
                        if (pb != null && pb.size() > 0) {
                            if (o.Pricebook2Id == null) {
                                o.Pricebook2Id = pb[0].Id;
                            }
                        }
                        
                        //Record the number of contacts on the account. Doing this because contacts will be required to generate a quote. Only do this if null or not correct to save an uncessessary update.
                        //Account[] acnt = [SELECT Id FROM Account WHERE ID = :o.AccountId];
                        //List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :o.AccountId];
                        if (accountMap.get(o.AccountId) != null && acctToContactMap.get(o.AccountId) != null && 
                                (accountMap.get(o.AccountId).Contact_Count__c == null || accountMap.get(o.AccountId).Contact_Count__c != acctToContactMap.get(o.AccountId).size())) {
                            accountMap.get(o.AccountId).Contact_Count__c = acctToContactMap.get(o.AccountId).size();
                            
                            checkRecursiveTrigger.setOfObjectIds.add(accountMap.get(o.AccountId).Id);
                            //update accountMap.get(o.AccountId);
                            accountUpdates.add(accountMap.get(o.AccountId));
                        }
                        
                        //List<SBQQ__Quote__c> relatedQuotes = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :o.ID AND SBQQ__Opportunity2__c != NULL];
                        
                        //If no SOFs exist for the quote and it's marked as sold, generate them.
                        //List<Order> sof = [SELECT Id FROM Order WHERE OpportunityId = :o.Id];
                        
                        if (o.StageName != NULL && o.StageName.contains('Sold') && (oppyToOrderMap.get(o.Id) == null || oppyToOrderMap.get(o.Id).size() == 0)) {
                            if (o.SBQQ__PrimaryQuote__c != null) {
                                if (o.Quote_Status_Text__c.equals('Approved') || o.Quote_Status_Text__c.equals('Complete')) {
                                    if (o.Primary_Quote_Customer_Signed__c) {
                                        if (o.DateTime_Stamp_SOLD_Status__c == null) {
                                            o.DateTime_Stamp_SOLD_Status__c = System.Today();
                                            o.CloseDate = System.today();
                                        }
                                    } else {
                                        //o.addError('The primary quote indicates that it has not been signed by the customer.');
                                    }
                                } else {
                                    //o.addError('The primary quote has not been approved so the order cannot be generated.');
                                }
                            } else {
                                //o.addError('There is no primary quote on the opportunity.');
                            }
                        } else {//Only run the last part if it's not attempting to create and order or if it's already ordered...
                            if (oppyToQuoteMap.get(o.ID) != null && oppyToQuoteMap.get(o.ID).size() > 0) {
                                if (o.LeadSource != null && (o.LeadSource.equals('Agent') || o.LeadSource.equals('Vendor Referral Program')) && o.Referring_Vendor_Agent__c != null) {
                                    //Agent__c a = [SELECT ID, Residual_Planned__c, Upfront_Planned__c FROM Agent__c WHERE ID = :o.Referring_Vendor_Agent__c LIMIT 1];
                                    for (SBQQ__Quote__c quote : oppyToQuoteMap.get(o.ID)) {
                                        quote.Agent__c = agentMap.get(o.Referring_Vendor_Agent__c).Id;
                                        quote.Agent_Residual_Perc__c = null;
                                        quote.Agent_Upfront__c = null;
                                        
                                        String residualString = agentMap.get(o.Referring_Vendor_Agent__c).Residual_Planned__c;
                                        if (residualString != null) {
                                            residualString = residualString.replaceAll('[^\\d.]', '');
                                        }
                                        String upfrontString = agentMap.get(o.Referring_Vendor_Agent__c).Upfront_Planned__c;
                                        if (upfrontString != null) {
                                            upfrontString = upfrontString.replaceAll('[^\\d.]', '');
                                        }
                                        
                                        Decimal residual;
                                        try {
                                            residual = Decimal.valueOf(residualString);
                                        } catch (Exception e) {
                                            residual = 0;
                                        }
                                        
                                        Decimal upfront;
                                        try {
                                            upfront = Decimal.valueOf(upfrontString);
                                        } catch (Exception e) {
                                            upfront = 0;
                                        }
                                        
                                        if (residual != null) {
                                            quote.Agent_Residual_Perc__c = residual;
                                        }
                                        if (upfront != null) {
                                            quote.Agent_Upfront__c = upfront;
                                        }
                                        
                                        checkRecursiveTrigger.setOfObjectIds.add(quote.Id);
                                    }
                                    
                                    //update oppyToQuoteMap.get(o.ID);
                                    quoteUpdates.addAll(oppyToQuoteMap.get(o.ID));
                                } else {
                                    for (SBQQ__Quote__c quote : oppyToQuoteMap.get(o.ID) ) {
                                        quote.Agent_Residual_Perc__c = null;
                                        quote.Agent_SPIF__c = null;
                                        quote.Agent_Upfront__c = null;
                                        
                                        checkRecursiveTrigger.setOfObjectIds.add(quote.Id);
                                    }
                                    
                                    //update oppyToQuoteMap.get(o.ID);
                                    quoteUpdates.addAll(oppyToQuoteMap.get(o.ID));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if(accountUpdates != NULL && accountUpdates.size() > 0) {update new List<Account>(accountUpdates);}
    if(quoteUpdates != NULL && quoteUpdates.size() > 0) {update new List<SBQQ__Quote__c>(quoteUpdates);}
    
    
    SBQQ.TriggerControl.enable();
}