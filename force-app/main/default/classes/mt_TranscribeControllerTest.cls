/**
 * ============================================================================
 * MT Einstein Transcribe Controller Test
 * ============================================================================
 * 
 * @description     Comprehensive test class for mt_TranscribeController.
 *                  Provides test coverage for Einstein Transcribe API,
 *                  Whisper integration, configuration, and admin methods.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         November 2025
 * @updated         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 * COPYRIGHT & CONFIDENTIALITY NOTICE
 * ============================================================================
 * © 2025 Salesforce, Inc. All rights reserved.
 * ============================================================================
 */
@isTest
private class mt_TranscribeControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account with validation rule handling
        Account testAccount = new Account(
            Name = 'Test Account for Transcribe',
            Industry = 'Technology'
        );
        
        // Use Database.insert with allOrNone=false to handle validation rules gracefully
        Database.SaveResult result = Database.insert(testAccount, false);
        
        // If Account creation fails due to validation rules, tests will use existing Accounts
        if (!result.isSuccess()) {
            // Query for existing Account instead
            List<Account> existingAccounts = [SELECT Id, Name FROM Account LIMIT 1];
            if (!existingAccounts.isEmpty()) {
                testAccount = existingAccounts[0];
            }
        }
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@test.com'
        );
        insert testContact;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Note: Case creation removed due to org-specific flow requirements (SDO Service)
        
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;
        
        // Create test Task
        Task testTask = new Task(
            Subject = 'Test Task',
            WhatId = testAccount.Id,
            Status = 'Not Started'
        );
        insert testTask;
    }

    // ========== ACCESS TOKEN TESTS ==========

    @isTest
    static void testGetAccessTokenSuccess() {
        Map<String,Object> mockResponseMap = new Map<String,Object>{ 'access_token' => 'mockResponseToken' };
        String mockResponse = JSON.serialize(mockResponseMap);
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        System.Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        System.Test.stopTest();
        
        System.assertEquals('mockResponseToken', accessToken, 'Access token should match');
    }

    @isTest
    static void testGetAccessTokenNoToken() {
        String mockResponse = JSON.serialize(new Map<String,Object>{});
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        System.Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        System.Test.stopTest();
        
        System.assertNotEquals('mockResponseToken', accessToken);
    }

    @isTest
    static void testGetAccessTokenFailure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{
            'error' => 'invalid_request',
            'error_description' => 'Auth Failure'
        });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(401, mockResponse));
        
        System.Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        System.Test.stopTest();
        
        Assert.isNull(accessToken, 'Should return null on failure');
    }

    @isTest
    static void testGetAccessTokenException() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'access_token' => 1234 });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        System.Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        System.Test.stopTest();
        
        Assert.isNull(accessToken, 'Should return null on exception');
    }

    // ========== URL TESTS ==========

    @isTest
    static void testGetBaseUrl() {
        System.Test.startTest();
        String baseUrl = mt_TranscribeController.getBaseUrl();
        System.Test.stopTest();
        
        Assert.isNotNull(baseUrl, 'Base URL should not be null');
    }

    @isTest
    static void testGetOrgDomainUrl() {
        System.Test.startTest();
        String domainUrl = mt_TranscribeController.getOrgDomainUrl();
        System.Test.stopTest();
        
        Assert.isNotNull(domainUrl, 'Domain URL should not be null');
    }

    // ========== CONFIGURATION TESTS ==========

    @isTest
    static void testGetConfig_Default() {
        System.Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig('Default');
        System.Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetConfig_NotFound() {
        System.Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = 
            mt_TranscribeController.getConfig('NonExistent_' + System.now().getTime());
        System.Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
        // Method may return a default config or error - just verify it handles gracefully
        System.debug('Config result: ' + config);
    }

    @isTest
    static void testGetConfig_Null() {
        System.Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig(null);
        System.Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetConfig_Empty() {
        System.Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig('');
        System.Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetAllConfigs() {
        System.Test.startTest();
        List<mt_TranscribeController.VoiceAssistantConfigResult> configs = mt_TranscribeController.getAllConfigs();
        System.Test.stopTest();
        
        Assert.isNotNull(configs, 'Configs list should not be null');
    }

    @isTest
    static void testGetObjectConfigs() {
        System.Test.startTest();
        List<mt_TranscribeController.ObjectConfigResult> configs = mt_TranscribeController.getObjectConfigs('Default');
        System.Test.stopTest();
        
        Assert.isNotNull(configs, 'Object configs should not be null');
    }

    @isTest
    static void testGetObjectConfigs_Empty() {
        System.Test.startTest();
        List<mt_TranscribeController.ObjectConfigResult> configs = mt_TranscribeController.getObjectConfigs('');
        System.Test.stopTest();
        
        Assert.isNotNull(configs, 'Object configs should not be null');
    }

    @isTest
    static void testGetObjectConfig() {
        System.Test.startTest();
        mt_TranscribeController.ObjectConfigResult config = 
            mt_TranscribeController.getObjectConfig('Default', 'Opportunity');
        System.Test.stopTest();
        
        // May or may not exist - just verify no exception
        System.debug('Config: ' + config);
    }

    @isTest
    static void testGetObjectConfig_NullParams() {
        System.Test.startTest();
        mt_TranscribeController.ObjectConfigResult config = 
            mt_TranscribeController.getObjectConfig(null, null);
        System.Test.stopTest();
        
        // Should handle nulls gracefully
        System.debug('Config: ' + config);
    }

    // ========== SCHEMA DESCRIBE TESTS ==========

    @isTest
    static void testGetAvailableObjects() {
        System.Test.startTest();
        List<Map<String, String>> objects = mt_TranscribeController.getAvailableObjects();
        System.Test.stopTest();
        
        Assert.isNotNull(objects, 'Objects list should not be null');
        Assert.isTrue(objects.size() > 0, 'Should have objects');
        
        Boolean hasAccount = false;
        for (Map<String, String> obj : objects) {
            if (obj.get('value') == 'Account') hasAccount = true;
        }
        Assert.isTrue(hasAccount, 'Should include Account');
    }

    @isTest
    static void testGetObjectDescribe_Account() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Account');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.areEqual('Account', result.get('objectApiName'));
    }

    @isTest
    static void testGetObjectDescribe_Contact() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Contact');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectDescribe_Opportunity() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Opportunity');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectDescribe_Task() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Task');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testGetObjectDescribe_Invalid() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('InvalidObject__xyz');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetObjectDescribe_Null() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe(null);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    // ========== RELATED ACCOUNT TESTS ==========

    @isTest
    static void testGetRelatedAccount_FromAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(acc.Id);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(acc.Id, result.accountId);
        Assert.isNotNull(result.account, 'Should have account SObject');
    }

    @isTest
    static void testGetRelatedAccount_FromContact() {
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(con.Id);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(con.AccountId, result.accountId);
    }

    @isTest
    static void testGetRelatedAccount_FromOpportunity() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(opp.Id);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(opp.AccountId, result.accountId);
    }

    // Note: Case test removed due to org-specific flow requirements (SDO Service)

    @isTest
    static void testGetRelatedAccount_FromLead() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(l.Id);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        // Lead may not have account
    }

    @isTest
    static void testGetRelatedAccount_FromTask() {
        Task t = [SELECT Id, WhatId FROM Task LIMIT 1];
        
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(t.Id);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testGetRelatedAccount_InvalidId() {
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount('invalid');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should not find account');
    }

    @isTest
    static void testGetRelatedAccount_NullId() {
        System.Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(null);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should not find account');
    }

    // ========== ADMIN TESTS ==========

    @isTest
    static void testIsAdminUser() {
        System.Test.startTest();
        Boolean isAdmin = mt_TranscribeController.isAdminUser();
        System.Test.stopTest();
        
        // Just verify it doesn't throw
        System.debug('Is admin: ' + isAdmin);
    }

    @isTest
    static void testTestEinsteinConnection() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'access_token' => 'mockToken' });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        System.Test.startTest();
        mt_TranscribeController.ConnectionTestResult result = mt_TranscribeController.testEinsteinConnection();
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTestEinsteinConnection_Failure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'error' => 'failed' });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(401, mockResponse));
        
        System.Test.startTest();
        mt_TranscribeController.ConnectionTestResult result = mt_TranscribeController.testEinsteinConnection();
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testSaveOpenAIApiKey() {
        System.Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey('test-api-key-12345');
        System.Test.stopTest();
        
        // May succeed or fail depending on permissions
        System.debug('Save result: ' + result);
    }

    @isTest
    static void testSaveOpenAIApiKey_Empty() {
        System.Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey('');
        System.Test.stopTest();
        
        System.debug('Save result: ' + result);
    }

    @isTest
    static void testSaveOpenAIApiKey_Null() {
        System.Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey(null);
        System.Test.stopTest();
        
        System.debug('Save result: ' + result);
    }

    // ========== WHISPER TESTS ==========

    @isTest
    static void testTranscribeWithWhisper() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'text' => 'Test transcription' });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        System.Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper('base64audiodata', 'Default', 'en');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTranscribeWithWhisper_Failure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'error' => 'API Error' });
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, mockResponse));
        
        System.Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper('base64audiodata', 'Default', 'en');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTranscribeWithWhisper_NullAudio() {
        System.Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper(null, 'Default', null);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should fail for null audio');
    }

    // ========== LAYOUT TESTS ==========

    @isTest
    static void testGetObjectLayouts_Account() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('Account');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('layoutOptions'), 'Should have layout options');
    }

    @isTest
    static void testGetObjectLayouts_Contact() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('Contact');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectLayouts_Invalid() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('InvalidObject__xyz');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetObjectLayouts_Null() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts(null);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetFieldsForLayout_AllCreateable() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Account', 'ALL_CREATEABLE');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('fields'), 'Should have fields');
        
        List<Object> fields = (List<Object>)result.get('fields');
        Assert.isTrue(fields.size() > 0, 'Should have at least one field');
    }

    @isTest
    static void testGetFieldsForLayout_AllUpdateable() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Contact', 'ALL_UPDATEABLE');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetFieldsForLayout_RequiredOnly() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Opportunity', 'REQUIRED_ONLY');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('requiredFields'), 'Should have required fields');
    }

    @isTest
    static void testGetFieldsForLayout_CommonFields() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Lead', 'COMMON_FIELDS');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetFieldsForLayout_InvalidObject() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('InvalidObject__xyz', 'ALL_CREATEABLE');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetFieldsForLayout_NullObject() {
        System.Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout(null, 'ALL_CREATEABLE');
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    // ========== MOCK HTTP RESPONSE ==========

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public MockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}