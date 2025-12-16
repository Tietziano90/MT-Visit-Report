/**
 * ============================================================================
 * MT Config Metadata Service Test
 * ============================================================================
 * 
 * @description     Test class for mt_ConfigMetadataService.
 *                  Tests Custom Metadata CRUD operations via Metadata API.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 * COPYRIGHT & CONFIDENTIALITY NOTICE
 * ============================================================================
 * © 2025 Salesforce, Inc. All rights reserved.
 * ============================================================================
 */
@isTest
private class mt_ConfigMetadataServiceTest {

    /**
     * @description Test saving a new config via Metadata API
     * Note: Metadata API operations are async, so we test the method execution
     */
    @isTest
    static void testSaveConfiguration() {
        Map<String, Object> configData = new Map<String, Object>{
            'developerName' => 'Test_Config_' + System.now().getTime(),
            'label' => 'Test Configuration',
            'provider' => 'Einstein',
            'promptTemplateName' => 'MT_Voice_Record_Suggestion',
            'einsteinNamedCredential' => 'mt_EinsteinTranscribe',
            'whisperNamedCredential' => 'mt_OpenAI_Whisper',
            'whisperModel' => 'whisper-1',
            'isActive' => true,
            'description' => 'Test configuration'
        };
        String configJson = JSON.serialize(configData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveConfiguration(configJson);
        System.Test.stopTest();
        
        // Metadata API is async, so we just verify the method doesn't throw
        Assert.isNotNull(result, 'Should return a result');
    }

    /**
     * @description Test config creation with minimal data
     */
    @isTest
    static void testSaveConfiguration_MinimalData() {
        Map<String, Object> configData = new Map<String, Object>{
            'developerName' => 'Minimal_Config_' + System.now().getTime(),
            'label' => 'Minimal Config',
            'provider' => 'Einstein',
            'isActive' => false
        };
        String configJson = JSON.serialize(configData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveConfiguration(configJson);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }

    /**
     * @description Test config creation with empty JSON
     */
    @isTest
    static void testSaveConfiguration_EmptyJson() {
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveConfiguration('{}');
        System.Test.stopTest();
        
        // Should handle gracefully
        Assert.isNotNull(result, 'Should return a result even for empty JSON');
    }

    /**
     * @description Test object config save
     */
    @isTest
    static void testSaveObjectConfiguration() {
        Map<String, Object> objectConfigData = new Map<String, Object>{
            'developerName' => 'Test_Object_Config_' + System.now().getTime(),
            'label' => 'Test Object Config',
            'configProfile' => 'Default',
            'objectApiName' => 'Contact',
            'allowedFieldsJson' => '["FirstName","LastName","Email"]',
            'mandatoryFieldsJson' => '["LastName"]',
            'allowCreate' => true,
            'allowEdit' => true
        };
        String configJson = JSON.serialize(objectConfigData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveObjectConfiguration(configJson);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }

    /**
     * @description Test object config with Opportunity
     */
    @isTest
    static void testSaveObjectConfiguration_Opportunity() {
        Map<String, Object> objectConfigData = new Map<String, Object>{
            'developerName' => 'Test_Opp_Config_' + System.now().getTime(),
            'label' => 'Test Opportunity Config',
            'configProfile' => 'Default',
            'objectApiName' => 'Opportunity',
            'allowedFieldsJson' => '["Name","Amount","CloseDate","StageName"]',
            'mandatoryFieldsJson' => '["Name","CloseDate","StageName"]',
            'allowCreate' => true,
            'allowEdit' => true
        };
        String configJson = JSON.serialize(objectConfigData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveObjectConfiguration(configJson);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }

    /**
     * @description Test object config with empty allowed fields
     */
    @isTest
    static void testSaveObjectConfiguration_EmptyFields() {
        Map<String, Object> objectConfigData = new Map<String, Object>{
            'developerName' => 'Test_Empty_Config_' + System.now().getTime(),
            'label' => 'Test Empty Config',
            'configProfile' => 'Default',
            'objectApiName' => 'Task',
            'allowedFieldsJson' => '[]',
            'mandatoryFieldsJson' => '[]',
            'allowCreate' => false,
            'allowEdit' => false
        };
        String configJson = JSON.serialize(objectConfigData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveObjectConfiguration(configJson);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }

    /**
     * @description Test with all Whisper fields
     */
    @isTest
    static void testSaveConfiguration_WhisperConfig() {
        Map<String, Object> configData = new Map<String, Object>{
            'developerName' => 'Whisper_Config_' + System.now().getTime(),
            'label' => 'Whisper Configuration',
            'provider' => 'Whisper',
            'promptTemplateName' => 'MT_Voice_Record_Suggestion',
            'einsteinNamedCredential' => '',
            'whisperNamedCredential' => 'mt_OpenAI_Whisper',
            'whisperModel' => 'whisper-1',
            'isActive' => true,
            'description' => 'Configuration for OpenAI Whisper'
        };
        String configJson = JSON.serialize(configData);
        
        System.Test.startTest();
        String result = mt_ConfigMetadataService.saveConfiguration(configJson);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }
    
    /**
     * @description Test config with no developer name (should throw error)
     */
    @isTest
    static void testSaveConfiguration_NoDeveloperName() {
        Map<String, Object> configData = new Map<String, Object>{
            'label' => 'No Dev Name Config',
            'provider' => 'Einstein',
            'isActive' => true
        };
        String configJson = JSON.serialize(configData);
        
        System.Test.startTest();
        try {
            String result = mt_ConfigMetadataService.saveConfiguration(configJson);
            Assert.fail('Should have thrown exception');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Developer Name is required'), 'Should throw proper error');
        }
        System.Test.stopTest();
    }
    
    /**
     * @description Test object config with no config profile (should throw error)
     */
    @isTest
    static void testSaveObjectConfiguration_NoConfigProfile() {
        Map<String, Object> objectConfigData = new Map<String, Object>{
            'objectApiName' => 'Contact',
            'allowedFieldsJson' => '["FirstName","LastName"]',
            'allowCreate' => true
        };
        String configJson = JSON.serialize(objectConfigData);
        
        System.Test.startTest();
        try {
            String result = mt_ConfigMetadataService.saveObjectConfiguration(configJson);
            Assert.fail('Should have thrown exception');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Configuration Profile is required'), 'Should throw proper error');
        }
        System.Test.stopTest();
    }
    
    /**
     * @description Test object config with no object API name (should throw error)
     */
    @isTest
    static void testSaveObjectConfiguration_NoObjectApiName() {
        Map<String, Object> objectConfigData = new Map<String, Object>{
            'configProfile' => 'Default',
            'allowedFieldsJson' => '["FirstName","LastName"]',
            'allowCreate' => true
        };
        String configJson = JSON.serialize(objectConfigData);
        
        System.Test.startTest();
        try {
            String result = mt_ConfigMetadataService.saveObjectConfiguration(configJson);
            Assert.fail('Should have thrown exception');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Object API Name is required'), 'Should throw proper error');
        }
        System.Test.stopTest();
    }
    
    /**
     * @description Test cloneFlowAndPrompt with valid inputs
     */
    @isTest
    static void testCloneFlowAndPrompt() {
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = mt_ConfigMetadataService.cloneFlowAndPrompt(
            'MT_Visit_Report_MultiModal',
            'MT_Voice_Account_MultiModal',
            'Custom_Visit_Report',
            'Custom Visit Report',
            'Custom_Voice_Prompt',
            'Custom Voice Prompt'
        );
        
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
        Assert.isTrue(result.containsKey('success'), 'Should contain success key');
    }
    
    /**
     * @description Test cloneFlowAndPrompt with blank names
     */
    @isTest
    static void testCloneFlowAndPrompt_BlankNames() {
        System.Test.startTest();
        
        Map<String, Object> result = mt_ConfigMetadataService.cloneFlowAndPrompt(
            'MT_Visit_Report_MultiModal',
            'MT_Voice_Account_MultiModal',
            '',
            'Custom Visit Report',
            '',
            'Custom Voice Prompt'
        );
        
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
        Assert.isFalse((Boolean)result.get('success'), 'Should fail with blank names');
        Assert.isTrue(((String)result.get('message')).contains('required'), 'Should have error message');
    }
    
    /**
     * @description Test checkDeploymentStatus with manual deployment
     */
    @isTest
    static void testCheckDeploymentStatus_Manual() {
        System.Test.startTest();
        
        Map<String, Object> result = mt_ConfigMetadataService.checkDeploymentStatus('PENDING_MANUAL_DEPLOYMENT');
        
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
        Assert.areEqual('manual', result.get('status'), 'Should be manual status');
    }
    
    /**
     * @description Test checkDeploymentStatus with actual deployment ID
     */
    @isTest
    static void testCheckDeploymentStatus_WithId() {
        System.Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = mt_ConfigMetadataService.checkDeploymentStatus('0Af000000000000AAA');
        
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return a result');
    }
    
    /**
     * @description Mock HTTP callout for testing
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/tooling/query')) {
                // Mock query response
                res.setBody('{"records":[{"Id":"0Af000000000000AAA","Status":"Succeeded","ErrorMessage":null}]}');
            } else if (req.getEndpoint().contains('/tooling/composite')) {
                // Mock composite response
                res.setBody('{"compositeResponse":[{"body":{"records":[{"Id":"300000000000000AAA","Metadata":{"label":"Test Flow"}}]}}]}');
            }
            
            return res;
        }
    }
}