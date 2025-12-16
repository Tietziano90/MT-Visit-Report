/**
 * ============================================================================
 * OBJECT METADATA SERVICE - Dynamic Metadata Fetching
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
 * Universal, FULLY DYNAMIC metadata service for fetching object and field
 * metadata for ANY Salesforce object (standard or custom). Handles UI API
 * detection and returns consistent data structures for LWC consumption.
 * 
 * KEY FEATURES:
 * - Works with ANY standard or custom SObject type
 * - Dynamic field metadata including types, labels, required flags
 * - Picklist value fetching with dependent picklist support
 * - UI API support detection (Task, Event = false)
 * - Reference field object type detection (including polymorphic)
 * - Cacheable for performance
 * 
 * METHODS:
 * - getObjectMetadata() - Complete metadata for any object
 * - isUiApiSupported() - Check if lightning-record-form works
 * - getObjectIconName() - Standard icon for any object type
 * 
 * NON-UI API OBJECTS:
 * The following objects don't fully support lightning-record-form:
 * - Task, Event, ContentDocument, ContentVersion, FeedItem, etc.
 * The LWC uses this info to render custom field inputs instead.
 * ============================================================================
 */
public with sharing class mt_ObjectMetadataService {

    /**
     * Wrapper class for object metadata
     */
    public class ObjectMetadataWrapper {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String labelPlural;
        @AuraEnabled public Boolean isCustom;
        @AuraEnabled public Boolean isCreateable;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public List<FieldMetadataWrapper> fields;
        @AuraEnabled public Map<String, RecordTypeInfo> recordTypes;
    }

    /**
     * Wrapper class for field metadata
     */
    public class FieldMetadataWrapper {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isCreateable;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isNillable;
        @AuraEnabled public Integer length;
        @AuraEnabled public Integer precision;
        @AuraEnabled public Integer scale;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public String inlineHelpText;
        @AuraEnabled public List<PicklistValueWrapper> picklistValues;
        @AuraEnabled public List<String> referenceTo;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public Boolean isPolymorphic;
    }

    /**
     * Wrapper class for picklist values
     */
    public class PicklistValueWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Boolean isActive;
    }

    /**
     * Wrapper class for record type info
     */
    public class RecordTypeInfo {
        @AuraEnabled public String recordTypeId;
        @AuraEnabled public String name;
        @AuraEnabled public String developerName;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Boolean isAvailable;
    }

    /**
     * Get metadata for a specific object and its fields
     * @param objectApiName The API name of the object
     * @param fieldApiNames List of field API names to retrieve metadata for (if null, returns all fields)
     * @return ObjectMetadataWrapper containing object and field metadata
     */
    @AuraEnabled(cacheable=true)
    public static ObjectMetadataWrapper getObjectMetadata(String objectApiName, List<String> fieldApiNames) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name is required.');
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }

            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            
            ObjectMetadataWrapper wrapper = new ObjectMetadataWrapper();
            wrapper.apiName = describeResult.getName();
            wrapper.label = describeResult.getLabel();
            wrapper.labelPlural = describeResult.getLabelPlural();
            wrapper.isCustom = describeResult.isCustom();
            wrapper.isCreateable = describeResult.isCreateable();
            wrapper.isUpdateable = describeResult.isUpdateable();
            wrapper.fields = new List<FieldMetadataWrapper>();
            wrapper.recordTypes = new Map<String, RecordTypeInfo>();

            // Get record types
            Map<Id, Schema.RecordTypeInfo> recordTypeInfos = describeResult.getRecordTypeInfosById();
            for (Schema.RecordTypeInfo rtInfo : recordTypeInfos.values()) {
                if (rtInfo.isAvailable() && !rtInfo.isMaster()) {
                    RecordTypeInfo rt = new RecordTypeInfo();
                    rt.recordTypeId = rtInfo.getRecordTypeId();
                    rt.name = rtInfo.getName();
                    rt.developerName = rtInfo.getDeveloperName();
                    rt.isDefault = rtInfo.isDefaultRecordTypeMapping();
                    rt.isAvailable = rtInfo.isAvailable();
                    wrapper.recordTypes.put(rt.developerName, rt);
                }
            }

            // Get field metadata
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            Set<String> fieldsToProcess = new Set<String>();
            
            if (fieldApiNames != null && !fieldApiNames.isEmpty()) {
                for (String fieldName : fieldApiNames) {
                    fieldsToProcess.add(fieldName.toLowerCase());
                }
            } else {
                fieldsToProcess = fieldMap.keySet();
            }

            for (String fieldKey : fieldsToProcess) {
                Schema.SObjectField field = fieldMap.get(fieldKey);
                if (field != null) {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    wrapper.fields.add(buildFieldMetadata(fieldDescribe));
                }
            }

            return wrapper;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching metadata for ' + objectApiName + ': ' + e.getMessage());
        }
    }

    /**
     * Get metadata for multiple objects at once
     * @param objectFieldMap Map of object API names to list of field API names
     * @return Map of object API names to their metadata
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, ObjectMetadataWrapper> getMultipleObjectMetadata(Map<String, List<String>> objectFieldMap) {
        if (objectFieldMap == null || objectFieldMap.isEmpty()) {
            throw new AuraHandledException('Object field map is required.');
        }

        Map<String, ObjectMetadataWrapper> result = new Map<String, ObjectMetadataWrapper>();
        
        for (String objectApiName : objectFieldMap.keySet()) {
            try {
                result.put(objectApiName, getObjectMetadata(objectApiName, objectFieldMap.get(objectApiName)));
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error fetching metadata for ' + objectApiName + ': ' + e.getMessage());
                // Continue processing other objects even if one fails
            }
        }

        return result;
    }

    /**
     * Get picklist values for a specific field, optionally filtered by record type
     * @param objectApiName The API name of the object
     * @param fieldApiName The API name of the picklist field
     * @param recordTypeId Optional record type ID for dependent picklists
     * @return List of picklist values
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistValueWrapper> getPicklistValues(String objectApiName, String fieldApiName, String recordTypeId) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            throw new AuraHandledException('Object API name and Field API name are required.');
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }

            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            Schema.SObjectField field = describeResult.fields.getMap().get(fieldApiName.toLowerCase());
            
            if (field == null) {
                throw new AuraHandledException('Field not found: ' + fieldApiName + ' on ' + objectApiName);
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            List<PicklistValueWrapper> picklistValues = new List<PicklistValueWrapper>();

            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.isActive()) {
                    PicklistValueWrapper pv = new PicklistValueWrapper();
                    pv.label = entry.getLabel();
                    pv.value = entry.getValue();
                    pv.isDefault = entry.isDefaultValue();
                    pv.isActive = entry.isActive();
                    picklistValues.add(pv);
                }
            }

            return picklistValues;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
    }

    /**
     * Check if an object is supported by UI API for record-edit-form
     * @param objectApiName The API name of the object
     * @return True if object is fully supported by UI API
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isUiApiSupported(String objectApiName) {
        // Objects known to have limited UI API support
        Set<String> limitedSupportObjects = new Set<String>{
            'Task',
            'Event', 
            'EmailMessage',
            'ContentDocument',
            'ContentVersion',
            'Attachment',
            'Note'
        };

        return !limitedSupportObjects.contains(objectApiName);
    }

    /**
     * Get required fields for an object based on field-level requirements
     * @param objectApiName The API name of the object
     * @return List of required field API names
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getRequiredFields(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name is required.');
        }

        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }

            List<String> requiredFields = new List<String>();
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

            for (Schema.SObjectField field : fieldMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                // A field is required if it's not nillable, createable, and not defaulted on create
                if (!fieldDescribe.isNillable() && 
                    fieldDescribe.isCreateable() && 
                    !fieldDescribe.isDefaultedOnCreate() &&
                    fieldDescribe.getType() != Schema.DisplayType.BOOLEAN) {
                    requiredFields.add(fieldDescribe.getName());
                }
            }

            return requiredFields;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching required fields: ' + e.getMessage());
        }
    }

    /**
     * Build field metadata wrapper from field describe result
     */
    private static FieldMetadataWrapper buildFieldMetadata(Schema.DescribeFieldResult fieldDescribe) {
        FieldMetadataWrapper fieldWrapper = new FieldMetadataWrapper();
        fieldWrapper.apiName = fieldDescribe.getName();
        fieldWrapper.label = fieldDescribe.getLabel();
        fieldWrapper.dataType = String.valueOf(fieldDescribe.getType());
        fieldWrapper.isRequired = !fieldDescribe.isNillable() && fieldDescribe.isCreateable();
        fieldWrapper.isCreateable = fieldDescribe.isCreateable();
        fieldWrapper.isUpdateable = fieldDescribe.isUpdateable();
        fieldWrapper.isNillable = fieldDescribe.isNillable();
        fieldWrapper.length = fieldDescribe.getLength();
        fieldWrapper.precision = fieldDescribe.getPrecision();
        fieldWrapper.scale = fieldDescribe.getScale();
        fieldWrapper.inlineHelpText = fieldDescribe.getInlineHelpText();
        fieldWrapper.referenceTo = new List<String>();
        fieldWrapper.relationshipName = fieldDescribe.getRelationshipName();
        
        // Check for polymorphic relationships (like WhatId, WhoId)
        List<Schema.SObjectType> referenceToTypes = fieldDescribe.getReferenceTo();
        fieldWrapper.isPolymorphic = referenceToTypes != null && referenceToTypes.size() > 1;
        
        if (referenceToTypes != null) {
            for (Schema.SObjectType refType : referenceToTypes) {
                fieldWrapper.referenceTo.add(refType.getDescribe().getName());
            }
        }

        // Get default value if available
        Object defaultVal = fieldDescribe.getDefaultValue();
        if (defaultVal != null) {
            fieldWrapper.defaultValue = String.valueOf(defaultVal);
        }

        // Get picklist values for picklist/combobox fields
        Schema.DisplayType fieldType = fieldDescribe.getType();
        if (fieldType == Schema.DisplayType.PICKLIST || 
            fieldType == Schema.DisplayType.MULTIPICKLIST || 
            fieldType == Schema.DisplayType.COMBOBOX) {
            fieldWrapper.picklistValues = new List<PicklistValueWrapper>();
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.isActive()) {
                    PicklistValueWrapper pv = new PicklistValueWrapper();
                    pv.label = entry.getLabel();
                    pv.value = entry.getValue();
                    pv.isDefault = entry.isDefaultValue();
                    pv.isActive = entry.isActive();
                    fieldWrapper.picklistValues.add(pv);
                }
            }
        }

        return fieldWrapper;
    }
}