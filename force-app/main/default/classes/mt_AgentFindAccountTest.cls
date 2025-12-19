@isTest
private class mt_AgentFindAccountTest {
    
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Company Inc', BillingCity = 'San Francisco', BillingCountry = 'USA'),
            new Account(Name = 'Test Company LLC', BillingCity = 'New York', BillingCountry = 'USA'),
            new Account(Name = 'Acme Corporation', BillingCity = 'Chicago', BillingCountry = 'USA')
        };
        insert accounts;
    }
    
    @isTest
    static void testFindAccount_SingleMatch() {
        Account testAcc = [SELECT Id, Name FROM Account WHERE Name = 'Acme Corporation' LIMIT 1];
        
        mt_AgentFindAccount.AccountSearchRequest request = new mt_AgentFindAccount.AccountSearchRequest();
        request.accountName = 'Acme';
        
        System.Test.startTest();
        List<mt_AgentFindAccount.AccountSearchResult> results = 
            mt_AgentFindAccount.findAccount(new List<mt_AgentFindAccount.AccountSearchRequest>{request});
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Search should be successful');
        System.assertEquals(testAcc.Id, results[0].accountId, 'Should return correct account ID');
    }
    
    @isTest
    static void testFindAccount_NoMatch() {
        mt_AgentFindAccount.AccountSearchRequest request = new mt_AgentFindAccount.AccountSearchRequest();
        request.accountName = 'NonExistent Company XYZ123';
        
        System.Test.startTest();
        List<mt_AgentFindAccount.AccountSearchResult> results = 
            mt_AgentFindAccount.findAccount(new List<mt_AgentFindAccount.AccountSearchRequest>{request});
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Search should fail');
    }
}

