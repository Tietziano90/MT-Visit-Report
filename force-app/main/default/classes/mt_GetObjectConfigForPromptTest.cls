/**
 * ============================================================================
 * MT Get Object Config For Prompt Test
 * ============================================================================
 * 
 * @description     Test class for mt_GetObjectConfigForPrompt invocable action.
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
public class mt_GetObjectConfigForPromptTest {

    /**
     * @description Test successful config retrieval with existing config
     */
    @isTest
    static void testGetObjectConfigForPrompt_WithConfig() {
        // Create input
        mt_GetObjectConfigForPrompt.ConfigInput input = new mt_GetObjectConfigForPrompt.ConfigInput();
        input.configName = 'Default';
        
        List<mt_GetObjectConfigForPrompt.ConfigInput> inputs = new List<mt_GetObjectConfigForPrompt.ConfigInput>{ input };
        
        Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should return one output');
        System.assertEquals(true, outputs[0].success, 'Should be successful');
        System.assertNotEquals(null, outputs[0].allowedObjectsConfig, 'Should have config string');
    }

    /**
     * @description Test config retrieval with non-existent config (returns default)
     */
    @isTest
    static void testGetObjectConfigForPrompt_NoConfig() {
        mt_GetObjectConfigForPrompt.ConfigInput input = new mt_GetObjectConfigForPrompt.ConfigInput();
        input.configName = 'NonExistentConfig_' + System.now().getTime();
        
        List<mt_GetObjectConfigForPrompt.ConfigInput> inputs = new List<mt_GetObjectConfigForPrompt.ConfigInput>{ input };
        
        Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should return one output');
        System.assertEquals(true, outputs[0].success, 'Should be successful with default config');
        System.assert(outputs[0].allowedObjectsConfig.contains('ALLOWED OBJECTS'), 'Should contain default config text');
    }

    /**
     * @description Test multiple inputs
     */
    @isTest
    static void testGetObjectConfigForPrompt_MultipleInputs() {
        mt_GetObjectConfigForPrompt.ConfigInput input1 = new mt_GetObjectConfigForPrompt.ConfigInput();
        input1.configName = 'Default';
        
        mt_GetObjectConfigForPrompt.ConfigInput input2 = new mt_GetObjectConfigForPrompt.ConfigInput();
        input2.configName = 'Default';
        
        List<mt_GetObjectConfigForPrompt.ConfigInput> inputs = new List<mt_GetObjectConfigForPrompt.ConfigInput>{ input1, input2 };
        
        Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        Test.stopTest();
        
        System.assertEquals(2, outputs.size(), 'Should return two outputs');
    }

    /**
     * @description Test empty config name
     */
    @isTest
    static void testGetObjectConfigForPrompt_EmptyConfigName() {
        mt_GetObjectConfigForPrompt.ConfigInput input = new mt_GetObjectConfigForPrompt.ConfigInput();
        input.configName = '';
        
        List<mt_GetObjectConfigForPrompt.ConfigInput> inputs = new List<mt_GetObjectConfigForPrompt.ConfigInput>{ input };
        
        Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should return one output');
        // Should still succeed with default config
        System.assertEquals(true, outputs[0].success, 'Should succeed with default');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with valid config name
     */
    @isTest
    static void testGetConfig_WithValidConfig() {
        Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('Default');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Should be successful');
        System.assertNotEquals(null, result.get('allowedObjectsConfig'), 'Should have config string');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with null config name
     */
    @isTest
    static void testGetConfig_WithNullConfig() {
        Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should default to 'Default' config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with empty config name
     */
    @isTest
    static void testGetConfig_WithEmptyConfig() {
        Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should default to 'Default' config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with non-existent config
     */
    @isTest
    static void testGetConfig_WithNonExistentConfig() {
        Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('NonExistent_' + System.now().getTime());
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should still succeed with default/fallback config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
}