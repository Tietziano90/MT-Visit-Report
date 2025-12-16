public with sharing class AgentforceDataService {
    
    /**
     * Check if an agent has voice capability by attempting bootstrap
     * This is the REAL test - if bootstrap succeeds, agent is voice-enabled!
     */
    @AuraEnabled(cacheable=false)
    public static Boolean checkVoiceCapability(String instanceUrl, String agentId) {
        try {
            String endpoint = instanceUrl + '/agentforce/bootstrap?agentid=' + agentId;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(5000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // If bootstrap succeeds (200), agent is voice-enabled
            return res.getStatusCode() == 200;
        } catch (Exception e) {
            System.debug('Voice check failed for agent ' + agentId + ': ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Get voice-enabled agents using Tooling API (Atlas__VoiceAgent planner type)
     * Falls back to template filter if Tooling API fails
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getAllBots() {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, Object>> botsList = new List<Map<String, Object>>();
        response.put('instanceUrl', URL.getOrgDomainUrl().toExternalForm());
        
        try {
            Set<String> voiceAgentDeveloperNames = new Set<String>();
            Boolean usedToolingApi = false;
            
            // STEP 1: Try Tooling API to find voice-enabled agents (PlannerType = Atlas__VoiceAgent)
            try {
                System.debug('🔍 Attempting Tooling API query for voice agents...');
                voiceAgentDeveloperNames = queryVoiceAgentsViaToolingApi();
                
                if (!voiceAgentDeveloperNames.isEmpty()) {
                    usedToolingApi = true;
                    System.debug('✅ Tooling API success! Found ' + voiceAgentDeveloperNames.size() + ' voice agents: ' + voiceAgentDeveloperNames);
                    response.put('detectionMethod', 'Tooling API - Atlas__VoiceAgent');
                } else {
                    System.debug('⚠️  Tooling API returned no voice agents, falling back to template filter...');
                }
            } catch (Exception e) {
                System.debug('❌ Tooling API failed: ' + e.getMessage() + ', falling back to template filter...');
            }
            
            // STEP 2: Query BotDefinitions - filter by voice agents OR template
            List<BotDefinition> botDefinitions;
            
            if (usedToolingApi && !voiceAgentDeveloperNames.isEmpty()) {
                // Query only the voice-enabled agents we found via Tooling API
                botDefinitions = [
                    SELECT Id, DeveloperName, MasterLabel, Description, Type, 
                           AgentType, AgentTemplate, LastModifiedDate
                    FROM BotDefinition
                    WHERE IsDeleted = false 
                    AND DeveloperName IN :voiceAgentDeveloperNames
                    ORDER BY MasterLabel
                ];
                System.debug('📊 Filtered to ' + botDefinitions.size() + ' voice agents via Tooling API results');
            } else {
                // Fallback: Query agents with Einstein Service Agent template
                botDefinitions = [
                    SELECT Id, DeveloperName, MasterLabel, Description, Type, 
                           AgentType, AgentTemplate, LastModifiedDate
                    FROM BotDefinition
                    WHERE IsDeleted = false 
                    AND AgentTemplate = 'SvcCopilotTmpl__EinsteinServiceAgent'
                    ORDER BY MasterLabel
                ];
                response.put('detectionMethod', 'SOQL - AgentTemplate Filter');
                System.debug('📊 Using template fallback, found ' + botDefinitions.size() + ' agents with SvcCopilotTmpl__EinsteinServiceAgent');
            }
            
            // STEP 3: Build response with version info
            for (BotDefinition bd : botDefinitions) {
                Map<String, Object> botInfo = new Map<String, Object>();
                botInfo.put('id', bd.Id);
                botInfo.put('developerName', bd.DeveloperName);
                botInfo.put('masterLabel', bd.MasterLabel);
                botInfo.put('description', bd.Description);
                botInfo.put('type', bd.Type);
                botInfo.put('agentType', bd.AgentType);
                botInfo.put('agentTemplate', bd.AgentTemplate);
                botInfo.put('lastModifiedDate', String.valueOf(bd.LastModifiedDate));
                botInfo.put('isVoiceEnabled', true); // All filtered agents are voice-enabled
                
                // Get active version
                List<BotVersion> activeVersions = [
                    SELECT Id, VersionNumber, Status
                    FROM BotVersion
                    WHERE BotDefinitionId = :bd.Id 
                    AND Status = 'Active'
                    ORDER BY VersionNumber DESC
                    LIMIT 1
                ];
                
                if (!activeVersions.isEmpty()) {
                    botInfo.put('activeVersionId', activeVersions[0].Id);
                    botInfo.put('activeVersionNumber', activeVersions[0].VersionNumber);
                } else {
                    // Fallback to latest version if no active version
                    List<BotVersion> latestVersions = [
                        SELECT Id, VersionNumber, Status
                        FROM BotVersion
                        WHERE BotDefinitionId = :bd.Id
                        ORDER BY VersionNumber DESC
                        LIMIT 1
                    ];
                    if (!latestVersions.isEmpty()) {
                        botInfo.put('activeVersionId', latestVersions[0].Id);
                        botInfo.put('activeVersionNumber', latestVersions[0].VersionNumber);
                    }
                }
                
                botsList.add(botInfo);
            }
            
            response.put('bots', botsList);
            response.put('count', botsList.size());
            System.debug('✅ Returning ' + botsList.size() + ' voice-enabled agents');
            
        } catch (Exception e) {
            response.put('error', e.getMessage());
            System.debug('❌ Error in getAllBots: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
        
        return response;
    }
    
    /**
     * Query voice agents via Tooling API using Named Credential
     * Returns set of DeveloperNames for agents with PlannerType = 'Atlas__VoiceAgent'
     */
    private static Set<String> queryVoiceAgentsViaToolingApi() {
        Set<String> voiceAgentNames = new Set<String>();
        
        try {
            // Step 1: Get OAuth token via Named Credential
            HttpRequest tokenReq = new HttpRequest();
            tokenReq.setEndpoint('callout:APITooling/services/oauth2/token');
            tokenReq.setMethod('POST');
            tokenReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            tokenReq.setBody('grant_type=client_credentials');
            
            Http http = new Http();
            HttpResponse tokenResp = http.send(tokenReq);
            
            if (tokenResp.getStatusCode() != 200) {
                System.debug('❌ Token request failed: ' + tokenResp.getStatusCode());
                return voiceAgentNames;
            }
            
            Map<String, Object> tokenData = (Map<String, Object>) JSON.deserializeUntyped(tokenResp.getBody());
            String accessToken = (String) tokenData.get('access_token');
            
            // Step 2: Query GenAiPlannerDefinition for voice agents
            String query = 'SELECT Id, DeveloperName, MasterLabel, PlannerType ' +
                          'FROM GenAiPlannerDefinition ' +
                          'WHERE PlannerType = \'Atlas__VoiceAgent\'';
            String encodedQuery = EncodingUtil.urlEncode(query, 'UTF-8');
            String endpoint = 'callout:APITooling/services/data/v65.0/tooling/query/?q=' + encodedQuery;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            HttpResponse resp = http.send(req);
            
            if (resp.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                List<Object> records = (List<Object>) result.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    String devName = (String) record.get('DeveloperName');
                    if (String.isNotBlank(devName)) {
                        voiceAgentNames.add(devName);
                    }
                }
            } else {
                System.debug('❌ Tooling API query failed: ' + resp.getStatusCode() + ' - ' + resp.getBody());
            }
            
        } catch (Exception e) {
            System.debug('❌ Tooling API exception: ' + e.getMessage());
        }
        
        return voiceAgentNames;
    }
}

