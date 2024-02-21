/**
 * @description       : 
 * @author            : clabelle@everstream.net
 * @last modified on  : 06-08-2023
 * @last modified by  : clabelle@everstream.net
**/
@isTest(seeAllData=true)
public class CPQ_SimilarSalesCostEstimateTest {
    testMethod static void testA() {
        SBQQ__QuoteLineGroup__c qlg = [SELECT Id, Address_Z__c, Address_Z__r.Address__c, Address_Z__r.City__c, Address_Z__r.State__c, 
                                       Address_A__c, Address_A__r.Address__c, Address_A__r.City__c, Address_A__r.State__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
                                       FROM SBQQ__QuoteLineGroup__c WHERE Address_Z__c = 'aD80B0000004DWySAM' LIMIT 1];
        
        List<Sales_Cost_Estimate__c> ests = [SELECT Id FROM Sales_Cost_Estimate__c WHERE CPQ_Quote_Line_Group__c = :qlg.Id];
        
        Test.startTest();

        Sales_Cost_Estimate__c similarCostEstimate_A = CPQ_SimilarSalesCostEstimate.getMostSimilarCostEstimate(qlg, false);

        Test.stopTest();
    }

    testMethod static void testZ() {
        SBQQ__QuoteLineGroup__c qlg = [SELECT Id, Address_Z__c, Address_Z__r.Address__c, Address_Z__r.City__c, Address_Z__r.State__c, 
                                       Address_A__c, Address_A__r.Address__c, Address_A__r.City__c, Address_A__r.State__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
                                       FROM SBQQ__QuoteLineGroup__c WHERE Address_Z__c = 'aD80B0000004DWySAM' LIMIT 1];
        
        List<Sales_Cost_Estimate__c> ests = [SELECT Id FROM Sales_Cost_Estimate__c WHERE CPQ_Quote_Line_Group__c = :qlg.Id];
        
        Test.startTest();
        
        Sales_Cost_Estimate__c similarCostEstimate_Z = CPQ_SimilarSalesCostEstimate.getMostSimilarCostEstimate(qlg, true);

        Test.stopTest();
    }

    testMethod static void testFiles() {
        SBQQ__QuoteLineGroup__c qlg = [SELECT Id, Address_Z__c, Address_Z__r.Address__c, Address_Z__r.City__c, Address_Z__r.State__c, 
                                       Address_A__c, Address_A__r.Address__c, Address_A__r.City__c, Address_A__r.State__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
                                       FROM SBQQ__QuoteLineGroup__c WHERE Address_Z__c = 'aD80B0000004DWySAM' LIMIT 1];
        
        List<Sales_Cost_Estimate__c> ests = [SELECT Id FROM Sales_Cost_Estimate__c WHERE CPQ_Quote_Line_Group__c = :qlg.Id];
        
        List<ContentDocumentLink> documentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = '0690B000005f69WQAQ' LIMIT 1];
        if (documentLinks != null && documentLinks.size() > 0) {
            for (Sales_Cost_Estimate__c est : ests) {
                for (ContentDocumentLink nd : documentLinks) {
                    try {
                        ContentDocumentLink newLink = new ContentDocumentLink();
                        newLink.LinkedEntityId = est.Id;
                        newLink.ContentDocumentId = nd.ContentDocumentId;
                        newLink.ShareType = 'V';
                        newLink.Visibility = 'AllUsers';
                        //upsert newLink;
                    } catch (Exception e) { System.debug(e); }
                }
            }
        }

        //Sales_Cost_Estimate__c fileEst = [SELECT Id, Cloned_From__c FROM Sales_Cost_Estimate__c WHERE Id = 'a1B4P00000G7JtRUAV'];
        Sales_Cost_Estimate__c testEst = [SELECT Id, Cloned_From__c FROM Sales_Cost_Estimate__c WHERE Cloned_From__c != NULL ORDER BY LastModifiedDate Desc LIMIT 1];
        
        Test.startTest();
        
        CPQ_SimilarSalesCostEstimate.shareFilesToNewEst(testEst.Id, testEst.Cloned_From__c);

        Test.stopTest();
    }
}