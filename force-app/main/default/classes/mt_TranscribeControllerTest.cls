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
public class mt_TranscribeControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account for Transcribe',
            Industry = 'Technology'
        );
        insert testAccount;
        
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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('mockResponseToken', accessToken, 'Access token should match');
    }

    @isTest
    static void testGetAccessTokenNoToken() {
        String mockResponse = JSON.serialize(new Map<String,Object>{});
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        Test.stopTest();
        
        System.assertNotEquals('mockResponseToken', accessToken);
    }

    @isTest
    static void testGetAccessTokenFailure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{
            'error' => 'invalid_request',
            'error_description' => 'Auth Failure'
        });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(401, mockResponse));
        
        Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        Test.stopTest();
        
        Assert.isNull(accessToken, 'Should return null on failure');
    }

    @isTest
    static void testGetAccessTokenException() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'access_token' => 1234 });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        String accessToken = mt_TranscribeController.getAccessToken();
        Test.stopTest();
        
        Assert.isNull(accessToken, 'Should return null on exception');
    }

    // ========== URL TESTS ==========

    @isTest
    static void testGetBaseUrl() {
        Test.startTest();
        String baseUrl = mt_TranscribeController.getBaseUrl();
        Test.stopTest();
        
        Assert.isNotNull(baseUrl, 'Base URL should not be null');
    }

    @isTest
    static void testGetOrgDomainUrl() {
        Test.startTest();
        String domainUrl = mt_TranscribeController.getOrgDomainUrl();
        Test.stopTest();
        
        Assert.isNotNull(domainUrl, 'Domain URL should not be null');
    }

    // ========== CONFIGURATION TESTS ==========

    @isTest
    static void testGetConfig_Default() {
        Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig('Default');
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetConfig_NotFound() {
        Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = 
            mt_TranscribeController.getConfig('NonExistent_' + System.now().getTime());
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
        // Method may return a default config or error - just verify it handles gracefully
        System.debug('Config result: ' + config);
    }

    @isTest
    static void testGetConfig_Null() {
        Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig(null);
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetConfig_Empty() {
        Test.startTest();
        mt_TranscribeController.VoiceAssistantConfigResult config = mt_TranscribeController.getConfig('');
        Test.stopTest();
        
        Assert.isNotNull(config, 'Config result should not be null');
    }

    @isTest
    static void testGetAllConfigs() {
        Test.startTest();
        List<mt_TranscribeController.VoiceAssistantConfigResult> configs = mt_TranscribeController.getAllConfigs();
        Test.stopTest();
        
        Assert.isNotNull(configs, 'Configs list should not be null');
    }

    @isTest
    static void testGetObjectConfigs() {
        Test.startTest();
        List<mt_TranscribeController.ObjectConfigResult> configs = mt_TranscribeController.getObjectConfigs('Default');
        Test.stopTest();
        
        Assert.isNotNull(configs, 'Object configs should not be null');
    }

    @isTest
    static void testGetObjectConfigs_Empty() {
        Test.startTest();
        List<mt_TranscribeController.ObjectConfigResult> configs = mt_TranscribeController.getObjectConfigs('');
        Test.stopTest();
        
        Assert.isNotNull(configs, 'Object configs should not be null');
    }

    @isTest
    static void testGetObjectConfig() {
        Test.startTest();
        mt_TranscribeController.ObjectConfigResult config = 
            mt_TranscribeController.getObjectConfig('Default', 'Opportunity');
        Test.stopTest();
        
        // May or may not exist - just verify no exception
        System.debug('Config: ' + config);
    }

    @isTest
    static void testGetObjectConfig_NullParams() {
        Test.startTest();
        mt_TranscribeController.ObjectConfigResult config = 
            mt_TranscribeController.getObjectConfig(null, null);
        Test.stopTest();
        
        // Should handle nulls gracefully
        System.debug('Config: ' + config);
    }

    // ========== SCHEMA DESCRIBE TESTS ==========

    @isTest
    static void testGetAvailableObjects() {
        Test.startTest();
        List<Map<String, String>> objects = mt_TranscribeController.getAvailableObjects();
        Test.stopTest();
        
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
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Account');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.areEqual('Account', result.get('objectApiName'));
    }

    @isTest
    static void testGetObjectDescribe_Contact() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Contact');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectDescribe_Opportunity() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Opportunity');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectDescribe_Task() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('Task');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testGetObjectDescribe_Invalid() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe('InvalidObject__xyz');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetObjectDescribe_Null() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectDescribe(null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    // ========== RELATED ACCOUNT TESTS ==========

    @isTest
    static void testGetRelatedAccount_FromAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(acc.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(acc.Id, result.accountId);
        Assert.isNotNull(result.account, 'Should have account SObject');
    }

    @isTest
    static void testGetRelatedAccount_FromContact() {
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(con.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(con.AccountId, result.accountId);
    }

    @isTest
    static void testGetRelatedAccount_FromOpportunity() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(opp.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Should find account');
        Assert.areEqual(opp.AccountId, result.accountId);
    }

    // Note: Case test removed due to org-specific flow requirements (SDO Service)

    @isTest
    static void testGetRelatedAccount_FromLead() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(l.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        // Lead may not have account
    }

    @isTest
    static void testGetRelatedAccount_FromTask() {
        Task t = [SELECT Id, WhatId FROM Task LIMIT 1];
        
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(t.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testGetRelatedAccount_InvalidId() {
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount('invalid');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should not find account');
    }

    @isTest
    static void testGetRelatedAccount_NullId() {
        Test.startTest();
        mt_TranscribeController.RelatedAccountResult result = mt_TranscribeController.getRelatedAccount(null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should not find account');
    }

    // ========== ADMIN TESTS ==========

    @isTest
    static void testIsAdminUser() {
        Test.startTest();
        Boolean isAdmin = mt_TranscribeController.isAdminUser();
        Test.stopTest();
        
        // Just verify it doesn't throw
        System.debug('Is admin: ' + isAdmin);
    }

    @isTest
    static void testTestEinsteinConnection() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'access_token' => 'mockToken' });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        mt_TranscribeController.ConnectionTestResult result = mt_TranscribeController.testEinsteinConnection();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTestEinsteinConnection_Failure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'error' => 'failed' });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(401, mockResponse));
        
        Test.startTest();
        mt_TranscribeController.ConnectionTestResult result = mt_TranscribeController.testEinsteinConnection();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testSaveOpenAIApiKey() {
        Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey('test-api-key-12345');
        Test.stopTest();
        
        // May succeed or fail depending on permissions
        System.debug('Save result: ' + result);
    }

    @isTest
    static void testSaveOpenAIApiKey_Empty() {
        Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey('');
        Test.stopTest();
        
        System.debug('Save result: ' + result);
    }

    @isTest
    static void testSaveOpenAIApiKey_Null() {
        Test.startTest();
        Boolean result = mt_TranscribeController.saveOpenAIApiKey(null);
        Test.stopTest();
        
        System.debug('Save result: ' + result);
    }

    // ========== WHISPER TESTS ==========

    @isTest
    static void testTranscribeWithWhisper() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'text' => 'Test transcription' });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper('base64audiodata', 'Default');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTranscribeWithWhisper_Failure() {
        String mockResponse = JSON.serialize(new Map<String,Object>{ 'error' => 'API Error' });
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, mockResponse));
        
        Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper('base64audiodata', 'Default');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }

    @isTest
    static void testTranscribeWithWhisper_NullAudio() {
        Test.startTest();
        mt_TranscribeController.TranscriptionResult result = 
            mt_TranscribeController.transcribeWithWhisper(null, 'Default');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse(result.success, 'Should fail for null audio');
    }

    // ========== LAYOUT TESTS ==========

    @isTest
    static void testGetObjectLayouts_Account() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('Account');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('layoutOptions'), 'Should have layout options');
    }

    @isTest
    static void testGetObjectLayouts_Contact() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('Contact');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetObjectLayouts_Invalid() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts('InvalidObject__xyz');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetObjectLayouts_Null() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getObjectLayouts(null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetFieldsForLayout_AllCreateable() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Account', 'ALL_CREATEABLE');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('fields'), 'Should have fields');
        
        List<Object> fields = (List<Object>)result.get('fields');
        Assert.isTrue(fields.size() > 0, 'Should have at least one field');
    }

    @isTest
    static void testGetFieldsForLayout_AllUpdateable() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Contact', 'ALL_UPDATEABLE');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetFieldsForLayout_RequiredOnly() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Opportunity', 'REQUIRED_ONLY');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
        Assert.isNotNull(result.get('requiredFields'), 'Should have required fields');
    }

    @isTest
    static void testGetFieldsForLayout_CommonFields() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('Lead', 'COMMON_FIELDS');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue((Boolean)result.get('success'), 'Should be successful');
    }

    @isTest
    static void testGetFieldsForLayout_InvalidObject() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout('InvalidObject__xyz', 'ALL_CREATEABLE');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isFalse((Boolean)result.get('success'), 'Should not be successful');
    }

    @isTest
    static void testGetFieldsForLayout_NullObject() {
        Test.startTest();
        Map<String, Object> result = mt_TranscribeController.getFieldsForLayout(null, 'ALL_CREATEABLE');
        Test.stopTest();
        
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