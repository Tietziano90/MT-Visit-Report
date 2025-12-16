/**
 * Controller for Agentforce Voice LWC
 * Handles API calls to bootstrap, create sessions, and join voice sessions
 */
public with sharing class AgentforceVoiceController {
    
    /**
     * Get the bootstrap JWT token for voice API
     */
    @AuraEnabled
    public static Map<String, Object> getBootstrapToken(String instanceUrl, String agentId) {
        try {
            String endpoint = instanceUrl + '/agentforce/bootstrap?agentid=' + agentId;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(10000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return new Map<String, Object>{
                    'success' => true,
                    'access_token' => result.get('access_token'),
                    'jwt' => result.get('jwt')
                };
            } else {
                return new Map<String, Object>{
                    'success' => false,
                    'error' => 'Bootstrap failed: ' + res.getStatus() + ' - ' + res.getBody()
                };
            }
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }
    
    /**
     * Create a new voice session
     */
    @AuraEnabled
    public static Map<String, Object> createSession(String voiceJwt, String agentId, String versionId, String instanceUrl) {
        try {
            String endpoint = 'https://api.salesforce.com/einstein/ai-agent/v1.1/agents/' + agentId + '/sessions';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + voiceJwt);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-agent-mode', 'preview');
            req.setHeader('x-agent-version-id', versionId);
            req.setTimeout(10000);
            
            Map<String, Object> payload = new Map<String, Object>{
                'externalSessionKey' => 'session_' + String.valueOf(System.currentTimeMillis()),
                'instanceConfig' => new Map<String, String>{ 'endpoint' => instanceUrl },
                'tz' => 'UTC',
                'variables' => new List<Object>(),
                'featureSupport' => 'Streaming',
                'streamingCapabilities' => new Map<String, Object>{ 'chunkTypes' => new List<String>{ 'Text' } },
                'bypassUser' => true
            };
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String sessionId = (String) (result.containsKey('sessionId') ? result.get('sessionId') : result.get('id'));
                
                return new Map<String, Object>{
                    'success' => true,
                    'sessionId' => sessionId
                };
            } else {
                return new Map<String, Object>{
                    'success' => false,
                    'error' => 'Create session failed: ' + res.getStatus() + ' - ' + res.getBody()
                };
            }
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }
    
    /**
     * Join a voice session and get LiveKit credentials
     */
    @AuraEnabled
    public static Map<String, Object> joinSession(String voiceJwt, String sessionId, String versionId) {
        try {
            String endpoint = 'https://api.salesforce.com/einstein/ai-agent/v1.1/realtime/sessions/' + sessionId + '/join';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + voiceJwt);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-agent-mode', 'preview');
            req.setHeader('x-agent-version-id', versionId);
            req.setTimeout(10000);
            
            Map<String, Object> payload = new Map<String, Object>{
                'greeted' => false  // Agent waits for user to speak first
            };
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> room = (Map<String, Object>) result.get('room');
                
                return new Map<String, Object>{
                    'success' => true,
                    'url' => room.get('endpoint'),
                    'token' => room.get('token'),
                    'roomName' => room.get('name')
                };
            } else {
                return new Map<String, Object>{
                    'success' => false,
                    'error' => 'Join session failed: ' + res.getStatus() + ' - ' + res.getBody()
                };
            }
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }
}




