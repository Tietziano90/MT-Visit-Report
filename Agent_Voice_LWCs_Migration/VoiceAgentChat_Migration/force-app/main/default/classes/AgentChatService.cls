/**
 * Service class for Einstein AI Agent Chat API
 * Handles session creation, message sending, and agent listing
 */
public with sharing class AgentChatService {
    
    private static final String NAMED_CREDENTIAL = 'callout:APITooling';
    private static final String AGENT_API_BASE = 'https://api.salesforce.com/einstein/ai-agent/v1';
    
    /**
     * Wrapper class for Agent information
     */
    public class AgentInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String masterLabel;
        @AuraEnabled public String description;
        @AuraEnabled public String agentType;
    }
    
    /**
     * Wrapper class for Chat Session
     */
    public class ChatSession {
        @AuraEnabled public String sessionId;
        @AuraEnabled public String initialMessage;
    }
    
    /**
     * Wrapper class for Agent Response
     */
    public class AgentMessage {
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean isContentSafe;
        @AuraEnabled public List<Citation> citedReferences;
    }
    
    /**
     * Wrapper class for Citations
     */
    public class Citation {
        @AuraEnabled public String type;
        @AuraEnabled public String value;
    }
    
    /**
     * Get OAuth access token using Client Credentials flow
     */
    private static String getAccessToken() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + '/services/oauth2/token');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('grant_type=client_credentials');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            return (String)responseMap.get('access_token');
        } else {
            throw new AuraHandledException('Failed to obtain access token: ' + response.getBody());
        }
    }
    
    /**
     * Get instance URL
     */
    private static String getInstanceUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }
    
    /**
     * Get all available agents
     */
    @AuraEnabled(cacheable=false)
    public static List<AgentInfo> getAllAgents() {
        try {
            List<AgentInfo> agents = new List<AgentInfo>();
            
            List<BotDefinition> bots = [
                SELECT Id, MasterLabel, Description, AgentType, Type
                FROM BotDefinition
                WHERE IsDeleted = false
                AND AgentType != null
                ORDER BY MasterLabel
                LIMIT 50
            ];
            
            for (BotDefinition bot : bots) {
                AgentInfo info = new AgentInfo();
                info.id = bot.Id;
                info.masterLabel = bot.MasterLabel;
                info.description = bot.Description != null ? bot.Description : 'Agentforce Assistant';
                info.agentType = bot.AgentType != null ? bot.AgentType : bot.Type;
                agents.add(info);
            }
            
            return agents;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching agents: ' + e.getMessage());
        }
    }
    
    /**
     * Create a new chat session with an agent
     */
    @AuraEnabled
    public static ChatSession createSession(String agentId) {
        try {
            String accessToken = getAccessToken();
            String instanceUrl = getInstanceUrl();
            
            // Generate unique external session key
            String externalSessionKey = String.valueOf(Crypto.getRandomLong());
            
            // Build payload
            Map<String, Object> payload = new Map<String, Object>{
                'externalSessionKey' => externalSessionKey,
                'featureSupport' => 'Streaming',
                'streamingCapabilities' => new Map<String, Object>{
                    'chunkTypes' => new List<String>{'Text'}
                },
                'variables' => new List<Object>(),
                'bypassUser' => false,
                'instanceConfig' => new Map<String, Object>{
                    'endpoint' => instanceUrl
                }
            };
            
            // Create session
            HttpRequest request = new HttpRequest();
            request.setEndpoint(AGENT_API_BASE + '/agents/' + agentId + '/sessions');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                ChatSession session = new ChatSession();
                session.sessionId = (String)responseData.get('sessionId');
                
                // Extract initial message from agent
                List<Object> messages = (List<Object>)responseData.get('messages');
                if (messages != null && !messages.isEmpty()) {
                    Map<String, Object> firstMsg = (Map<String, Object>)messages[0];
                    if (firstMsg.get('type') == 'Inform') {
                        session.initialMessage = (String)firstMsg.get('message');
                    }
                }
                
                return session;
            } else {
                throw new AuraHandledException('Failed to create session: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error creating session: ' + e.getMessage());
        }
    }
    
    /**
     * Send a message to the agent and get response
     */
    @AuraEnabled
    public static List<AgentMessage> sendMessage(String sessionId, String messageText, Integer sequenceId) {
        try {
            System.debug('📤 Sending message - SessionId: ' + sessionId);
            System.debug('📤 Message: ' + messageText);
            System.debug('📤 Sequence ID: ' + sequenceId);
            
            String accessToken = getAccessToken();
            
            // Build message payload
            Map<String, Object> messagePayload = new Map<String, Object>{
                'sequenceId' => sequenceId,
                'type' => 'Text',
                'text' => messageText
            };
            
            Map<String, Object> payload = new Map<String, Object>{
                'message' => messagePayload
            };
            
            String requestBody = JSON.serialize(payload);
            System.debug('📤 Request body: ' + requestBody);
            
            // Send message
            HttpRequest request = new HttpRequest();
            String endpoint = AGENT_API_BASE + '/sessions/' + sessionId + '/messages';
            System.debug('📤 Endpoint: ' + endpoint);
            
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            System.debug('📥 Response status: ' + response.getStatusCode());
            System.debug('📥 Response body: ' + response.getBody());
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> messagesData = (List<Object>)responseData.get('messages');
                
                List<AgentMessage> messages = new List<AgentMessage>();
                
                if (messagesData != null) {
                    for (Object msgObj : messagesData) {
                        Map<String, Object> msgMap = (Map<String, Object>)msgObj;
                        
                        AgentMessage msg = new AgentMessage();
                        msg.id = (String)msgMap.get('id');
                        msg.type = (String)msgMap.get('type');
                        msg.message = (String)msgMap.get('message');
                        msg.isContentSafe = (Boolean)msgMap.get('isContentSafe');
                        
                        // Parse citations if present
                        List<Object> citationsData = (List<Object>)msgMap.get('citedReferences');
                        if (citationsData != null && !citationsData.isEmpty()) {
                            msg.citedReferences = new List<Citation>();
                            for (Object citObj : citationsData) {
                                Map<String, Object> citMap = (Map<String, Object>)citObj;
                                Citation cit = new Citation();
                                cit.type = (String)citMap.get('type');
                                cit.value = (String)citMap.get('value');
                                msg.citedReferences.add(cit);
                            }
                        }
                        
                        messages.add(msg);
                    }
                }
                
                return messages;
            } else {
                System.debug('❌ Failed to send message - Status: ' + response.getStatusCode());
                System.debug('❌ Response body: ' + response.getBody());
                throw new AuraHandledException('Failed to send message: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('❌ Exception in sendMessage: ' + e.getMessage());
            System.debug('❌ Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error sending message: ' + e.getMessage());
        }
    }
    
    /**
     * End a chat session
     */
    @AuraEnabled
    public static void endSession(String sessionId) {
        try {
            String accessToken = getAccessToken();
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(AGENT_API_BASE + '/sessions/' + sessionId);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() != 204 && response.getStatusCode() != 200) {
                System.debug('Warning: Session end returned status ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error ending session: ' + e.getMessage());
            // Don't throw - ending session is best-effort
        }
    }
}

