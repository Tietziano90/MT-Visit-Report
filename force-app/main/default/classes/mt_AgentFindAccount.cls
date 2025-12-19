/*
================================================================================
MT AGENT FIND ACCOUNT - Apex Class
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
 * MT AGENT FIND ACCOUNT - Apex Class
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
 * Invocable Apex method for Agentforce AI Agent to find Accounts by name
 * using fuzzy search (SOSL). Handles voice input with potential typos.
 * 
 * @features
 * - SOSL fuzzy search for Account names
 * - Returns top 5 matches
 * - Provides additional context (city, country, phone)
 * - Handles multiple matches with suggestions
 * - Error handling for invalid input
 * 
 * @usage
 * Called by AI Agent via Prompt Action
 * Input: Account name from voice transcript
 * Output: Account ID and name if found
 * 
 * ============================================================================
 */
public with sharing class mt_AgentFindAccount {
    
    /**
     * Find Account by name for the AI Agent
     * Returns Account ID and name if found
     */
    @InvocableMethod(label='Find Account for Visit Report' 
                     description='Searches for an Account by name and returns the ID' 
                     category='AI Agent')
    public static List<AccountSearchResult> findAccount(List<AccountSearchRequest> requests) {
        List<AccountSearchResult> results = new List<AccountSearchResult>();
        
        for (AccountSearchRequest request : requests) {
            AccountSearchResult result = new AccountSearchResult();
            
            try {
                // Use SOSL for fuzzy search - better for voice input with typos
                String searchQuery = 'FIND {' + String.escapeSingleQuotes(request.accountName) + '*} IN NAME FIELDS RETURNING Account(Id, Name, BillingCity, BillingCountry, Phone ORDER BY Name LIMIT 5)';
                List<List<SObject>> searchResults = Search.query(searchQuery);
                List<Account> accounts = (List<Account>)searchResults[0];
                
                if (accounts.isEmpty()) {
                    result.success = false;
                    result.message = 'I could not find an account with that name. Could you spell it differently or provide more details?';
                } else if (accounts.size() == 1) {
                    result.success = true;
                    result.accountId = accounts[0].Id;
                    result.accountName = accounts[0].Name;
                    result.message = 'Found account: ' + accounts[0].Name;
                    if (String.isNotBlank(accounts[0].BillingCity)) {
                        result.message += ' in ' + accounts[0].BillingCity;
                    }
                } else {
                    // Multiple matches - return first but mention there are others
                    result.success = true;
                    result.accountId = accounts[0].Id;
                    result.accountName = accounts[0].Name;
                    result.message = 'Found ' + accounts.size() + ' accounts. Using: ' + accounts[0].Name;
                }
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'Error searching for account: ' + e.getMessage();
                System.debug('Error in findAccount: ' + e.getMessage());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Input/Output classes
    public class AccountSearchRequest {
        @InvocableVariable(required=true label='Account Name' description='The name of the account to search for')
        public String accountName;
    }
    
    public class AccountSearchResult {
        @InvocableVariable(label='Success' description='Whether the search was successful')
        public Boolean success;
        
        @InvocableVariable(label='Account ID' description='The ID of the found account')
        public String accountId;
        
        @InvocableVariable(label='Account Name' description='The name of the found account')
        public String accountName;
        
        @InvocableVariable(label='Message' description='Message to relay to the user')
        public String message;
    }
}

