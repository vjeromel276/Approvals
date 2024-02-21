/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @group             : 
 * @last modified on  : 03-28-2023
 * @last modified by  : clabelle@everstream.net
**/
@isTest(seeAllData=true)
public class CPQ_UpdateQuoteCostInfoFromSCETest {
    testMethod static void runComplete() {
        Sales_Cost_Estimate__c[] sce = [SELECT Id, CPQ_Quote_Line_Group__c, CPQ_Quote__c, Status__c, 
                                        Cost_Total_1C_Cost__c, Quote_Vendor_Total_Cost__c, Quote_Vendor_ID__c,
                                        Quote_Vendor_MRC__c, Quote_Vendor_NRC__c
                                        FROM Sales_Cost_Estimate__c 
                                        WHERE CPQ_Quote_Line_Group__c != NULL 
                                        AND Status__c = 'Complete' LIMIT 1];

        sce[0].OSP_Design_Comments__c = 'TEST';
        sce[0].Solutions_Engineer_Notes__c = 'TEST';
        sce[0].Sales_Cost_Engineering_Notes__c = 'TEST';
        update sce;

        SBQQ__Quote__c[] q = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :sce[0].CPQ_Quote__c];
        SBQQ__QuoteLineGroup__c[] qlg = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Id = :sce[0].CPQ_Quote_Line_Group__c];
        
        CPQ_UpdateQuoteCostInfoFromSCE.updateCosts(q[0].Id, qlg[0].Id, sce[0].Id, true, true);
    }
    
    testMethod static void runCompleteOffNet() {
        Sales_Cost_Estimate__c[] sce = [SELECT Id, CPQ_Quote_Line_Group__c, CPQ_Quote__c, Status__c, 
                                        Cost_Total_1C_Cost__c, Quote_Vendor_Total_Cost__c, Quote_Vendor_ID__c,
                                        Quote_Vendor_MRC__c, Quote_Vendor_NRC__c
                                        FROM Sales_Cost_Estimate__c 
                                        WHERE CPQ_Quote_Line_Group__c != NULL 
                                        AND Status__c = 'Complete' AND Evaluation_Options__c = 'Off-Net ONLY' LIMIT 1];
        SBQQ__Quote__c[] q = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :sce[0].CPQ_Quote__c];
        SBQQ__QuoteLineGroup__c[] qlg = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Id = :sce[0].CPQ_Quote_Line_Group__c];
        
        CPQ_UpdateQuoteCostInfoFromSCE.updateCosts(q[0].Id, qlg[0].Id, sce[0].Id, true, true);
    }
    
    testMethod static void runIncomplete() {
        Sales_Cost_Estimate__c[] sce = [SELECT Id, CPQ_Quote_Line_Group__c, CPQ_Quote__c, Status__c, 
                                        Cost_Total_1C_Cost__c, Quote_Vendor_Total_Cost__c, Quote_Vendor_ID__c,
                                        Quote_Vendor_MRC__c, Quote_Vendor_NRC__c
                                        FROM Sales_Cost_Estimate__c 
                                        WHERE CPQ_Quote_Line_Group__c != NULL 
                                        AND Status__c != 'Complete' LIMIT 1];
        SBQQ__Quote__c[] q = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :sce[0].CPQ_Quote__c];
        SBQQ__QuoteLineGroup__c[] qlg = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Id = :sce[0].CPQ_Quote_Line_Group__c];
        
        CPQ_UpdateQuoteCostInfoFromSCE.updateCosts(q[0].Id, qlg[0].Id, sce[0].Id, true, true);
    }
    
    testMethod static void forceException() {
        CPQ_UpdateQuoteCostInfoFromSCE.updateCosts(null, null, null, null, null);
    }
}