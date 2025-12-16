/**
 * ============================================================================
 * MT Image File Service - Test Class
 * ============================================================================
 * 
 * @description     Test coverage for mt_ImageFileService
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
@isTest
private class mt_ImageFileServiceTest {
    
    // Simple 1x1 red pixel PNG in base64
    private static final String TEST_IMAGE_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
    
    @isTest
    static void testCreateImageDocument() {
        System.Test.startTest();
        
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            TEST_IMAGE_BASE64,
            'test_image.png',
            'image/png'
        );
        
        System.Test.stopTest();
        
        System.assertNotEquals(null, doc, 'ContentDocument should be created');
        System.assertNotEquals(null, doc.Id, 'ContentDocument should have an Id');
        System.assertEquals('test_image.png', doc.Title, 'Title should match');
    }
    
    @isTest
    static void testCreateImageDocumentWithNullData() {
        System.Test.startTest();
        
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            null,
            'test_image.png',
            'image/png'
        );
        
        System.Test.stopTest();
        
        System.assertEquals(null, doc, 'Should return null for null data');
    }
    
    @isTest
    static void testCreateImageDocumentWithEmptyData() {
        System.Test.startTest();
        
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            '',
            'test_image.png',
            'image/png'
        );
        
        System.Test.stopTest();
        
        System.assertEquals(null, doc, 'Should return null for empty data');
    }
    
    @isTest
    static void testInvocableCreateImageDocuments() {
        mt_ImageFileService.ImageDocumentRequest request = new mt_ImageFileService.ImageDocumentRequest();
        request.base64Data = TEST_IMAGE_BASE64;
        request.fileName = 'invocable_test.png';
        request.mimeType = 'image/png';
        
        List<mt_ImageFileService.ImageDocumentRequest> requests = new List<mt_ImageFileService.ImageDocumentRequest>{ request };
        
        System.Test.startTest();
        
        List<mt_ImageFileService.ImageDocumentResult> results = mt_ImageFileService.createImageDocuments(requests);
        
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should be successful');
        System.assertNotEquals(null, results[0].contentDocumentId, 'Should have ContentDocument Id');
    }
    
    @isTest
    static void testInvocableWithNoImage() {
        mt_ImageFileService.ImageDocumentRequest request = new mt_ImageFileService.ImageDocumentRequest();
        request.base64Data = null;
        request.fileName = 'no_image.png';
        request.mimeType = 'image/png';
        
        List<mt_ImageFileService.ImageDocumentRequest> requests = new List<mt_ImageFileService.ImageDocumentRequest>{ request };
        
        System.Test.startTest();
        
        List<mt_ImageFileService.ImageDocumentResult> results = mt_ImageFileService.createImageDocuments(requests);
        
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should be successful (no image is OK)');
    }
    
    @isTest
    static void testDeleteImageDocument() {
        // First create a document
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            TEST_IMAGE_BASE64,
            'to_delete.png',
            'image/png'
        );
        
        Id docId = doc.Id;
        
        System.Test.startTest();
        
        mt_ImageFileService.deleteImageDocument(docId);
        
        System.Test.stopTest();
        
        List<ContentDocument> remaining = [SELECT Id FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, remaining.size(), 'Document should be deleted');
    }
    
    @isTest
    static void testDeleteImageDocumentWithNull() {
        System.Test.startTest();
        
        // Should not throw exception
        mt_ImageFileService.deleteImageDocument(null);
        
        System.Test.stopTest();
        
        // If we get here, test passed
        System.assert(true, 'Should handle null without exception');
    }
    
    @isTest
    static void testCreateImageDocumentWithMultiFileFormat() {
        // Test multi-file JSON format (backwards compatibility)
        String multiFileJson = '[{"base64":"' + TEST_IMAGE_BASE64 + '","fileName":"multi_test.png","mimeType":"image/png"}]';
        
        System.Test.startTest();
        
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            multiFileJson,
            'ignored.png',
            'application/json+multifile'
        );
        
        System.Test.stopTest();
        
        System.assertNotEquals(null, doc, 'ContentDocument should be created from multi-file format');
        System.assertEquals('multi_test.png', doc.Title, 'Should use filename from JSON');
    }
    
    @isTest
    static void testCreateImageDocumentWithEmptyMultiFileArray() {
        // Test empty multi-file array
        String emptyMultiFileJson = '[]';
        
        System.Test.startTest();
        
        ContentDocument doc = mt_ImageFileService.createImageDocument(
            emptyMultiFileJson,
            'ignored.png',
            'application/json+multifile'
        );
        
        System.Test.stopTest();
        
        System.assertEquals(null, doc, 'Should return null for empty multi-file array');
    }
    
    @isTest
    static void testCreateImageDocumentWithInvalidMultiFileJson() {
        // Test invalid JSON format
        String invalidJson = 'not valid json';
        
        System.Test.startTest();
        
        try {
            ContentDocument doc = mt_ImageFileService.createImageDocument(
                invalidJson,
                'ignored.png',
                'application/json+multifile'
            );
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid multi-file format'), 'Should throw proper error');
        }
        
        System.Test.stopTest();
    }
    
    @isTest
    static void testInvocableWithError() {
        // Test error handling in invocable method
        mt_ImageFileService.ImageDocumentRequest request = new mt_ImageFileService.ImageDocumentRequest();
        request.base64Data = 'invalid-base64-data!!!';
        request.fileName = 'error_test.png';
        request.mimeType = 'image/png';
        
        List<mt_ImageFileService.ImageDocumentRequest> requests = new List<mt_ImageFileService.ImageDocumentRequest>{ request };
        
        System.Test.startTest();
        
        List<mt_ImageFileService.ImageDocumentResult> results = mt_ImageFileService.createImageDocuments(requests);
        
        System.Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should be unsuccessful');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
    }
    
    @isTest
    static void testCreateImageDocumentWithInvalidBase64() {
        // Test invalid base64 data
        System.Test.startTest();
        
        try {
            ContentDocument doc = mt_ImageFileService.createImageDocument(
                'this is not valid base64!@#$%',
                'invalid.png',
                'image/png'
            );
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Failed to process image'), 'Should throw proper error');
        }
        
        System.Test.stopTest();
    }
}