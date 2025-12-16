/**
 * ============================================================================
 * MT Image File Service
 * ============================================================================
 * 
 * @description     Service class for handling image file operations.
 *                  Converts base64 images to ContentDocument records for
 *                  use with Prompt Builder File Inputs.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
public with sharing class mt_ImageFileService {
    
    /**
     * @description Creates a ContentDocument from a base64 encoded image
     * @param base64Data The base64 encoded image data (without data URI prefix)
     *                   OR a JSON array of files (for backwards compatibility with multi-file)
     * @param fileName The name for the file
     * @param mimeType The MIME type (e.g., 'image/jpeg', 'image/png', 'application/json+multifile')
     * @return The ContentDocument record
     */
    @AuraEnabled
    public static ContentDocument createImageDocument(String base64Data, String fileName, String mimeType) {
        if (String.isBlank(base64Data)) {
            return null;
        }
        
        try {
            String actualBase64 = base64Data;
            String actualFileName = fileName;
            String actualMimeType = mimeType;
            
            // Handle multi-file JSON format (backwards compatibility)
            // If mimeType is 'application/json+multifile', the base64Data is actually a JSON array
            if (mimeType == 'application/json+multifile') {
                System.debug('Detected multi-file format, extracting first file...');
                try {
                    // Parse JSON array and extract first file
                    List<Object> fileList = (List<Object>) JSON.deserializeUntyped(base64Data);
                    if (fileList != null && !fileList.isEmpty()) {
                        Map<String, Object> firstFile = (Map<String, Object>) fileList[0];
                        actualBase64 = (String) firstFile.get('base64');
                        actualFileName = (String) firstFile.get('fileName');
                        actualMimeType = (String) firstFile.get('mimeType');
                        System.debug('Extracted first file: ' + actualFileName + ' (' + actualMimeType + ')');
                    } else {
                        System.debug('No files found in multi-file JSON');
                        return null;
                    }
                } catch (Exception jsonEx) {
                    System.debug('Failed to parse multi-file JSON: ' + jsonEx.getMessage());
                    throw new AuraHandledException('Invalid multi-file format: ' + jsonEx.getMessage());
                }
            }
            
            if (String.isBlank(actualBase64)) {
                return null;
            }
            
            // Decode base64 to blob
            Blob fileBlob = EncodingUtil.base64Decode(actualBase64);
            
            // Create ContentVersion (which auto-creates ContentDocument)
            ContentVersion cv = new ContentVersion();
            cv.Title = actualFileName;
            cv.PathOnClient = actualFileName;
            cv.VersionData = fileBlob;
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Query the ContentDocumentId from the inserted ContentVersion
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            
            // Return the ContentDocument
            return [SELECT Id, Title, FileType, ContentSize, LatestPublishedVersionId 
                    FROM ContentDocument 
                    WHERE Id = :cv.ContentDocumentId 
                    LIMIT 1];
            
        } catch (Exception e) {
            System.debug('Error creating image document: ' + e.getMessage());
            throw new AuraHandledException('Failed to process image: ' + e.getMessage());
        }
    }
    
    /**
     * @description Invocable method to create a ContentDocument from base64 image
     *              Can be called from Flow
     */
    @InvocableMethod(label='Create Image Document' description='Converts base64 image to ContentDocument for Prompt Builder')
    public static List<ImageDocumentResult> createImageDocuments(List<ImageDocumentRequest> requests) {
        List<ImageDocumentResult> results = new List<ImageDocumentResult>();
        
        for (ImageDocumentRequest request : requests) {
            ImageDocumentResult result = new ImageDocumentResult();
            
            if (String.isNotBlank(request.base64Data)) {
                try {
                    ContentDocument doc = createImageDocument(
                        request.base64Data, 
                        request.fileName, 
                        request.mimeType
                    );
                    result.contentDocumentId = doc.Id;
                    result.contentDocument = doc;
                    result.success = true;
                } catch (Exception e) {
                    result.success = false;
                    result.errorMessage = e.getMessage();
                }
            } else {
                result.success = true; // No image provided is OK
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Deletes a ContentDocument (cleanup after prompt execution)
     * @param contentDocumentId The ID of the ContentDocument to delete
     */
    @AuraEnabled
    public static void deleteImageDocument(Id contentDocumentId) {
        if (contentDocumentId != null) {
            try {
                delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
            } catch (Exception e) {
                System.debug('Error deleting image document: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Request class for invocable method
     */
    public class ImageDocumentRequest {
        @InvocableVariable(label='Base64 Image Data' description='The base64 encoded image (without data URI prefix)')
        public String base64Data;
        
        @InvocableVariable(label='File Name' description='The name for the file')
        public String fileName;
        
        @InvocableVariable(label='MIME Type' description='The image MIME type (e.g., image/jpeg)')
        public String mimeType;
    }
    
    /**
     * @description Result class for invocable method
     */
    public class ImageDocumentResult {
        @InvocableVariable(label='Content Document ID' description='The ID of the created ContentDocument')
        public Id contentDocumentId;
        
        @InvocableVariable(label='Content Document' description='The ContentDocument record')
        public ContentDocument contentDocument;
        
        @InvocableVariable(label='Success' description='Whether the operation succeeded')
        public Boolean success;
        
        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
    }
    
}