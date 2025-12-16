/**
 * ============================================================================
 * MT Config Metadata Service
 * ============================================================================
 * 
 * @description     Service class for creating and updating Custom Metadata
 *                  records via the Metadata API. Allows in-app management
 *                  of Voice Assistant configuration profiles.
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
public with sharing class mt_ConfigMetadataService {
    
    /**
     * @description Creates or updates a Voice Assistant configuration record
     * @param configData JSON string containing configuration data
     * @return String Job ID for the deployment (for reference)
     */
    @AuraEnabled
    public static String saveConfiguration(String configData) {
        try {
            Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(configData);
            
            String developerName = (String) config.get('developerName');
            String label = (String) config.get('label');
            String provider = (String) config.get('provider');
            String promptTemplateName = (String) config.get('promptTemplateName');
            String einsteinNamedCredential = (String) config.get('einsteinNamedCredential');
            String whisperNamedCredential = (String) config.get('whisperNamedCredential');
            String whisperModel = (String) config.get('whisperModel');
            Boolean isActive = config.get('isActive') != null ? (Boolean) config.get('isActive') : true;
            String description = (String) config.get('description');
            
            // Validate developer name
            if (String.isBlank(developerName)) {
                throw new AuraHandledException('Developer Name is required');
            }
            
            // Create the Custom Metadata record
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'MT_VoiceAssistantConfig__mdt.' + developerName;
            customMetadata.label = String.isNotBlank(label) ? label : developerName;
            
            // Add field values
            customMetadata.values.add(createFieldValue('TranscriptionProvider__c', provider));
            customMetadata.values.add(createFieldValue('PromptTemplateName__c', promptTemplateName));
            customMetadata.values.add(createFieldValue('EinsteinNamedCredential__c', 
                String.isNotBlank(einsteinNamedCredential) ? einsteinNamedCredential : 'mt_EinsteinTranscribe'));
            customMetadata.values.add(createFieldValue('WhisperNamedCredential__c', 
                String.isNotBlank(whisperNamedCredential) ? whisperNamedCredential : 'mt_OpenAI_Whisper'));
            customMetadata.values.add(createFieldValue('WhisperModel__c', 
                String.isNotBlank(whisperModel) ? whisperModel : 'whisper-1'));
            customMetadata.values.add(createFieldValue('IsActive__c', isActive));
            customMetadata.values.add(createFieldValue('Description__c', description));
            
            // Create deployment container
            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(customMetadata);
            
            // Deploy asynchronously
            Id jobId = Metadata.Operations.enqueueDeployment(container, new ConfigDeployCallback());
            
            return String.valueOf(jobId);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates or updates a Voice Assistant object configuration record
     * @param objectConfigData JSON string containing object configuration data
     * @return String Job ID for the deployment (for reference)
     */
    @AuraEnabled
    public static String saveObjectConfiguration(String objectConfigData) {
        try {
            Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(objectConfigData);
            
            String configProfile = (String) config.get('configProfile');
            String objectApiName = (String) config.get('objectApiName');
            List<Object> allowedFields = (List<Object>) config.get('allowedFields');
            List<Object> mandatoryFields = (List<Object>) config.get('mandatoryFields');
            Boolean allowCreate = config.get('allowCreate') != null ? (Boolean) config.get('allowCreate') : true;
            Boolean allowEdit = config.get('allowEdit') != null ? (Boolean) config.get('allowEdit') : true;
            
            // Validate required fields
            if (String.isBlank(configProfile)) {
                throw new AuraHandledException('Configuration Profile is required');
            }
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object API Name is required');
            }
            
            // Generate developer name: ConfigProfile_ObjectName
            String developerName = configProfile + '_' + objectApiName.replace('__c', '').replace('__mdt', '');
            String label = configProfile + ' - ' + objectApiName;
            
            // Create the Custom Metadata record
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'MT_VoiceAssistantObjectConfig__mdt.' + developerName;
            customMetadata.label = label;
            
            // Add field values
            customMetadata.values.add(createFieldValue('ConfigProfile__c', configProfile));
            customMetadata.values.add(createFieldValue('ObjectApiName__c', objectApiName));
            customMetadata.values.add(createFieldValue('AllowedFields__c', 
                allowedFields != null ? JSON.serialize(allowedFields) : '[]'));
            customMetadata.values.add(createFieldValue('MandatoryFields__c', 
                mandatoryFields != null ? JSON.serialize(mandatoryFields) : '[]'));
            customMetadata.values.add(createFieldValue('AllowCreate__c', allowCreate));
            customMetadata.values.add(createFieldValue('AllowEdit__c', allowEdit));
            
            // Create deployment container
            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(customMetadata);
            
            // Deploy asynchronously
            Id jobId = Metadata.Operations.enqueueDeployment(container, new ConfigDeployCallback());
            
            return String.valueOf(jobId);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving object configuration: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to create a Custom Metadata field value
     */
    private static Metadata.CustomMetadataValue createFieldValue(String fieldName, Object value) {
        Metadata.CustomMetadataValue fieldValue = new Metadata.CustomMetadataValue();
        fieldValue.field = fieldName;
        fieldValue.value = value;
        return fieldValue;
    }
    
    /**
     * @description Callback class for metadata deployment
     */
    public class ConfigDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('Configuration deployment succeeded');
            } else {
                System.debug('Configuration deployment failed: ' + result.errorMessage);
            }
        }
    }
    
    // ==========================================================================
    // FLOW & PROMPT TEMPLATE CLONING
    // ==========================================================================
    
    /**
     * @description Clones an existing Flow and Prompt Template with new names
     * @param sourceFlowName The API name of the source Flow to clone
     * @param sourcePromptName The API name of the source Prompt Template to clone
     * @param newFlowName The API name for the new Flow
     * @param newFlowLabel The label for the new Flow
     * @param newPromptName The API name for the new Prompt Template
     * @param newPromptLabel The label for the new Prompt Template
     * @return Map containing job IDs and status
     */
    @AuraEnabled
    public static Map<String, Object> cloneFlowAndPrompt(
        String sourceFlowName, 
        String sourcePromptName,
        String newFlowName,
        String newFlowLabel,
        String newPromptName,
        String newPromptLabel
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Validate inputs
            if (String.isBlank(newFlowName) || String.isBlank(newPromptName)) {
                throw new AuraHandledException('New Flow and Prompt names are required');
            }
            
            // Sanitize names (remove spaces, special chars)
            newFlowName = sanitizeApiName(newFlowName);
            newPromptName = sanitizeApiName(newPromptName);
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            // Step 1: Get the source Flow definition
            String flowBody = getFlowDefinition(baseUrl, sourceFlowName);
            if (String.isBlank(flowBody)) {
                throw new AuraHandledException('Could not retrieve source Flow: ' + sourceFlowName);
            }
            
            // Step 2: Get the source Prompt Template definition
            String promptBody = getPromptTemplateDefinition(baseUrl, sourcePromptName);
            if (String.isBlank(promptBody)) {
                throw new AuraHandledException('Could not retrieve source Prompt Template: ' + sourcePromptName);
            }
            
            // Step 3: Modify the Flow to use the new prompt template name
            String modifiedFlowBody = flowBody
                .replace('<label>' + getFlowLabel(flowBody) + '</label>', '<label>' + newFlowLabel + '</label>')
                .replace('<interviewLabel>' + sourceFlowName, '<interviewLabel>' + newFlowName)
                .replace('actionName>' + sourcePromptName + '<', 'actionName>' + newPromptName + '<')
                .replace('nameSegment>' + sourcePromptName + '<', 'nameSegment>' + newPromptName + '<');
            
            // Step 4: Modify the Prompt Template
            String modifiedPromptBody = promptBody
                .replace('<masterLabel>' + getPromptLabel(promptBody) + '</masterLabel>', '<masterLabel>' + newPromptLabel + '</masterLabel>');
            
            // Step 5: Deploy both using Metadata API via REST
            String deployResult = deployFlowAndPrompt(baseUrl, newFlowName, modifiedFlowBody, newPromptName, modifiedPromptBody);
            
            result.put('success', true);
            result.put('message', 'Flow and Prompt Template cloning initiated. Deployment ID: ' + deployResult);
            result.put('deploymentId', deployResult);
            result.put('newFlowName', newFlowName);
            result.put('newPromptName', newPromptName);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error cloning: ' + e.getMessage());
            System.debug('Clone error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Retrieves a Flow definition via Tooling API
     */
    private static String getFlowDefinition(String baseUrl, String flowName) {
        try {
            // Query for the Flow
            String query = 'SELECT Id, Definition FROM Flow WHERE Definition.DeveloperName = \'' + flowName + '\' AND Status = \'Active\' ORDER BY VersionNumber DESC LIMIT 1';
            
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
                
                if (records != null && !records.isEmpty()) {
                    Map<String, Object> record = (Map<String, Object>) records[0];
                    String flowId = (String) record.get('Id');
                    
                    // Now get the full Flow definition XML
                    return retrieveFlowMetadata(baseUrl, flowName);
                }
            }
        } catch (Exception e) {
            System.debug('Error getting Flow definition: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * @description Retrieves Flow metadata XML via Metadata API REST
     */
    private static String retrieveFlowMetadata(String baseUrl, String flowName) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/v59.0/tooling/sobjects/Flow/?q=DeveloperName=\'' + flowName + '\'');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            
            // Use composite request to get the Flow body
            String compositeBody = '{"allOrNone": false, "compositeRequest": [' +
                '{"method": "GET", "url": "/services/data/v59.0/tooling/query?q=' + 
                EncodingUtil.urlEncode('SELECT Id, FullName, Metadata FROM FlowDefinition WHERE DeveloperName = \'' + flowName + '\'', 'UTF-8') + 
                '", "referenceId": "flowDef"}]}';
            
            HttpRequest compReq = new HttpRequest();
            compReq.setEndpoint(baseUrl + '/services/data/v59.0/tooling/composite');
            compReq.setMethod('POST');
            compReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            compReq.setHeader('Content-Type', 'application/json');
            compReq.setBody(compositeBody);
            
            Http http = new Http();
            HttpResponse res = http.send(compReq);
            
            if (res.getStatusCode() == 200) {
                // Parse and extract the flow metadata
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> compositeResponse = (List<Object>) response.get('compositeResponse');
                
                if (compositeResponse != null && !compositeResponse.isEmpty()) {
                    Map<String, Object> flowDefResponse = (Map<String, Object>) compositeResponse[0];
                    Map<String, Object> body = (Map<String, Object>) flowDefResponse.get('body');
                    List<Object> records = (List<Object>) body.get('records');
                    
                    if (records != null && !records.isEmpty()) {
                        Map<String, Object> flowDef = (Map<String, Object>) records[0];
                        Map<String, Object> metadata = (Map<String, Object>) flowDef.get('Metadata');
                        return JSON.serialize(metadata);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error retrieving Flow metadata: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * @description Retrieves a Prompt Template definition via Tooling API
     */
    private static String getPromptTemplateDefinition(String baseUrl, String promptName) {
        try {
            String query = 'SELECT Id, DeveloperName, MasterLabel, TemplateContent FROM GenAiPromptTemplate WHERE DeveloperName = \'' + promptName + '\' LIMIT 1';
            
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
                
                if (records != null && !records.isEmpty()) {
                    return JSON.serialize(records[0]);
                }
            }
        } catch (Exception e) {
            System.debug('Error getting Prompt Template definition: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * @description Deploys Flow and Prompt Template via Metadata API
     */
    private static String deployFlowAndPrompt(String baseUrl, String flowName, String flowBody, String promptName, String promptBody) {
        // For now, we'll create a simple deployment using REST Metadata API
        // This is a simplified version - full implementation would use proper Metadata API deploy
        
        try {
            // Create a deployment request
            // Note: Full implementation requires creating a zip with package.xml
            // For MVP, we'll guide users to use the manual approach
            
            return 'PENDING_MANUAL_DEPLOYMENT';
        } catch (Exception e) {
            throw new AuraHandledException('Deployment error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Extracts the label from Flow XML
     */
    private static String getFlowLabel(String flowBody) {
        // Simple extraction - in production, use proper XML parsing
        Integer start = flowBody.indexOf('<label>') + 7;
        Integer endIdx = flowBody.indexOf('</label>');
        if (start > 6 && endIdx > start) {
            return flowBody.substring(start, endIdx);
        }
        return 'MT Visit Report';
    }
    
    /**
     * @description Extracts the label from Prompt Template
     */
    private static String getPromptLabel(String promptBody) {
        // Extract MasterLabel from JSON
        try {
            Map<String, Object> prompt = (Map<String, Object>) JSON.deserializeUntyped(promptBody);
            return (String) prompt.get('MasterLabel');
        } catch (Exception e) {
            return 'MT Voice Record Suggestion';
        }
    }
    
    /**
     * @description Sanitizes a string to be a valid API name
     */
    private static String sanitizeApiName(String input) {
        if (String.isBlank(input)) return input;
        // Replace spaces with underscores, remove special characters
        return input.replaceAll('[^a-zA-Z0-9_]', '_').replaceAll('_+', '_');
    }
    
    /**
     * @description Check deployment status
     */
    @AuraEnabled
    public static Map<String, Object> checkDeploymentStatus(String deploymentId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (deploymentId == 'PENDING_MANUAL_DEPLOYMENT') {
                result.put('status', 'manual');
                result.put('message', 'Manual deployment required. Please use Setup to clone the Flow and Prompt Template.');
                return result;
            }
            
            // Query deployment status via Tooling API
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String query = 'SELECT Id, Status, ErrorMessage FROM DeployRequest WHERE Id = \'' + deploymentId + '\'';
            
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
                
                if (records != null && !records.isEmpty()) {
                    Map<String, Object> record = (Map<String, Object>) records[0];
                    result.put('status', record.get('Status'));
                    result.put('errorMessage', record.get('ErrorMessage'));
                }
            }
            
            result.put('success', true);
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', e.getMessage());
        }
        
        return result;
    }
}