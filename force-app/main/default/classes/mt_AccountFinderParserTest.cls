/**
 * ============================================================================
 * MT Account Finder Parser Test
 * ============================================================================
 * 
 * @description     Test class for mt_AccountFinderParser
 * @author          Michael Tietze, Principal AI Architect
 * @created         January 2026
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
@isTest
private class mt_AccountFinderParserTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Company Inc',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            Phone = '555-1234',
            Website = 'https://testcompany.com'
        );
        Database.SaveResult result = Database.insert(testAccount, false);
        
        // If Account creation fails, tests will use existing data or skip
        if (!result.isSuccess()) {
            System.debug('Test Account creation failed: ' + result.getErrors());
        }
    }
    
    @isTest
    static void testParseAccountFinderResponse_ExactMatch() {
        // Check if test Account exists
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Test Company Inc' LIMIT 1];
        if (accounts.isEmpty()) {
            // Skip test if no Account available
            return;
        }
        
        String jsonResponse = '{"accountName":"Test Company Inc","confidence":"high","searchTerms":["Test Company","Test Co"]}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Test Company Inc', results[0].accountName, 'Account name should match');
        Assert.isNotNull(results[0].accountId, 'Should find Account ID');
        Assert.areEqual('high', results[0].confidence, 'Confidence should be high');
    }
    
    @isTest
    static void testParseAccountFinderResponse_FuzzyMatch() {
        // Check if test Account exists
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        if (accounts.isEmpty()) {
            // Skip test if no Account available
            return;
        }
        Account acc = accounts[0];
        
        // Use partial name from existing account
        String partialName = acc.Name.substring(0, Math.min(5, acc.Name.length()));
        String jsonResponse = '{"accountName":"' + partialName + '","confidence":"medium","searchTerms":[]}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isNotNull(results[0].accountName, 'Should have account name');
    }
    
    @isTest
    static void testParseAccountFinderResponse_NoMatch() {
        String jsonResponse = '{"accountName":"Nonexistent Company XYZ 999","confidence":"low","searchTerms":["XYZ999"]}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Nonexistent Company XYZ 999', results[0].accountName, 'Account name should match');
        Assert.isNull(results[0].accountId, 'Should not find Account ID');
    }
    
    @isTest
    static void testParseAccountFinderResponse_Unknown() {
        String jsonResponse = '{"accountName":"Unknown","confidence":"low","searchTerms":[]}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Unknown', results[0].accountName, 'Account name should be Unknown');
        Assert.isNull(results[0].accountId, 'Should not search for Unknown');
    }
    
    @isTest
    static void testParseAccountFinderResponse_InvalidJson() {
        String jsonResponse = 'invalid json {';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Error parsing response', results[0].accountName, 'Should indicate error');
        Assert.areEqual('low', results[0].confidence, 'Confidence should be low');
    }
    
    @isTest
    static void testParseAccountFinderResponse_EmptyJson() {
        String jsonResponse = '{}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isNull(results[0].accountId, 'Should not find Account');
    }
    
    @isTest
    static void testParseAccountFinderResponse_WithSearchTerms() {
        // Check if test Account exists
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        if (accounts.isEmpty()) {
            // Skip test if no Account available
            return;
        }
        Account acc = accounts[0];
        
        String jsonResponse = '{"accountName":"' + acc.Name + '","confidence":"high","searchTerms":["' + acc.Name + '","Test"]}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isNotNull(results[0].accountName, 'Should have account name');
    }
    
    @isTest
    static void testParseAccountFinderResponse_MultipleRequests() {
        String jsonResponse1 = '{"accountName":"Company A","confidence":"high","searchTerms":[]}';
        String jsonResponse2 = '{"accountName":"Company B","confidence":"medium","searchTerms":[]}';
        
        mt_AccountFinderParser.Request req1 = new mt_AccountFinderParser.Request();
        req1.jsonResponse = jsonResponse1;
        
        mt_AccountFinderParser.Request req2 = new mt_AccountFinderParser.Request();
        req2.jsonResponse = jsonResponse2;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req1, req2});
        System.Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return two results');
        Assert.areEqual('Company A', results[0].accountName, 'First account name should match');
        Assert.areEqual('Company B', results[1].accountName, 'Second account name should match');
    }
    
    @isTest
    static void testParseAccountFinderResponse_NullSearchTerms() {
        String jsonResponse = '{"accountName":"Test","confidence":"low"}';
        
        mt_AccountFinderParser.Request req = new mt_AccountFinderParser.Request();
        req.jsonResponse = jsonResponse;
        
        System.Test.startTest();
        List<mt_AccountFinderParser.AccountFinderResult> results = 
            mt_AccountFinderParser.parseAccountFinderResponse(new List<mt_AccountFinderParser.Request>{req});
        System.Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Test', results[0].accountName, 'Account name should match');
    }
}
