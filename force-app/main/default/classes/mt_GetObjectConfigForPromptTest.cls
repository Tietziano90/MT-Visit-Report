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
private class mt_GetObjectConfigForPromptTest {

    /**
     * @description Test successful config retrieval with existing config
     */
    @isTest
    static void testGetObjectConfigForPrompt_WithConfig() {
        // Create input
        mt_GetObjectConfigForPrompt.ConfigInput input = new mt_GetObjectConfigForPrompt.ConfigInput();
        input.configName = 'Default';
        
        List<mt_GetObjectConfigForPrompt.ConfigInput> inputs = new List<mt_GetObjectConfigForPrompt.ConfigInput>{ input };
        
        System.Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        System.Test.stopTest();
        
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
        
        System.Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        System.Test.stopTest();
        
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
        
        System.Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        System.Test.stopTest();
        
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
        
        System.Test.startTest();
        List<mt_GetObjectConfigForPrompt.ConfigOutput> outputs = mt_GetObjectConfigForPrompt.getObjectConfigForPrompt(inputs);
        System.Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should return one output');
        // Should still succeed with default config
        System.assertEquals(true, outputs[0].success, 'Should succeed with default');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with valid config name
     */
    @isTest
    static void testGetConfig_WithValidConfig() {
        System.Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('Default');
        System.Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Should be successful');
        System.assertNotEquals(null, result.get('allowedObjectsConfig'), 'Should have config string');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with null config name
     */
    @isTest
    static void testGetConfig_WithNullConfig() {
        System.Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig(null);
        System.Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should default to 'Default' config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with empty config name
     */
    @isTest
    static void testGetConfig_WithEmptyConfig() {
        System.Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('');
        System.Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should default to 'Default' config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
    
    /**
     * @description Test AuraEnabled getConfig method with non-existent config
     */
    @isTest
    static void testGetConfig_WithNonExistentConfig() {
        System.Test.startTest();
        Map<String, Object> result = mt_GetObjectConfigForPrompt.getConfig('NonExistent_' + System.now().getTime());
        System.Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should still succeed with default/fallback config
        System.assertEquals(true, result.get('success'), 'Should be successful');
    }
}