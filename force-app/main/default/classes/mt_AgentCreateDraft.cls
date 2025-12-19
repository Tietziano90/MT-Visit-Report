/*
================================================================================
MT AGENT CREATE DRAFT - Apex Class
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 1.0

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

/**
 * ============================================================================
 * MT AGENT CREATE DRAFT - Apex Class
 * ============================================================================
 * 
 * @author      Michael Tietze, Principal AI Architect
 * @contact     mtietze@salesforce.com
 * @created     December 2025
 * @modified    December 2025
 * @version     1.0
 * 
 * ============================================================================
 * COPYRIGHT AND DISTRIBUTION
 * ============================================================================
 * Copyright © 2025 Salesforce, Inc. All rights reserved.
 * 
 * Author: Michael Tietze, Principal AI Architect
 * 
 * INTERNAL USE ONLY - This code may not be shared externally or distributed
 * outside of Salesforce without prior written approval from Michael Tietze
 * (mtietze@salesforce.com).
 * 
 * THIS CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
 * ============================================================================
 * 
 * @description 
 * Invocable Apex method for Agentforce AI Agent to create Visit Report Draft
 * records after collecting visit information via phone conversation.
 * 
 * @features
 * - Creates MT_Visit_Report_Draft__c records
 * - Validates required fields (Account, Transcript)
 * - Sets initial status to "New" for flow processing
 * - Captures configuration profile
 * - Links to current user
 * 
 * @usage
 * Called by AI Agent via Prompt Action
 * Input: Account ID, transcript, configuration profile
 * Output: Draft record ID and success status
 * 
 * ============================================================================
 */
public with sharing class mt_AgentCreateDraft {
    
    /**
     * Create Visit Report Draft from Agent conversation
     */
    @InvocableMethod(label='Create Visit Report Draft' 
                     description='Creates a new Visit Report Draft record from the agent conversation' 
                     category='AI Agent')
    public static List<CreateDraftResult> createVisitReportDraft(List<CreateDraftRequest> requests) {
        List<CreateDraftResult> results = new List<CreateDraftResult>();
        
        for (CreateDraftRequest request : requests) {
            CreateDraftResult result = new CreateDraftResult();
            
            try {
                // Validate required fields
                if (String.isBlank(request.accountId)) {
                    result.success = false;
                    result.message = 'Account ID is required to create a visit report.';
                    results.add(result);
                    continue;
                }
                
                if (String.isBlank(request.transcript)) {
                    result.success = false;
                    result.message = 'Transcript is required to create a visit report.';
                    results.add(result);
                    continue;
                }
                
                // Create the draft record
                MT_Visit_Report_Draft__c draft = new MT_Visit_Report_Draft__c(
                    Account__c = request.accountId,
                    Transcript__c = request.transcript,
                    Status__c = 'New',
                    Configuration_Profile__c = String.isNotBlank(request.configProfile) ? 
                                                request.configProfile : 'Default',
                    Created_By_User__c = UserInfo.getUserId()
                );
                
                insert draft;
                
                result.success = true;
                result.draftId = draft.Id;
                result.message = 'Perfect! I have created your visit report draft. ' +
                                'It will be processed automatically and you will see it in your account shortly.';
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'I encountered an error creating the visit report: ' + e.getMessage();
                System.debug('Error in createVisitReportDraft: ' + e.getMessage());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Input/Output classes
    public class CreateDraftRequest {
        @InvocableVariable(required=true label='Account ID' description='The Account ID for the visit report')
        public String accountId;
        
        @InvocableVariable(required=true label='Transcript' description='The full conversation transcript')
        public String transcript;
        
        @InvocableVariable(label='Configuration Profile' description='Optional configuration profile name')
        public String configProfile;
    }
    
    public class CreateDraftResult {
        @InvocableVariable(label='Success' description='Whether the draft was created successfully')
        public Boolean success;
        
        @InvocableVariable(label='Draft ID' description='The ID of the created draft')
        public String draftId;
        
        @InvocableVariable(label='Message' description='Message to relay to the user')
        public String message;
    }
}

