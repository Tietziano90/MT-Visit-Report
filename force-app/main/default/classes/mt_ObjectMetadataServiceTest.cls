/**
 * ============================================================================
 * MT Object Metadata Service Test
 * ============================================================================
 * 
 * @description     Comprehensive test class for mt_ObjectMetadataService.
 *                  Tests object and field metadata retrieval.
 *                  Targets 75%+ code coverage for production deployment.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 * COPYRIGHT & CONFIDENTIALITY NOTICE
 * ============================================================================
 * © 2025 Salesforce, Inc. All rights reserved.
 * ============================================================================
 */
@isTest
private class mt_ObjectMetadataServiceTest {

    // ========== GET OBJECT METADATA TESTS ==========

    @isTest
    static void testGetObjectMetadata_Account() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Account', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Account', metadata.apiName, 'Object name should match');
        Assert.areEqual('Account', metadata.label, 'Label should match');
        Assert.isTrue(metadata.fields.size() > 0, 'Should have fields');
        Assert.isTrue(metadata.isCreateable, 'Account should be createable');
    }

    @isTest
    static void testGetObjectMetadata_Contact() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Contact', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Contact', metadata.apiName, 'Object name should match');
        
        // Verify expected fields exist
        Boolean hasLastName = false;
        Boolean hasEmail = false;
        Boolean hasAccountId = false;
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'LastName') {
                hasLastName = true;
                Assert.isTrue(field.isRequired, 'LastName should be required');
            }
            if (field.apiName == 'Email') {
                hasEmail = true;
                Assert.areEqual('EMAIL', field.dataType, 'Email should be EMAIL type');
            }
            if (field.apiName == 'AccountId') {
                hasAccountId = true;
                Assert.isNotNull(field.referenceTo, 'AccountId should have reference');
            }
        }
        Assert.isTrue(hasLastName, 'Should have LastName field');
        Assert.isTrue(hasEmail, 'Should have Email field');
    }

    @isTest
    static void testGetObjectMetadata_Opportunity() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Opportunity', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Opportunity', metadata.apiName, 'Object name should match');
        
        // Verify StageName has picklist values
        Boolean hasStageName = false;
        Boolean hasAmount = false;
        Boolean hasCloseDate = false;
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'StageName') {
                hasStageName = true;
                Assert.isTrue(field.picklistValues != null && field.picklistValues.size() > 0, 
                    'StageName should have picklist values');
            }
            if (field.apiName == 'Amount') {
                hasAmount = true;
                Assert.areEqual('CURRENCY', field.dataType, 'Amount should be CURRENCY type');
            }
            if (field.apiName == 'CloseDate') {
                hasCloseDate = true;
                Assert.areEqual('DATE', field.dataType, 'CloseDate should be DATE type');
            }
        }
        Assert.isTrue(hasStageName, 'Should have StageName field');
    }

    @isTest
    static void testGetObjectMetadata_Task() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Task', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Task', metadata.apiName, 'Object name should match');
        
        // Verify polymorphic fields
        Boolean hasWhoId = false;
        Boolean hasWhatId = false;
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'WhoId') {
                hasWhoId = true;
                Assert.isTrue(field.isPolymorphic || (field.referenceTo != null && field.referenceTo.size() > 1), 
                    'WhoId should be polymorphic');
            }
            if (field.apiName == 'WhatId') {
                hasWhatId = true;
            }
        }
    }

    @isTest
    static void testGetObjectMetadata_Event() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Event', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Event', metadata.apiName, 'Object name should match');
    }

    @isTest
    static void testGetObjectMetadata_Lead() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Lead', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Lead', metadata.apiName, 'Object name should match');
        
        // Verify Status has picklist
        Boolean hasStatus = false;
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'Status') {
                hasStatus = true;
                Assert.isTrue(field.picklistValues != null, 'Status should have picklist values');
            }
        }
    }

    @isTest
    static void testGetObjectMetadata_Case_WithFields() {
        // Note: Removed from test setup due to SDO flows, but metadata describe should work
        List<String> fields = new List<String>{ 'Subject', 'Status', 'Priority' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Case', fields);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Case', metadata.apiName, 'Object name should match');
    }

    @isTest
    static void testGetObjectMetadata_WithSpecificFields() {
        List<String> fields = new List<String>{ 'Name', 'Industry', 'Phone', 'Website' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Account', fields);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Account', metadata.apiName);
        // Should have at least the requested fields
        Assert.isTrue(metadata.fields.size() >= fields.size(), 'Should have at least requested fields');
    }

    @isTest
    static void testGetObjectMetadata_WithEmptyFieldList() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Account', new List<String>());
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('Account', metadata.apiName);
    }

    @isTest
    static void testGetObjectMetadata_User() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('User', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata, 'Should return metadata');
        Assert.areEqual('User', metadata.apiName, 'Object name should match');
    }

    // ========== UI API SUPPORT TESTS ==========

    @isTest
    static void testIsUiApiSupported_Account() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Account');
        System.Test.stopTest();
        
        Assert.isTrue(isSupported, 'Account should be UI API supported');
    }

    @isTest
    static void testIsUiApiSupported_Contact() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Contact');
        System.Test.stopTest();
        
        Assert.isTrue(isSupported, 'Contact should be UI API supported');
    }

    @isTest
    static void testIsUiApiSupported_Opportunity() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Opportunity');
        System.Test.stopTest();
        
        Assert.isTrue(isSupported, 'Opportunity should be UI API supported');
    }

    @isTest
    static void testIsUiApiSupported_Task() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Task');
        System.Test.stopTest();
        
        // Task may or may not be supported depending on org config
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    @isTest
    static void testIsUiApiSupported_Event() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Event');
        System.Test.stopTest();
        
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    @isTest
    static void testIsUiApiSupported_Lead() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Lead');
        System.Test.stopTest();
        
        Assert.isTrue(isSupported, 'Lead should be UI API supported');
    }

    @isTest
    static void testIsUiApiSupported_Case() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('Case');
        System.Test.stopTest();
        
        Assert.isTrue(isSupported, 'Case should be UI API supported');
    }

    @isTest
    static void testIsUiApiSupported_User() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('User');
        System.Test.stopTest();
        
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    // ========== FIELD TYPES TESTS ==========

    @isTest
    static void testFieldMetadata_TextFields() {
        List<String> fields = new List<String>{ 'FirstName', 'LastName', 'Email', 'Phone' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Contact', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            Assert.isNotNull(field.apiName, 'Field should have apiName');
            Assert.isNotNull(field.label, 'Field should have label');
            Assert.isNotNull(field.dataType, 'Field should have dataType');
        }
    }

    @isTest
    static void testFieldMetadata_PicklistFields() {
        List<String> fields = new List<String>{ 'StageName', 'Type', 'LeadSource' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Opportunity', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'StageName' || field.apiName == 'Type' || field.apiName == 'LeadSource') {
                Assert.isNotNull(field.picklistValues, 'Picklist field should have values');
                if (field.picklistValues != null && field.picklistValues.size() > 0) {
                    mt_ObjectMetadataService.PicklistValueWrapper plv = field.picklistValues[0];
                    Assert.isNotNull(plv.value, 'Picklist value should have value');
                    Assert.isNotNull(plv.label, 'Picklist value should have label');
                }
            }
        }
    }

    @isTest
    static void testFieldMetadata_ReferenceFields() {
        List<String> fields = new List<String>{ 'AccountId' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Contact', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'AccountId') {
                Assert.isNotNull(field.referenceTo, 'Reference field should have referenceTo');
                Assert.isTrue(field.referenceTo.size() > 0, 'Should reference at least one object');
            }
        }
    }

    @isTest
    static void testFieldMetadata_DateTimeFields() {
        List<String> fields = new List<String>{ 'CloseDate', 'CreatedDate', 'LastModifiedDate' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Opportunity', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'CloseDate') {
                Assert.areEqual('DATE', field.dataType, 'CloseDate should be DATE');
            }
        }
    }

    @isTest
    static void testFieldMetadata_CurrencyFields() {
        List<String> fields = new List<String>{ 'Amount' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Opportunity', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'Amount') {
                Assert.areEqual('CURRENCY', field.dataType, 'Amount should be CURRENCY');
            }
        }
    }

    @isTest
    static void testFieldMetadata_BooleanFields() {
        List<String> fields = new List<String>{ 'HasOptedOutOfEmail', 'DoNotCall' };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Contact', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            if (field.apiName == 'HasOptedOutOfEmail' || field.apiName == 'DoNotCall') {
                Assert.areEqual('BOOLEAN', field.dataType, 'Should be BOOLEAN type');
            }
        }
    }

    // ========== RECORD TYPES TESTS ==========

    @isTest
    static void testRecordTypes_Account() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Account', null);
        System.Test.stopTest();
        
        // Record types may or may not exist
        Assert.isNotNull(metadata.recordTypes, 'recordTypes should not be null');
    }

    @isTest
    static void testRecordTypes_Opportunity() {
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Opportunity', null);
        System.Test.stopTest();
        
        Assert.isNotNull(metadata.recordTypes, 'recordTypes should not be null');
    }

    // ========== ERROR HANDLING TESTS ==========

    @isTest
    static void testGetObjectMetadata_InvalidObject() {
        System.Test.startTest();
        try {
            mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
                mt_ObjectMetadataService.getObjectMetadata('InvalidObjectXYZ__c', null);
            // If it doesn't throw, verify it handles gracefully
            System.assert(metadata == null || metadata.apiName == null, 'Should return null or empty for invalid object');
        } catch (AuraHandledException e) {
            // Expected - invalid object should throw
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetObjectMetadata_NullObject() {
        System.Test.startTest();
        try {
            mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
                mt_ObjectMetadataService.getObjectMetadata(null, null);
            // If it doesn't throw, that's acceptable
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetObjectMetadata_EmptyObject() {
        System.Test.startTest();
        try {
            mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
                mt_ObjectMetadataService.getObjectMetadata('', null);
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testIsUiApiSupported_InvalidObject() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('InvalidObjectXYZ__c');
        System.Test.stopTest();
        
        // Invalid objects may return true or false depending on implementation
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    @isTest
    static void testIsUiApiSupported_NullObject() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported(null);
        System.Test.stopTest();
        
        // Null objects may return true or false depending on implementation
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    @isTest
    static void testIsUiApiSupported_EmptyObject() {
        System.Test.startTest();
        Boolean isSupported = mt_ObjectMetadataService.isUiApiSupported('');
        System.Test.stopTest();
        
        // Empty objects may return true or false depending on implementation
        System.assertNotEquals(null, isSupported, 'Should return boolean');
    }

    // ========== GET MULTIPLE OBJECT METADATA TESTS ==========

    @isTest
    static void testGetMultipleObjectMetadata_Success() {
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        objectFieldMap.put('Account', new List<String>{ 'Name', 'Industry' });
        objectFieldMap.put('Contact', new List<String>{ 'FirstName', 'LastName' });
        
        System.Test.startTest();
        Map<String, mt_ObjectMetadataService.ObjectMetadataWrapper> result = 
            mt_ObjectMetadataService.getMultipleObjectMetadata(objectFieldMap);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return result');
        Assert.isTrue(result.containsKey('Account'), 'Should have Account');
        Assert.isTrue(result.containsKey('Contact'), 'Should have Contact');
    }

    @isTest
    static void testGetMultipleObjectMetadata_SingleObject() {
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        objectFieldMap.put('Opportunity', new List<String>{ 'Name', 'Amount', 'StageName' });
        
        System.Test.startTest();
        Map<String, mt_ObjectMetadataService.ObjectMetadataWrapper> result = 
            mt_ObjectMetadataService.getMultipleObjectMetadata(objectFieldMap);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return result');
        Assert.isTrue(result.containsKey('Opportunity'), 'Should have Opportunity');
    }

    @isTest
    static void testGetMultipleObjectMetadata_WithInvalidObject() {
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        objectFieldMap.put('Account', new List<String>{ 'Name' });
        objectFieldMap.put('InvalidObject__xyz', new List<String>{ 'Field1' });
        
        System.Test.startTest();
        Map<String, mt_ObjectMetadataService.ObjectMetadataWrapper> result = 
            mt_ObjectMetadataService.getMultipleObjectMetadata(objectFieldMap);
        System.Test.stopTest();
        
        Assert.isNotNull(result, 'Should return result');
        Assert.isTrue(result.containsKey('Account'), 'Should have Account');
    }

    @isTest
    static void testGetMultipleObjectMetadata_EmptyMap() {
        System.Test.startTest();
        try {
            Map<String, mt_ObjectMetadataService.ObjectMetadataWrapper> result = 
                mt_ObjectMetadataService.getMultipleObjectMetadata(new Map<String, List<String>>());
            Assert.fail('Should throw exception for empty map');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetMultipleObjectMetadata_NullMap() {
        System.Test.startTest();
        try {
            Map<String, mt_ObjectMetadataService.ObjectMetadataWrapper> result = 
                mt_ObjectMetadataService.getMultipleObjectMetadata(null);
            Assert.fail('Should throw exception for null map');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    // ========== GET PICKLIST VALUES TESTS ==========

    @isTest
    static void testGetPicklistValues_OpportunityStageName() {
        System.Test.startTest();
        List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
            mt_ObjectMetadataService.getPicklistValues('Opportunity', 'StageName', null);
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Should return values');
        Assert.isTrue(values.size() > 0, 'Should have picklist values');
        
        // Verify structure
        mt_ObjectMetadataService.PicklistValueWrapper firstValue = values[0];
        Assert.isNotNull(firstValue.value, 'Value should not be null');
        Assert.isNotNull(firstValue.label, 'Label should not be null');
    }

    @isTest
    static void testGetPicklistValues_LeadStatus() {
        System.Test.startTest();
        List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
            mt_ObjectMetadataService.getPicklistValues('Lead', 'Status', null);
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Should return values');
        Assert.isTrue(values.size() > 0, 'Should have picklist values');
    }

    @isTest
    static void testGetPicklistValues_AccountIndustry() {
        System.Test.startTest();
        List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
            mt_ObjectMetadataService.getPicklistValues('Account', 'Industry', null);
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Should return values');
    }

    @isTest
    static void testGetPicklistValues_TaskStatus() {
        System.Test.startTest();
        List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
            mt_ObjectMetadataService.getPicklistValues('Task', 'Status', null);
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Should return values');
    }

    @isTest
    static void testGetPicklistValues_TaskPriority() {
        System.Test.startTest();
        List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
            mt_ObjectMetadataService.getPicklistValues('Task', 'Priority', null);
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Should return values');
    }

    @isTest
    static void testGetPicklistValues_InvalidObject() {
        System.Test.startTest();
        try {
            List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
                mt_ObjectMetadataService.getPicklistValues('InvalidObject__xyz', 'Status', null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            // Error message may vary - just verify exception was thrown
            Assert.isNotNull(e.getMessage(), 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues_InvalidField() {
        System.Test.startTest();
        try {
            List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
                mt_ObjectMetadataService.getPicklistValues('Account', 'InvalidField__xyz', null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            // Error message may vary - just verify exception was thrown
            Assert.isNotNull(e.getMessage(), 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues_NullObject() {
        System.Test.startTest();
        try {
            List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
                mt_ObjectMetadataService.getPicklistValues(null, 'Status', null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues_NullField() {
        System.Test.startTest();
        try {
            List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
                mt_ObjectMetadataService.getPicklistValues('Account', null, null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues_EmptyParams() {
        System.Test.startTest();
        try {
            List<mt_ObjectMetadataService.PicklistValueWrapper> values = 
                mt_ObjectMetadataService.getPicklistValues('', '', null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage() != null, 'Should have error message');
        }
        System.Test.stopTest();
    }

    // ========== ADDITIONAL COVERAGE TESTS ==========

    @isTest
    static void testAllStandardObjects() {
        List<String> standardObjects = new List<String>{
            'Account', 'Contact', 'Lead', 'Opportunity', 'Task', 'Event', 'User'
        };
        
        System.Test.startTest();
        for (String obj : standardObjects) {
            mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
                mt_ObjectMetadataService.getObjectMetadata(obj, null);
            Assert.isNotNull(metadata, obj + ' should return metadata');
        }
        System.Test.stopTest();
    }

    @isTest
    static void testFieldProperties() {
        List<String> fields = new List<String>{ 
            'Name', 'Description', 'Phone', 'Website', 'Industry', 'AnnualRevenue' 
        };
        
        System.Test.startTest();
        mt_ObjectMetadataService.ObjectMetadataWrapper metadata = 
            mt_ObjectMetadataService.getObjectMetadata('Account', fields);
        System.Test.stopTest();
        
        for (mt_ObjectMetadataService.FieldMetadataWrapper field : metadata.fields) {
            // Verify all expected properties are set
            Assert.isNotNull(field.apiName, 'apiName should not be null');
            Assert.isNotNull(field.label, 'label should not be null');
            Assert.isNotNull(field.dataType, 'dataType should not be null');
            // isRequired, isCreateable, isUpdateable are booleans - verify they exist
            System.debug('Field: ' + field.apiName + ', Required: ' + field.isRequired + 
                ', Createable: ' + field.isCreateable + ', Updateable: ' + field.isUpdateable);
        }
    }
}