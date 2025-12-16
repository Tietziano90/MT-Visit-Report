/**
 * ============================================================================
 * RECORD SERVICE - Generic Apex Service for DML Operations
 * ============================================================================
 * 
 * @author      Michael Tietze, Principal AI Architect
 * @contact     mtietze@salesforce.com
 * @created     November 2025
 * @modified    November 2025
 * @version     1.5
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
 * ============================================================================
 * 
 * @description 
 * Generic, FULLY DYNAMIC record service for creating and updating ANY SObject
 * type. This service is completely flexible - it works with standard objects,
 * custom objects, and any field types without hardcoding.
 * 
 * KEY FEATURES:
 * - Works with ANY standard or custom SObject type
 * - Automatic field type conversion (String to Date, Number, etc.)
 * - Duplicate detection with matched record ID extraction
 * - Field-level error reporting
 * - Related record queries by Account
 * - Lookup name resolution for display
 * 
 * METHODS:
 * - createRecord() - Create any SObject with field values
 * - updateRecord() - Update any SObject with field values
 * - saveRecordSimple() - LWC-friendly create/update method
 * - getRelatedRecords() - Fetch records related to an Account
 * - getDuplicateRecords() - Fetch details of potential duplicates
 * - resolveLookupNames() - Convert IDs to display names
 * - getRecordData() - Fetch existing record field values
 * ============================================================================
 */
