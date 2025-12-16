/**
 * Service class for Speech Foundation TTS API
 * Provides access token for LWC to call the API directly
 */
public with sharing class TTSService {
    
    private static final String NAMED_CREDENTIAL = 'callout:APITooling';
    
    /**
     * Get OAuth access token for LWC to use
     */
    @AuraEnabled(cacheable=false)
    public static String getAccessToken() {
        try {
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
                throw new AuraHandledException('Failed to get access token: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error getting access token: ' + e.getMessage());
            throw new AuraHandledException('Error getting access token: ' + e.getMessage());
        }
    }
}
