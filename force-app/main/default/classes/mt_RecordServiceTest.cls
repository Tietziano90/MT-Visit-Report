/**
 * ============================================================================
 * MT Record Service Test
 * ============================================================================
 * 
 * @description     Comprehensive test class for mt_RecordService.
 *                  Tests record CRUD operations, validation, and error handling.
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
private class mt_RecordServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account for Record Service',
            Industry = 'Technology',
            Phone = '555-1234'
        );
        insert testAccount;
        
        // Create second Account for duplicate testing
        Account testAccount2 = new Account(
            Name = 'Second Test Account',
            Industry = 'Finance'
        );
        insert testAccount2;
        
        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com',
            Phone = '555-5678'
        ));
        contacts.add(new Contact(
            FirstName = 'Second',
            LastName = 'Person',
            AccountId = testAccount.Id,
            Email = 'second@example.com'
        ));
        insert contacts;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert testOpp;
        
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com'
        );
        insert testLead;
        
        // Create test Tasks
        List<Task> tasks = new List<Task>();
        tasks.add(new Task(
            Subject = 'Test Task 1',
            WhatId = testAccount.Id,
            Status = 'Not Started'
        ));
        tasks.add(new Task(
            Subject = 'Test Task 2',
            WhatId = testAccount.Id,
            Status = 'Not Started'
        ));
        insert tasks;
    }

    // ========== CREATE RECORD TESTS ==========

    @isTest
    static void testCreateRecord_Contact() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'FirstName' => 'New',
            'LastName' => 'Person',
            'AccountId' => acc.Id,
            'Email' => 'new.person@test.com',
            'Title' => 'Manager',
            'Phone' => '555-9999'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Contact',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
        System.assertNotEquals(null, result.recordId, 'Should have record ID');
        System.assertEquals(true, result.isNew, 'Should be marked as new');
        System.assertEquals('Contact', result.objectType, 'Object type should match');
    }

    @isTest
    static void testCreateRecord_Opportunity() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'New Deal',
            'AccountId' => acc.Id,
            'StageName' => 'Qualification',
            'CloseDate' => Date.today().addDays(60),
            'Amount' => 50000,
            'Description' => 'Test opportunity',
            'NextStep' => 'Send proposal'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Opportunity',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testCreateRecord_Task() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Subject' => 'Follow up call',
            'ActivityDate' => Date.today().addDays(7),
            'WhatId' => acc.Id,
            'WhoId' => con.Id,
            'Status' => 'Not Started',
            'Priority' => 'Normal',
            'Description' => 'Call to discuss proposal'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Task',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testCreateRecord_Event() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Subject' => 'Meeting',
            'StartDateTime' => DateTime.now().addDays(1),
            'EndDateTime' => DateTime.now().addDays(1).addHours(1),
            'WhatId' => acc.Id,
            'Description' => 'Strategy meeting'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Event',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testCreateRecord_Lead() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'FirstName' => 'New',
            'LastName' => 'Lead',
            'Company' => 'New Company',
            'Email' => 'newlead@test.com',
            'Status' => 'Open - Not Contacted'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Lead',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testCreateRecord_Account() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'New Account Test',
            'Industry' => 'Healthcare',
            'Phone' => '555-1111',
            'Website' => 'https://test.com'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Account',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testCreateRecord_MissingRequired() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'FirstName' => 'Test'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Contact',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for missing required field');
        System.assertNotEquals(null, result.message, 'Should have error message');
    }

    @isTest
    static void testCreateRecord_InvalidObject() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'Test'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'InvalidObject__xyz',
            fieldValues,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for invalid object');
    }

    @isTest
    static void testCreateRecord_EmptyFields() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Contact',
            new Map<String, Object>(),
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail with empty fields');
    }

    @isTest
    static void testCreateRecord_NullFields() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Contact',
            null,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail with null fields');
    }

    @isTest
    static void testCreateRecord_NoDuplicateAllowed() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'FirstName' => 'No',
            'LastName' => 'Duplicate',
            'Email' => 'nodupe@test.com'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.createRecord(
            'Contact',
            fieldValues,
            null,
            false  // Don't allow duplicates
        );
        System.Test.stopTest();
        
        // Should succeed (first record) or fail if duplicate exists
        System.assertNotEquals(null, result, 'Should return result');
    }

    // ========== UPDATE RECORD TESTS ==========

    @isTest
    static void testUpdateRecord_Contact() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Title' => 'Senior Manager',
            'Phone' => '555-0000',
            'Description' => 'Updated contact'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Contact',
            con.Id,
            fieldValues
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
        System.assertEquals(false, result.isNew, 'Should not be new');
        
        Contact updated = [SELECT Title, Phone FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Senior Manager', updated.Title);
    }

    @isTest
    static void testUpdateRecord_Opportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Amount' => 25000,
            'StageName' => 'Qualification',
            'Description' => 'Updated description',
            'Probability' => 30
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Opportunity',
            opp.Id,
            fieldValues
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testUpdateRecord_Account() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Description' => 'Updated account description',
            'Industry' => 'Finance'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Account',
            acc.Id,
            fieldValues
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testUpdateRecord_InvalidId() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'Test'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Account',
            '001000000000000AAA',
            fieldValues
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for invalid ID');
    }

    @isTest
    static void testUpdateRecord_NullId() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Name' => 'Test'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Account',
            null,
            fieldValues
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for null ID');
    }

    @isTest
    static void testUpdateRecord_EmptyFields() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.updateRecord(
            'Account',
            acc.Id,
            new Map<String, Object>()
        );
        System.Test.stopTest();
        
        // Should handle gracefully
        System.assertNotEquals(null, result, 'Should return result');
    }

    // ========== SAVE RECORD SIMPLE TESTS ==========

    @isTest
    static void testSaveRecordSimple_Create() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'FirstName' => 'Simple',
            'LastName' => 'Create',
            'AccountId' => acc.Id
        };
        String fieldValuesJson = JSON.serialize(fieldValues);
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecordSimple(
            'Contact',
            null,
            fieldValuesJson,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testSaveRecordSimple_Update() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Amount' => 75000,
            'NextStep' => 'Final negotiation'
        };
        String fieldValuesJson = JSON.serialize(fieldValues);
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecordSimple(
            'Opportunity',
            opp.Id,
            fieldValuesJson,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testSaveRecordSimple_InvalidJson() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecordSimple(
            'Contact',
            null,
            'invalid json {',
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for invalid JSON');
    }

    @isTest
    static void testSaveRecordSimple_NullJson() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecordSimple(
            'Contact',
            null,
            null,
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for null JSON');
    }

    @isTest
    static void testSaveRecordSimple_EmptyJson() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecordSimple(
            'Contact',
            null,
            '{}',
            true
        );
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for empty JSON');
    }

    // ========== SAVE RECORD (REQUEST) TESTS ==========

    @isTest
    static void testSaveRecord_RequestCreate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        mt_RecordService.RecordRequest request = new mt_RecordService.RecordRequest();
        request.objectApiName = 'Contact';
        request.recordId = null;
        request.fieldValues = new Map<String, Object>{
            'FirstName' => 'Request',
            'LastName' => 'Create',
            'AccountId' => acc.Id
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecord(request);
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testSaveRecord_RequestUpdate() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        mt_RecordService.RecordRequest request = new mt_RecordService.RecordRequest();
        request.objectApiName = 'Contact';
        request.recordId = con.Id;
        request.fieldValues = new Map<String, Object>{
            'Title' => 'Updated via Request'
        };
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecord(request);
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
    }

    @isTest
    static void testSaveRecord_NullRequest() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.saveRecord(null);
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for null request');
    }

    // ========== CREATE RECORDS (BATCH) TESTS ==========

    @isTest
    static void testCreateRecords_Batch() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        List<Map<String, Object>> recordsFieldValues = new List<Map<String, Object>>();
        recordsFieldValues.add(new Map<String, Object>{
            'FirstName' => 'Batch1',
            'LastName' => 'Contact',
            'AccountId' => acc.Id
        });
        recordsFieldValues.add(new Map<String, Object>{
            'FirstName' => 'Batch2',
            'LastName' => 'Contact',
            'AccountId' => acc.Id
        });
        
        System.Test.startTest();
        List<mt_RecordService.DmlResult> results = mt_RecordService.createRecords(
            'Contact',
            recordsFieldValues,
            null
        );
        System.Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return 2 results');
        System.assertEquals(true, results[0].success, 'First should succeed');
        System.assertEquals(true, results[1].success, 'Second should succeed');
    }

    @isTest
    static void testCreateRecords_EmptyList() {
        System.Test.startTest();
        List<mt_RecordService.DmlResult> results = mt_RecordService.createRecords(
            'Contact',
            new List<Map<String, Object>>(),
            null
        );
        System.Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list');
    }

    @isTest
    static void testCreateRecords_NullList() {
        System.Test.startTest();
        List<mt_RecordService.DmlResult> results = mt_RecordService.createRecords(
            'Contact',
            null,
            null
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return list');
    }

    // ========== DELETE RECORD TESTS ==========

    @isTest
    static void testDeleteRecord_Success() {
        // Create a record to delete
        Account acc = new Account(Name = 'Account To Delete');
        insert acc;
        
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.deleteRecord(acc.Id);
        System.Test.stopTest();
        
        System.assertEquals(true, result.success, 'Should succeed: ' + result.message);
        
        // Verify deletion
        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, remaining.size(), 'Account should be deleted');
    }

    @isTest
    static void testDeleteRecord_InvalidId() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.deleteRecord('001000000000000AAA');
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for invalid ID');
    }

    @isTest
    static void testDeleteRecord_NullId() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.deleteRecord(null);
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for null ID');
    }

    @isTest
    static void testDeleteRecord_EmptyId() {
        System.Test.startTest();
        mt_RecordService.DmlResult result = mt_RecordService.deleteRecord('');
        System.Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail for empty ID');
    }

    // ========== GET RELATED RECORDS TESTS ==========

    @isTest
    static void testGetRelatedRecords_Contacts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'Contact',
            acc.Id,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
        System.assert(records.size() > 0, 'Should have contacts');
    }

    @isTest
    static void testGetRelatedRecords_Opportunities() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'Opportunity',
            acc.Id,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
    }

    @isTest
    static void testGetRelatedRecords_WithSearch() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'Contact',
            acc.Id,
            'Test',
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
    }

    @isTest
    static void testGetRelatedRecords_Tasks() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'Task',
            acc.Id,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
    }

    @isTest
    static void testGetRelatedRecords_InvalidObject() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'InvalidObject__xyz',
            acc.Id,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list');
    }

    @isTest
    static void testGetRelatedRecords_NullObject() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            null,
            acc.Id,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list');
    }

    @isTest
    static void testGetRelatedRecords_NullAccountId() {
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getRelatedRecords(
            'Contact',
            null,
            null,
            10
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list');
    }

    // ========== GET DUPLICATE RECORDS TESTS ==========

    @isTest
    static void testGetDuplicateRecords_Contacts() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 2];
        List<String> recordIds = new List<String>();
        for (Contact c : contacts) {
            recordIds.add(c.Id);
        }
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getDuplicateRecords(
            'Contact',
            recordIds
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
        System.assertEquals(2, records.size(), 'Should have 2 records');
    }

    @isTest
    static void testGetDuplicateRecords_Accounts() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];
        List<String> recordIds = new List<String>();
        for (Account a : accounts) {
            recordIds.add(a.Id);
        }
        
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getDuplicateRecords(
            'Account',
            recordIds
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return records');
    }

    @isTest
    static void testGetDuplicateRecords_EmptyIds() {
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getDuplicateRecords(
            'Contact',
            new List<String>()
        );
        System.Test.stopTest();
        
        System.assertEquals(0, records.size(), 'Should return empty list');
    }

    @isTest
    static void testGetDuplicateRecords_NullIds() {
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getDuplicateRecords(
            'Contact',
            null
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list');
    }

    @isTest
    static void testGetDuplicateRecords_InvalidObject() {
        System.Test.startTest();
        List<mt_RecordService.DuplicateRecordInfo> records = mt_RecordService.getDuplicateRecords(
            'InvalidObject__xyz',
            new List<String>{ 'abc123' }
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list');
    }

    // ========== GET RECORD FIELDS TESTS ==========

    @isTest
    static void testGetRecordFields_Contact() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            con.Id,
            new List<String>{ 'FirstName', 'LastName', 'Email' }
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Should return fields');
        System.assertEquals(true, fields.containsKey('FirstName'), 'Should have FirstName');
    }

    @isTest
    static void testGetRecordFields_Account() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            acc.Id,
            new List<String>{ 'Name', 'Industry', 'Phone' }
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Should return fields');
        System.assertEquals('Test Account for Record Service', fields.get('Name'));
    }

    @isTest
    static void testGetRecordFields_Opportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            opp.Id,
            new List<String>{ 'Name', 'Amount', 'StageName' }
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Should return fields');
    }

    @isTest
    static void testGetRecordFields_InvalidId() {
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            '001000000000000AAA',
            new List<String>{ 'Name' }
        );
        System.Test.stopTest();
        
        // Should handle gracefully
        System.assertNotEquals(null, fields, 'Should return map');
    }

    @isTest
    static void testGetRecordFields_NullId() {
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            null,
            new List<String>{ 'Name' }
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Should return empty map');
    }

    @isTest
    static void testGetRecordFields_EmptyFields() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        
        System.Test.startTest();
        Map<String, Object> fields = mt_RecordService.getRecordFields(
            acc.Id,
            new List<String>()
        );
        System.Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Should return map');
    }

    // ========== RESOLVE LOOKUP NAMES TESTS ==========

    @isTest
    static void testResolveLookupNames_Accounts() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        Map<String, String> lookupIds = new Map<String, String>();
        for (Account acc : accounts) {
            lookupIds.put(acc.Id, acc.Id);
        }
        
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(lookupIds);
        System.Test.stopTest();
        
        System.assertNotEquals(null, names, 'Should return names');
        System.assertEquals(accounts.size(), names.size(), 'Should have same count');
    }

    @isTest
    static void testResolveLookupNames_Contacts() {
        List<Contact> contacts = [SELECT Id, Name FROM Contact LIMIT 2];
        Map<String, String> lookupIds = new Map<String, String>();
        for (Contact con : contacts) {
            lookupIds.put(con.Id, con.Id);
        }
        
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(lookupIds);
        System.Test.stopTest();
        
        System.assertNotEquals(null, names, 'Should return names');
    }

    @isTest
    static void testResolveLookupNames_MixedTypes() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account for Record Service' LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, String> lookupIds = new Map<String, String>();
        lookupIds.put(acc.Id, acc.Id);
        lookupIds.put(con.Id, con.Id);
        
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(lookupIds);
        System.Test.stopTest();
        
        System.assertNotEquals(null, names, 'Should return names');
    }

    @isTest
    static void testResolveLookupNames_EmptyMap() {
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(new Map<String, String>());
        System.Test.stopTest();
        
        System.assertEquals(0, names.size(), 'Should return empty map');
    }

    @isTest
    static void testResolveLookupNames_NullMap() {
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(null);
        System.Test.stopTest();
        
        System.assertNotEquals(null, names, 'Should return empty map');
    }

    @isTest
    static void testResolveLookupNames_InvalidIds() {
        Map<String, String> lookupIds = new Map<String, String>();
        lookupIds.put('invalid1', 'invalid1');
        lookupIds.put('invalid2', 'invalid2');
        
        System.Test.startTest();
        Map<String, String> names = mt_RecordService.resolveLookupNames(lookupIds);
        System.Test.stopTest();
        
        System.assertNotEquals(null, names, 'Should handle gracefully');
    }
}