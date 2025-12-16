/**
 * ============================================================================
 * MT Einstein Transcribe Controller
 * ============================================================================
 * 
 * @description     Apex controller for Einstein Transcribe API integration.
 *                  Provides methods to authenticate and communicate with the
 *                  Einstein Transcribe service for speech-to-text functionality.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         November 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 * COPYRIGHT & CONFIDENTIALITY NOTICE
 * ============================================================================
 * © 2025 Salesforce, Inc. All rights reserved.
 * 
 * This code is the confidential and proprietary information of Salesforce, Inc.
 * It is intended solely for internal use within Salesforce.
 * 
 * DISTRIBUTION RESTRICTION: This code may NOT be shared externally or 
 * distributed outside of Salesforce without explicit written approval 
 * from Michael Tietze (mtietze@salesforce.com).
 * ============================================================================
 */
public with sharing class mt_TranscribeController {
    
    /**
     * @description Retrieves the Einstein Transcribe API base URL from custom metadata
     * @return String The base URL for Einstein Transcribe API calls
     */
    @AuraEnabled(cacheable=true)
    public static String getBaseUrl() {
        EinsteinTranscribeSettings__mdt settings = EinsteinTranscribeSettings__mdt.getInstance('Default');
        return settings.EinsteinTranscribeBaseURL__c;
    }
    
    /**
     * @description Returns the current org's My Domain URL
     *              Useful for configuring Named Credentials and displaying in Admin Settings
     * @return String The org's My Domain URL (e.g., https://mycompany.my.salesforce.com)
     */
    @AuraEnabled(cacheable=true)
    public static String getOrgDomainUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }
    
    /**
     * @description Obtains an OAuth access token for Einstein Transcribe API
     *              Uses Named Credential and client credentials flow
     * @return String The access token, or null if authentication fails
     */
    @AuraEnabled(cacheable=true)
    public static String getAccessToken() {
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:mt_EinsteinTranscribe/services/oauth2/token');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=client_credentials';
        request.setBody(body);
        
        Http http = new Http();
        HttpResponse response;
        
        try {
            response = http.send(request);
            
            if(response.getStatusCode() == 200){
                
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                if(responseMap.containsKey('access_token'))
                {
                    return (String)responseMap.get('access_token');
                }
                else
                {
                    String errorMessage = 'Access token not found in the response.';
                    Map<String, Object> logDetails = new Map<String, Object>();
                    logDetails.put('sourceClass', 'mt_TranscribeController');
                    logDetails.put('sourceFunction', 'getAccessToken');
                    logDetails.put('logMessage',errorMessage);
                    logDetails.put('timeTaken',  Limits.getCpuTime());
                    String logJsonString = JSON.serialize(logDetails);
                    logErrorAsync(logJsonString);
                }
            } else {
                String errorMessage = 'mt_EinsteinTranscribe received non-200 response. ' +
                    'Status: ' + response.getStatusCode() +
                    ', Body: ' + response.getBody();
                Map<String, Object> logDetails = new Map<String, Object>();
                logDetails.put('sourceClass', 'mt_TranscribeController');
                logDetails.put('sourceFunction', 'getAccessToken');
                logDetails.put('logMessage',errorMessage);
                logDetails.put('timeTaken',  Limits.getCpuTime());
                String logJsonString = JSON.serialize(logDetails);
                logErrorAsync(logJsonString);
            }
        } catch (Exception e) {
            Map<String, Object> logDetails = new Map<String, Object>();
            logDetails.put('sourceClass', 'mt_TranscribeController');
            logDetails.put('sourceFunction', 'getAccessToken');
            logDetails.put('logMessage',e.getMessage());
            logDetails.put('timeTaken', 0);
            String logJsonString = JSON.serialize(logDetails);
            logErrorAsync(logJsonString);
        }
        return null;
    }
    
    /**
     * @description Asynchronously logs errors for debugging purposes
     * @param logJsonString JSON string containing log details
     */
    @future
    public static void logErrorAsync(String logJsonString)
    {
        Map<String, Object> logDetails = (Map<String, Object>) JSON.deserializeUntyped(logJsonString);
        System.debug('mt_TranscribeController error log: ' + logDetails);
        // Extend here to log to a custom object if needed
    }
    
    /**
     * @description Finds the related Account ID for any given record
     *              Supports: Account, Contact, Opportunity, Case, Lead, Task, Event, and custom objects
     * @param recordId The ID of the record to find the related Account for
     * @return RelatedAccountResult containing accountId and accountName, or error info
     */
    @AuraEnabled
    public static RelatedAccountResult getRelatedAccount(String recordId) {
        RelatedAccountResult result = new RelatedAccountResult();
        
        if (String.isBlank(recordId)) {
            result.success = false;
            result.errorMessage = 'Record ID is required';
            return result;
        }
        
        try {
            // Get the object type from the record ID
            Id recId = Id.valueOf(recordId);
            String objectType = recId.getSObjectType().getDescribe().getName();
            
            System.debug('getRelatedAccount: Object type = ' + objectType + ' for recordId = ' + recordId);
            
            // Handle based on object type
            if (objectType == 'Account') {
                // It's already an Account
                Account acc = [SELECT Id, Name FROM Account WHERE Id = :recordId LIMIT 1];
                result.success = true;
                result.account = acc;
                result.accountId = acc.Id;
                result.accountName = acc.Name;
                result.objectType = objectType;
                
            } else if (objectType == 'Contact') {
                Contact con = [SELECT Id, AccountId, Account.Id, Account.Name FROM Contact WHERE Id = :recordId LIMIT 1];
                if (con.AccountId != null) {
                    result.success = true;
                    result.account = con.Account;
                    result.accountId = con.AccountId;
                    result.accountName = con.Account.Name;
                } else {
                    result.success = false;
                    result.errorMessage = 'Contact is not associated with an Account';
                }
                result.objectType = objectType;
                
            } else if (objectType == 'Opportunity') {
                Opportunity opp = [SELECT Id, AccountId, Account.Id, Account.Name FROM Opportunity WHERE Id = :recordId LIMIT 1];
                if (opp.AccountId != null) {
                    result.success = true;
                    result.account = opp.Account;
                    result.accountId = opp.AccountId;
                    result.accountName = opp.Account.Name;
                } else {
                    result.success = false;
                    result.errorMessage = 'Opportunity is not associated with an Account';
                }
                result.objectType = objectType;
                
            } else if (objectType == 'Case') {
                Case cs = [SELECT Id, AccountId, Account.Id, Account.Name FROM Case WHERE Id = :recordId LIMIT 1];
                if (cs.AccountId != null) {
                    result.success = true;
                    result.account = cs.Account;
                    result.accountId = cs.AccountId;
                    result.accountName = cs.Account.Name;
                } else {
                    result.success = false;
                    result.errorMessage = 'Case is not associated with an Account';
                }
                result.objectType = objectType;
                
            } else if (objectType == 'Lead') {
                // Leads don't have an Account, but might be converted
                Lead ld = [SELECT Id, Name, ConvertedAccountId, ConvertedAccount.Id, ConvertedAccount.Name, IsConverted FROM Lead WHERE Id = :recordId LIMIT 1];
                if (ld.IsConverted && ld.ConvertedAccountId != null) {
                    result.success = true;
                    result.account = ld.ConvertedAccount;
                    result.accountId = ld.ConvertedAccountId;
                    result.accountName = ld.ConvertedAccount.Name;
                } else {
                    result.success = false;
                    result.errorMessage = 'Lead is not converted to an Account yet';
                }
                result.objectType = objectType;
                
            } else if (objectType == 'Task' || objectType == 'Event') {
                // Tasks/Events use WhatId or WhoId
                SObject activity = Database.query('SELECT Id, WhatId, WhoId FROM ' + objectType + ' WHERE Id = :recordId LIMIT 1');
                Id whatId = (Id)activity.get('WhatId');
                Id whoId = (Id)activity.get('WhoId');
                
                if (whatId != null) {
                    String whatObjectType = whatId.getSObjectType().getDescribe().getName();
                    if (whatObjectType == 'Account') {
                        Account acc = [SELECT Id, Name FROM Account WHERE Id = :whatId LIMIT 1];
                        result.success = true;
                        result.account = acc;
                        result.accountId = acc.Id;
                        result.accountName = acc.Name;
                    } else if (whatObjectType == 'Opportunity') {
                        Opportunity opp = [SELECT Id, AccountId, Account.Id, Account.Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
                        if (opp.AccountId != null) {
                            result.success = true;
                            result.account = opp.Account;
                            result.accountId = opp.AccountId;
                            result.accountName = opp.Account.Name;
                        }
                    } else if (whatObjectType == 'Case') {
                        Case cs = [SELECT Id, AccountId, Account.Id, Account.Name FROM Case WHERE Id = :whatId LIMIT 1];
                        if (cs.AccountId != null) {
                            result.success = true;
                            result.account = cs.Account;
                            result.accountId = cs.AccountId;
                            result.accountName = cs.Account.Name;
                        }
                    }
                }
                
                // If not found via WhatId, try WhoId (Contact)
                if (!result.success && whoId != null) {
                    String whoObjectType = whoId.getSObjectType().getDescribe().getName();
                    if (whoObjectType == 'Contact') {
                        Contact con = [SELECT Id, AccountId, Account.Id, Account.Name FROM Contact WHERE Id = :whoId LIMIT 1];
                        if (con.AccountId != null) {
                            result.success = true;
                            result.account = con.Account;
                            result.accountId = con.AccountId;
                            result.accountName = con.Account.Name;
                        }
                    }
                }
                
                if (!result.success) {
                    result.errorMessage = objectType + ' is not associated with an Account';
                }
                result.objectType = objectType;
                
            } else {
                // Try to find AccountId field dynamically for custom objects
                result = findAccountDynamically(recordId, objectType);
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error finding related Account: ' + e.getMessage();
            System.debug('getRelatedAccount error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Dynamically finds Account relationship for custom objects
     * @param recordId The record ID
     * @param objectType The object API name
     * @return RelatedAccountResult with account info if found
     */
    private static RelatedAccountResult findAccountDynamically(String recordId, String objectType) {
        RelatedAccountResult result = new RelatedAccountResult();
        result.objectType = objectType;
        
        try {
            // Get object describe
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectType).getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            // Look for AccountId or Account__c field
            String accountFieldName = null;
            if (fieldMap.containsKey('AccountId')) {
                accountFieldName = 'AccountId';
            } else if (fieldMap.containsKey('Account__c')) {
                accountFieldName = 'Account__c';
            }
            
            if (accountFieldName != null) {
                String query = 'SELECT Id, ' + accountFieldName + ' FROM ' + objectType + ' WHERE Id = :recordId LIMIT 1';
                SObject record = Database.query(query);
                Id accountId = (Id)record.get(accountFieldName);
                
                if (accountId != null) {
                    Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
                    result.success = true;
                    result.account = acc;
                    result.accountId = acc.Id;
                    result.accountName = acc.Name;
                } else {
                    result.success = false;
                    result.errorMessage = objectType + ' has no Account associated';
                }
            } else {
                result.success = false;
                result.errorMessage = 'Object ' + objectType + ' does not have an Account relationship';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Could not find Account relationship: ' + e.getMessage();
        }
        
        return result;
    }
    
    // ==========================================================================
    // CONFIGURATION MANAGEMENT
    // ==========================================================================
    
    /**
     * @description Retrieves a Voice Assistant configuration by name
     * @param configName The DeveloperName of the configuration (e.g., 'Default', 'Sales_Config')
     * @return VoiceAssistantConfigResult containing configuration details
     */
    @AuraEnabled(cacheable=true)
    public static VoiceAssistantConfigResult getConfig(String configName) {
        VoiceAssistantConfigResult result = new VoiceAssistantConfigResult();
        
        try {
            String safeName = String.isBlank(configName) ? 'Default' : configName;
            MT_VoiceAssistantConfig__mdt config = MT_VoiceAssistantConfig__mdt.getInstance(safeName);
            
            if (config == null) {
                // Fallback to Default if specified config not found
                config = MT_VoiceAssistantConfig__mdt.getInstance('Default');
            }
            
            if (config != null) {
                result.success = true;
                result.configName = config.DeveloperName;
                result.provider = config.TranscriptionProvider__c;
                result.promptTemplateName = config.PromptTemplateName__c;
                result.einsteinNamedCredential = config.EinsteinNamedCredential__c;
                result.whisperNamedCredential = config.WhisperNamedCredential__c;
                result.whisperModel = config.WhisperModel__c;
                result.isActive = config.IsActive__c;
                result.description = config.Description__c;
                result.enableImageInput = config.EnableImageInput__c == true;
                result.showProviderSelector = config.ShowProviderSelector__c == true;
            } else {
                result.success = false;
                result.errorMessage = 'No configuration found. Please create a Default configuration.';
            }
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Error loading configuration: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Get all available configuration profiles
     * @return List of configuration names and details
     */
    @AuraEnabled
    public static List<VoiceAssistantConfigResult> getAllConfigs() {
        List<VoiceAssistantConfigResult> results = new List<VoiceAssistantConfigResult>();
        
        for (MT_VoiceAssistantConfig__mdt config : [
            SELECT DeveloperName, MasterLabel, TranscriptionProvider__c, PromptTemplateName__c,
                   EinsteinNamedCredential__c, WhisperNamedCredential__c, WhisperModel__c,
                   IsActive__c, Description__c
            FROM MT_VoiceAssistantConfig__mdt
            ORDER BY MasterLabel
        ]) {
            VoiceAssistantConfigResult result = new VoiceAssistantConfigResult();
            result.success = true;
            result.configName = config.DeveloperName;
            result.label = config.MasterLabel;
            result.provider = config.TranscriptionProvider__c;
            result.promptTemplateName = config.PromptTemplateName__c;
            result.einsteinNamedCredential = config.EinsteinNamedCredential__c;
            result.whisperNamedCredential = config.WhisperNamedCredential__c;
            result.whisperModel = config.WhisperModel__c;
            result.isActive = config.IsActive__c;
            result.description = config.Description__c;
            results.add(result);
        }
        
        return results;
    }
    
    // ==========================================================================
    // OPENAI WHISPER TRANSCRIPTION
    // ==========================================================================
    
    /**
     * @description Transcribe audio using OpenAI Whisper API
     * @param audioBase64 Base64-encoded audio data
     * @param configName Configuration profile name to use
     * @return TranscriptionResult with transcribed text or error
     */
    @AuraEnabled
    public static TranscriptionResult transcribeWithWhisper(String audioBase64, String configName) {
        TranscriptionResult result = new TranscriptionResult();
        
        try {
            // Get configuration
            VoiceAssistantConfigResult config = getConfig(configName);
            if (!config.success) {
                result.success = false;
                result.errorMessage = config.errorMessage;
                return result;
            }
            
            // Get API key from Custom Settings or check External Credential
            String apiKey = getOpenAIApiKey();
            
            // Build the request
            String namedCredential = String.isNotBlank(config.whisperNamedCredential) 
                ? config.whisperNamedCredential 
                : 'mt_OpenAI_Whisper';
            String model = String.isNotBlank(config.whisperModel) ? config.whisperModel : 'whisper-1';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + namedCredential + '/v1/audio/transcriptions');
            req.setMethod('POST');
            req.setTimeout(120000); // 2 minute timeout for audio processing
            
            // Create multipart form data
            String boundary = '----WebKitFormBoundary' + String.valueOf(DateTime.now().getTime());
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
            
            // Build multipart body
            Blob audioBlob = EncodingUtil.base64Decode(audioBase64);
            String body = buildMultipartBody(boundary, audioBlob, model);
            req.setBodyAsBlob(Blob.valueOf(body));
            
            // Note: Authorization header is set by Named Credential
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.success = true;
                result.transcription = (String) responseMap.get('text');
            } else {
                result.success = false;
                result.errorMessage = 'Whisper API error: ' + res.getStatusCode() + ' - ' + res.getBody();
                logErrorAsync(JSON.serialize(new Map<String, Object>{
                    'sourceClass' => 'mt_TranscribeController',
                    'sourceFunction' => 'transcribeWithWhisper',
                    'logMessage' => result.errorMessage,
                    'timeTaken' => Limits.getCpuTime()
                }));
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Whisper transcription failed: ' + e.getMessage();
            logErrorAsync(JSON.serialize(new Map<String, Object>{
                'sourceClass' => 'mt_TranscribeController',
                'sourceFunction' => 'transcribeWithWhisper',
                'logMessage' => e.getMessage(),
                'timeTaken' => Limits.getCpuTime()
            }));
        }
        
        return result;
    }
    
    /**
     * @description Build multipart form body for Whisper API
     * @param boundary The boundary string
     * @param audioBlob The audio data
     * @param model The Whisper model to use
     * @return String multipart form body
     */
    private static String buildMultipartBody(String boundary, Blob audioBlob, String model) {
        String body = '';
        
        // File field
        body += '--' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="file"; filename="audio.webm"\r\n';
        body += 'Content-Type: audio/webm\r\n\r\n';
        body += EncodingUtil.base64Encode(audioBlob) + '\r\n';
        
        // Model field
        body += '--' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="model"\r\n\r\n';
        body += model + '\r\n';
        
        // Response format
        body += '--' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="response_format"\r\n\r\n';
        body += 'json\r\n';
        
        body += '--' + boundary + '--\r\n';
        
        return body;
    }
    
    /**
     * @description Get OpenAI API key from Custom Settings
     * @return String The API key or null if not set
     */
    private static String getOpenAIApiKey() {
        MT_VoiceAssistantSecrets__c secrets = MT_VoiceAssistantSecrets__c.getOrgDefaults();
        return secrets != null ? secrets.OpenAI_API_Key__c : null;
    }
    
    // ==========================================================================
    // ADMIN SETTINGS METHODS
    // ==========================================================================
    
    /**
     * @description Check if current user has admin access to Voice Assistant settings
     * @return Boolean true if user is System Administrator or has custom permission
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isAdminUser() {
        // Check for System Administrator profile (handles localized profile names)
        Profile userProfile = [
            SELECT Name, PermissionsModifyAllData, PermissionsViewSetup 
            FROM Profile 
            WHERE Id = :UserInfo.getProfileId() 
            LIMIT 1
        ];
        
        // System Administrator has ModifyAllData and ViewSetup permissions
        // This is more reliable than checking the profile name (which may be localized)
        if (userProfile.PermissionsModifyAllData && userProfile.PermissionsViewSetup) {
            return true;
        }
        
        // Also check for common System Administrator profile names (for orgs without those permissions)
        if (userProfile.Name == 'System Administrator' || 
            userProfile.Name == 'Systemadministrator' ||  // German
            userProfile.Name == 'Administrateur système' || // French
            userProfile.Name == '系统管理员') {  // Chinese
            return true;
        }
        
        // Check for custom permission (can be assigned via Permission Set)
        return FeatureManagement.checkPermission('mt_VoiceAssistant_Admin');
    }
    
    /**
     * @description Save OpenAI API key to Custom Settings
     * @param apiKey The API key to save
     * @return Boolean true if save was successful
     */
    @AuraEnabled
    public static Boolean saveOpenAIApiKey(String apiKey) {
        try {
            MT_VoiceAssistantSecrets__c secrets = MT_VoiceAssistantSecrets__c.getOrgDefaults();
            if (secrets == null) {
                secrets = new MT_VoiceAssistantSecrets__c();
            }
            secrets.OpenAI_API_Key__c = apiKey;
            upsert secrets;
            return true;
        } catch (Exception e) {
            System.debug('Error saving API key: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Test Einstein API connection
     * @return ConnectionTestResult with status and message
     */
    @AuraEnabled
    public static ConnectionTestResult testEinsteinConnection() {
        ConnectionTestResult result = new ConnectionTestResult();
        
        try {
            String token = getAccessToken();
            if (String.isNotBlank(token)) {
                result.success = true;
                result.message = 'Einstein API connection successful';
            } else {
                result.success = false;
                result.message = 'Failed to obtain access token. Check Named Credential configuration.';
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Connection error: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Test OpenAI Whisper API connection
     * @return ConnectionTestResult with status and message
     */
    @AuraEnabled
    public static ConnectionTestResult testWhisperConnection() {
        ConnectionTestResult result = new ConnectionTestResult();
        
        try {
            // Simple request to verify credentials
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:mt_OpenAI_Whisper/v1/models');
            req.setMethod('GET');
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                result.success = true;
                result.message = 'OpenAI Whisper API connection successful';
            } else {
                result.success = false;
                result.message = 'API returned status ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Connection error: ' + e.getMessage();
        }
        
        return result;
    }
    
    // ==========================================================================
    // OBJECT CONFIGURATION METHODS
    // ==========================================================================
    
    /**
     * @description Get object configurations for a specific configuration profile
     * @param configName The configuration profile name (e.g., 'Default', 'Sales_Config')
     * @return List of object configurations
     */
    @AuraEnabled
    public static List<ObjectConfigResult> getObjectConfigs(String configName) {
        List<ObjectConfigResult> results = new List<ObjectConfigResult>();
        String safeName = String.isBlank(configName) ? 'Default' : configName;
        
        for (MT_VoiceAssistantObjectConfig__mdt config : [
            SELECT DeveloperName, MasterLabel, ConfigProfile__c, ObjectApiName__c,
                   AllowedFields__c, MandatoryFields__c, AllowCreate__c, AllowEdit__c
            FROM MT_VoiceAssistantObjectConfig__mdt
            WHERE ConfigProfile__c = :safeName
            ORDER BY ObjectApiName__c
        ]) {
            ObjectConfigResult result = new ObjectConfigResult();
            result.developerName = config.DeveloperName;
            result.label = config.MasterLabel;
            result.configProfile = config.ConfigProfile__c;
            result.objectApiName = config.ObjectApiName__c;
            result.allowedFieldsJson = config.AllowedFields__c;
            result.mandatoryFieldsJson = config.MandatoryFields__c;
            result.allowCreate = config.AllowCreate__c;
            result.allowEdit = config.AllowEdit__c;
            
            // Parse JSON arrays
            if (String.isNotBlank(config.AllowedFields__c)) {
                result.allowedFields = (List<Object>) JSON.deserializeUntyped(config.AllowedFields__c);
            }
            if (String.isNotBlank(config.MandatoryFields__c)) {
                result.mandatoryFields = (List<Object>) JSON.deserializeUntyped(config.MandatoryFields__c);
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Get object configuration for a specific object within a profile
     * @param configName The configuration profile name
     * @param objectApiName The object API name (e.g., 'Opportunity')
     * @return ObjectConfigResult with configuration details
     */
    @AuraEnabled(cacheable=true)
    public static ObjectConfigResult getObjectConfig(String configName, String objectApiName) {
        String safeName = String.isBlank(configName) ? 'Default' : configName;
        
        List<MT_VoiceAssistantObjectConfig__mdt> configs = [
            SELECT DeveloperName, MasterLabel, ConfigProfile__c, ObjectApiName__c,
                   AllowedFields__c, MandatoryFields__c, AllowCreate__c, AllowEdit__c
            FROM MT_VoiceAssistantObjectConfig__mdt
            WHERE ConfigProfile__c = :safeName AND ObjectApiName__c = :objectApiName
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            return null;
        }
        
        MT_VoiceAssistantObjectConfig__mdt config = configs[0];
        ObjectConfigResult result = new ObjectConfigResult();
        result.developerName = config.DeveloperName;
        result.label = config.MasterLabel;
        result.configProfile = config.ConfigProfile__c;
        result.objectApiName = config.ObjectApiName__c;
        result.allowedFieldsJson = config.AllowedFields__c;
        result.mandatoryFieldsJson = config.MandatoryFields__c;
        result.allowCreate = config.AllowCreate__c;
        result.allowEdit = config.AllowEdit__c;
        
        // Parse JSON arrays
        if (String.isNotBlank(config.AllowedFields__c)) {
            result.allowedFields = (List<Object>) JSON.deserializeUntyped(config.AllowedFields__c);
        }
        if (String.isNotBlank(config.MandatoryFields__c)) {
            result.mandatoryFields = (List<Object>) JSON.deserializeUntyped(config.MandatoryFields__c);
        }
        
        return result;
    }
    
    /**
     * @description Get list of available standard and custom objects
     * @return List of object options with label and value
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableObjects() {
        List<Map<String, String>> objects = new List<Map<String, String>>();
        
        // Define common objects to include
        Set<String> includedObjects = new Set<String>{
            'Account', 'Contact', 'Opportunity', 'Lead', 'Case', 'Task', 'Event',
            'Campaign', 'Contract', 'Order', 'Product2', 'Quote'
        };
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for (String objName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objName).getDescribe();
            
            // Include if it's a standard object we want, or a custom object
            Boolean isIncludedStandard = includedObjects.contains(objDescribe.getName());
            Boolean isCustom = objDescribe.isCustom() && !objDescribe.getName().endsWith('__mdt') && !objDescribe.getName().endsWith('__c');
            Boolean isAccessibleCustom = objDescribe.isCustom() && objDescribe.getName().endsWith('__c') && objDescribe.isAccessible() && objDescribe.isCreateable();
            
            if ((isIncludedStandard || isAccessibleCustom) && objDescribe.isAccessible()) {
                Map<String, String> obj = new Map<String, String>();
                obj.put('value', objDescribe.getName());
                obj.put('label', objDescribe.getLabel());
                objects.add(obj);
            }
        }
        
        // Sort by label using a simple bubble sort since List<Map> doesn't implement Comparable
        for (Integer i = 0; i < objects.size() - 1; i++) {
            for (Integer j = 0; j < objects.size() - i - 1; j++) {
                String label1 = objects[j].get('label');
                String label2 = objects[j + 1].get('label');
                if (label1 != null && label2 != null && label1.compareTo(label2) > 0) {
                    Map<String, String> temp = objects[j];
                    objects[j] = objects[j + 1];
                    objects[j + 1] = temp;
                }
            }
        }
        
        return objects;
    }
    
    /**
     * @description Get available prompt templates from the org
     * @return List of prompt template options
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailablePromptTemplates() {
        List<Map<String, String>> templates = new List<Map<String, String>>();
        
        try {
            // Query GenAiPromptTemplate using Tooling API
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String query = 'SELECT Id, DeveloperName, MasterLabel FROM GenAiPromptTemplate WHERE Status = \'Published\' ORDER BY MasterLabel';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/v59.0/tooling/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) response.get('records');
                
                if (records != null) {
                    for (Object record : records) {
                        Map<String, Object> rec = (Map<String, Object>) record;
                        Map<String, String> template = new Map<String, String>();
                        template.put('name', String.valueOf(rec.get('DeveloperName')));
                        template.put('label', String.valueOf(rec.get('MasterLabel')));
                        templates.add(template);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error fetching prompt templates: ' + e.getMessage());
        }
        
        // Always include the default template if list is empty
        if (templates.isEmpty()) {
            Map<String, String> defaultTemplate = new Map<String, String>();
            defaultTemplate.put('name', 'MT_Voice_Record_Suggestion');
            defaultTemplate.put('label', 'MT Voice Record Suggestion');
            templates.add(defaultTemplate);
        }
        
        return templates;
    }
    
    /**
     * @description Get field information for a specific object
     * @param objectApiName The API name of the object
     * @return Map containing object info and list of fields
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getObjectDescribe(String objectApiName) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                result.put('success', false);
                result.put('errorMessage', 'Object not found: ' + objectApiName);
                return result;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
            result.put('success', true);
            result.put('objectApiName', objDescribe.getName());
            result.put('objectLabel', objDescribe.getLabel());
            result.put('isCreateable', objDescribe.isCreateable());
            result.put('isUpdateable', objDescribe.isUpdateable());
            
            // Get fields
            List<Map<String, Object>> fields = new List<Map<String, Object>>();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Skip system fields and non-accessible fields
                if (!fieldDescribe.isAccessible()) continue;
                if (fieldName.toLowerCase() == 'id') continue;
                
                // Include updateable fields and name fields
                if (fieldDescribe.isUpdateable() || fieldDescribe.isNameField() || fieldDescribe.isCreateable()) {
                    Map<String, Object> field = new Map<String, Object>();
                    field.put('value', fieldDescribe.getName());
                    field.put('label', fieldDescribe.getLabel());
                    field.put('type', String.valueOf(fieldDescribe.getType()));
                    field.put('isRequired', !fieldDescribe.isNillable() && fieldDescribe.isCreateable());
                    field.put('isCreateable', fieldDescribe.isCreateable());
                    field.put('isUpdateable', fieldDescribe.isUpdateable());
                    fields.add(field);
                }
            }
            
            result.put('fields', fields);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('errorMessage', 'Error describing object: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get page layouts for an object with their fields
     * @param objectApiName The API name of the object
     * @return Map containing layouts and their fields
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getObjectLayouts(String objectApiName) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(objectApiName)) {
                result.put('success', false);
                result.put('errorMessage', 'Object API name is required');
                return result;
            }
            
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                result.put('success', false);
                result.put('errorMessage', 'Object not found: ' + objectApiName);
                return result;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
            // Get all record types for the object
            Map<Id, Schema.RecordTypeInfo> recordTypes = objDescribe.getRecordTypeInfosById();
            
            // Get all fields for reference
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            // Build layout options
            List<Map<String, Object>> layoutOptions = new List<Map<String, Object>>();
            
            // Add "All Createable Fields" option
            Map<String, Object> allFieldsOption = new Map<String, Object>();
            allFieldsOption.put('value', 'ALL_CREATEABLE');
            allFieldsOption.put('label', 'All Createable Fields');
            allFieldsOption.put('description', 'Include all fields that can be created on this object');
            layoutOptions.add(allFieldsOption);
            
            // Add "All Updateable Fields" option
            Map<String, Object> updateableOption = new Map<String, Object>();
            updateableOption.put('value', 'ALL_UPDATEABLE');
            updateableOption.put('label', 'All Updateable Fields');
            updateableOption.put('description', 'Include all fields that can be updated on this object');
            layoutOptions.add(updateableOption);
            
            // Add "Required Fields Only" option
            Map<String, Object> requiredOption = new Map<String, Object>();
            requiredOption.put('value', 'REQUIRED_ONLY');
            requiredOption.put('label', 'Required Fields Only');
            requiredOption.put('description', 'Include only required/mandatory fields');
            layoutOptions.add(requiredOption);
            
            // Add "Common Fields" option - most commonly used fields
            Map<String, Object> commonOption = new Map<String, Object>();
            commonOption.put('value', 'COMMON_FIELDS');
            commonOption.put('label', 'Common Fields');
            commonOption.put('description', 'Include commonly used fields (Name, standard lookup fields, etc.)');
            layoutOptions.add(commonOption);
            
            result.put('success', true);
            result.put('objectApiName', objectApiName);
            result.put('layoutOptions', layoutOptions);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('errorMessage', 'Error fetching layouts: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get fields based on a layout/field selection option
     * @param objectApiName The API name of the object
     * @param layoutOption The layout option (ALL_CREATEABLE, ALL_UPDATEABLE, REQUIRED_ONLY, COMMON_FIELDS)
     * @return List of field API names
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldsForLayout(String objectApiName, String layoutOption) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(objectApiName)) {
                result.put('success', false);
                result.put('errorMessage', 'Object API name is required');
                return result;
            }
            
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                result.put('success', false);
                result.put('errorMessage', 'Object not found: ' + objectApiName);
                return result;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            List<String> selectedFields = new List<String>();
            List<String> requiredFields = new List<String>();
            
            // Define common fields for standard objects
            Set<String> commonFieldNames = new Set<String>{
                'name', 'firstname', 'lastname', 'email', 'phone', 'title',
                'accountid', 'amount', 'closedate', 'stagename', 'description',
                'subject', 'activitydate', 'status', 'priority', 'type',
                'company', 'leadsource', 'industry', 'website'
            };
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                String fieldApiName = fieldDescribe.getName();
                String fieldNameLower = fieldApiName.toLowerCase();
                
                // Skip system fields
                if (fieldNameLower == 'id' || fieldNameLower == 'isdeleted' || 
                    fieldNameLower == 'systemmodstamp' || fieldNameLower == 'createdbyid' ||
                    fieldNameLower == 'createddate' || fieldNameLower == 'lastmodifiedbyid' ||
                    fieldNameLower == 'lastmodifieddate') {
                    continue;
                }
                
                if (!fieldDescribe.isAccessible()) continue;
                
                Boolean isRequired = !fieldDescribe.isNillable() && fieldDescribe.isCreateable();
                Boolean isCreateable = fieldDescribe.isCreateable();
                Boolean isUpdateable = fieldDescribe.isUpdateable();
                Boolean isCommon = commonFieldNames.contains(fieldNameLower);
                
                // Track required fields
                if (isRequired) {
                    requiredFields.add(fieldApiName);
                }
                
                // Apply filter based on option
                if (layoutOption == 'ALL_CREATEABLE' && isCreateable) {
                    selectedFields.add(fieldApiName);
                } else if (layoutOption == 'ALL_UPDATEABLE' && isUpdateable) {
                    selectedFields.add(fieldApiName);
                } else if (layoutOption == 'REQUIRED_ONLY' && isRequired) {
                    selectedFields.add(fieldApiName);
                } else if (layoutOption == 'COMMON_FIELDS' && (isCommon || isRequired) && (isCreateable || isUpdateable)) {
                    selectedFields.add(fieldApiName);
                }
            }
            
            result.put('success', true);
            result.put('objectApiName', objectApiName);
            result.put('layoutOption', layoutOption);
            result.put('fields', selectedFields);
            result.put('requiredFields', requiredFields);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('errorMessage', 'Error fetching fields: ' + e.getMessage());
        }
        
        return result;
    }
    
    // ==========================================================================
    // AUTOMATED SETUP HELPERS
    // ==========================================================================
    
    /**
     * @description Automatically assigns both Voice Assistant permission sets to all System Administrators.
     *              This automates Step 1 of the setup process by assigning to all admins in the org.
     * @return Map with success status and message
     */
    @AuraEnabled
    public static Map<String, Object> assignPermissionSetsToCurrentUser() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get the System Administrator profile
            Profile sysAdminProfile = [
                SELECT Id 
                FROM Profile 
                WHERE Name = 'System Administrator' 
                LIMIT 1
            ];
            
            // Get all active System Administrator users
            List<User> sysAdminUsers = [
                SELECT Id, Name 
                FROM User 
                WHERE ProfileId = :sysAdminProfile.Id 
                AND IsActive = true
            ];
            
            if (sysAdminUsers.isEmpty()) {
                result.put('success', false);
                result.put('message', 'No active System Administrator users found.');
                return result;
            }
            
            // Get the permission sets we want to assign
            List<PermissionSet> permSets = [
                SELECT Id, Name, Label 
                FROM PermissionSet 
                WHERE Name IN ('mt_VoiceAssistant_User', 'mt_VoiceAssistant_Admin')
            ];
            
            if (permSets.isEmpty()) {
                result.put('success', false);
                result.put('message', 'Permission sets not found. Please ensure they are deployed.');
                return result;
            }
            
            // Get existing assignments for all sys admin users
            Set<Id> userIds = new Set<Id>();
            for (User u : sysAdminUsers) {
                userIds.add(u.Id);
            }
            
            Map<Id, Set<Id>> userToAssignedPermSets = new Map<Id, Set<Id>>();
            for (PermissionSetAssignment psa : [
                SELECT AssigneeId, PermissionSetId 
                FROM PermissionSetAssignment 
                WHERE AssigneeId IN :userIds 
                AND PermissionSetId IN :permSets
            ]) {
                if (!userToAssignedPermSets.containsKey(psa.AssigneeId)) {
                    userToAssignedPermSets.put(psa.AssigneeId, new Set<Id>());
                }
                userToAssignedPermSets.get(psa.AssigneeId).add(psa.PermissionSetId);
            }
            
            // Assign missing permission sets
            List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
            Integer totalAssignments = 0;
            Integer usersUpdated = 0;
            
            for (User u : sysAdminUsers) {
                Set<Id> assignedPermSets = userToAssignedPermSets.get(u.Id);
                if (assignedPermSets == null) {
                    assignedPermSets = new Set<Id>();
                }
                
                Boolean userNeedsAssignment = false;
                for (PermissionSet ps : permSets) {
                    if (!assignedPermSets.contains(ps.Id)) {
                        toInsert.add(new PermissionSetAssignment(
                            AssigneeId = u.Id,
                            PermissionSetId = ps.Id
                        ));
                        totalAssignments++;
                        userNeedsAssignment = true;
                    }
                }
                
                if (userNeedsAssignment) {
                    usersUpdated++;
                }
            }
            
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
            
            // Build result message
            String message = '';
            if (totalAssignments > 0) {
                message = 'Successfully assigned permission sets to ' + usersUpdated + ' System Administrator(s). ' +
                         'Total assignments: ' + totalAssignments + '.';
            } else {
                message = 'All ' + sysAdminUsers.size() + ' System Administrator(s) already have the required permission sets assigned.';
            }
            
            result.put('success', true);
            result.put('message', message);
            result.put('assignedCount', totalAssignments);
            result.put('usersUpdated', usersUpdated);
            result.put('totalAdmins', sysAdminUsers.size());
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error assigning permission sets: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Checks if the current user has the required permission sets assigned.
     * @return Map with permission set status
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> checkPermissionSetStatus() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // Get all required permission sets
            Map<String, Boolean> permSetStatus = new Map<String, Boolean>{
                'mt_Einstein_Transcribe' => false,
                'mt_VoiceAssistant_Admin' => false
            };
            
            // Check which are assigned
            for (PermissionSetAssignment psa : [
                SELECT PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :currentUserId 
                AND PermissionSet.Name IN ('mt_Einstein_Transcribe', 'mt_VoiceAssistant_Admin')
            ]) {
                permSetStatus.put(psa.PermissionSet.Name, true);
            }
            
            result.put('success', true);
            result.put('permissionSets', permSetStatus);
            result.put('allAssigned', !permSetStatus.values().contains(false));
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Updates the Named Credential URL to match the current org's domain.
     *              This automates Step 4 of the setup process.
     *              Note: Requires Metadata API access which may not be available in all contexts.
     * @return Map with success status and message
     */
    @AuraEnabled
    public static Map<String, Object> updateNamedCredentialUrl() {
        Map<String, Object> result = new Map<String, Object>();
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        
        try {
            // Check current Named Credential URL
            List<NamedCredential> namedCreds = [
                SELECT Id, DeveloperName, Endpoint 
                FROM NamedCredential 
                WHERE DeveloperName = 'mt_EinsteinTranscribe' 
                LIMIT 1
            ];
            
            if (namedCreds.isEmpty()) {
                result.put('success', false);
                result.put('message', 'Named Credential "mt_EinsteinTranscribe" not found. Please deploy it first.');
                return result;
            }
            
            String currentUrl = namedCreds[0].Endpoint;
            
            // Check if already correct
            if (currentUrl != null && currentUrl.equals(orgUrl)) {
                result.put('success', true);
                result.put('message', 'Named Credential URL is already set correctly to: ' + orgUrl);
                result.put('alreadyCorrect', true);
                return result;
            }
            
            // Unfortunately, NamedCredential.Endpoint is not directly updateable via DML
            // It requires Metadata API deployment. We'll inform the user.
            result.put('success', false);
            result.put('message', 'Named Credential URL cannot be updated programmatically. Please update it manually in Setup. Current: ' + (currentUrl != null ? currentUrl : '(not set)') + ' → Required: ' + orgUrl);
            result.put('currentUrl', currentUrl);
            result.put('requiredUrl', orgUrl);
            result.put('requiresManualUpdate', true);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error checking Named Credential: ' + e.getMessage());
        }
        
        return result;
    }
    
    // ==========================================================================
    // SETUP NAVIGATION HELPERS
    // ==========================================================================
    
    /**
     * @description Gets direct URLs to setup components for easier configuration.
     *              Returns URLs to Named Credential, External Credential, Connected App, and Permission Sets.
     * @return Map containing setup URLs and component IDs
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSetupUrls() {
        Map<String, Object> result = new Map<String, Object>();
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String setupBaseUrl = baseUrl.replace('.my.salesforce.com', '.my.salesforce-setup.com');
        
        // Store org domain for Named Credential update
        result.put('orgDomainUrl', baseUrl);
        
        try {
            // Get Named Credential ID and details
            List<NamedCredential> namedCreds = [
                SELECT Id, DeveloperName, MasterLabel, Endpoint 
                FROM NamedCredential 
                WHERE DeveloperName = 'mt_EinsteinTranscribe' 
                LIMIT 1
            ];
            if (!namedCreds.isEmpty()) {
                String ncId = namedCreds[0].Id;
                result.put('namedCredentialId', ncId);
                result.put('namedCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/page?address=%2F' + ncId);
                result.put('namedCredentialName', namedCreds[0].MasterLabel);
                result.put('namedCredentialEndpoint', namedCreds[0].Endpoint);
                // Check if endpoint needs update
                result.put('namedCredentialNeedsUpdate', !String.valueOf(namedCreds[0].Endpoint).contains(baseUrl.substringAfter('https://')));
            } else {
                result.put('namedCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/home');
            }
            
            // Query Connected Application to get IDs for proper URLs
            List<ConnectedApplication> connApps = [
                SELECT Id, Name 
                FROM ConnectedApplication 
                WHERE Name = 'MT Einstein Transcribe' OR Name = 'mt_EinsteinTranscribe'
                LIMIT 1
            ];
            if (!connApps.isEmpty()) {
                String connAppId = connApps[0].Id; // This is the 0H4... ID
                result.put('connectedAppId', connAppId);
                result.put('connectedAppName', connApps[0].Name);
                
                // Step 2: View Connected App details (to get Consumer Key/Secret)
                // URL pattern: /lightning/setup/ConnectedApplication/page?address=%2Fapp%2Fmgmt%2Fforceconnectedapps%2FforceAppDetail.apexp%3FconnectedAppId%3D{id}
                String viewUrl = baseUrl + '/lightning/setup/ConnectedApplication/page?address=' + 
                    EncodingUtil.urlEncode('/app/mgmt/forceconnectedapps/forceAppDetail.apexp?connectedAppId=' + connAppId + '&retURL=/setup/NavigationMenus/home', 'UTF-8');
                result.put('connectedAppViewUrl', viewUrl);
                
                // Step 3: Manage/Edit Connected App (for Client Credentials Flow)
                // URL pattern: /lightning/setup/ConnectedApplication/page?address=%2F{id}%2Fe (edit mode)
                String manageUrl = baseUrl + '/lightning/setup/ConnectedApplication/page?address=' + 
                    EncodingUtil.urlEncode('/' + connAppId + '/e?retURL=/' + connAppId, 'UTF-8');
                result.put('connectedAppManageUrl', manageUrl);
                
                // Fallback URL (App Manager list)
                result.put('connectedAppUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
            } else {
                result.put('connectedAppUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
                result.put('connectedAppViewUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
                result.put('connectedAppManageUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
            }
            
            // Try to get External Credential ID via Tooling API callout
            String extCredId = getExternalCredentialId('mt_EinsteinTranscribe');
            if (String.isNotBlank(extCredId)) {
                result.put('externalCredentialId', extCredId);
                // Direct URL to External Credential view
                result.put('externalCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/ExternalCredential/' + extCredId + '/view');
            } else {
                // Fallback to External Credentials tab
                result.put('externalCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/home');
            }
            
            // Get Permission Set IDs - these are queryable
            List<PermissionSet> permSets = [
                SELECT Id, Name, Label 
                FROM PermissionSet 
                WHERE Name IN ('mt_Einstein_Transcribe', 'mt_VoiceAssistant_Admin')
                ORDER BY Name
            ];
            
            if (!permSets.isEmpty()) {
                List<Map<String, String>> permSetList = new List<Map<String, String>>();
                for (PermissionSet ps : permSets) {
                    Map<String, String> psInfo = new Map<String, String>();
                    psInfo.put('id', ps.Id);
                    psInfo.put('name', ps.Name);
                    psInfo.put('label', ps.Label);
                    psInfo.put('url', baseUrl + '/lightning/setup/PermSets/page?address=%2F' + ps.Id);
                    permSetList.add(psInfo);
                }
                result.put('permissionSets', permSetList);
                result.put('permissionSetUrl', baseUrl + '/lightning/setup/PermSets/page?address=%2F' + permSets[0].Id);
            } else {
                result.put('permissionSetUrl', baseUrl + '/lightning/setup/PermSets/home');
            }
            
            result.put('userPermSetAssignUrl', baseUrl + '/lightning/setup/ManageUsers/home');
            result.put('success', true);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('errorMessage', e.getMessage());
            // Fallback to generic URLs
            result.put('namedCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/home');
            result.put('externalCredentialUrl', baseUrl + '/lightning/setup/NamedCredential/home');
            result.put('connectedAppUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
            result.put('connectedAppViewUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
            result.put('connectedAppManageUrl', baseUrl + '/lightning/setup/ConnectedApplication/home');
            result.put('permissionSetUrl', baseUrl + '/lightning/setup/PermSets/home');
        }
        
        return result;
    }
    
    /**
     * @description Get External Credential ID using Tooling API
     * @param developerName The developer name of the External Credential
     * @return The External Credential ID or null if not found
     */
    private static String getExternalCredentialId(String developerName) {
        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String query = 'SELECT Id FROM ExternalCredential WHERE DeveloperName = \'' + developerName + '\' LIMIT 1';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/v59.0/tooling/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                if (records != null && !records.isEmpty()) {
                    Map<String, Object> record = (Map<String, Object>) records[0];
                    return (String) record.get('Id');
                }
            }
        } catch (Exception e) {
            System.debug('Error getting External Credential ID: ' + e.getMessage());
        }
        return null;
    }
    
    // ==========================================================================
    // WRAPPER CLASSES
    // ==========================================================================
    
    /**
     * @description Wrapper class for object configuration results
     */
    public class ObjectConfigResult {
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
        @AuraEnabled public String configProfile;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String allowedFieldsJson;
        @AuraEnabled public String mandatoryFieldsJson;
        @AuraEnabled public List<Object> allowedFields;
        @AuraEnabled public List<Object> mandatoryFields;
        @AuraEnabled public Boolean allowCreate;
        @AuraEnabled public Boolean allowEdit;
    }
    
    /**
     * @description Wrapper class for related account lookup results
     */
    public class RelatedAccountResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public Account account;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String objectType;
        @AuraEnabled public String errorMessage;
    }
    
    /**
     * @description Wrapper class for Voice Assistant configuration
     */
    public class VoiceAssistantConfigResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String configName;
        @AuraEnabled public String label;
        @AuraEnabled public String provider;
        @AuraEnabled public String promptTemplateName;
        @AuraEnabled public String einsteinNamedCredential;
        @AuraEnabled public String whisperNamedCredential;
        @AuraEnabled public String whisperModel;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean enableImageInput = false;
        @AuraEnabled public Boolean showProviderSelector = false;
        @AuraEnabled public String errorMessage;
    }
    
    /**
     * @description Wrapper class for transcription results
     */
    public class TranscriptionResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String transcription;
        @AuraEnabled public String errorMessage;
    }
    
    /**
     * @description Wrapper class for connection test results
     */
    public class ConnectionTestResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String message;
    }
}