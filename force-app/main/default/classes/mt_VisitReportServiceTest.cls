/**
 * ============================================================================
 * MT Visit Report Service Test Class
 * ============================================================================
 * 
 * @description     Test class for mt_VisitReportService
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
@isTest
private class mt_VisitReportServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Customer Account');
        insert testAccount;
        
        // Create test User (use current user for simplicity)
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Create test drafts with different statuses
        List<MT_Visit_Report_Draft__c> drafts = new List<MT_Visit_Report_Draft__c>();
        
        // Draft 1: Ready status
        drafts.add(new MT_Visit_Report_Draft__c(
            Status__c = 'Ready',
            Transcript__c = 'Test transcript for ready draft',
            Prompt_Response_JSON__c = '{"records":[],"Summary":"Test summary","Reasoning":"Test reasoning"}',
            Account__c = testAccount.Id,
            Created_By_User__c = testUser.Id,
            Configuration_Profile__c = 'Default',
            Summary__c = '<ul><li>Test summary</li></ul>',
            Reasoning__c = '<ul><li>Test reasoning</li></ul>'
        ));
        
        // Draft 2: Processed status
        drafts.add(new MT_Visit_Report_Draft__c(
            Status__c = 'Processed',
            Transcript__c = 'Test transcript for processed draft',
            Prompt_Response_JSON__c = '{"records":[],"Summary":"Processed summary","Reasoning":"Processed reasoning"}',
            Account__c = testAccount.Id,
            Created_By_User__c = testUser.Id,
            Configuration_Profile__c = 'Default',
            Processed_Date__c = DateTime.now()
        ));
        
        // Draft 3: New status
        drafts.add(new MT_Visit_Report_Draft__c(
            Status__c = 'New',
            Transcript__c = 'Test transcript for new draft',
            Account__c = testAccount.Id,
            Created_By_User__c = testUser.Id,
            Configuration_Profile__c = 'Default'
        ));
        
        insert drafts;
    }
    
    @isTest
    static void testGetDraftsForAccount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        System.Test.startTest();
        List<MT_Visit_Report_Draft__c> drafts = mt_VisitReportService.getDraftsForAccount(testAccount.Id);
        System.Test.stopTest();
        
        // Should only return drafts with Status = 'Ready'
        System.assertEquals(1, drafts.size(), 'Should return exactly 1 Ready draft');
        System.assertEquals('Ready', drafts[0].Status__c, 'Draft status should be Ready');
    }
    
    @isTest
    static void testGetDraftsForAccount_BlankId() {
        System.Test.startTest();
        List<MT_Visit_Report_Draft__c> drafts = mt_VisitReportService.getDraftsForAccount('');
        System.Test.stopTest();
        
        System.assertEquals(0, drafts.size(), 'Should return empty list for blank account ID');
    }
    
    @isTest
    static void testUpdateDraftStatus() {
        MT_Visit_Report_Draft__c draft = [
            SELECT Id, Status__c, Processed_Date__c 
            FROM MT_Visit_Report_Draft__c 
            WHERE Status__c = 'Ready' 
            LIMIT 1
        ];
        
        System.Test.startTest();
        mt_VisitReportService.updateDraftStatus(draft.Id, 'Processed');
        System.Test.stopTest();
        
        // Verify update
        MT_Visit_Report_Draft__c updatedDraft = [
            SELECT Id, Status__c, Processed_Date__c 
            FROM MT_Visit_Report_Draft__c 
            WHERE Id = :draft.Id
        ];
        
        System.assertEquals('Processed', updatedDraft.Status__c, 'Status should be updated to Processed');
        System.assertNotEquals(null, updatedDraft.Processed_Date__c, 'Processed Date should be set');
    }
    
    @isTest
    static void testUpdateDraftStatus_BlankParams() {
        Boolean exceptionThrown = false;
        
        System.Test.startTest();
        try {
            mt_VisitReportService.updateDraftStatus('', 'Processed');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('required'), 'Should throw exception for blank parameters');
        }
        System.Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for blank draft ID');
    }
    
    @isTest
    static void testFindAccountByName_ExactMatch() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        System.Test.startTest();
        String foundAccountId = mt_VisitReportService.findAccountByName(testAccount.Name);
        System.Test.stopTest();
        
        System.assertEquals(testAccount.Id, foundAccountId, 'Should find account by exact name match');
    }
    
    @isTest
    static void testFindAccountByName_PartialMatch() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        
        System.Test.startTest();
        String foundAccountId = mt_VisitReportService.findAccountByName('Test Customer');
        System.Test.stopTest();
        
        System.assertEquals(testAccount.Id, foundAccountId, 'Should find account by partial name match');
    }
    
    @isTest
    static void testFindAccountByName_NoMatch() {
        System.Test.startTest();
        String foundAccountId = mt_VisitReportService.findAccountByName('Nonexistent Account XYZ123');
        System.Test.stopTest();
        
        System.assertEquals(null, foundAccountId, 'Should return null for non-existent account');
    }
    
    @isTest
    static void testFindAccountByName_BlankName() {
        System.Test.startTest();
        String foundAccountId = mt_VisitReportService.findAccountByName('');
        System.Test.stopTest();
        
        System.assertEquals(null, foundAccountId, 'Should return null for blank name');
    }
    
    @isTest
    static void testGetMyPendingDrafts() {
        System.Test.startTest();
        List<MT_Visit_Report_Draft__c> drafts = mt_VisitReportService.getMyPendingDrafts();
        System.Test.stopTest();
        
        // Should return only Ready drafts for current user
        System.assertEquals(1, drafts.size(), 'Should return 1 pending draft for current user');
        System.assertEquals('Ready', drafts[0].Status__c, 'Draft should have Ready status');
    }
    
    @isTest
    static void testParsePromptResponse() {
        String jsonResponse = '{"records":[],"Summary":"<ul><li>Test summary</li></ul>","Reasoning":"<ul><li>Test reasoning</li></ul>"}';
        
        mt_VisitReportService.ParseRequest request = new mt_VisitReportService.ParseRequest();
        request.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_VisitReportService.ParseResult> results = mt_VisitReportService.parsePromptResponse(new List<mt_VisitReportService.ParseRequest>{request});
        System.Test.stopTest();
        
        System.assertNotEquals(null, results, 'Parsed result should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].summary.contains('Test summary'), 'Summary should be extracted');
        System.assert(results[0].reasoning.contains('Test reasoning'), 'Reasoning should be extracted');
    }
    
    @isTest
    static void testParsePromptResponse_BlankJson() {
        mt_VisitReportService.ParseRequest request = new mt_VisitReportService.ParseRequest();
        request.jsonResponse = '';
        
        System.Test.startTest();
        List<mt_VisitReportService.ParseResult> results = mt_VisitReportService.parsePromptResponse(new List<mt_VisitReportService.ParseRequest>{request});
        System.Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return result for blank JSON');
        System.assertEquals('', results[0].summary, 'Summary should be empty string');
        System.assertEquals('', results[0].reasoning, 'Reasoning should be empty string');
    }
    
    @isTest
    static void testParsePromptResponse_InvalidJson() {
        mt_VisitReportService.ParseRequest request = new mt_VisitReportService.ParseRequest();
        request.jsonResponse = 'invalid json {]';
        
        System.Test.startTest();
        List<mt_VisitReportService.ParseResult> results = mt_VisitReportService.parsePromptResponse(new List<mt_VisitReportService.ParseRequest>{request});
        System.Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return result for invalid JSON');
        System.assert(results[0].summary.contains('Error'), 'Summary should indicate error');
    }
    
    @isTest
    static void testGetDraftById() {
        MT_Visit_Report_Draft__c draft = [
            SELECT Id 
            FROM MT_Visit_Report_Draft__c 
            WHERE Status__c = 'Ready' 
            LIMIT 1
        ];
        
        System.Test.startTest();
        MT_Visit_Report_Draft__c retrievedDraft = mt_VisitReportService.getDraftById(draft.Id);
        System.Test.stopTest();
        
        System.assertNotEquals(null, retrievedDraft, 'Should retrieve draft by ID');
        System.assertEquals(draft.Id, retrievedDraft.Id, 'Should return correct draft');
        System.assertNotEquals(null, retrievedDraft.Account__c, 'Should include Account lookup');
    }
    
    @isTest
    static void testGetDraftById_BlankId() {
        Boolean exceptionThrown = false;
        
        System.Test.startTest();
        try {
            mt_VisitReportService.getDraftById('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('required'), 'Should throw exception for blank ID');
        }
        System.Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for blank draft ID');
    }
}



