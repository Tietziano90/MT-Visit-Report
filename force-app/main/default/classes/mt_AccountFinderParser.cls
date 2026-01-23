/**
 * @description Parser for Account Finder prompt response
 * @author Michael Tietze
 */
public with sharing class mt_AccountFinderParser {
    
    public class AccountFinderResult {
        @InvocableVariable(label='Account ID' description='The found Account ID')
        public String accountId;
        
        @InvocableVariable(label='Account Name' description='The extracted account name')
        public String accountName;
        
        @InvocableVariable(label='Confidence' description='Confidence level of the match')
        public String confidence;
        
        @InvocableVariable(label='Account Record' description='The Account sObject record')
        public Account accountRecord;
    }
    
    public class Request {
        @InvocableVariable(required=true label='JSON Response' description='The JSON response from the Account Finder prompt')
        public String jsonResponse;
    }
    
    /**
     * @description Parse the Account Finder JSON response and search for matching Account
     * @param requests List of JSON responses to parse
     * @return List of AccountFinderResult with Account information
     */
    @InvocableMethod(label='Parse Account Finder Response' description='Parses the Account Finder JSON, searches for matching Account, and returns Account details' category='AI')
    public static List<AccountFinderResult> parseAccountFinderResponse(List<Request> requests) {
        List<AccountFinderResult> results = new List<AccountFinderResult>();
        
        for (Request req : requests) {
            AccountFinderResult result = new AccountFinderResult();
            
            try {
                // Parse JSON response
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(req.jsonResponse);
                
                result.accountName = (String) jsonMap.get('accountName');
                result.confidence = (String) jsonMap.get('confidence');
                
                // Get search terms from AI response
                List<Object> searchTermsObj = (List<Object>) jsonMap.get('searchTerms');
                List<String> searchTerms = new List<String>();
                if (searchTermsObj != null) {
                    for (Object term : searchTermsObj) {
                        searchTerms.add((String) term);
                    }
                }
                
                // Search for Account using the extracted name and search terms
                if (String.isNotBlank(result.accountName) && result.accountName != 'Unknown') {
                    result.accountRecord = searchForAccount(result.accountName, searchTerms);
                    
                    if (result.accountRecord != null) {
                        result.accountId = result.accountRecord.Id;
                        result.confidence = 'high';
                    }
                }
                
            } catch (Exception e) {
                System.debug('Error parsing Account Finder response: ' + e.getMessage());
                result.accountName = 'Error parsing response';
                result.confidence = 'low';
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Search for Account using name and variations
     * @param accountName The primary account name
     * @param searchTerms List of search term variations
     * @return Account record if found, null otherwise
     */
    private static Account searchForAccount(String accountName, List<String> searchTerms) {
        // Build SOSL search query with all terms
        List<String> allTerms = new List<String>{accountName};
        if (searchTerms != null && !searchTerms.isEmpty()) {
            allTerms.addAll(searchTerms);
        }
        
        // Try exact match first
        List<Account> exactMatches = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                   BillingPostalCode, BillingCountry, Phone, Website
            FROM Account 
            WHERE Name = :accountName
            LIMIT 1
        ];
        
        if (!exactMatches.isEmpty()) {
            return exactMatches[0];
        }
        
        // Try fuzzy match with LIKE
        String searchPattern = '%' + accountName + '%';
        List<Account> fuzzyMatches = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                   BillingPostalCode, BillingCountry, Phone, Website
            FROM Account 
            WHERE Name LIKE :searchPattern
            ORDER BY Name
            LIMIT 1
        ];
        
        if (!fuzzyMatches.isEmpty()) {
            return fuzzyMatches[0];
        }
        
        // Try search terms
        for (String term : allTerms) {
            if (String.isBlank(term) || term == accountName) {
                continue;
            }
            
            List<Account> termMatches = [
                SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                       BillingPostalCode, BillingCountry, Phone, Website
                FROM Account 
                WHERE Name LIKE :('%' + term + '%')
                LIMIT 1
            ];
            
            if (!termMatches.isEmpty()) {
                return termMatches[0];
            }
        }
        
        return null;
    }
}
