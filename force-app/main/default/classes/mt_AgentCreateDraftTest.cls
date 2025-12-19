@isTest
private class mt_AgentCreateDraftTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAcc = new Account(Name = 'Test Company for Draft', BillingCity = 'Boston');
        insert testAcc;
    }
    
    @isTest
    static void testCreateDraft_Success() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        
        mt_AgentCreateDraft.CreateDraftRequest request = new mt_AgentCreateDraft.CreateDraftRequest();
        request.accountId = testAcc.Id;
        request.transcript = 'Test visit report. Met with John Doe.';
        request.configProfile = 'Default';
        
        System.Test.startTest();
        List<mt_AgentCreateDraft.CreateDraftResult> results = 
            mt_AgentCreateDraft.createVisitReportDraft(new List<mt_AgentCreateDraft.CreateDraftRequest>{request});
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Draft creation should be successful');
        System.assertNotEquals(null, results[0].draftId, 'Should return a draft ID');
    }
    
    @isTest
    static void testCreateDraft_MissingAccountId() {
        mt_AgentCreateDraft.CreateDraftRequest request = new mt_AgentCreateDraft.CreateDraftRequest();
        request.accountId = null;
        request.transcript = 'Test transcript';
        
        System.Test.startTest();
        List<mt_AgentCreateDraft.CreateDraftResult> results = 
            mt_AgentCreateDraft.createVisitReportDraft(new List<mt_AgentCreateDraft.CreateDraftRequest>{request});
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should fail without account ID');
    }
}

