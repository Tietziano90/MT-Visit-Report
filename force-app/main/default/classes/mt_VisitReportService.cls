/**
 * ============================================================================
 * MT Visit Report Service
 * ============================================================================
 * 
 * @description     Backend service for managing visit report drafts created
 *                  by AI Agent phone calls. Provides methods for querying,
 *                  updating, and managing draft records.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
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
public with sharing class mt_VisitReportService {
    
    /**
     * @description Retrieves visit report drafts for a specific Account
     * @param accountId The Account ID to filter drafts by
     * @return List of draft records with Status = 'Ready'
     */
    @AuraEnabled(cacheable=true)
    public static List<MT_Visit_Report_Draft__c> getDraftsForAccount(String accountId) {
        if (String.isBlank(accountId)) {
            return new List<MT_Visit_Report_Draft__c>();
        }
        
        try {
            return [
                SELECT Id, Name, CreatedDate, Status__c, Summary__c, 
                       Reasoning__c, Prompt_Response_JSON__c, Configuration_Profile__c,
                       Account__c, Account__r.Name, Created_By_User__c, Created_By_User__r.Name,
                       Processed_Date__c
                FROM MT_Visit_Report_Draft__c
                WHERE Account__c = :accountId 
                AND (Status__c = 'Ready' OR Status__c = 'Processed')
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving drafts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates the status of a visit report draft
     * @param draftId The draft record ID to update
     * @param status The new status value ('Processed', 'Rejected', etc.)
     */
    @AuraEnabled
    public static void updateDraftStatus(String draftId, String status) {
        if (String.isBlank(draftId) || String.isBlank(status)) {
            throw new AuraHandledException('Draft ID and status are required');
        }
        
        try {
            MT_Visit_Report_Draft__c draft = new MT_Visit_Report_Draft__c(
                Id = draftId,
                Status__c = status,
                Processed_Date__c = DateTime.now()
            );
            update draft;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating draft status: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates a visit report draft with created record IDs and marks it as processed
     * @param draftId The draft record ID to update
     * @param contactIds Comma-separated Contact IDs
     * @param opportunityIds Comma-separated Opportunity IDs
     * @param taskIds Comma-separated Task IDs
     * @param eventIds Comma-separated Event IDs
     * @param leadIds Comma-separated Lead IDs
     */
    @AuraEnabled
    public static void updateDraftWithRecords(
        String draftId, 
        String contactIds, 
        String opportunityIds, 
        String taskIds, 
        String eventIds, 
        String leadIds
    ) {
        if (String.isBlank(draftId)) {
            throw new AuraHandledException('Draft ID is required');
        }
        
        try {
            MT_Visit_Report_Draft__c draft = new MT_Visit_Report_Draft__c(
                Id = draftId,
                Status__c = 'Processed',
                Processed_Date__c = DateTime.now(),
                Created_Contact_IDs__c = contactIds,
                Created_Opportunity_IDs__c = opportunityIds,
                Created_Task_IDs__c = taskIds,
                Created_Event_IDs__c = eventIds,
                Created_Lead_IDs__c = leadIds
            );
            update draft;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating draft with records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Finds an Account by name (fuzzy matching)
     *              Used by Agentforce AI Agent to identify the customer
     * @param name The account name to search for
     * @return Account ID if found, null otherwise
     */
    @AuraEnabled
    public static String findAccountByName(String name) {
        if (String.isBlank(name)) {
            return null;
        }
        
        try {
            // Clean up the input
            String searchTerm = '%' + name.trim() + '%';
            
            // Try exact match first
            List<Account> exactMatches = [
                SELECT Id, Name 
                FROM Account 
                WHERE Name = :name.trim()
                LIMIT 1
            ];
            
            if (!exactMatches.isEmpty()) {
                return exactMatches[0].Id;
            }
            
            // Try partial match
            List<Account> partialMatches = [
                SELECT Id, Name 
                FROM Account 
                WHERE Name LIKE :searchTerm
                ORDER BY Name
                LIMIT 1
            ];
            
            if (!partialMatches.isEmpty()) {
                return partialMatches[0].Id;
            }
            
            return null;
        } catch (Exception e) {
            System.debug('Error finding account: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Retrieves ALL pending drafts (not just current user)
     *              Shows all visit reports ready for review across the org
     * @return List of draft records with Status = 'Ready'
     */
    @AuraEnabled(cacheable=true)
    public static List<MT_Visit_Report_Draft__c> getMyPendingDrafts() {
        try {
            return [
                SELECT Id, Name, CreatedDate, Status__c, Summary__c, 
                       Reasoning__c, Prompt_Response_JSON__c, Configuration_Profile__c,
                       Account__c, Account__r.Name, Processed_Date__c,
                       Created_By_User__c, Created_By_User__r.Name
                FROM MT_Visit_Report_Draft__c
                WHERE Status__c = 'Ready'
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving pending drafts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves ALL processed drafts (not just current user)
     *              Shows the history of completed visit reports across the org
     * @return List of draft records with Status = 'Processed'
     */
    @AuraEnabled(cacheable=true)
    public static List<MT_Visit_Report_Draft__c> getMyProcessedDrafts() {
        try {
            return [
                SELECT Id, Name, CreatedDate, Status__c, Summary__c, 
                       Reasoning__c, Prompt_Response_JSON__c, Configuration_Profile__c,
                       Account__c, Account__r.Name, Processed_Date__c,
                       Created_By_User__c, Created_By_User__r.Name
                FROM MT_Visit_Report_Draft__c
                WHERE Status__c = 'Processed'
                ORDER BY Processed_Date__c DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving processed drafts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses the JSON response to extract Summary and Reasoning
     *              Used by the record-triggered flow to populate fields
     * @param requests List of JSON responses to parse
     * @return List of ParseResult objects with summary and reasoning
     */
    @InvocableMethod(label='Parse Prompt Response' description='Extracts Summary and Reasoning from GenAI JSON response' category='AI Processing')
    public static List<ParseResult> parsePromptResponse(List<ParseRequest> requests) {
        List<ParseResult> results = new List<ParseResult>();
        
        for (ParseRequest request : requests) {
            ParseResult result = new ParseResult();
            result.summary = '';
            result.reasoning = '';
            
            if (String.isBlank(request.jsonResponse)) {
                results.add(result);
                continue;
            }
            
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(request.jsonResponse);
                
                if (responseMap.containsKey('Summary')) {
                    result.summary = String.valueOf(responseMap.get('Summary'));
                }
                
                if (responseMap.containsKey('Reasoning')) {
                    result.reasoning = String.valueOf(responseMap.get('Reasoning'));
                }
                
            } catch (Exception e) {
                System.debug('Error parsing JSON response: ' + e.getMessage());
                result.summary = 'Error parsing response';
                result.reasoning = e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Inner classes for Invocable Method
    public class ParseRequest {
        @InvocableVariable(label='JSON Response' required=true)
        public String jsonResponse;
    }
    
    public class ParseResult {
        @InvocableVariable(label='Summary')
        public String summary;
        
        @InvocableVariable(label='Reasoning')
        public String reasoning;
    }
    
    /**
     * @description Retrieves a single draft by ID with all details
     * @param draftId The draft record ID
     * @return Draft record with all fields
     */
    @AuraEnabled(cacheable=true)
    public static MT_Visit_Report_Draft__c getDraftById(String draftId) {
        if (String.isBlank(draftId)) {
            throw new AuraHandledException('Draft ID is required');
        }
        
        try {
            return [
                SELECT Id, Name, CreatedDate, Status__c, Summary__c, 
                       Reasoning__c, Prompt_Response_JSON__c, Configuration_Profile__c,
                       Account__c, Account__r.Name, Created_By_User__c, Created_By_User__r.Name,
                       Transcript__c, Error_Message__c, Processed_Date__c
                FROM MT_Visit_Report_Draft__c
                WHERE Id = :draftId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving draft: ' + e.getMessage());
        }
    }
}



