/**
 * ============================================================================
 * MT File Combiner Service Test
 * ============================================================================
 * 
 * @description     Test class for mt_FileCombinerService
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
@IsTest
private class mt_FileCombinerServiceTest {
    
    // Small 1x1 pixel PNG base64
    private static final String SAMPLE_PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    
    @IsTest
    static void testCombineImages_SingleImage() {
        // Create test input
        mt_FileCombinerService.CombineFilesInput input = new mt_FileCombinerService.CombineFilesInput();
        
        List<Map<String, String>> files = new List<Map<String, String>>();
        Map<String, String> file1 = new Map<String, String>();
        file1.put('base64', SAMPLE_PNG_BASE64);
        file1.put('fileName', 'test1.png');
        file1.put('mimeType', 'image/png');
        files.add(file1);
        
        input.filesJson = JSON.serialize(files);
        input.combinationType = 'IMAGE_GRID';
        
        System.Test.startTest();
        List<mt_FileCombinerService.CombineFilesOutput> outputs = 
            mt_FileCombinerService.combineFiles(new List<mt_FileCombinerService.CombineFilesInput>{ input });
        System.Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should return one output');
        System.assertEquals(true, outputs[0].success, 'Should succeed');
        System.assertEquals(1, outputs[0].fileCount, 'Should have 1 file');
        System.assertNotEquals(null, outputs[0].contentDocumentId, 'Should have ContentDocument ID');
    }
    
    @IsTest
    static void testCombineImages_MultipleImages() {
        mt_FileCombinerService.CombineFilesInput input = new mt_FileCombinerService.CombineFilesInput();
        
        List<Map<String, String>> files = new List<Map<String, String>>();
        for (Integer i = 0; i < 3; i++) {
            Map<String, String> file = new Map<String, String>();
            file.put('base64', SAMPLE_PNG_BASE64);
            file.put('fileName', 'test' + i + '.png');
            file.put('mimeType', 'image/png');
            files.add(file);
        }
        
        input.filesJson = JSON.serialize(files);
        
        System.Test.startTest();
        List<mt_FileCombinerService.CombineFilesOutput> outputs = 
            mt_FileCombinerService.combineFiles(new List<mt_FileCombinerService.CombineFilesInput>{ input });
        System.Test.stopTest();
        
        System.assertEquals(true, outputs[0].success, 'Should succeed');
        System.assertEquals(3, outputs[0].fileCount, 'Should have 3 files');
    }
    
    @IsTest
    static void testCombineFiles_EmptyInput() {
        mt_FileCombinerService.CombineFilesInput input = new mt_FileCombinerService.CombineFilesInput();
        input.filesJson = '';
        
        System.Test.startTest();
        List<mt_FileCombinerService.CombineFilesOutput> outputs = 
            mt_FileCombinerService.combineFiles(new List<mt_FileCombinerService.CombineFilesInput>{ input });
        System.Test.stopTest();
        
        System.assertEquals(false, outputs[0].success, 'Should fail with empty input');
        System.assertNotEquals(null, outputs[0].errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testCombineFiles_TooManyFiles() {
        mt_FileCombinerService.CombineFilesInput input = new mt_FileCombinerService.CombineFilesInput();
        
        List<Map<String, String>> files = new List<Map<String, String>>();
        for (Integer i = 0; i < 7; i++) {
            Map<String, String> file = new Map<String, String>();
            file.put('base64', SAMPLE_PNG_BASE64);
            file.put('fileName', 'test' + i + '.png');
            file.put('mimeType', 'image/png');
            files.add(file);
        }
        
        input.filesJson = JSON.serialize(files);
        
        System.Test.startTest();
        List<mt_FileCombinerService.CombineFilesOutput> outputs = 
            mt_FileCombinerService.combineFiles(new List<mt_FileCombinerService.CombineFilesInput>{ input });
        System.Test.stopTest();
        
        System.assertEquals(false, outputs[0].success, 'Should fail with too many files');
        System.assert(outputs[0].errorMessage.contains('Maximum'), 'Should mention maximum limit');
    }
    
    @IsTest
    static void testValidateFiles() {
        List<Map<String, String>> files = new List<Map<String, String>>();
        Map<String, String> file1 = new Map<String, String>();
        file1.put('base64', SAMPLE_PNG_BASE64);
        file1.put('fileName', 'test.png');
        file1.put('mimeType', 'image/png');
        files.add(file1);
        
        String filesJson = JSON.serialize(files);
        
        System.Test.startTest();
        Map<String, Object> result = mt_FileCombinerService.validateFiles(filesJson);
        System.Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Validation should succeed');
        System.assertEquals(1, result.get('fileCount'), 'Should count 1 file');
        System.assertEquals(false, result.get('exceedsLimit'), 'Should not exceed limit');
    }
    
    @IsTest
    static void testCombinePdfs() {
        // Minimal PDF content (not a real PDF, just for testing)
        String fakePdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('%PDF-1.4 test content'));
        
        mt_FileCombinerService.CombineFilesInput input = new mt_FileCombinerService.CombineFilesInput();
        
        List<Map<String, String>> files = new List<Map<String, String>>();
        Map<String, String> file1 = new Map<String, String>();
        file1.put('base64', fakePdfBase64);
        file1.put('fileName', 'test1.pdf');
        file1.put('mimeType', 'application/pdf');
        files.add(file1);
        
        Map<String, String> file2 = new Map<String, String>();
        file2.put('base64', fakePdfBase64);
        file2.put('fileName', 'test2.pdf');
        file2.put('mimeType', 'application/pdf');
        files.add(file2);
        
        input.filesJson = JSON.serialize(files);
        input.combinationType = 'PDF_MERGE';
        
        System.Test.startTest();
        List<mt_FileCombinerService.CombineFilesOutput> outputs = 
            mt_FileCombinerService.combineFiles(new List<mt_FileCombinerService.CombineFilesInput>{ input });
        System.Test.stopTest();
        
        System.assertEquals(true, outputs[0].success, 'Should succeed');
        System.assertEquals(2, outputs[0].fileCount, 'Should have 2 files');
    }
}