public with sharing class mt_RecordService {

    /**
     * Result wrapper for DML operations
     */
    public class DmlResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String recordId;
        @AuraEnabled public String message;
        @AuraEnabled public List<FieldError> fieldErrors;
        @AuraEnabled public String objectType;
        @AuraEnabled public Boolean isNew;
        @AuraEnabled public Boolean isDuplicateError;
        @AuraEnabled public List<String> duplicateRecordIds;
    }

    /**
     * Field-level error wrapper
     */
    public class FieldError {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String message;
    }

    /**
     * Request wrapper for creating/updating records
     */
    public class RecordRequest {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String recordId;
        @AuraEnabled public Map<String, Object> fieldValues;
        @AuraEnabled public String recordTypeDeveloperName;
    }

    /**
     * Create a new record of any SObject type
     * @param objectApiName The API name of the object to create
     * @param fieldValues Map of field API names to values
     * @param recordTypeDeveloperName Optional record type developer name
     * @param allowDuplicates Whether to bypass duplicate detection rules
     * @return DmlResult with success status and record ID or error details
     */
    @AuraEnabled
    public static DmlResult createRecord(String objectApiName, Map<String, Object> fieldValues, String recordTypeDeveloperName, Boolean allowDuplicates) {
        DmlResult result = new DmlResult();
        result.objectType = objectApiName;
        result.isNew = true;
        result.fieldErrors = new List<FieldError>();

        try {
            // Validate inputs
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object API name is required.');
            }
            if (fieldValues == null || fieldValues.isEmpty()) {
                throw new AuraHandledException('Field values are required.');
            }

            // Get SObject type
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }

            // Check if object is createable
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            if (!describeResult.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create ' + objectApiName + ' records.');
            }

            // Create new SObject instance
            SObject record = sObjectType.newSObject();

            // Handle record type if specified
            if (String.isNotBlank(recordTypeDeveloperName)) {
                Id recordTypeId = getRecordTypeId(describeResult, recordTypeDeveloperName);
                if (recordTypeId != null) {
                    record.put('RecordTypeId', recordTypeId);
                }
            }

            // Set field values
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            setFieldValues(record, fieldValues, fieldMap, true);

            // Perform insert with duplicate detection (unless bypassed)
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.DuplicateRuleHeader.allowSave = (allowDuplicates == true);
            dmlOptions.DuplicateRuleHeader.runAsCurrentUser = true;
            System.debug(LoggingLevel.INFO, 'DML Options - allowSave (bypass duplicates): ' + dmlOptions.DuplicateRuleHeader.allowSave);
            
            Database.SaveResult saveResult = Database.insert(record, dmlOptions);
            
            if (saveResult.isSuccess()) {
                result.success = true;
                result.recordId = record.Id;
                result.message = objectApiName + ' created successfully.';
            } else {
                result.success = false;
                result.duplicateRecordIds = new List<String>();
                
                // Check for duplicate errors
                for (Database.Error err : saveResult.getErrors()) {
                    if (err instanceof Database.DuplicateError) {
                        Database.DuplicateError dupError = (Database.DuplicateError) err;
                        result.isDuplicateError = true;
                        
                        // Get duplicate results
                        Datacloud.DuplicateResult dupResult = dupError.getDuplicateResult();
                        if (dupResult != null && dupResult.getMatchResults() != null) {
                            for (Datacloud.MatchResult matchResult : dupResult.getMatchResults()) {
                                if (matchResult.getMatchRecords() != null) {
                                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                        SObject matchedRecord = matchRecord.getRecord();
                                        if (matchedRecord != null && matchedRecord.Id != null) {
                                            result.duplicateRecordIds.add(String.valueOf(matchedRecord.Id));
                                        }
                                    }
                                }
                            }
                        }
                        result.message = 'Duplicate record(s) found. Use one of these records or create anyway.';
                    } else {
                        // Non-duplicate error
                        if (String.isBlank(result.message)) {
                            result.message = err.getMessage();
                        }
                        if (err.getFields() != null) {
                            for (String field : err.getFields()) {
                                FieldError fieldError = new FieldError();
                                fieldError.fieldApiName = field;
                                fieldError.message = err.getMessage();
                                result.fieldErrors.add(fieldError);
                            }
                        }
                    }
                }
            }

        } catch (DmlException e) {
            result.success = false;
            result.message = formatDmlException(e);
            result.fieldErrors = extractFieldErrors(e);
        } catch (AuraHandledException e) {
            result.success = false;
            result.message = e.getMessage();
        } catch (Exception e) {
            result.success = false;
            result.message = 'An unexpected error occurred: ' + e.getMessage();
        }

        return result;
    }

    /**
     * Update an existing record of any SObject type
     * @param objectApiName The API name of the object
     * @param recordId The ID of the record to update
     * @param fieldValues Map of field API names to values
     * @return DmlResult with success status or error details
     */
    @AuraEnabled
    public static DmlResult updateRecord(String objectApiName, String recordId, Map<String, Object> fieldValues) {
        DmlResult result = new DmlResult();
        result.objectType = objectApiName;
        result.recordId = recordId;
        result.isNew = false;
        result.fieldErrors = new List<FieldError>();

        try {
            System.debug(LoggingLevel.INFO, '=== UPDATE RECORD START ===');
            System.debug(LoggingLevel.INFO, 'objectApiName: ' + objectApiName);
            System.debug(LoggingLevel.INFO, 'recordId: ' + recordId);
            System.debug(LoggingLevel.INFO, 'fieldValues: ' + fieldValues);
            
            // Validate inputs
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object API name is required.');
            }
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required for update.');
            }
            if (fieldValues == null || fieldValues.isEmpty()) {
                throw new AuraHandledException('Field values are required.');
            }

            // Validate record ID format
            Id validId;
            try {
                validId = Id.valueOf(recordId);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid record ID format: ' + recordId);
            }

            // Verify object type matches record ID
            String idObjectType = validId.getSObjectType().getDescribe().getName();
            if (!idObjectType.equalsIgnoreCase(objectApiName)) {
                throw new AuraHandledException('Record ID does not match specified object type. Expected: ' + objectApiName + ', Got: ' + idObjectType);
            }

            // Get SObject type
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

            if (!describeResult.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update ' + objectApiName + ' records.');
            }

            // Create SObject instance with ID
            SObject record = sObjectType.newSObject(validId);
            System.debug(LoggingLevel.INFO, 'Created SObject with ID: ' + record.Id);

            // Set field values
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            System.debug(LoggingLevel.INFO, 'Field map keys: ' + fieldMap.keySet());
            setFieldValues(record, fieldValues, fieldMap, false);
            
            // Debug: Log what's on the record before update
            System.debug(LoggingLevel.INFO, 'Record before update: ' + record);
            for (String fieldName : fieldValues.keySet()) {
                try {
                    System.debug(LoggingLevel.INFO, 'Field ' + fieldName + ' value on SObject: ' + record.get(fieldName));
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Could not get field ' + fieldName + ': ' + e.getMessage());
                }
            }

            // Perform update
            System.debug(LoggingLevel.INFO, 'About to perform DML update...');
            update record;
            System.debug(LoggingLevel.INFO, 'DML update completed successfully');
            
            // VERIFICATION: Query the record to confirm the update was persisted
            List<String> fieldNamesToVerify = new List<String>(fieldValues.keySet());
            fieldNamesToVerify.add('Id');
            String verifyQuery = 'SELECT ' + String.join(fieldNamesToVerify, ', ') + ' FROM ' + objectApiName + ' WHERE Id = :validId LIMIT 1';
            System.debug(LoggingLevel.INFO, 'Verification query: ' + verifyQuery);
            
            List<String> mismatchedFields = new List<String>();
            List<SObject> verifyResults = Database.query(verifyQuery);
            if (!verifyResults.isEmpty()) {
                SObject verifiedRecord = verifyResults[0];
                System.debug(LoggingLevel.INFO, '=== VERIFICATION RESULTS ===');
                for (String fn : fieldValues.keySet()) {
                    Object expectedValue = fieldValues.get(fn);
                    Object actualValue;
                    try {
                        actualValue = verifiedRecord.get(fn);
                    } catch (Exception e) {
                        actualValue = null;
                    }
                    System.debug(LoggingLevel.INFO, 'Field: ' + fn + ' | Expected: ' + expectedValue + ' | Actual in DB: ' + actualValue);
                    
                    // Check if values match (comparing as strings for simplicity)
                    String expectedStr = String.valueOf(expectedValue);
                    String actualStr = String.valueOf(actualValue);
                    // Handle numeric comparison (122000 vs 122000.00)
                    Boolean valuesMatch = false;
                    if (expectedStr == actualStr) {
                        valuesMatch = true;
                    } else {
                        // Try numeric comparison
                        try {
                            Decimal expectedNum = Decimal.valueOf(expectedStr);
                            Decimal actualNum = Decimal.valueOf(actualStr);
                            valuesMatch = (expectedNum == actualNum);
                        } catch (Exception e) {
                            valuesMatch = false;
                        }
                    }
                    
                    if (!valuesMatch) {
                        System.debug(LoggingLevel.WARN, 'MISMATCH DETECTED for field ' + fn + '!');
                        mismatchedFields.add(fn);
                    }
                }
                System.debug(LoggingLevel.INFO, '=== END VERIFICATION ===');
            }

            // Check if any fields didn't persist
            if (!mismatchedFields.isEmpty()) {
                result.success = false;
                result.message = 'Could not update: ' + String.join(mismatchedFields, ', ');
                // Add field errors for highlighting
                for (String fn : mismatchedFields) {
                    FieldError fe = new FieldError();
                    fe.fieldApiName = fn;
                    fe.message = 'Update blocked';
                    result.fieldErrors.add(fe);
                }
            } else {
                result.success = true;
                result.message = objectApiName + ' updated successfully.';
            }

        } catch (DmlException e) {
            result.success = false;
            result.message = formatDmlException(e);
            result.fieldErrors = extractFieldErrors(e);
        } catch (AuraHandledException e) {
            result.success = false;
            result.message = e.getMessage();
        } catch (Exception e) {
            result.success = false;
            result.message = 'An unexpected error occurred: ' + e.getMessage();
        }

        return result;
    }

    /**
     * Create or update a record based on whether recordId is provided
     * @param request RecordRequest containing all necessary data
     * @return DmlResult with success status or error details
     */
    @AuraEnabled
    public static DmlResult saveRecord(RecordRequest request) {
        if (request == null) {
            DmlResult result = new DmlResult();
            result.success = false;
            result.message = 'Request is required.';
            return result;
        }

        if (String.isNotBlank(request.recordId)) {
            return updateRecord(request.objectApiName, request.recordId, request.fieldValues);
        } else {
            return createRecord(request.objectApiName, request.fieldValues, request.recordTypeDeveloperName, false);
        }
    }

    /**
     * Create or update a record - simpler method signature for LWC compatibility
     * @param objectApiName The API name of the object
     * @param recordId The ID of the record (null for create)
     * @param fieldValuesJson JSON string of field values
     * @param allowDuplicates Whether to bypass duplicate detection rules
     * @return DmlResult with success status or error details
     */
    @AuraEnabled
    public static DmlResult saveRecordSimple(String objectApiName, String recordId, String fieldValuesJson, Boolean allowDuplicates) {
        System.debug(LoggingLevel.INFO, 'saveRecordSimple called');
        System.debug(LoggingLevel.INFO, 'objectApiName: ' + objectApiName);
        System.debug(LoggingLevel.INFO, 'recordId: ' + recordId);
        System.debug(LoggingLevel.INFO, 'fieldValuesJson: ' + fieldValuesJson);
        System.debug(LoggingLevel.INFO, 'allowDuplicates: ' + allowDuplicates);
        
        DmlResult result = new DmlResult();
        result.fieldErrors = new List<FieldError>();
        
        try {
            if (String.isBlank(objectApiName)) {
                result.success = false;
                result.message = 'Object API name is required.';
                return result;
            }
            
            if (String.isBlank(fieldValuesJson)) {
                result.success = false;
                result.message = 'Field values are required.';
                return result;
            }
            
            // Parse JSON to Map
            Map<String, Object> fieldValues = (Map<String, Object>) JSON.deserializeUntyped(fieldValuesJson);
            
            System.debug(LoggingLevel.INFO, 'Parsed fieldValues: ' + fieldValues);
            
            if (String.isNotBlank(recordId)) {
                return updateRecord(objectApiName, recordId, fieldValues);
            } else {
                return createRecord(objectApiName, fieldValues, null, allowDuplicates == true);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'saveRecordSimple error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            result.success = false;
            result.message = 'Error: ' + e.getMessage();
            return result;
        }
    }

    /**
     * Create multiple records in a single transaction
     * @param objectApiName The API name of the object
     * @param recordsFieldValues List of field value maps, one per record
     * @param recordTypeDeveloperName Optional record type developer name (applied to all records)
     * @return List of DmlResults for each record
     */
    @AuraEnabled
    public static List<DmlResult> createRecords(String objectApiName, List<Map<String, Object>> recordsFieldValues, String recordTypeDeveloperName) {
        List<DmlResult> results = new List<DmlResult>();

        if (String.isBlank(objectApiName)) {
            DmlResult errorResult = new DmlResult();
            errorResult.success = false;
            errorResult.message = 'Object API name is required.';
            results.add(errorResult);
            return results;
        }

        if (recordsFieldValues == null || recordsFieldValues.isEmpty()) {
            DmlResult errorResult = new DmlResult();
            errorResult.success = false;
            errorResult.message = 'At least one record is required.';
            results.add(errorResult);
            return results;
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }

            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            if (!describeResult.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create ' + objectApiName + ' records.');
            }

            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            Id recordTypeId = null;
            if (String.isNotBlank(recordTypeDeveloperName)) {
                recordTypeId = getRecordTypeId(describeResult, recordTypeDeveloperName);
            }

            List<SObject> recordsToInsert = new List<SObject>();
            for (Map<String, Object> fieldValues : recordsFieldValues) {
                SObject record = sObjectType.newSObject();
                if (recordTypeId != null) {
                    record.put('RecordTypeId', recordTypeId);
                }
                setFieldValues(record, fieldValues, fieldMap, true);
                recordsToInsert.add(record);
            }

            Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                DmlResult result = new DmlResult();
                result.objectType = objectApiName;
                result.isNew = true;
                result.fieldErrors = new List<FieldError>();

                if (saveResults[i].isSuccess()) {
                    result.success = true;
                    result.recordId = saveResults[i].getId();
                    result.message = objectApiName + ' created successfully.';
                } else {
                    result.success = false;
                    List<String> errorMessages = new List<String>();
                    for (Database.Error err : saveResults[i].getErrors()) {
                        errorMessages.add(err.getMessage());
                        if (err.getFields() != null) {
                            for (String field : err.getFields()) {
                                FieldError fieldError = new FieldError();
                                fieldError.fieldApiName = field;
                                fieldError.message = err.getMessage();
                                result.fieldErrors.add(fieldError);
                            }
                        }
                    }
                    result.message = String.join(errorMessages, '; ');
                }
                results.add(result);
            }

        } catch (AuraHandledException e) {
            DmlResult errorResult = new DmlResult();
            errorResult.success = false;
            errorResult.message = e.getMessage();
            results.add(errorResult);
        } catch (Exception e) {
            DmlResult errorResult = new DmlResult();
            errorResult.success = false;
            errorResult.message = 'An unexpected error occurred: ' + e.getMessage();
            results.add(errorResult);
        }

        return results;
    }

    /**
     * Delete a record
     * @param recordId The ID of the record to delete
     * @return DmlResult with success status or error details
     */
    @AuraEnabled
    public static DmlResult deleteRecord(String recordId) {
        DmlResult result = new DmlResult();
        result.recordId = recordId;
        result.fieldErrors = new List<FieldError>();

        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }

            Id validId;
            try {
                validId = Id.valueOf(recordId);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid record ID format: ' + recordId);
            }

            Schema.SObjectType sObjectType = validId.getSObjectType();
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            result.objectType = describeResult.getName();

            if (!describeResult.isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete ' + result.objectType + ' records.');
            }

            SObject record = sObjectType.newSObject(validId);
            delete record;

            result.success = true;
            result.message = result.objectType + ' deleted successfully.';

        } catch (DmlException e) {
            result.success = false;
            result.message = formatDmlException(e);
        } catch (AuraHandledException e) {
            result.success = false;
            result.message = e.getMessage();
        } catch (Exception e) {
            result.success = false;
            result.message = 'An unexpected error occurred: ' + e.getMessage();
        }

        return result;
    }

    /**
     * Set field values on an SObject with proper type conversion
     */
    private static void setFieldValues(SObject record, Map<String, Object> fieldValues, Map<String, Schema.SObjectField> fieldMap, Boolean isCreate) {
        System.debug(LoggingLevel.INFO, '=== setFieldValues START ===');
        System.debug(LoggingLevel.INFO, 'isCreate: ' + isCreate);
        System.debug(LoggingLevel.INFO, 'fieldValues to process: ' + fieldValues);
        
        for (String fieldApiName : fieldValues.keySet()) {
            Object value = fieldValues.get(fieldApiName);
            System.debug(LoggingLevel.INFO, 'Processing field: ' + fieldApiName + ' with value: ' + value);
            
            // Skip null/empty values and Id field for creates
            if (value == null) {
                System.debug(LoggingLevel.INFO, 'Skipping null value for: ' + fieldApiName);
                continue;
            }
            if (fieldApiName.equalsIgnoreCase('Id')) {
                System.debug(LoggingLevel.INFO, 'Skipping Id field');
                continue;
            }
            if (fieldApiName.equalsIgnoreCase('ObjectType')) continue;
            if (fieldApiName.equalsIgnoreCase('RecordType')) continue;

            // Get field describe
            Schema.SObjectField field = fieldMap.get(fieldApiName.toLowerCase());
            if (field == null) {
                System.debug(LoggingLevel.WARN, 'Field not found in fieldMap: ' + fieldApiName + ' (searched for: ' + fieldApiName.toLowerCase() + ')');
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            System.debug(LoggingLevel.INFO, 'Field describe - Name: ' + fieldDescribe.getName() + ', Type: ' + fieldDescribe.getType() + ', Updateable: ' + fieldDescribe.isUpdateable());
            
            // Check field-level security
            if (isCreate && !fieldDescribe.isCreateable()) {
                System.debug(LoggingLevel.WARN, 'Field not createable: ' + fieldApiName);
                continue;
            }
            if (!isCreate && !fieldDescribe.isUpdateable()) {
                System.debug(LoggingLevel.WARN, 'Field not updateable (FLS): ' + fieldApiName);
                continue;
            }

            // Convert and set value based on field type
            try {
                Object convertedValue = convertFieldValue(value, fieldDescribe);
                System.debug(LoggingLevel.INFO, 'Converted value for ' + fieldApiName + ': ' + convertedValue);
                
                if (convertedValue != null || fieldDescribe.isNillable()) {
                    record.put(fieldDescribe.getName(), convertedValue);  // Use actual field name from describe
                    System.debug(LoggingLevel.INFO, 'Successfully set ' + fieldDescribe.getName() + ' = ' + convertedValue);
                } else {
                    System.debug(LoggingLevel.WARN, 'Skipping field ' + fieldApiName + ' - convertedValue is null and field is not nillable');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error setting field ' + fieldApiName + ': ' + e.getMessage());
            }
        }
        System.debug(LoggingLevel.INFO, '=== setFieldValues END ===');
    }

    /**
     * Convert field value to appropriate Apex type based on field describe
     */
    private static Object convertFieldValue(Object value, Schema.DescribeFieldResult fieldDescribe) {
        if (value == null) return null;
        
        String stringValue = String.valueOf(value);
        if (String.isBlank(stringValue)) return null;

        Schema.DisplayType fieldType = fieldDescribe.getType();

        switch on fieldType {
            when STRING, TEXTAREA, URL, EMAIL, PHONE, PICKLIST, MULTIPICKLIST, COMBOBOX {
                return stringValue;
            }
            when ID, REFERENCE {
                // Validate ID format
                if (stringValue.length() == 15 || stringValue.length() == 18) {
                    try {
                        return Id.valueOf(stringValue);
                    } catch (Exception e) {
                        return null;
                    }
                }
                return null;
            }
            when BOOLEAN {
                return Boolean.valueOf(stringValue);
            }
            when INTEGER {
                return Integer.valueOf(stringValue);
            }
            when DOUBLE, PERCENT, CURRENCY {
                return Decimal.valueOf(stringValue);
            }
            when DATE {
                // Handle various date formats
                try {
                    if (stringValue.contains('T')) {
                        return Date.valueOf(stringValue.substringBefore('T'));
                    }
                    return Date.valueOf(stringValue);
                } catch (Exception e) {
                    return null;
                }
            }
            when DATETIME {
                // Handle ISO format and other datetime strings
                try {
                    // Remove timezone suffix if present and parse
                    String cleanedValue = stringValue.replace('+0000', 'Z');
                    if (!cleanedValue.endsWith('Z')) {
                        cleanedValue = cleanedValue + 'Z';
                    }
                    return (DateTime) JSON.deserialize('"' + cleanedValue + '"', DateTime.class);
                } catch (Exception e) {
                    try {
                        return DateTime.valueOf(stringValue);
                    } catch (Exception e2) {
                        return null;
                    }
                }
            }
            when TIME {
                try {
                    List<String> timeParts = stringValue.split(':');
                    Integer hours = Integer.valueOf(timeParts[0]);
                    Integer minutes = timeParts.size() > 1 ? Integer.valueOf(timeParts[1]) : 0;
                    Integer seconds = timeParts.size() > 2 ? Integer.valueOf(timeParts[2].substringBefore('.')) : 0;
                    return Time.newInstance(hours, minutes, seconds, 0);
                } catch (Exception e) {
                    return null;
                }
            }
            when else {
                return value;
            }
        }
    }

    /**
     * Get record type ID from developer name
     */
    private static Id getRecordTypeId(Schema.DescribeSObjectResult describeResult, String developerName) {
        Map<String, Schema.RecordTypeInfo> recordTypes = describeResult.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo rtInfo = recordTypes.get(developerName);
        if (rtInfo != null && rtInfo.isAvailable()) {
            return rtInfo.getRecordTypeId();
        }
        return null;
    }

    /**
     * Wrapper for duplicate record info
     */
    public class DuplicateRecordInfo {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public Map<String, Object> fields;
    }

    /**
     * Get related records for an Account (e.g., all Contacts or Opportunities on an Account)
     * @param objectApiName The API name of the object to search
     * @param accountId The Account ID to filter by
     * @param searchTerm Optional search term to filter results
     * @param limitRecords Maximum number of records to return
     * @return List of DuplicateRecordInfo with record details
     */
    @AuraEnabled
    public static List<DuplicateRecordInfo> getRelatedRecords(String objectApiName, String accountId, String searchTerm, Integer limitRecords) {
        List<DuplicateRecordInfo> results = new List<DuplicateRecordInfo>();
        
        if (String.isBlank(objectApiName)) {
            return results;
        }
        
        Integer queryLimit = (limitRecords != null && limitRecords > 0) ? Math.min(limitRecords, 50) : 20;
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return results;
            }
            
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            
            // Determine name field
            String nameField = 'Name';
            if (objectApiName == 'Case') {
                nameField = 'CaseNumber';
            } else if (objectApiName == 'Task' || objectApiName == 'Event') {
                nameField = 'Subject';
            }
            
            // Build field list
            List<String> fieldsToQuery = new List<String>{'Id'};
            if (fieldMap.containsKey(nameField.toLowerCase())) {
                fieldsToQuery.add(nameField);
            }
            
            // Add common fields for display
            for (String fieldName : new List<String>{'Email', 'Phone', 'Title', 'StageName', 'Amount', 'CloseDate', 'Status', 'Subject'}) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    fieldsToQuery.add(fieldName);
                }
            }
            
            // Determine account field
            String accountField = null;
            if (fieldMap.containsKey('accountid')) {
                accountField = 'AccountId';
            } else if (fieldMap.containsKey('account__c')) {
                accountField = 'Account__c';
            }
            
            // Build query
            String query = 'SELECT ' + String.join(fieldsToQuery, ', ') + ' FROM ' + String.escapeSingleQuotes(objectApiName);
            
            List<String> conditions = new List<String>();
            
            // Add account filter if we have an account ID and the object has an account field
            if (String.isNotBlank(accountId) && accountField != null) {
                conditions.add(accountField + ' = :accountId');
            }
            
            // Add search term filter
            if (String.isNotBlank(searchTerm)) {
                String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                conditions.add(nameField + ' LIKE :searchPattern');
            }
            
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            query += ' ORDER BY LastModifiedDate DESC LIMIT ' + queryLimit;
            
            System.debug('getRelatedRecords query: ' + query);
            
            List<SObject> records = Database.query(query);
            
            for (SObject record : records) {
                DuplicateRecordInfo info = new DuplicateRecordInfo();
                info.recordId = String.valueOf(record.Id);
                info.fields = new Map<String, Object>();
                
                // Get name
                if (fieldsToQuery.contains(nameField)) {
                    Object nameValue = record.get(nameField);
                    info.name = nameValue != null ? String.valueOf(nameValue) : 'Unknown';
                } else {
                    info.name = String.valueOf(record.Id);
                }
                
                // Add other fields
                for (String fieldName : fieldsToQuery) {
                    if (fieldName != 'Id') {
                        Object value = record.get(fieldName);
                        if (value != null) {
                            info.fields.put(fieldName, value);
                        }
                    }
                }
                
                results.add(info);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching related records: ' + e.getMessage());
        }
        
        return results;
    }

    /**
     * Get details of potential duplicate records
     * @param objectApiName The API name of the object
     * @param recordIds List of record IDs to fetch
     * @return List of DuplicateRecordInfo with record details
     */
    @AuraEnabled(cacheable=true)
    public static List<DuplicateRecordInfo> getDuplicateRecords(String objectApiName, List<String> recordIds) {
        List<DuplicateRecordInfo> results = new List<DuplicateRecordInfo>();
        
        if (String.isBlank(objectApiName) || recordIds == null || recordIds.isEmpty()) {
            return results;
        }
        
        try {
            // Get object describe
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return results;
            }
            
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            
            // Determine name field
            String nameField = 'Name';
            if (objectApiName == 'Case') {
                nameField = 'CaseNumber';
            } else if (objectApiName == 'Task' || objectApiName == 'Event') {
                nameField = 'Subject';
            }
            
            // Get a few key fields for display
            List<String> fieldsToQuery = new List<String>{'Id'};
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            
            if (fieldMap.containsKey(nameField.toLowerCase())) {
                fieldsToQuery.add(nameField);
            }
            
            // Add common identifying fields if they exist
            for (String fieldName : new List<String>{'Email', 'Phone', 'AccountId', 'Company', 'Title'}) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    fieldsToQuery.add(fieldName);
                }
            }
            
            // Build and execute query
            String query = 'SELECT ' + String.join(fieldsToQuery, ', ') + 
                          ' FROM ' + String.escapeSingleQuotes(objectApiName) + 
                          ' WHERE Id IN :recordIds LIMIT 10';
            
            List<SObject> records = Database.query(query);
            
            for (SObject record : records) {
                DuplicateRecordInfo info = new DuplicateRecordInfo();
                info.recordId = String.valueOf(record.Id);
                info.fields = new Map<String, Object>();
                
                // Get name
                if (fieldsToQuery.contains(nameField)) {
                    Object nameValue = record.get(nameField);
                    info.name = nameValue != null ? String.valueOf(nameValue) : 'Unknown';
                } else {
                    info.name = String.valueOf(record.Id);
                }
                
                // Add other fields
                for (String fieldName : fieldsToQuery) {
                    if (fieldName != 'Id') {
                        Object value = record.get(fieldName);
                        if (value != null) {
                            info.fields.put(fieldName, value);
                        }
                    }
                }
                
                results.add(info);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching duplicate records: ' + e.getMessage());
        }
        
        return results;
    }

    /**
     * Format DML exception for user-friendly display
     */
    private static String formatDmlException(DmlException e) {
        List<String> messages = new List<String>();
        for (Integer i = 0; i < e.getNumDml(); i++) {
            String fieldName = '';
            if (e.getDmlFieldNames(i) != null && !e.getDmlFieldNames(i).isEmpty()) {
                fieldName = e.getDmlFieldNames(i)[0] + ': ';
            }
            messages.add(fieldName + e.getDmlMessage(i));
        }
        return String.join(messages, '; ');
    }

    /**
     * Extract field-level errors from DML exception
     */
    private static List<FieldError> extractFieldErrors(DmlException e) {
        List<FieldError> fieldErrors = new List<FieldError>();
        for (Integer i = 0; i < e.getNumDml(); i++) {
            List<String> fields = e.getDmlFieldNames(i);
            if (fields != null) {
                for (String fieldName : fields) {
                    FieldError fe = new FieldError();
                    fe.fieldApiName = fieldName;
                    fe.message = e.getDmlMessage(i);
                    fieldErrors.add(fe);
                }
            }
        }
        return fieldErrors;
    }

    /**
     * Fetch an existing record with specified fields
     * @param recordId The ID of the record to fetch
     * @param fieldApiNames List of field API names to retrieve
     * @return Map of field API names to their current values
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecordFields(String recordId, List<String> fieldApiNames) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (String.isBlank(recordId)) {
            return result;
        }

        try {
            // Get object type from record ID
            Id validId = Id.valueOf(recordId);
            Schema.SObjectType sObjectType = validId.getSObjectType();
            String objectApiName = sObjectType.getDescribe().getName();
            
            // Build dynamic query
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            if (fieldApiNames != null) {
                for (String field : fieldApiNames) {
                    fieldsToQuery.add(field.toLowerCase());
                }
            }
            
            // Check which fields actually exist on the object
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            List<String> validFields = new List<String>();
            for (String fieldName : fieldsToQuery) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    validFields.add(fieldName);
                }
            }
            
            if (validFields.isEmpty()) {
                validFields.add('Id');
            }
            
            String query = 'SELECT ' + String.join(validFields, ', ') + 
                          ' FROM ' + objectApiName + 
                          ' WHERE Id = :recordId LIMIT 1';
            
            List<SObject> records = Database.query(query);
            
            if (!records.isEmpty()) {
                SObject record = records[0];
                for (String fieldName : validFields) {
                    try {
                        result.put(fieldName, record.get(fieldName));
                    } catch (Exception e) {
                        // Field might not be accessible
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching record: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * Resolve lookup field IDs to their display names
     * @param lookupIds Map of field keys to record IDs
     * @return Map of field keys to display names
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> resolveLookupNames(Map<String, String> lookupIds) {
        Map<String, String> result = new Map<String, String>();
        
        if (lookupIds == null || lookupIds.isEmpty()) {
            return result;
        }

        System.debug(LoggingLevel.INFO, 'resolveLookupNames called with ' + lookupIds.size() + ' lookups');
        System.debug(LoggingLevel.DEBUG, 'Lookup IDs: ' + lookupIds);

        // Group IDs by their object type, but track ALL field keys for each ID
        Map<String, Set<String>> idsByObjectType = new Map<String, Set<String>>();
        // Map: recordId -> List of all field keys that reference this ID
        Map<String, List<String>> idToFieldKeys = new Map<String, List<String>>();
        
        for (String fieldKey : lookupIds.keySet()) {
            String recordId = lookupIds.get(fieldKey);
            if (String.isBlank(recordId)) {
                System.debug(LoggingLevel.WARN, 'Skipping blank recordId for key: ' + fieldKey);
                continue;
            }
            
            // Validate ID format
            if (recordId.length() != 15 && recordId.length() != 18) {
                System.debug(LoggingLevel.WARN, 'Skipping invalid ID length for key: ' + fieldKey + ', ID: ' + recordId);
                continue;
            }
            
            try {
                Id validId = Id.valueOf(recordId);
                String objectType = validId.getSObjectType().getDescribe().getName();
                
                if (!idsByObjectType.containsKey(objectType)) {
                    idsByObjectType.put(objectType, new Set<String>());
                }
                idsByObjectType.get(objectType).add(recordId);
                
                // Store ALL field keys that reference this record ID (not just one!)
                if (!idToFieldKeys.containsKey(recordId)) {
                    idToFieldKeys.put(recordId, new List<String>());
                }
                idToFieldKeys.get(recordId).add(fieldKey);
                
                System.debug(LoggingLevel.DEBUG, 'Added lookup: ' + fieldKey + ' -> ' + recordId + ' (' + objectType + ')');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Invalid ID for key: ' + fieldKey + ', ID: ' + recordId + ', Error: ' + e.getMessage());
            }
        }

        System.debug(LoggingLevel.INFO, 'Grouped into ' + idsByObjectType.size() + ' object types');

        // Query each object type for names
        for (String objectType : idsByObjectType.keySet()) {
            Set<String> ids = idsByObjectType.get(objectType);
            if (ids.isEmpty()) continue;
            
            System.debug(LoggingLevel.INFO, 'Querying ' + ids.size() + ' records for ' + objectType);
            
            try {
                // Determine the name field based on object type
                String nameField = getNameField(objectType);
                
                String query = 'SELECT Id, ' + nameField + ' FROM ' + objectType + 
                              ' WHERE Id IN :ids';
                
                List<SObject> records = Database.query(query);
                System.debug(LoggingLevel.INFO, 'Found ' + records.size() + ' records for ' + objectType);
                
                for (SObject record : records) {
                    String recordId = (String) record.get('Id');
                    List<String> fieldKeys = idToFieldKeys.get(recordId);
                    Object nameValue = record.get(nameField);
                    
                    System.debug(LoggingLevel.DEBUG, 'Record ' + recordId + ' has name: ' + nameValue + ', fieldKeys: ' + fieldKeys);
                    
                    if (nameValue != null && fieldKeys != null) {
                        String nameString = String.valueOf(nameValue);
                        // Update ALL field keys that reference this record ID
                        for (String fieldKey : fieldKeys) {
                            result.put(fieldKey, nameString);
                            System.debug(LoggingLevel.DEBUG, 'Set result: ' + fieldKey + ' -> ' + nameString);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error resolving lookup names for ' + objectType + ': ' + e.getMessage());
            }
        }
        
        System.debug(LoggingLevel.INFO, 'Returning ' + result.size() + ' resolved names');
        return result;
    }

    /**
     * Get the name field for an object type
     */
    private static String getNameField(String objectType) {
        // Special cases for objects with different name fields
        Map<String, String> nameFieldMap = new Map<String, String>{
            'Case' => 'CaseNumber',
            'Task' => 'Subject',
            'Event' => 'Subject',
            'Solution' => 'SolutionNumber',
            'Contract' => 'ContractNumber'
        };
        
        if (nameFieldMap.containsKey(objectType)) {
            return nameFieldMap.get(objectType);
        }
        
        // For Contact, use FirstName + LastName
        if (objectType == 'Contact') {
            return 'Name';
        }
        
        // Default to Name field
        return 'Name';
    }
}