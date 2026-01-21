/**
 * ============================================================================
 * MT Get Object Config For Prompt - Invocable Action
 * ============================================================================
 * 
 * @description     Invocable Apex action for Flow that retrieves object and
 *                  field configurations for a given profile and formats them
 *                  as a string to be used in AI Prompt Templates.
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
public with sharing class mt_GetObjectConfigForPrompt {
    
    /**
     * @description Input wrapper for the invocable method
     */
    public class ConfigInput {
        @InvocableVariable(label='Configuration Profile Name' description='The developer name of the configuration profile (e.g., Default)' required=true)
        public String configName;
    }
    
    /**
     * @description Output wrapper for the invocable method
     */
    public class ConfigOutput {
        @InvocableVariable(label='Allowed Objects Configuration' description='Formatted string describing allowed objects and their fields for the AI prompt')
        public String allowedObjectsConfig;
        
        @InvocableVariable(label='Success' description='Whether the configuration was retrieved successfully')
        public Boolean success;
        
        @InvocableVariable(label='Error Message' description='Error message if retrieval failed')
        public String errorMessage;
    }
    
    /**
     * @description Invocable method to get object configurations formatted for prompt
     * @param inputs List of ConfigInput containing the configuration profile name
     * @return List of ConfigOutput containing the formatted configuration string
     */
    @InvocableMethod(label='Get Object Config for Prompt' description='Retrieves allowed objects and fields for a configuration profile, formatted for use in AI prompts' category='MT Voice Assistant')
    public static List<ConfigOutput> getObjectConfigForPrompt(List<ConfigInput> inputs) {
        List<ConfigOutput> outputs = new List<ConfigOutput>();
        
        for (ConfigInput input : inputs) {
            ConfigOutput output = new ConfigOutput();
            
            try {
                // Get all object configurations for this profile
                List<MT_VoiceAssistantObjectConfig__mdt> configs = [
                    SELECT DeveloperName, ObjectApiName__c, AllowedFields__c, MandatoryFields__c,
                           AllowCreate__c, AllowEdit__c
                    FROM MT_VoiceAssistantObjectConfig__mdt
                    WHERE ConfigProfile__c = :input.configName
                    ORDER BY ObjectApiName__c
                ];
                
                if (configs.isEmpty()) {
                    // No specific config - return default message
                    output.allowedObjectsConfig = buildDefaultConfig();
                    output.success = true;
                } else {
                    output.allowedObjectsConfig = buildConfigString(configs);
                    output.success = true;
                }
                
            } catch (Exception e) {
                output.success = false;
                output.errorMessage = e.getMessage();
                output.allowedObjectsConfig = buildDefaultConfig();
            }
            
            outputs.add(output);
        }
        
        return outputs;
    }
    
    /**
     * @description Builds a formatted configuration string from the object configs
     * @param configs List of object configuration metadata records
     * @return Formatted string for the prompt
     */
    private static String buildConfigString(List<MT_VoiceAssistantObjectConfig__mdt> configs) {
        List<String> sections = new List<String>();
        
        for (MT_VoiceAssistantObjectConfig__mdt config : configs) {
            List<String> objectSection = new List<String>();
            
            // Object header with permissions
            String permissions = '';
            List<String> perms = new List<String>();
            if (config.AllowCreate__c) perms.add('CREATE');
            if (config.AllowEdit__c) perms.add('UPDATE');
            permissions = String.join(perms, ', ');
            
            objectSection.add('### ' + config.ObjectApiName__c + ' (' + permissions + ')');
            
            // Get field metadata for this object
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(config.ObjectApiName__c)?.getDescribe()?.fields?.getMap();
            
            // Allowed fields with detailed metadata
            if (String.isNotBlank(config.AllowedFields__c) && fieldMap != null) {
                try {
                    List<Object> fields = (List<Object>) JSON.deserializeUntyped(config.AllowedFields__c);
                    List<String> fieldDetails = new List<String>();
                    
                    objectSection.add('\n**Allowed Fields:**');
                    for (Object f : fields) {
                        String fieldApiName = String.valueOf(f);
                        Schema.SObjectField field = fieldMap.get(fieldApiName.toLowerCase());
                        
                        if (field != null) {
                            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                            String fieldDetail = '- **' + fieldApiName + '** (' + fieldDescribe.getLabel() + ')';
                            fieldDetail += ' - Type: ' + fieldDescribe.getType();
                            
                            // Add picklist values if applicable
                            if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || 
                                fieldDescribe.getType() == Schema.DisplayType.COMBOBOX) {
                                List<String> picklistLabels = new List<String>();
                                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                                    if (entry.isActive()) {
                                        picklistLabels.add(entry.getLabel());
                                    }
                                }
                                if (!picklistLabels.isEmpty()) {
                                    fieldDetail += ' - Options: ' + String.join(picklistLabels, ', ');
                                }
                            }
                            
                            // Mark required fields
                            if (!fieldDescribe.isNillable() && fieldDescribe.isCreateable()) {
                                fieldDetail += ' - **REQUIRED**';
                            }
                            
                            fieldDetails.add(fieldDetail);
                        } else {
                            fieldDetails.add('- **' + fieldApiName + '**');
                        }
                    }
                    objectSection.add(String.join(fieldDetails, '\n'));
                } catch (Exception e) {
                    objectSection.add('**Allowed Fields:** ' + config.AllowedFields__c);
                }
            }
            
            // Mandatory fields (must always be included in suggestions)
            if (String.isNotBlank(config.MandatoryFields__c)) {
                try {
                    List<Object> fields = (List<Object>) JSON.deserializeUntyped(config.MandatoryFields__c);
                    List<String> fieldStrings = new List<String>();
                    for (Object f : fields) {
                        fieldStrings.add(String.valueOf(f));
                    }
                    objectSection.add('\n**Required Fields (always include):** ' + String.join(fieldStrings, ', '));
                } catch (Exception e) {
                    objectSection.add('\n**Required Fields:** ' + config.MandatoryFields__c);
                }
            }
            
            sections.add(String.join(objectSection, '\n'));
        }
        
        String header = '## ALLOWED OBJECTS & FIELDS CONFIGURATION\n\n';
        header += 'You may ONLY suggest records for the following objects with the specified fields.\n';
        header += 'Always include the Required Fields even if not explicitly mentioned in the transcript.\n\n';
        header += '**IMPORTANT INSTRUCTIONS FOR PICKLIST FIELDS:**\n';
        header += '- For picklist fields, you MUST use the exact picklist VALUE (not the label) in your JSON output\n';
        header += '- The picklist options listed show the LABELS that users see, but you must map them to their API values\n';
        header += '- Example: If you see "Options: Open, In Progress, Closed" for Status field, and the transcript says "in progress", use the exact API value like "In Progress" or "InProgress" depending on the picklist configuration\n';
        header += '- When in doubt, use the label as shown in the options list\n\n';
        
        return header + String.join(sections, '\n\n');
    }
    
    /**
     * @description Returns a default configuration when no specific config exists
     * @return Default configuration string
     */
    private static String buildDefaultConfig() {
        return '## ALLOWED OBJECTS & FIELDS CONFIGURATION\n\n' +
               'No specific field restrictions configured. You may suggest:\n' +
               '- **Contact:** FirstName, LastName, Email, Phone, Title, AccountId\n' +
               '- **Opportunity:** Name, Amount, CloseDate, StageName, AccountId, NextStep, Description\n' +
               '- **Task:** Subject, ActivityDate, Description, WhatId, WhoId, Priority, Status\n' +
               '- **Event:** Subject, StartDateTime, EndDateTime, Description, WhatId, WhoId, Location\n\n' +
               'Always include required fields for record creation (e.g., LastName for Contact, Name/StageName/CloseDate for Opportunity).';
    }
    
    /**
     * @description AuraEnabled method for LWC to get config preview
     * @param configName The configuration profile name
     * @return Map containing the allowedObjectsConfig and success status
     */
    @AuraEnabled
    public static Map<String, Object> getConfig(String configName) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            ConfigInput input = new ConfigInput();
            input.configName = String.isBlank(configName) ? 'Default' : configName;
            
            List<ConfigOutput> outputs = getObjectConfigForPrompt(new List<ConfigInput>{ input });
            
            if (!outputs.isEmpty()) {
                result.put('allowedObjectsConfig', outputs[0].allowedObjectsConfig);
                result.put('success', outputs[0].success);
                result.put('errorMessage', outputs[0].errorMessage);
            } else {
                result.put('success', false);
                result.put('errorMessage', 'No output returned');
            }
        } catch (Exception e) {
            result.put('success', false);
            result.put('errorMessage', e.getMessage());
        }
        
        return result;
    }
}