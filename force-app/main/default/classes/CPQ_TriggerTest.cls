@isTest(seeAllData=true)
public class CPQ_TriggerTest {
    testMethod static void quoteTest() {
        Test.startTest();
        
        List<Account> accts = TestDataFactory.createAccountsWithOpps(1,1);
        Account act1 = accts.get(0);
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :act1.Id];
        
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuoteWithGroupsAndLines(act1.Id, opp.Id, 2,1,1);
        
        checkRecursiveTrigger.resetIds();
        SBQQ__Quote__c q1 = quotes.get(0);
        q1.SBQQ__Primary__c = true;
        update q1;
        
        checkRecursiveTrigger.resetIds();
        q1.SBQQ__Status__c = 'Cost Pending';
        update q1;
        
        checkRecursiveTrigger.resetIds();
        SBQQ__Quote__c q0 = quotes.get(0).clone(false,true,false,false);
        q0.SBQQ__Primary__c = false;
        insert q0;
        
        checkRecursiveTrigger.resetIds();
        q1.SBQQ__Status__c = 'Cost Returned';
        q1.ApprovalStatus__c = 'Pending';
        update q1;
        
        checkRecursiveTrigger.resetIds();
        q1.SBQQ__Status__c = 'Pending Approval';
        q1.ApprovalStatus__c = 'Approved';
        update q1;
        
        checkRecursiveTrigger.resetIds();
        q1.SBQQ__Status__c = 'Complete';
        q1.ApprovalStatus__c = 'Approved';
        update q1;
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    testMethod static void quoteCostPendingTest() {
        Test.startTest();
        
        List<Account> accts = TestDataFactory.createAccountsWithOpps(1,1);
        Account act1 = accts.get(0);
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :act1.Id];
        
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuoteWithGroupsAndLines(act1.Id, opp.Id, 3,2,1);
        
        List<SBQQ__Quote__c> relatedQuotes = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.ID];
        System.assert(relatedQuotes.size() > 1);
        
        checkRecursiveTrigger.resetIds();
        opp.LeadSource='Coffee Promo';
        update opp;
        
        checkRecursiveTrigger.resetIds();
        opp.LeadSource='Agent';
        update opp;
        
        checkRecursiveTrigger.resetIds();
        SBQQ__Quote__c q1 = quotes.get(0);
        q1.SBQQ__Status__c = 'Waiting for Information';
        Database.SaveResult res = Database.update(q1);
        System.assert(res.isSuccess());
        System.assertEquals('Waiting for Information', q1.SBQQ__Status__c);
        
        checkRecursiveTrigger.resetIds();
        q1.SBQQ__Status__c = 'Cost Pending';
        res = Database.update(q1);
        System.assert(res.isSuccess());
        System.assertEquals('Cost Pending', q1.SBQQ__Status__c);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    testMethod static void sceTest() {
        Test.startTest();
        
        List<Account> accts = TestDataFactory.createAccountsWithOpps(1,1);
        Account act1 = accts.get(0);
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :act1.Id];
        
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuoteWithGroupsAndLines(act1.Id, opp.Id, 2,2,2);
        
        SBQQ__Quote__c q1 = quotes.get(0);
        
        SBQQ__QuoteLineGroup__c grp = [SELECT Id, Address_Z__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :q1.Id LIMIT 1];
        Sales_Cost_Estimate__c sce = new Sales_Cost_Estimate__c(CPQ_Quote__c=q1.Id,
                                                                CPQ_Quote_Line_Group__c=grp.Id,
                                                                Related_Opportunity__c=q1.SBQQ__Opportunity2__c,
                                                                Evaluation_Options__c='Both',
                                                                Address_Z__c=grp.Address_Z__c);
        insert sce;
        
        MAINTENANCE_Off_Net_Vendors__c vend = new MAINTENANCE_Off_Net_Vendors__c(Name='Test Vendor');
        insert vend;
        
        checkRecursiveTrigger.resetIds();
        Sales_Off_Net_Vendor_Quote__c vendQuote = new Sales_Off_Net_Vendor_Quote__c(MAINTENANCE_Off_Net_Vendor__c=vend.Id,
                                                                                    Quote_1_Bandwidth__c='100',
                                                                                    Quote_1_Term__c='36',
                                                                                    Quote_1_Vendor_MRC__c=1,
                                                                                    Quote_1_Vendor_NRC__c=1,
                                                                                    QUOTE_1_Select__c=true,
                                                                                    Sales_Cost_Estimate__c=sce.Id);
        insert vendQuote;
        
        checkRecursiveTrigger.resetIds();
        vendQuote.QUOTE_1_Select__c=false;
        update vendQuote;
        
        checkRecursiveTrigger.resetIds();
        SBQQ__QuoteLineGroup__c tempgrp = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :q1.Id LIMIT 1];
        tempgrp.Cost_Total_1C_Cost__c=1000;
        tempgrp.Off_Net_Total_Cost__c=1000;
        tempgrp.On_Off_Net_Pricing__c='Off Net';
        update tempgrp;
        
        checkRecursiveTrigger.resetIds();
        SBQQ__QuoteLine__c qteLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Group__c = :tempgrp.Id LIMIT 1];
        update qteLine;
        
        checkRecursiveTrigger.resetIds();
        sce.Status__c = 'Information Requested';
        update sce;
        
        checkRecursiveTrigger.resetIds();
        sce.Status__c = 'Design';
        update sce;
        
        checkRecursiveTrigger.resetIds();
        sce.Construction_Materials_Total__c = 10000;
        sce.Status__c = 'Complete';
        update sce;
        
        Test.stopTest();
    }
    
    testMethod static void testROI() {
        Test.startTest();
        
        List<Account> accts = TestDataFactory.createAccountsWithOpps(1,1);
        Account act1 = accts.get(0);
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :act1.Id];
        
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuoteWithGroupsAndLines(act1.Id, opp.Id, 1,1,1);
        
        SBQQ__QuoteLineGroup__c qlg = [SELECT Id FROM SBQQ__QuoteLineGroup__c ORDER BY CreatedDate DESC LIMIT 1];
        
        checkRecursiveTrigger.resetIds();
        qlg.ROI_Payback_Months__c = 35;
        update qlg;
        
        checkRecursiveTrigger.resetIds();
        qlg.ROI_Payback_Months__c = 1;
        update qlg;
        
        Test.stopTest();
    }
    
    testMethod static void testQuoteLines() {
        List<Account> accts = TestDataFactory.createAccountsWithOpps(1,1);
        Account act1 = accts.get(0);
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :act1.Id];
        
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuoteWithGroupsAndLines(act1.Id, opp.Id, 1,1,1);
        
        SBQQ__Quote__c q1 = quotes.get(0);
        SBQQ__QuoteLine__c qol = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :q1.Id LIMIT 1];
        
        Test.startTest();
        
        qol.NRC__c = 1000;
        checkRecursiveTrigger.resetIds();
        update qol;
        
        Test.stopTest();
    }
}