/*
================================================================================
MT RECORD SUGGESTION - Lightning Web Component
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 1.5

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

/**
 * ============================================================================
 * MT RECORD SUGGESTION - Lightning Web Component
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
 * 
 * THIS CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
 * ============================================================================
 * 
 * @description 
 * A fully DYNAMIC and FLEXIBLE LWC for processing AI-generated JSON payloads
 * and rendering intelligent create/update forms for ANY Salesforce object type.
 * The component automatically adapts to whatever objects are in the payload -
 * no hardcoding required.
 * 
 * FLEXIBILITY NOTES:
 * - Works with ANY standard or custom object (Contact, Opportunity, MyCustom__c)
 * - Automatically detects UI API support per object type
 * - Dynamically fetches field metadata and picklist values
 * - Handles polymorphic fields (WhatId, WhoId) for any object
 * - Output properties return data for ALL object types in the payload
 * 
 * @features
 * - Parses AI JSON payloads with records, summary, and reasoning
 * - Auto-detects new vs existing records based on ID presence
 * - Groups records by object type in accordion sections
 * - Uses lightning-record-form for UI API supported objects
 * - Custom field rendering for Task, Event, and other non-UI API objects
 * - Supports all field types: text, picklist, date, lookup, polymorphic, etc.
 * - Duplicate detection with record picker modal
 * - "Link to Existing" functionality for any record
 * - Real-time lookup name resolution (shows Account Name, not ID)
 * - Comparison view for existing records (Current vs New values)
 * - Individual and bulk save operations
 * - DYNAMIC output properties for Flow integration (works with any object)
 * 
 * @usage
 * In Flow Screen:
 * - Input: payload (JSON string), accountId (optional), defaultLayout ("1", "2", "3")
 * - Output: savedRecordIds[], savedRecordsJson, savedObjectTypes[], savedRecordsCount
 * 
 * @example JSON Input (works with ANY object types)
 * {
 *   "records": [
 *     { "type": "Contact", "FirstName": "John", "LastName": "Doe", "AccountId": "001xx..." },
 *     { "type": "Opportunity", "Id": "006xx...", "Amount": 50000, "StageName": "Closed Won" },
 *     { "type": "MyCustomObject__c", "Name": "Custom Record", "Field__c": "Value" }
 *   ],
 *   "Summary": "<ul><li>Created new contact John Doe</li></ul>",
 *   "Reasoning": "Based on the transcript..."
 * }
 * 
 * @see ObjectMetadataService - Apex class for dynamic metadata fetching
 * @see RecordService - Apex class for generic DML operations
 * ============================================================================
 */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

// ============================================================================
// APEX IMPORTS
// ============================================================================
// ObjectMetadataService: Fetches field metadata, picklist values, UI API support
import getObjectMetadata from '@salesforce/apex/mt_ObjectMetadataService.getObjectMetadata';
import isUiApiSupported from '@salesforce/apex/mt_ObjectMetadataService.isUiApiSupported';

// RecordService: Handles all DML operations (create, update) with proper error handling
import saveRecordSimple from '@salesforce/apex/mt_RecordService.saveRecordSimple';
import getRecordFields from '@salesforce/apex/mt_RecordService.getRecordFields';
import resolveLookupNames from '@salesforce/apex/mt_RecordService.resolveLookupNames';
import getDuplicateRecords from '@salesforce/apex/mt_RecordService.getDuplicateRecords';
import getRelatedRecords from '@salesforce/apex/mt_RecordService.getRelatedRecords';

// TranscribeController: Object configuration for mandatory/allowed fields
import getObjectConfigs from '@salesforce/apex/mt_TranscribeController.getObjectConfigs';

// ============================================================================
// CONSTANTS
// ============================================================================
/**
 * Enable/disable debug logging
 * Set to false in production for performance
 */
const DEBUG_MODE = true;

export default class AiRecordSuggestions extends LightningElement {
    // ========== PUBLIC API ==========
    
    /**
     * The JSON payload from AI containing records array
     * Example: { "records": [...], "Reasoning": "...", "Summary": "..." }
     */
    @api 
    get payload() {
        return this._payloadString;
    }
    set payload(value) {
        this._payloadString = value;
        this._parsePayload(value);
    }

    @api accountId;
    @api configName = 'Default';
    @api requiredFieldsConfig;
    
    // Object configurations loaded from Custom Metadata
    _objectConfigs = new Map(); // Map<objectApiName, configObject>
    
    @api 
    get defaultLayout() {
        return this._layoutColumns;
    }
    set defaultLayout(value) {
        if (value && ['1', '2', '3'].includes(value)) {
            this._layoutColumns = value;
        }
    }

    // ========== OUTPUT PROPERTIES (for Flow) ==========
    // DYNAMIC outputs work with ANY object type from the JSON input
    // Legacy outputs kept for backward compatibility with existing flows

    // ---------- DYNAMIC OUTPUTS (Recommended) ----------

    /**
     * Output: All saved record IDs as a single flat collection
     * Contains IDs from ALL object types that were saved
     * @returns {String[]} Array of all saved record IDs
     */
    @api
    get savedRecordIds() {
        const allIds = [];
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                group.records
                    .filter(r => r.isSaved && r.id)
                    .forEach(r => allIds.push(r.id));
            });
        }
        return allIds;
    }

    /**
     * Output: All saved records as JSON object grouped by object type
     * Format: { "Contact": ["id1"], "Opportunity": ["id2"], "CustomObject__c": ["id3"] }
     * This is the PRIMARY output for dynamic processing - works with ANY object type
     * @returns {String} JSON string of saved record IDs grouped by object type
     */
    @api
    get savedRecordsJson() {
        const result = {};
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                const savedIds = group.records
                    .filter(r => r.isSaved && r.id)
                    .map(r => r.id);
                if (savedIds.length > 0) {
                    result[group.objectType] = savedIds;
                }
            });
        }
        return JSON.stringify(result);
    }

    /**
     * Output: List of object types that had records saved
     * @returns {String[]} Array of object API names that have saved records
     */
    @api
    get savedObjectTypes() {
        const types = [];
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                if (group.records.some(r => r.isSaved)) {
                    types.push(group.objectType);
                }
            });
        }
        return types;
    }

    /**
     * Output: Total count of saved records across all object types
     * @returns {Number} Total number of records saved
     */
    @api
    get savedRecordsCount() {
        let count = 0;
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                count += group.records.filter(r => r.isSaved).length;
            });
        }
        return count;
    }

    /**
     * Output: Count of records by object type as JSON
     * @returns {String} JSON string of counts per object type
     */
    @api
    get savedRecordsCountByType() {
        const result = {};
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                const savedCount = group.records.filter(r => r.isSaved).length;
                if (savedCount > 0) {
                    result[group.objectType] = savedCount;
                }
            });
        }
        return JSON.stringify(result);
    }

    /**
     * Output: Full summary as JSON
     * @returns {String} Comprehensive JSON summary of all records
     */
    @api
    get recordsSummaryJson() {
        const result = {};
        if (this._recordGroups) {
            this._recordGroups.forEach(group => {
                const saved = group.records.filter(r => r.isSaved);
                const pending = group.records.filter(r => !r.isSaved);
                result[group.objectType] = {
                    total: group.records.length,
                    saved: saved.length,
                    pending: pending.length,
                    savedIds: saved.filter(r => r.id).map(r => r.id),
                    hasErrors: group.records.some(r => r.hasError)
                };
            });
        }
        return JSON.stringify(result);
    }

    // ---------- LEGACY OUTPUTS (for backward compatibility) ----------
    // These are convenience shortcuts - use savedRecordsJson for dynamic access

    /** @returns {String[]} Saved Contact IDs */
    @api get savedContactIds() { return this._getSavedIdsByType('Contact'); }
    
    /** @returns {String[]} Saved Opportunity IDs */
    @api get savedOpportunityIds() { return this._getSavedIdsByType('Opportunity'); }
    
    /** @returns {String[]} Saved Task IDs */
    @api get savedTaskIds() { return this._getSavedIdsByType('Task'); }
    
    /** @returns {String[]} Saved Event IDs */
    @api get savedEventIds() { return this._getSavedIdsByType('Event'); }
    
    /** @returns {String[]} Saved Case IDs */
    @api get savedCaseIds() { return this._getSavedIdsByType('Case'); }
    
    /** @returns {String[]} Saved Lead IDs */
    @api get savedLeadIds() { return this._getSavedIdsByType('Lead'); }

    /** Helper to get saved IDs by object type */
    _getSavedIdsByType(objectType) {
        const group = this._recordGroups?.find(g => g.objectType === objectType);
        return group ? group.records.filter(r => r.isSaved && r.id).map(r => r.id) : [];
    }

    // ========== INTERNAL STATE ==========
    
    _payloadString;
    @track _parsedData = null;
    @track _recordGroups = [];
    @track _isLoading = true;
    @track _error = null;
    @track _metadataCache = {};
    @track _isSummaryEditing = false;
    @track _isSummaryExpanded = true;
    @track _summaryText = '';
    @track _layoutColumns = '1'; // Default to 1 column
    @track _isSettingsOpen = false;
    
    // Add Field Modal state
    @track _isAddFieldModalOpen = false;
    @track _addFieldModalGroupIndex = null;
    @track _addFieldModalRecordIndex = null;
    @track _addFieldModalOptions = [];
    @track _addFieldModalSelectedField = null;
    @track _addFieldModalValue = '';
    @track _addFieldModalFieldMeta = null;
    
    // Polymorphic Lookup Modal state (for mobile)
    @track _isPolymorphicModalOpen = false;
    @track _polymorphicModalGroupIndex = null;
    @track _polymorphicModalRecordIndex = null;
    @track _polymorphicModalFieldName = null;
    @track _polymorphicModalObjectType = null;
    @track _polymorphicModalRecordId = null;

    // Record Picker Modal state (unified for duplicates and linking)
    @track _isRecordPickerModalOpen = false;
    @track _recordPickerModalGroupIndex = null;
    @track _recordPickerModalRecordIndex = null;
    @track _recordPickerModalObjectType = null;
    @track _recordPickerModalLoading = false;
    @track _recordPickerModalTitle = '';
    @track _recordPickerModalSubtitle = '';
    @track _recordPickerModalAllowCreate = false;
    @track _recordPickerModalMode = ''; // 'duplicate' or 'link'
    @track _recordPickerSearchTerm = '';
    @track _suggestedRecords = [];

    // Mobile scroll container quirk (Salesforce app): modals can render at the top of the scroll container.
    // Ensure the modal is brought into view when opened so the user always sees it immediately.
    _lastScrolledModalKey = null;

    // ========== LIFECYCLE ==========

    async connectedCallback() {
        this._log('connectedCallback');
        // Load object configurations from Custom Metadata
        await this._loadObjectConfigs();
    }

    renderedCallback() {
        this._maybeRepositionOpenModalIntoView();
    }

    _maybeRepositionOpenModalIntoView() {
        // Only needed on mobile (Salesforce app scroll container quirks)
        if (FORM_FACTOR !== 'Small') {
            return;
        }

        let modalKey = null;
        if (this._isRecordPickerModalOpen) modalKey = 'recordPicker';
        else if (this._isAddFieldModalOpen) modalKey = 'addField';
        else if (this._isSettingsOpen) modalKey = 'settings';

        if (!modalKey) {
            this._lastScrolledModalKey = null;
            return;
        }

        if (this._lastScrolledModalKey === modalKey) return;
        this._lastScrolledModalKey = modalKey;

        requestAnimationFrame(() => {
            const modalEl = this.template.querySelector('section.mt-scroll-modal');
            if (!modalEl) return;

            const backdropEl = this.template.querySelector('div.mt-scroll-backdrop');

            // Reset any previous transforms first
            modalEl.style.transform = '';
            if (backdropEl) backdropEl.style.transform = '';

            // If the modal ended up outside the viewport (often above), shift it into view WITHOUT scrolling the page.
            const rect = modalEl.getBoundingClientRect();
            const vh = window.innerHeight || 0;
            const padding = 16;
            let shiftY = 0;
            if (rect.top < padding) {
                shiftY = padding - rect.top;
            } else if (rect.bottom > (vh - padding)) {
                shiftY = (vh - padding) - rect.bottom;
            }

            if (shiftY !== 0) {
                modalEl.style.transform = `translateY(${shiftY}px)`;
                if (backdropEl) backdropEl.style.transform = `translateY(${shiftY}px)`;
            }

            const firstFocusable = modalEl.querySelector('input, button, select, textarea, [tabindex="0"]');
            if (firstFocusable && typeof firstFocusable.focus === 'function') {
                firstFocusable.focus();
            }
        });
    }
    
    /**
     * Load object configurations from Custom Metadata for the selected config profile
     */
    async _loadObjectConfigs() {
        try {
            const configName = this.configName || 'Default';
            this._log('Loading object configs for profile:', configName);
            
            const configs = await getObjectConfigs({ configName: configName });
            
            // Store in map for quick lookup
            this._objectConfigs = new Map();
            configs.forEach(config => {
                this._objectConfigs.set(config.objectApiName, {
                    allowedFields: config.allowedFields || [],
                    mandatoryFields: config.mandatoryFields || [],
                    allowCreate: config.allowCreate !== false,
                    allowEdit: config.allowEdit !== false
                });
            });
            
            this._log('Loaded object configs:', this._objectConfigs.size, 'objects');
        } catch (error) {
            console.error('Error loading object configs:', error);
            // Continue without configs - will use defaults
        }
    }

    _sanitizeDisplayValue(value) {
        if (value === null || value === undefined) return value;
        if (typeof value !== 'string') return value;
        const v = value.trim();
        // Guard against accidentally rendering raw HTML fragments like 
        //  in desktop UI.
        if (/^<\/?[a-z][\s\S]*>$/.test(v)) {
            return '';
        }
        return value;
    }

    _sanitizeForFieldValue(value) {
        // Be stricter for field values: if it contains HTML-looking fragments, strip it out.
        // This prevents payloads that accidentally include closing tags from leaking into the UI.
        if (value === null || value === undefined) return value;
        if (typeof value !== 'string') return value;
        const v = value.trim();
        if (!v) return value;
        if (/^<\/?[a-z][\s\S]*>$/.test(v)) return '';
        if (v.includes('<') || v.includes('>')) {
            // Keep only the text content by removing tag-shaped chunks.
            return v.replace(/<\/?[^>]+>/g, '').trim();
        }
        return value;
    }
    
    /**
     * Get the object configuration for a specific object type
     * @param {String} objectApiName - The object API name
     * @returns {Object} The config or default values
     */
    _getObjectConfig(objectApiName) {
        if (this._objectConfigs && this._objectConfigs.has(objectApiName)) {
            return this._objectConfigs.get(objectApiName);
        }
        // Default: all fields allowed
        return {
            allowedFields: [],
            mandatoryFields: [],
            allowCreate: true,
            allowEdit: true
        };
    }
    
    /**
     * Check if a field is allowed for an object based on config
     * @param {String} objectApiName - The object API name
     * @param {String} fieldName - The field API name
     * @returns {Boolean} Whether the field is allowed (or no restrictions)
     */
    _isFieldAllowed(objectApiName, fieldName) {
        // Relationship fields are ALWAYS allowed regardless of config
        const ALWAYS_ALLOWED = ['Id', 'WhatId', 'WhoId', 'AccountId', 'OwnerId', 'ContactId', 'LeadId', 'CaseId', 'OpportunityId'];
        if (ALWAYS_ALLOWED.includes(fieldName)) {
            return true;
        }
        
        const config = this._getObjectConfig(objectApiName);
        // If no allowed fields specified, all fields are allowed
        if (!config.allowedFields || config.allowedFields.length === 0) {
            return true;
        }
        return config.allowedFields.includes(fieldName);
    }
    
    /**
     * Get mandatory fields for an object
     * @param {String} objectApiName - The object API name
     * @returns {Array} List of mandatory field names
     */
    _getMandatoryFields(objectApiName) {
        const config = this._getObjectConfig(objectApiName);
        return config.mandatoryFields || [];
    }

    // ========== COMPUTED PROPERTIES ==========

    get isLoading() {
        return this._isLoading;
    }

    get hasError() {
        return !!this._error;
    }

    get errorMessage() {
        return this._error;
    }

    get hasRecords() {
        return this._recordGroups && this._recordGroups.length > 0;
    }

    get noRecords() {
        return !this._isLoading && !this._error && !this.hasRecords;
    }

    get summary() {
        return this._parsedData?.Summary || '';
    }

    get reasoning() {
        return this._parsedData?.Reasoning || '';
    }

    get recordGroups() {
        return this._recordGroups;
    }

    get allSaved() {
        if (!this._recordGroups || this._recordGroups.length === 0) return false;
        return this._recordGroups.every(group => 
            group.records.every(rec => rec.isSaved)
        );
    }

    get saveAllDisabled() {
        return this._isLoading || this.allSaved;
    }

    // Mobile/Tablet/Desktop detection
    get isMobile() {
        return FORM_FACTOR === 'Small';
    }

    get isTablet() {
        return FORM_FACTOR === 'Medium';
    }

    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }

    get containerClass() {
        let classes = 'ai-record-suggestions';
        if (this.isMobile) classes += ' mobile-view';
        if (this.isTablet) classes += ' tablet-view';
        return classes;
    }

    get formColumns() {
        return this.isMobile ? '1' : '2';
    }

    // Image/File display properties
    get hasAttachedFile() {
        return this._parsedData?.attachedFileName || this._parsedData?.imageFileName;
    }

    get attachedFileName() {
        return this._parsedData?.attachedFileName || this._parsedData?.imageFileName || '';
    }

    get attachedFileType() {
        return this._parsedData?.attachedFileType || this._parsedData?.imageMimeType || '';
    }

    // Summary editing properties
    get hasSummary() {
        return !!this._parsedData?.Summary;
    }

    get isSummaryReadOnly() {
        return !this._isSummaryEditing;
    }
    
    get isSummaryExpanded() {
        return this._isSummaryExpanded;
    }

    get summaryText() {
        return this._summaryText || this._parsedData?.Summary || '';
    }

    // Layout properties
    get layoutOptions() {
        return [
            { label: '1 Column', value: '1' },
            { label: '2 Columns', value: '2' },
            { label: '3 Columns', value: '3' }
        ];
    }

    get layoutColumns() {
        return this._layoutColumns;
    }

    get layoutItemSize() {
        // Returns the size for lightning-layout-item based on columns
        const columnMap = {
            '1': '12',  // Full width
            '2': '6',   // Half width
            '3': '4'    // Third width
        };
        return columnMap[this._layoutColumns] || '12';
    }

    get isSettingsOpen() {
        return this._isSettingsOpen;
    }

    // Add Field Modal getters
    get isAddFieldModalOpen() {
        return this._isAddFieldModalOpen;
    }

    get addFieldModalTitle() {
        if (this._addFieldModalGroupIndex !== null && this._addFieldModalRecordIndex !== null) {
            const record = this._recordGroups[this._addFieldModalGroupIndex]?.records[this._addFieldModalRecordIndex];
            return record?.title || 'Record';
        }
        return 'Record';
    }

    get addFieldModalOptions() {
        return this._addFieldModalOptions;
    }

    get addFieldModalSelectedField() {
        return this._addFieldModalSelectedField;
    }

    get addFieldModalValue() {
        return this._addFieldModalValue;
    }

    get addFieldModalDisabled() {
        return !this._addFieldModalSelectedField;
    }

    get addFieldModalIsDate() {
        return this._addFieldModalFieldMeta?.dataType === 'DATE';
    }

    get addFieldModalIsDateTime() {
        return this._addFieldModalFieldMeta?.dataType === 'DATETIME';
    }

    get addFieldModalIsNumber() {
        return ['DOUBLE', 'INTEGER', 'CURRENCY', 'PERCENT'].includes(this._addFieldModalFieldMeta?.dataType);
    }

    get addFieldModalIsPicklist() {
        return ['PICKLIST', 'COMBOBOX', 'MULTIPICKLIST'].includes(this._addFieldModalFieldMeta?.dataType);
    }

    get addFieldModalIsBoolean() {
        return this._addFieldModalFieldMeta?.dataType === 'BOOLEAN';
    }

    get addFieldModalPicklistOptions() {
        if (this._addFieldModalFieldMeta?.picklistValues) {
            return this._addFieldModalFieldMeta.picklistValues.map(pv => ({
                label: pv.label,
                value: pv.value
            }));
        }
        return [];
    }

    // Polymorphic Modal getters
    get isPolymorphicModalOpen() {
        return this._isPolymorphicModalOpen;
    }
    
    get polymorphicModalField() {
        if (!this._polymorphicModalGroupIndex && this._polymorphicModalGroupIndex !== 0) return null;
        if (!this._polymorphicModalRecordIndex && this._polymorphicModalRecordIndex !== 0) return null;
        if (!this._polymorphicModalFieldName) return null;
        
        const record = this._recordGroups[this._polymorphicModalGroupIndex]?.records?.[this._polymorphicModalRecordIndex];
        return record?.fields?.find(f => f.apiName === this._polymorphicModalFieldName);
    }

    // Record Picker Modal getters
    get isRecordPickerModalOpen() {
        return this._isRecordPickerModalOpen;
    }

    get recordPickerModalObjectType() {
        return this._recordPickerModalObjectType;
    }

    get recordPickerModalTitle() {
        return this._recordPickerModalTitle;
    }

    get recordPickerModalSubtitle() {
        return this._recordPickerModalSubtitle;
    }

    get recordPickerModalLoading() {
        return this._recordPickerModalLoading;
    }

    get recordPickerModalAllowCreate() {
        return this._recordPickerModalAllowCreate;
    }

    get recordPickerSearchTerm() {
        return this._recordPickerSearchTerm;
    }

    get suggestedRecords() {
        return this._suggestedRecords;
    }

    get hasSuggestedRecords() {
        return this._suggestedRecords && this._suggestedRecords.length > 0;
    }

    get showRecordPickerSearch() {
        return this._recordPickerModalMode !== 'duplicate';
    }

    // ========== PAYLOAD PARSING ==========

    async _parsePayload(value) {
        this._isLoading = true;
        this._error = null;
        this._recordGroups = [];

        try {
            // Parse JSON string
            let parsed;
            if (typeof value === 'string') {
                // Clean up malformed JSON if needed
                const cleanStart = value.indexOf('{');
                const cleanEnd = value.lastIndexOf('}') + 1;
                const cleanJson = value.substring(cleanStart, cleanEnd);
                parsed = JSON.parse(cleanJson);
            } else if (typeof value === 'object' && value !== null) {
                parsed = value;
            } else {
                this._error = 'Invalid payload format';
                this._isLoading = false;
                return;
            }

            this._parsedData = parsed;

            if (!parsed.records || !Array.isArray(parsed.records) || parsed.records.length === 0) {
                this._log('No records in payload');
                this._isLoading = false;
                return;
            }

            // Group records by ObjectType
            await this._processRecords(parsed.records);
            
            // Fetch existing record data for updates
            await this._loadExistingRecordData();
            
            // Resolve lookup field names
            await this._resolveLookupFieldNames();

        } catch (e) {
            console.error('Error parsing payload:', e);
            this._error = `Error parsing payload: ${e.message}`;
        } finally {
            this._isLoading = false;
        }
    }

    async _processRecords(records) {
        // Group by ObjectType
        const grouped = {};
        
        for (const record of records) {
            const objectType = record.ObjectType;
            if (!objectType) continue;

            if (!grouped[objectType]) {
                grouped[objectType] = {
                    objectType,
                    label: objectType,
                    labelPlural: `${objectType}s`,
                    icon: this._getObjectIcon(objectType),
                    records: [],
                    useUiApi: true,
                    metadata: null,
                    isExpanded: true,
                    saveAllLabel: `Save All`,
                    allSaved: false
                };

                // Check UI API support
                try {
                    const supported = await isUiApiSupported({ objectApiName: objectType });
                    grouped[objectType].useUiApi = supported;
                } catch (e) {
                    this._log('Error checking UI API support', e);
                    grouped[objectType].useUiApi = false;
                }
                
                // Always fetch metadata for field types and picklist values
                try {
                    const metadata = await this._getMetadata(objectType);
                    grouped[objectType].metadata = metadata;
                    if (metadata) {
                        grouped[objectType].label = metadata.label || objectType;
                        grouped[objectType].labelPlural = metadata.labelPlural || `${objectType}s`;
                    }
                    this._log('Fetched metadata for ' + objectType, metadata);
                } catch (e) {
                    this._log('Error fetching metadata for ' + objectType, e);
                }
            }

            // Process record
            const processedRecord = this._processRecord(record, grouped[objectType]);
            grouped[objectType].records.push(processedRecord);
        }

        this._recordGroups = Object.values(grouped);
        this._log('Record groups', this._recordGroups);
    }

    _processRecord(record, group) {
        const isNew = !record.Id;
        
        // Extract fields (excluding ObjectType, special fields, and system fields)
        const fields = [];
        const excludeFields = [
            'ObjectType', 'Reasoning', 'Summary',
            // System fields that users shouldn't see/edit
            'RecordTypeId', 'OwnerId', 'CreatedById', 'LastModifiedById',
            'CreatedDate', 'LastModifiedDate', 'SystemModstamp', 'IsDeleted'
        ];
        
        for (const [key, value] of Object.entries(record)) {
            if (excludeFields.includes(key)) continue;
            if (key === 'Id' && !value) continue;

            // Find field metadata (case-insensitive match)
            const fieldMeta = group.metadata?.fields?.find(
                f => f.apiName.toLowerCase() === key.toLowerCase()
            );
            
            const dataType = fieldMeta?.dataType || this._inferDataType(key, value);
            
            // Format picklist options for lightning-combobox
            // The combobox expects { label: 'Label', value: 'value' }
            let picklistOptions = [];
            if (fieldMeta?.picklistValues && fieldMeta.picklistValues.length > 0) {
                picklistOptions = fieldMeta.picklistValues.map(pv => ({
                    label: pv.label,
                    value: pv.value
                }));
            }
            
            // Determine if this is a picklist or multi-select picklist
            const isPicklistType = dataType === 'PICKLIST' || dataType === 'COMBOBOX';
            const isMultiPicklist = dataType === 'MULTIPICKLIST';
            const isReferenceType = dataType === 'REFERENCE';
            
            // For multi-picklist, format the selected values array
            let multiPicklistSelectedValues = [];
            if (isMultiPicklist && value) {
                // Multi-picklist values are stored as semicolon-separated string
                multiPicklistSelectedValues = String(value).split(';').filter(v => v);
            }
            
            // For reference fields, determine the target object(s)
            const referenceTo = fieldMeta?.referenceTo || [];
            const isPolymorphic = fieldMeta?.isPolymorphic || referenceTo.length > 1;
            // Get the first (or only) reference target for non-polymorphic lookups
            const referenceObjectApiName = referenceTo.length === 1 ? referenceTo[0] : null;
            
            // For polymorphic fields, build object type options and detect initial object type
            let polymorphicObjectOptions = [];
            let selectedPolymorphicObject = null;
            if (isPolymorphic && referenceTo.length > 0) {
                // Build dropdown options for object types
                polymorphicObjectOptions = referenceTo.map(objName => ({
                    label: this._getObjectLabel(objName),
                    value: objName
                }));
                
                // Try to detect the object type from the current value (ID prefix)
                if (value && (String(value).length === 15 || String(value).length === 18)) {
                    selectedPolymorphicObject = this._detectObjectTypeFromId(String(value), referenceTo);
                }
                // Default to first option if not detected
                if (!selectedPolymorphicObject && referenceTo.length > 0) {
                    selectedPolymorphicObject = referenceTo[0];
                }
            }
            
            this._log('Processing field', { 
                field: key, 
                dataType, 
                hasMetadata: !!fieldMeta, 
                picklistCount: picklistOptions.length,
                referenceTo,
                isPolymorphic
            });
            
            fields.push({
                apiName: key,
                newValue: this._sanitizeForFieldValue(value),  // AI suggested value
                oldValue: null,   // Current value (fetched for existing records)
                hasOldValue: false,
                isChanged: false,
                label: fieldMeta?.label || this._formatLabel(key),
                dataType: dataType,
                isRequired: fieldMeta?.isRequired || false,
                picklistValues: picklistOptions,
                hasPicklistValues: picklistOptions.length > 0,
                multiPicklistSelectedValues: multiPicklistSelectedValues,
                isSelected: true,
                isDisabled: false,
                // Reference field info for lookup functionality
                referenceTo: referenceTo,
                referenceObjectApiName: referenceObjectApiName,
                isPolymorphic: isPolymorphic,
                // Polymorphic field properties
                polymorphicObjectOptions: polymorphicObjectOptions,
                selectedPolymorphicObject: selectedPolymorphicObject,
                hasPolymorphicOptions: polymorphicObjectOptions.length > 0,
                // Type flags for template rendering
                isString: dataType === 'STRING' && !picklistOptions.length,
                isTextArea: dataType === 'TEXTAREA',
                isReference: isReferenceType && !isPolymorphic && referenceObjectApiName,
                isPolymorphicReference: isReferenceType && isPolymorphic,
                isDate: dataType === 'DATE',
                isDateTime: dataType === 'DATETIME',
                isTime: dataType === 'TIME',
                isPicklist: isPicklistType && picklistOptions.length > 0,
                isMultiPicklist: isMultiPicklist && picklistOptions.length > 0,
                isDouble: dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'PERCENT',
                isCurrency: dataType === 'CURRENCY',
                isBoolean: dataType === 'BOOLEAN',
                isEmail: dataType === 'EMAIL',
                isPhone: dataType === 'PHONE',
                isUrl: dataType === 'URL',
                isLocation: dataType === 'LOCATION',
                isAddress: dataType === 'ADDRESS',
                // Fallback for unsupported types
                isUnsupported: ['BASE64', 'ENCRYPTEDSTRING', 'DATACATEGORYGROUPREFERENCE', 'ANYTYPE'].includes(dataType),
                // Row class for styling
                rowClass: 'field-row slds-m-bottom_small' + ((dataType === 'DATE' || dataType === 'DATETIME') ? ' field-row-date' : '')
            });
        }
        
        // Apply object configuration: filter allowed fields and add mandatory fields
        const objectConfig = this._getObjectConfig(group.objectType);
        const hasFieldRestrictions = objectConfig.allowedFields && objectConfig.allowedFields.length > 0;
        const mandatoryFields = objectConfig.mandatoryFields || [];
        
        // Filter fields if there are restrictions
        // Always allow: Id, relationship fields (WhatId, WhoId, AccountId, OwnerId, etc.)
        // Note: Task/Event date fields are critical on mobile (e.g. Task.ActivityDate "Due Date").
        // Some org configs restrict allowedFields and accidentally exclude them, so we always allow common activity date fields.
        const ALWAYS_ALLOWED_FIELDS = ['Id', 'WhatId', 'WhoId', 'AccountId', 'OwnerId', 'ContactId', 'LeadId', 'CaseId', 'OpportunityId', 'ActivityDate', 'StartDateTime', 'EndDateTime'];
        let processedFields = fields;
        if (hasFieldRestrictions) {
            processedFields = fields.filter(f => 
                ALWAYS_ALLOWED_FIELDS.includes(f.apiName) || objectConfig.allowedFields.includes(f.apiName)
            );
            this._log('Filtered fields by allowed list', { 
                objectType: group.objectType, 
                before: fields.length, 
                after: processedFields.length,
                alwaysAllowed: ALWAYS_ALLOWED_FIELDS
            });
        }
        
        // Add mandatory fields ONLY for NEW records (not for updates)
        // Updates should only show changed fields, not all mandatory fields
        const existingFieldNames = new Set(processedFields.map(f => f.apiName.toLowerCase()));
        if (isNew) {
            for (const mandatoryFieldName of mandatoryFields) {
            if (!existingFieldNames.has(mandatoryFieldName.toLowerCase())) {
                // Find field metadata
                const fieldMeta = group.metadata?.fields?.find(
                    f => f.apiName.toLowerCase() === mandatoryFieldName.toLowerCase()
                );
                
                if (fieldMeta) {
                    const dataType = fieldMeta.dataType;
                    let picklistOptions = [];
                    if (fieldMeta.picklistValues && fieldMeta.picklistValues.length > 0) {
                        picklistOptions = fieldMeta.picklistValues.map(pv => ({
                            label: pv.label,
                            value: pv.value
                        }));
                    }
                    
                    // Create a field entry for the mandatory field with empty/null value
                    processedFields.push({
                        apiName: fieldMeta.apiName,
                        newValue: null,
                        oldValue: null,
                        hasOldValue: false,
                        isChanged: false,
                        label: fieldMeta.label || this._formatLabel(mandatoryFieldName),
                        dataType: dataType,
                        isRequired: fieldMeta.isRequired || false,
                        picklistValues: picklistOptions,
                        hasPicklistValues: picklistOptions.length > 0,
                        multiPicklistSelectedValues: [],
                        isSelected: true,
                        isDisabled: false,
                        isMandatoryFromConfig: true, // Flag that this was added from config
                        referenceTo: fieldMeta.referenceTo || [],
                        referenceObjectApiName: fieldMeta.referenceTo?.length === 1 ? fieldMeta.referenceTo[0] : null,
                        isPolymorphic: fieldMeta.isPolymorphic || (fieldMeta.referenceTo?.length > 1),
                        polymorphicObjectOptions: [],
                        selectedPolymorphicObject: null,
                        hasPolymorphicOptions: false,
                        isString: dataType === 'STRING' && !picklistOptions.length,
                        isTextArea: dataType === 'TEXTAREA',
                        isReference: dataType === 'REFERENCE' && fieldMeta.referenceTo?.length === 1,
                        isPolymorphicReference: dataType === 'REFERENCE' && fieldMeta.referenceTo?.length > 1,
                        isDate: dataType === 'DATE',
                        isDateTime: dataType === 'DATETIME',
                        isTime: dataType === 'TIME',
                        isPicklist: (dataType === 'PICKLIST' || dataType === 'COMBOBOX') && picklistOptions.length > 0,
                        isMultiPicklist: dataType === 'MULTIPICKLIST' && picklistOptions.length > 0,
                        isDouble: dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'PERCENT',
                        isCurrency: dataType === 'CURRENCY',
                        isBoolean: dataType === 'BOOLEAN',
                        isEmail: dataType === 'EMAIL',
                        isPhone: dataType === 'PHONE',
                        isUrl: dataType === 'URL',
                        isLocation: dataType === 'LOCATION',
                        isAddress: dataType === 'ADDRESS',
                        isUnsupported: false,
                        rowClass: 'field-row slds-m-bottom_small' + ((dataType === 'DATE' || dataType === 'DATETIME') ? ' field-row-date' : '') + ' field-mandatory-config'
                    });
                    
                    this._log('Added mandatory field from config', { 
                        objectType: group.objectType, 
                        field: mandatoryFieldName 
                    });
                }
            }
            } // End: for (mandatoryFieldName)
        } // End: if (isNew) - only add mandatory fields for new records

        return {
            id: record.Id || null,
            uuid: this._generateUuid(),
            isNew,
            isExisting: !isNew,
            isLoadingExisting: !isNew,
            isLayoutFull: false, // For Full/Compact toggle
            layoutToggleLabel: 'Switch to Full', // Label for menu item
            isEditMode: false, // For edit mode toggle
            isSaved: false,
            isSaving: false,
            isNotSaved: true, // Computed: !isSaved
            hasError: false,
            errorMessage: null,
            fieldErrors: [], // Array of field-level errors
            cardClass: '', // Card class for visual state (updated dynamically)
            wasJustCreated: false, // True if this was a new record that was just saved
            isDuplicateError: false, // True if error is duplicate detection
            isMissingRequiredFields: false, // True if error is missing required fields
            missingFieldsList: '', // Comma-separated list of missing field names
            missingFieldsApiNames: [], // API names of missing fields
            hasNonDuplicateError: false, // True if has error but not duplicate or required field
            hasProposedChanges: !isNew, // True if should show Proposed Changes section
            showSavedFieldsOnly: false, // True for non-UI API objects after save
            fields: processedFields.filter(f => f.apiName !== 'Id'), // Exclude ID from editable fields
            title: this._getRecordTitle(record, group.objectType),
            existingRecordData: null
        };
    }

    /**
     * Fetch existing record data for records with IDs
     */
    async _loadExistingRecordData() {
        this._log('Loading existing record data...');
        
        for (const group of this._recordGroups) {
            for (const record of group.records) {
                this._log('Checking record', { id: record.id, isExisting: record.isExisting });
                
                if (record.id && record.isExisting) {
                    // Validate ID format (15 or 18 alphanumeric characters)
                    const isValidId = record.id && 
                        (record.id.length === 15 || record.id.length === 18) && 
                        /^[a-zA-Z0-9]+$/.test(record.id);
                    
                    if (!isValidId) {
                        this._log('Invalid ID format, skipping fetch', record.id);
                        record.isLoadingExisting = false;
                        record.isExisting = false; // Treat as new record
                        record.isNew = true;
                        record.id = null; // Clear invalid ID
                        continue;
                    }
                    
                    try {
                        const fieldNames = record.fields
                            .filter(f => f.apiName !== 'Id')
                            .map(f => f.apiName);
                        
                        this._log('Fetching fields for record', { recordId: record.id, fieldNames });
                        
                        const existingData = await getRecordFields({
                            recordId: record.id,
                            fieldApiNames: fieldNames
                        });
                        
                        // Check if we got any data back
                        if (!existingData || Object.keys(existingData).length === 0) {
                            this._log('Record not found in Salesforce, treating as new', record.id);
                            record.isLoadingExisting = false;
                            record.isExisting = false;
                            record.isNew = true;
                            continue;
                        }

                        this._log('Fetched existing record data', existingData);

                        // Update fields with old values
                        record.fields.forEach(field => {
                            if (field.apiName !== 'Id') {
                                // Check if field exists in the returned data (even if null)
                                const fieldKey = Object.keys(existingData).find(
                                    k => k.toLowerCase() === field.apiName.toLowerCase()
                                );
                                
                                if (fieldKey !== undefined) {
                                    field.oldValue = this._sanitizeDisplayValue(existingData[fieldKey]);
                                    field.hasOldValue = true;
                                    field.isChanged = String(field.oldValue || '') !== String(field.newValue || '');
                                    this._log('Set old value for field', { 
                                        field: field.apiName, 
                                        oldValue: field.oldValue, 
                                        newValue: field.newValue,
                                        isChanged: field.isChanged,
                                        hasOldValue: field.hasOldValue
                                    });
                                }
                            }
                        });

                        // Get display name from existing record
                        if (existingData.Name) {
                            record.existingName = existingData.Name;
                        } else if (existingData.Subject) {
                            // For Task/Event
                            record.existingName = existingData.Subject;
                        } else if (existingData.FirstName || existingData.LastName) {
                            // For Contact
                            record.existingName = `${existingData.FirstName || ''} ${existingData.LastName || ''}`.trim();
                        }

                        record.existingRecordData = existingData;
                        record.isLoadingExisting = false;

                    } catch (e) {
                        console.error('Error fetching existing record', e);
                        this._log('Error fetching existing record, treating as new', e);
                        record.isLoadingExisting = false;
                        record.isExisting = false;
                        record.isNew = true;
                        // Remove the Id field since we can't update
                        record.fields = record.fields.filter(f => f.apiName !== 'Id');
                    }
                }
            }
        }
        
        this._log('Finished loading existing records, triggering reactivity');
        
        // Trigger reactivity by creating new array and objects
        this._recordGroups = this._recordGroups.map(group => ({
            ...group,
            records: group.records.map(record => ({
                ...record,
                fields: record.fields.map(field => ({ ...field }))
            }))
        }));
    }

    async _getMetadata(objectType) {
        if (this._metadataCache[objectType]) {
            return this._metadataCache[objectType];
        }

        try {
            const metadata = await getObjectMetadata({ 
                objectApiName: objectType, 
                fieldApiNames: null 
            });
            this._metadataCache[objectType] = metadata;
            return metadata;
        } catch (e) {
            this._log('Error fetching metadata', e);
            return null;
        }
    }

    // ========== EVENT HANDLERS ==========

    /**
     * Toggle section expand/collapse
     */
    handleToggleSection(event) {
        const groupIndex = parseInt(event.currentTarget.dataset.groupIndex, 10);
        this._recordGroups[groupIndex].isExpanded = !this._recordGroups[groupIndex].isExpanded;
        // Force reactivity
        this._recordGroups = [...this._recordGroups];
    }
    
    /**
     * Toggle summary section expand/collapse
     */
    handleToggleSummary() {
        this._isSummaryExpanded = !this._isSummaryExpanded;
    }
    
    /**
     * Stop event propagation (for buttons inside clickable headers)
     */
    handleStopPropagation(event) {
        event.stopPropagation();
    }
    
    /**
     * Save all records in a specific group
     */
    async handleSaveAllInGroup(event) {
        const groupIndex = parseInt(event.currentTarget.dataset.groupIndex, 10);
        const group = this._recordGroups[groupIndex];
        
        this._log(`Saving all ${group.labelPlural}...`);
        
        // Save each unsaved record
        for (let i = 0; i < group.records.length; i++) {
            const record = group.records[i];
            if (!record.isSaved) {
                await this._saveRecord(groupIndex, i, false); // false = don't show individual toasts
            }
        }
        
        // Update allSaved status
        this._updateGroupSaveStatus(groupIndex);
    }
    
    /**
     * Update the allSaved status for a group
     */
    _updateGroupSaveStatus(groupIndex) {
        const group = this._recordGroups[groupIndex];
        group.allSaved = group.records.every(r => r.isSaved);
        this._recordGroups = [...this._recordGroups];
    }

    handleFieldChange(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;
        const value = event.target.value ?? event.detail?.value;

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.newValue = this._sanitizeForFieldValue(value);
            // Update isChanged flag
            if (field.hasOldValue) {
                field.isChanged = String(field.oldValue) !== String(field.newValue);
            }
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Handle multi-picklist (dual listbox) changes
     */
    handleMultiPicklistChange(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;
        const selectedValues = event.detail.value; // Array of selected values

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            // Store as semicolon-separated string (Salesforce format)
            field.newValue = selectedValues.join(';');
            field.multiPicklistSelectedValues = selectedValues;
            // Update isChanged flag
            if (field.hasOldValue) {
                field.isChanged = String(field.oldValue) !== String(field.newValue);
            }
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Handle lookup/record picker selection
     */
    handleLookupChange(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;
        const recordId = event.detail.recordId; // Selected record ID

        this._log('Lookup changed', { fieldApiName, recordId });

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.newValue = recordId;
            // Clear the display value since user selected a new record
            // The record picker will show the name automatically
            field.displayValue = null;
            field.hasDisplayValue = false;
            // Update isChanged flag
            if (field.hasOldValue) {
                field.isChanged = String(field.oldValue) !== String(field.newValue);
            }
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Handle polymorphic object type selection change
     */
    handlePolymorphicObjectChange(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;
        const selectedObject = event.detail.value;

        this._log('Polymorphic object type changed', { fieldApiName, selectedObject });

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.selectedPolymorphicObject = selectedObject;
            // Clear the current value since object type changed
            field.newValue = null;
            field.displayValue = null;
            field.hasDisplayValue = false;
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Open polymorphic modal on mobile
     */
    handleOpenPolymorphicModal(event) {
        this._polymorphicModalGroupIndex = parseInt(event.currentTarget.dataset.groupIndex, 10);
        this._polymorphicModalRecordIndex = parseInt(event.currentTarget.dataset.recordIndex, 10);
        this._polymorphicModalFieldName = event.currentTarget.dataset.fieldName;
        
        const field = this.polymorphicModalField;
        if (field) {
            this._polymorphicModalObjectType = field.selectedPolymorphicObject;
            this._polymorphicModalRecordId = field.newValue;
        }
        
        this._isPolymorphicModalOpen = true;
        
        // Position modal at current scroll position on mobile (centered horizontally, positioned vertically)
        if (this.isMobile) {
            setTimeout(() => {
                const modal = this.template.querySelector('.polymorphic-dropdown-modal');
                if (modal) {
                    const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY || 0;
                    const viewportHeight = window.innerHeight;
                    const modalHeight = modal.offsetHeight || 400; // Estimate if not rendered yet
                    const topPosition = Math.max(20, Math.min(scrollTop + 20, viewportHeight - modalHeight - 20));
                    modal.style.setProperty('top', `${topPosition}px`, 'important');
                }
            }, 50); // Slightly longer delay to ensure modal is rendered
        }
    }
    
    /**
     * Handle combobox click - open modal on mobile
     */
    handlePolymorphicComboboxClick(event) {
        if (!this.isMobile) return; // Only on mobile
        
        // Prevent default dropdown behavior
        event.preventDefault();
        event.stopPropagation();
        
        // Open modal instead
        const combobox = event.currentTarget;
        this._polymorphicModalGroupIndex = parseInt(combobox.dataset.groupIndex, 10);
        this._polymorphicModalRecordIndex = parseInt(combobox.dataset.recordIndex, 10);
        this._polymorphicModalFieldName = combobox.dataset.fieldName;
        
        const field = this.polymorphicModalField;
        if (field) {
            this._polymorphicModalObjectType = field.selectedPolymorphicObject;
            this._polymorphicModalRecordId = field.newValue;
        }
        
        this._isPolymorphicModalOpen = true;
        
        // Position modal at current scroll position
        setTimeout(() => {
            const modal = this.template.querySelector('.polymorphic-dropdown-modal');
            if (modal) {
                const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY || 0;
                const viewportHeight = window.innerHeight;
                const modalHeight = modal.offsetHeight || 400; // Estimate if not rendered yet
                const topPosition = Math.max(20, Math.min(scrollTop + 20, viewportHeight - modalHeight - 20));
                modal.style.setProperty('top', `${topPosition}px`, 'important');
            }
        }, 50); // Slightly longer delay to ensure modal is rendered
        
        // Position modal at current scroll position (centered horizontally, positioned vertically)
        setTimeout(() => {
            const modal = this.template.querySelector('.polymorphic-dropdown-modal');
            if (modal) {
                const scrollTop = window.pageYOffset || document.documentElement.scrollTop || window.scrollY || 0;
                const viewportHeight = window.innerHeight;
                const modalHeight = modal.offsetHeight || 400; // Estimate if not rendered yet
                const topPosition = Math.max(20, Math.min(scrollTop + 20, viewportHeight - modalHeight - 20));
                modal.style.setProperty('top', `${topPosition}px`, 'important');
            }
        }, 50); // Slightly longer delay to ensure modal is rendered
    }
    
    /**
     * Close polymorphic modal
     */
    handleClosePolymorphicModal() {
        this._isPolymorphicModalOpen = false;
    }
    
    /**
     * Handle record type change in modal
     */
    handlePolymorphicModalObjectChange(event) {
        this._polymorphicModalObjectType = event.detail.value;
        this._polymorphicModalRecordId = null;
    }
    
    /**
     * Handle record selection in modal
     */
    handlePolymorphicModalRecordChange(event) {
        this._polymorphicModalRecordId = event.detail.value;
    }
    
    /**
     * Save polymorphic modal selection
     */
    handleSavePolymorphicModal() {
        const groupIndex = this._polymorphicModalGroupIndex;
        const recordIndex = this._polymorphicModalRecordIndex;
        const fieldApiName = this._polymorphicModalFieldName;

        const field = this._recordGroups[groupIndex].records[recordIndex].fields.find(f => f.apiName === fieldApiName);
        if (field) {
            field.selectedPolymorphicObject = this._polymorphicModalObjectType;
            field.newValue = this._polymorphicModalRecordId;
            // Resolve display value immediately if possible
            if (this._polymorphicModalRecordId) {
                this._resolveLookupFieldNames(); // Re-resolve all lookups
            } else {
                field.displayValue = null;
                field.hasDisplayValue = false;
            }
            this._recordGroups = [...this._recordGroups];
        }
        this.handleClosePolymorphicModal();
    }

    // ========== SUMMARY EDITING HANDLERS ==========

    handleEditSummary() {
        this._isSummaryEditing = true;
        this._summaryText = this._parsedData?.Summary || '';
    }

    handleSaveSummary() {
        this._isSummaryEditing = false;
        if (this._parsedData) {
            this._parsedData.Summary = this._summaryText;
        }
    }

    handleSummaryChange(event) {
        this._summaryText = event.target.value;
    }

    handleLayoutChange(event) {
        this._layoutColumns = event.detail.value;
    }

    handleOpenSettings() {
        this._isSettingsOpen = true;
    }

    handleCloseSettings() {
        this._isSettingsOpen = false;
    }

    // ========== ADD FIELD HANDLERS ==========

    handleStartAddField(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        const group = this._recordGroups[groupIndex];
        
        // Build available field options from metadata
        const existingFieldNames = record.fields.map(f => f.apiName.toLowerCase());
        const availableFields = group.metadata?.fields?.filter(f => 
            !existingFieldNames.includes(f.apiName.toLowerCase()) &&
            f.isCreateable &&
            !['Id', 'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'IsDeleted'].includes(f.apiName)
        ) || [];
        
        // Open modal instead of inline form
        this._addFieldModalGroupIndex = groupIndex;
        this._addFieldModalRecordIndex = recordIndex;
        this._addFieldModalOptions = availableFields.map(f => ({
            label: f.label,
            value: f.apiName
        })).sort((a, b) => a.label.localeCompare(b.label));
        this._addFieldModalSelectedField = null;
        this._addFieldModalValue = '';
        this._addFieldModalFieldMeta = null;
        this._isAddFieldModalOpen = true;
    }

    handleModalFieldSelect(event) {
        const selectedApiName = event.detail.value;
        this._addFieldModalSelectedField = selectedApiName;
        this._addFieldModalValue = ''; // Reset value when field changes
        
        // Get field metadata for type detection
        if (selectedApiName && this._addFieldModalGroupIndex !== null) {
            const group = this._recordGroups[this._addFieldModalGroupIndex];
            this._addFieldModalFieldMeta = group.metadata?.fields?.find(f => f.apiName === selectedApiName);
            this._log('Modal field selected', { field: selectedApiName, meta: this._addFieldModalFieldMeta });
        }
    }

    handleModalValueChange(event) {
        if (event.target.type === 'checkbox') {
            this._addFieldModalValue = event.target.checked;
        } else {
            this._addFieldModalValue = event.detail?.value ?? event.target.value;
        }
    }

    handleModalAddFieldConfirm() {
        if (!this._addFieldModalSelectedField || this._addFieldModalGroupIndex === null || this._addFieldModalRecordIndex === null) {
            return;
        }
        
        const record = this._recordGroups[this._addFieldModalGroupIndex].records[this._addFieldModalRecordIndex];
        const group = this._recordGroups[this._addFieldModalGroupIndex];
        const fieldMeta = this._addFieldModalFieldMeta;
        
        if (!fieldMeta) return;
        
        const dataType = fieldMeta.dataType;
        
        // Format picklist options
        let picklistOptions = [];
        if (fieldMeta.picklistValues && fieldMeta.picklistValues.length > 0) {
            picklistOptions = fieldMeta.picklistValues.map(pv => ({
                label: pv.label,
                value: pv.value
            }));
        }
        
        const isPicklistType = ['PICKLIST', 'COMBOBOX'].includes(dataType);
        const isMultiPicklist = dataType === 'MULTIPICKLIST';
        const isReferenceType = dataType === 'REFERENCE';
        const referenceTo = fieldMeta.referenceTo || [];
        const isPolymorphic = fieldMeta.isPolymorphic || referenceTo.length > 1;
        const referenceObjectApiName = referenceTo.length === 1 ? referenceTo[0] : null;
        
        // Create the new field
        const newField = {
            apiName: this._addFieldModalSelectedField,
            newValue: this._sanitizeForFieldValue(this._addFieldModalValue || null),
            oldValue: null,
            hasOldValue: false,
            isChanged: false,
            label: fieldMeta.label,
            dataType: dataType,
            isRequired: fieldMeta.isRequired || false,
            picklistValues: picklistOptions,
            hasPicklistValues: picklistOptions.length > 0,
            multiPicklistSelectedValues: [],
            isSelected: true,
            isDisabled: false,
            // Ensure it renders in the exact same "field-row" design as the others (and date rows get the date styling hook)
            rowClass: 'field-row slds-m-bottom_small' + ((dataType === 'DATE' || dataType === 'DATETIME') ? ' field-row-date' : ''),
            referenceTo: referenceTo,
            referenceObjectApiName: referenceObjectApiName,
            isPolymorphic: isPolymorphic,
            polymorphicObjectOptions: isPolymorphic ? referenceTo.map(obj => ({ label: this._getObjectLabel(obj), value: obj })) : [],
            selectedPolymorphicObject: isPolymorphic && referenceTo.length > 0 ? referenceTo[0] : null,
            hasPolymorphicOptions: isPolymorphic && referenceTo.length > 0,
            isString: dataType === 'STRING' && !picklistOptions.length,
            isTextArea: dataType === 'TEXTAREA',
            isReference: isReferenceType && !isPolymorphic && referenceObjectApiName,
            isPolymorphicReference: isReferenceType && isPolymorphic,
            isDate: dataType === 'DATE',
            isDateTime: dataType === 'DATETIME',
            isTime: dataType === 'TIME',
            isPicklist: (isPicklistType || isMultiPicklist) && picklistOptions.length > 0,
            isMultiPicklist: isMultiPicklist && picklistOptions.length > 0,
            isDouble: ['DOUBLE', 'INTEGER', 'PERCENT'].includes(dataType),
            isCurrency: dataType === 'CURRENCY',
            isBoolean: dataType === 'BOOLEAN',
            isEmail: dataType === 'EMAIL',
            isPhone: dataType === 'PHONE',
            isUrl: dataType === 'URL',
            isNewlyAdded: true
        };
        
        // Add to record's fields
        record.fields.push(newField);
        
        // Close modal
        this._isAddFieldModalOpen = false;
        this._addFieldModalGroupIndex = null;
        this._addFieldModalRecordIndex = null;
        this._addFieldModalOptions = [];
        this._addFieldModalSelectedField = null;
        this._addFieldModalValue = '';
        this._addFieldModalFieldMeta = null;
        
        this._recordGroups = [...this._recordGroups];
        
        this._showToast('Field Added', `${fieldMeta.label} has been added to the record.`, 'success');
    }

    handleNewFieldSelect(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        const group = this._recordGroups[groupIndex];
        
        record.selectedNewField = event.detail.value;
        record.addFieldDisabled = !record.selectedNewField;
        record.newFieldValue = ''; // Reset value when field changes
        
        // Set field type flags based on selected field metadata
        if (record.selectedNewField && group.metadata?.fields) {
            const fieldMeta = group.metadata.fields.find(f => f.apiName === record.selectedNewField);
            if (fieldMeta) {
                const dataType = fieldMeta.dataType;
                record.newFieldIsDate = dataType === 'DATE';
                record.newFieldIsDateTime = dataType === 'DATETIME';
                record.newFieldIsNumber = ['DOUBLE', 'INTEGER', 'CURRENCY', 'PERCENT'].includes(dataType);
                record.newFieldIsPicklist = ['PICKLIST', 'COMBOBOX', 'MULTIPICKLIST'].includes(dataType);
                record.newFieldIsBoolean = dataType === 'BOOLEAN';
                
                // Set picklist options if applicable
                if (record.newFieldIsPicklist && fieldMeta.picklistValues) {
                    record.newFieldPicklistOptions = fieldMeta.picklistValues.map(pv => ({
                        label: pv.label,
                        value: pv.value
                    }));
                } else {
                    record.newFieldPicklistOptions = [];
                }
                
                this._log('Selected field for add', { 
                    field: record.selectedNewField, 
                    dataType, 
                    isDate: record.newFieldIsDate,
                    isPicklist: record.newFieldIsPicklist
                });
            }
        }
        
        this._recordGroups = [...this._recordGroups];
    }

    handleNewFieldValueChange(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        record.newFieldValue = event.target.value;
        
        this._recordGroups = [...this._recordGroups];
    }

    handleAddFieldConfirm(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        const group = this._recordGroups[groupIndex];
        
        if (!record.selectedNewField) return;
        
        // Find the field metadata
        const fieldMeta = group.metadata?.fields?.find(
            f => f.apiName === record.selectedNewField
        );
        
        if (!fieldMeta) return;
        
        const dataType = fieldMeta.dataType;
        
        // Format picklist options
        let picklistOptions = [];
        if (fieldMeta.picklistValues && fieldMeta.picklistValues.length > 0) {
            picklistOptions = fieldMeta.picklistValues.map(pv => ({
                label: pv.label,
                value: pv.value
            }));
        }
        
        const isPicklistType = dataType === 'PICKLIST' || dataType === 'COMBOBOX';
        const isMultiPicklist = dataType === 'MULTIPICKLIST';
        const isReferenceType = dataType === 'REFERENCE';
        const referenceTo = fieldMeta.referenceTo || [];
        const isPolymorphic = fieldMeta.isPolymorphic || referenceTo.length > 1;
        const referenceObjectApiName = referenceTo.length === 1 ? referenceTo[0] : null;
        
        // Create the new field
        const newField = {
            apiName: record.selectedNewField,
            newValue: this._sanitizeForFieldValue(record.newFieldValue || null),
            oldValue: null,
            hasOldValue: false,
            isChanged: false,
            label: fieldMeta.label,
            dataType: dataType,
            isRequired: fieldMeta.isRequired || false,
            picklistValues: picklistOptions,
            hasPicklistValues: picklistOptions.length > 0,
            multiPicklistSelectedValues: [],
            isSelected: true,
            isDisabled: false,
            referenceTo: referenceTo,
            referenceObjectApiName: referenceObjectApiName,
            isPolymorphic: isPolymorphic,
            polymorphicObjectOptions: isPolymorphic ? referenceTo.map(obj => ({ label: this._getObjectLabel(obj), value: obj })) : [],
            selectedPolymorphicObject: isPolymorphic && referenceTo.length > 0 ? referenceTo[0] : null,
            hasPolymorphicOptions: isPolymorphic && referenceTo.length > 0,
            isString: dataType === 'STRING' && !picklistOptions.length,
            isTextArea: dataType === 'TEXTAREA',
            isReference: isReferenceType && !isPolymorphic && referenceObjectApiName,
            isPolymorphicReference: isReferenceType && isPolymorphic,
            isDate: dataType === 'DATE',
            isDateTime: dataType === 'DATETIME',
            isTime: dataType === 'TIME',
            isPicklist: (isPicklistType || isMultiPicklist) && picklistOptions.length > 0,
            isMultiPicklist: isMultiPicklist && picklistOptions.length > 0,
            isDouble: dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'PERCENT',
            isCurrency: dataType === 'CURRENCY',
            isBoolean: dataType === 'BOOLEAN',
            isEmail: dataType === 'EMAIL',
            isPhone: dataType === 'PHONE',
            isUrl: dataType === 'URL',
            isNewlyAdded: true // Flag to show it's user-added
        };
        
        // Add to record's fields
        record.fields.push(newField);
        
        // Reset add field state
        record.isAddingField = false;
        record.selectedNewField = null;
        record.newFieldValue = '';
        record.availableFieldOptions = [];
        
        this._recordGroups = [...this._recordGroups];
        
        this._showToast('Field Added', `${fieldMeta.label} has been added to the record.`, 'success');
    }

    handleCancelAddField() {
        // Close modal and reset state
        this._isAddFieldModalOpen = false;
        this._addFieldModalGroupIndex = null;
        this._addFieldModalRecordIndex = null;
        this._addFieldModalOptions = [];
        this._addFieldModalSelectedField = null;
        this._addFieldModalValue = '';
        this._addFieldModalFieldMeta = null;
    }

    handleFieldToggle(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.isSelected = event.target.checked;
        }
    }

    handleLayoutToggle(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        record.isLayoutFull = !record.isLayoutFull;
        record.layoutToggleLabel = record.isLayoutFull ? 'Switch to Compact' : 'Switch to Full';
        
        // Trigger reactivity
        this._recordGroups = [...this._recordGroups];
    }

    handleEditToggle(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const record = this._recordGroups[groupIndex].records[recordIndex];
        record.isEditMode = !record.isEditMode;
        
        // Trigger reactivity
        this._recordGroups = [...this._recordGroups];
    }

    /**
     * Handle refresh button click - refreshes the record data from Salesforce
     */
    async handleRefreshRecord(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        const group = this._recordGroups[groupIndex];
        const record = group.records[recordIndex];
        
        if (!record.id) {
            // No toast - user can see the record isn't saved yet
            return;
        }
        
        this._log('Refreshing record', { recordId: record.id, objectType: group.objectType });
        
        // Show loading state
        record.isRefreshing = true;
        this._recordGroups = [...this._recordGroups];
        
        try {
            // Notify LDS to refresh the record (for lightning-record-form)
            getRecordNotifyChange([{ recordId: record.id }]);
            
            // Also refresh the comparison fields if we have them
            if (record.fields && record.fields.length > 0) {
                const fieldNames = record.fields.map(f => f.apiName);
                const existingData = await getRecordFields({
                    recordId: record.id,
                    fieldApiNames: fieldNames
                });
                
                if (existingData) {
                    // Update fields with fresh values
                    record.fields.forEach(field => {
                        const fieldKey = Object.keys(existingData).find(
                            k => k.toLowerCase() === field.apiName.toLowerCase()
                        );
                        if (fieldKey !== undefined) {
                            const sanitized = this._sanitizeDisplayValue(existingData[fieldKey]);
                            field.oldValue = sanitized;
                            field.newValue = sanitized;
                            field.hasOldValue = true;
                            field.isChanged = false;
                        }
                    });
                    
                    // Get display name from existing record
                    if (existingData.Name) {
                        record.existingName = existingData.Name;
                        record.title = existingData.Name;
                    } else if (existingData.Subject) {
                        record.existingName = existingData.Subject;
                        record.title = existingData.Subject;
                    } else if (existingData.FirstName || existingData.LastName) {
                        const fullName = `${existingData.FirstName || ''} ${existingData.LastName || ''}`.trim();
                        record.existingName = fullName;
                        record.title = fullName;
                    }
                }
            }
            
            this._showToast('Refreshed', 'Record data has been refreshed.', 'success');
            
        } catch (e) {
            console.error('Error refreshing record:', e);
            // Error shown in console - no toast needed
        } finally {
            record.isRefreshing = false;
            this._recordGroups = [...this._recordGroups];
        }
    }

    handleAcceptField(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.isSelected = !field.isSelected;
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Handle field row click on mobile - toggles field selection
     * Only works on mobile devices
     */
    handleFieldRowClick(event) {
        // Only handle on mobile
        if (FORM_FACTOR !== 'Small') {
            return;
        }

        // Get the clicked element
        const target = event.target;
        const currentTarget = event.currentTarget;

        // If clicking directly on an actual input/textarea/select element, don't toggle
        if (target.tagName === 'INPUT' || 
            target.tagName === 'TEXTAREA' || 
            target.tagName === 'SELECT') {
            return;
        }

        // If clicking on a button that's not a label, check if it's interactive
        if (target.tagName === 'BUTTON' || target.closest('button')) {
            const button = target.tagName === 'BUTTON' ? target : target.closest('button');
            // Allow clicks on label buttons, but not other buttons
            if (button && !button.classList.contains('slds-form-element__label')) {
                // Check if it's a lookup/search button - those should work
                const isLookupButton = button.closest('lightning-record-picker') ||
                                     button.closest('.slds-input__icon-group') ||
                                     button.closest('.slds-combobox__input-entity-icon');
                if (!isLookupButton) {
                    return;
                }
            }
        }

        const groupIndex = parseInt(currentTarget.dataset.groupIndex, 10);
        const recordIndex = parseInt(currentTarget.dataset.recordIndex, 10);
        const fieldApiName = currentTarget.dataset.fieldName;
        const isSaved = currentTarget.dataset.isSaved === 'true';

        // Don't allow selection if record is saved
        if (isSaved) {
            return;
        }

        const field = this._recordGroups[groupIndex].records[recordIndex].fields
            .find(f => f.apiName === fieldApiName);
        
        if (field) {
            field.isSelected = !field.isSelected;
            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * For custom mtDateInput: always select the field when the user interacts with the date control.
     * Prevents iOS Salesforce app date picker interactions from toggling the row off.
     */
    handleDateFieldSelect(event) {
        event.stopPropagation();

        // Only handle on mobile
        if (FORM_FACTOR !== 'Small') {
            return;
        }

        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        const fieldApiName = event.target.dataset.fieldName;

        if (Number.isNaN(groupIndex) || Number.isNaN(recordIndex) || !fieldApiName) {
            return;
        }

        const record = this._recordGroups?.[groupIndex]?.records?.[recordIndex];
        if (!record || record.isSaved) return;

        const field = record.fields.find(f => f.apiName === fieldApiName);
        if (field && !field.isSelected) {
            field.isSelected = true;
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Check if a value looks like a Salesforce ID
     */
    _isSalesforceId(value) {
        if (!value) return false;
        const val = String(value);
        // Salesforce IDs are 15 or 18 alphanumeric characters
        return (val.length === 15 || val.length === 18) && /^[a-zA-Z0-9]+$/.test(val);
    }

    /**
     * Resolve lookup field IDs to display names
     */
    async _resolveLookupFieldNames() {
        this._log('Resolving lookup field names...');
        
        // Collect all lookup field values (both new and old)
        // Use the actual record ID value as key suffix to ensure uniqueness
        const allLookupIds = {};
        const fieldMapping = []; // Track which fields to update
        
        for (const group of this._recordGroups) {
            for (const record of group.records) {
                for (const field of record.fields) {
                    // Check if field is a reference type OR if field name ends with Id and value looks like an ID
                    const isLookupField = field.isReference || 
                        (field.apiName.endsWith('Id') && field.apiName !== 'Id');
                    
                    if (isLookupField) {
                        // Check new value
                        if (field.newValue && this._isSalesforceId(field.newValue)) {
                            const key = `new_${record.uuid}_${field.apiName}`;
                            allLookupIds[key] = String(field.newValue);
                            fieldMapping.push({
                                key,
                                recordUuid: record.uuid,
                                fieldApiName: field.apiName,
                                isOldValue: false
                            });
                            this._log('Collected lookup for resolution', { key, value: field.newValue, field: field.apiName });
                        }
                        
                        // Check old value
                        if (field.oldValue && this._isSalesforceId(field.oldValue)) {
                            const key = `old_${record.uuid}_${field.apiName}`;
                            allLookupIds[key] = String(field.oldValue);
                            fieldMapping.push({
                                key,
                                recordUuid: record.uuid,
                                fieldApiName: field.apiName,
                                isOldValue: true
                            });
                            this._log('Collected old lookup for resolution', { key, value: field.oldValue, field: field.apiName });
                        }
                    }
                }
            }
        }
        
        this._log('Lookup IDs to resolve', allLookupIds);
        this._log('Field mapping', fieldMapping);
        
        if (Object.keys(allLookupIds).length === 0) {
            this._log('No lookup fields to resolve');
            return;
        }

        try {
            const resolvedNames = await resolveLookupNames({ lookupIds: allLookupIds });
            this._log('Resolved lookup names from Apex', resolvedNames);

            // Update fields using the mapping we created earlier
            for (const mapping of fieldMapping) {
                const resolvedName = resolvedNames[mapping.key];
                if (resolvedName) {
                    // Find the record and field
                    for (const group of this._recordGroups) {
                        for (const record of group.records) {
                            if (record.uuid === mapping.recordUuid) {
                                const field = record.fields.find(f => f.apiName === mapping.fieldApiName);
                                if (field) {
                                    if (mapping.isOldValue) {
                                        field.oldDisplayValue = resolvedName;
                                        this._log('Set old display value', { field: field.apiName, value: resolvedName });
                                    } else {
                                        field.displayValue = resolvedName;
                                        field.hasDisplayValue = true;
                                        this._log('Set new display value', { field: field.apiName, value: resolvedName });
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Trigger reactivity
            this._recordGroups = [...this._recordGroups];

        } catch (e) {
            this._log('Error resolving lookup names', e);
            console.error('Full error:', e);
        }
    }

    async handleSaveRecord(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        
        await this._saveRecord(groupIndex, recordIndex, true);
    }

    async handleSaveAll() {
        this._log('Starting Save All operation');
        
        let successCount = 0;
        let errorCount = 0;
        let skippedCount = 0;
        const errors = [];

        // Process all unsaved records - continue even if some fail
        for (let gi = 0; gi < this._recordGroups.length; gi++) {
            for (let ri = 0; ri < this._recordGroups[gi].records.length; ri++) {
                const record = this._recordGroups[gi].records[ri];
                const group = this._recordGroups[gi];
                
                if (record.isSaved) {
                    skippedCount++;
                    continue;
                }
                
                // Check if any fields are selected
                const selectedFields = record.fields.filter(f => f.isSelected && f.apiName !== 'Id');
                if (selectedFields.length === 0) {
                    skippedCount++;
                    continue;
                }

                // Try to save this record - catch any errors and continue
                try {
                    const result = await this._saveRecord(gi, ri, false);
                    
                    if (result.success) {
                        successCount++;
                    } else {
                        errorCount++;
                        errors.push({
                            recordTitle: record.existingName || record.title,
                            objectType: group.label,
                            message: result.message
                        });
                    }
                } catch (e) {
                    // Even if there's an exception, continue with other records
                    errorCount++;
                    errors.push({
                        recordTitle: record.existingName || record.title,
                        objectType: group.label,
                        message: e.message || 'Unknown error'
                    });
                    console.error('Error saving record in Save All:', e);
                }
            }
        }

        // Show summary toast
        if (errorCount === 0 && successCount > 0) {
            this._showToast('All Records Saved', 
                `Successfully saved ${successCount} record${successCount !== 1 ? 's' : ''}.`, 
                'success');
        } else if (errorCount > 0 && successCount > 0) {
            this._showToast('Partial Success', 
                `Saved ${successCount} record${successCount !== 1 ? 's' : ''}, ${errorCount} failed.`, 
                'warning', 'sticky');
        } else if (errorCount > 0 && successCount === 0) {
            // Errors are shown inline on each record - no toast needed
        } else if (skippedCount > 0) {
            this._showToast('No Records to Save', 
                'All records are either already saved or have no selected fields.', 
                'info');
        }

        // Dispatch event with summary
        this.dispatchEvent(new CustomEvent('saveallcomplete', {
            detail: { 
                successCount,
                errorCount,
                skippedCount,
                errors
            }
        }));
    }

    /**
     * Validate all unsaved records before save
     */
    _validateAllRecords() {
        const errors = [];
        
        for (const group of this._recordGroups) {
            for (const record of group.records) {
                if (record.isSaved) continue;
                
                const selectedFields = record.fields.filter(f => f.isSelected && f.apiName !== 'Id');
                if (selectedFields.length === 0) continue;
                
                // Check required fields
                const missingRequired = record.fields
                    .filter(f => f.isRequired && f.isSelected && 
                        (f.newValue === null || f.newValue === undefined || f.newValue === ''))
                    .map(f => f.label);
                
                if (missingRequired.length > 0) {
                    errors.push(`${record.existingName || record.title}: Missing required fields: ${missingRequired.join(', ')}`);
                }
            }
        }
        
        return errors;
    }

    // ========== SAVE LOGIC ==========

    /**
     * Save a single record
     * @param {Number} groupIndex Index of the record group
     * @param {Number} recordIndex Index of the record within the group
     * @param {Boolean} showToasts Whether to show individual success/error toasts
     * @returns {Object} Result with success flag and message
     */
    async _saveRecord(groupIndex, recordIndex, showToasts = true) {
        const group = this._recordGroups[groupIndex];
        const record = group.records[recordIndex];

        if (record.isSaved) {
            return { success: true, message: 'Already saved' };
        }

        record.isSaving = true;
        record.hasError = false;
        record.errorMessage = null;
        record.fieldErrors = [];
        this._recordGroups = [...this._recordGroups]; // Trigger reactivity

        try {
            // Build field values from selected fields only
            const fieldValues = {};
            let hasValues = false;
            
            // Debug: Log all fields and their states with explicit console.log for clarity
            console.log('[mtRecordSuggestion] === SAVE DEBUG START ===');
            console.log('[mtRecordSuggestion] Record ID:', record.id);
            console.log('[mtRecordSuggestion] isNew:', record.isNew, 'isExisting:', record.isExisting);
            console.log('[mtRecordSuggestion] record.fields array length:', record.fields ? record.fields.length : 'UNDEFINED');
            console.log('[mtRecordSuggestion] record.fields:', JSON.stringify(record.fields?.map(f => ({
                api: f.apiName,
                new: f.newValue,
                old: f.oldValue,
                sel: f.isSelected
            }))));
            
            record.fields
                .filter(f => f.isSelected && f.apiName !== 'Id')
                .forEach(f => {
                    // Include all selected fields with values (simplified logic)
                    // For updates, we still send all selected fields - Apex will handle the update
                    const value = f.newValue;
                    console.log('[mtRecordSuggestion] Processing field:', f.apiName, 'value:', value, 'type:', typeof value);
                    if (value !== null && value !== undefined && value !== '') {
                        fieldValues[f.apiName] = value;
                        hasValues = true;
                    }
                });

            console.log('[mtRecordSuggestion] Final fieldValues:', JSON.stringify(fieldValues));
            console.log('[mtRecordSuggestion] hasValues:', hasValues);
            console.log('[mtRecordSuggestion] === SAVE DEBUG END ===');

            // Validate that we have fields to save
            if (!hasValues) {
                record.isSaving = false;
                this._recordGroups = [...this._recordGroups];
                const message = record.isExisting ? 'No fields selected to update' : 'Please provide values for at least one field';
                if (record.isNew) {
                    record.hasError = true;
                    record.errorMessage = message;
                    record.cardClass = 'record-card-error';
                }
                // Validation errors shown inline - no toast needed
                return { success: !record.isNew, message };
            }

            // Use JSON serialization for reliable parameter passing
            const fieldValuesJson = JSON.stringify(fieldValues);

            this._log('Saving record', {
                objectApiName: group.objectType,
                recordId: record.id || null,
                fieldValuesJson: fieldValuesJson,
                allowDuplicates: record.allowDuplicates || false
            });

            const result = await saveRecordSimple({ 
                objectApiName: group.objectType,
                recordId: record.id || null,
                fieldValuesJson: fieldValuesJson,
                allowDuplicates: record.allowDuplicates || false
            });
            
            this._log('Save result', JSON.stringify(result));

            if (result && result.success) {
                const wasNew = record.isNew;
                
                record.isSaved = true;
                record.isNotSaved = false;
                record.id = result.recordId;
                record.hasError = false;
                record.errorMessage = null;
                record.fieldErrors = [];
                record.cardClass = 'true'; // Success state
                
                // Update fields to reflect saved state
                // For existing record updates: preserve the pre-save value for display
                record.fields.forEach(f => {
                    if (f.isSelected) {
                        // Store the original old value before overwriting (for "Old" column after save)
                        f.preSaveValue = f.oldValue;
                        f.oldValue = f.newValue;
                        f.hasOldValue = true;
                        f.isChanged = false;
                        f.hasError = false;
                        f.errorMessage = null;
                    }
                });
                
                // Flag to show updated labels after save (Old/Current instead of Current/New)
                record.showUpdatedLabels = true;
                
                // IMPORTANT: Notify Lightning Data Service that the record changed
                // This refreshes the lightning-record-form to show updated values
                if (record.id) {
                    getRecordNotifyChange([{ recordId: record.id }]);
                    this._log('Notified LDS of record change', record.id);
                }
                
                // Convert new records to existing mode so they show the record form
                // BUT only for objects that support UI API (not Task, Event, etc.)
                if (wasNew && group.useUiApi) {
                    record.isNew = false;
                    record.isExisting = true;
                    record.wasJustCreated = true; // Flag to hide "Proposed Changes" section
                    record.isLayoutFull = false; // Start in compact view
                    record.isEditMode = false; // Start in readonly
                    record.existingName = record.title; // Use the title as the name
                    // Clear fields since we'll show the record form
                    record.fields = [];
                    this._log('Converted new record to existing mode (UI API supported)', { objectType: group.objectType });
                } else if (wasNew) {
                    // For non-UI API objects, mark as saved with special display
                    record.wasJustCreated = true;
                    record.showSavedFieldsOnly = true; // Flag for simple saved fields display
                    // Clear old values so it doesn't show comparison
                    record.fields.forEach(f => {
                        f.hasOldValue = false;
                        f.oldValue = null;
                    });
                    this._log('Keeping new record display (UI API not supported)', { objectType: group.objectType });
                }
                
                if (showToasts) {
                    const action = wasNew ? 'created' : 'updated';
                    this._showToast('Success', 
                        `${group.label} ${action} successfully`, 
                        'success');
                }
                
                this.dispatchEvent(new CustomEvent('recordsaved', {
                    detail: { 
                        recordId: result.recordId, 
                        objectType: group.objectType,
                        isNew: wasNew,
                        fieldValues
                    }
                }));
                
                return { success: true, recordId: result.recordId };
                
            } else {
                record.hasError = true;
                record.errorMessage = this._formatErrorMessage(result);
                record.fieldErrors = result?.fieldErrors || [];
                record.cardClass = 'record-card-error'; // Error state
                
                // Check if this is a duplicate detection error (from Apex result)
                const isDuplicate = result?.isDuplicateError || this._isDuplicateError(record.errorMessage);
                record.isDuplicateError = isDuplicate;
                record.duplicateRecordIds = result?.duplicateRecordIds || [];
                
                // Check if this is a required field missing error
                const missingFields = this._extractMissingRequiredFields(record.errorMessage, result?.fieldErrors);
                record.isMissingRequiredFields = missingFields.length > 0;
                record.missingFieldsApiNames = missingFields;
                record.missingFieldsList = missingFields.join(', ');
                
                // Only show generic error if not duplicate and not missing required fields
                record.hasNonDuplicateError = !isDuplicate && !record.isMissingRequiredFields;
                
                this._log('Save failed', { errorMessage: record.errorMessage, fieldErrors: record.fieldErrors, isDuplicate, missingFields, duplicateIds: record.duplicateRecordIds });
                
                // Highlight fields with errors
                if (result?.fieldErrors && result.fieldErrors.length > 0) {
                    result.fieldErrors.forEach(fe => {
                        const field = record.fields.find(f => 
                            f.apiName.toLowerCase() === fe.fieldApiName.toLowerCase()
                        );
                        if (field) {
                            field.hasError = true;
                            field.errorMessage = fe.message;
                            field.rowClass = 'field-row slds-m-bottom_small' + ((field.isDate || field.isDateTime) ? ' field-row-date' : '') + ' field-has-error';
                        }
                    });
                }
                
                // Show toast on mobile for better visibility
                if (showToasts && this.isMobile) {
                    if (isDuplicate) {
                        this._showToast('Duplicate Detected', 'A similar record may already exist. Check the error message.', 'warning', 'sticky');
                    } else {
                        this._showToast('Error Saving Record', record.errorMessage, 'error', 'sticky');
                    }
                }
                
                return { success: false, message: record.errorMessage, isDuplicate };
            }
        } catch (e) {
            record.hasError = true;
            record.errorMessage = this._extractErrorMessage(e);
            record.cardClass = 'record-card-error'; // Error state
            
            // Check if this is a duplicate detection error
            const isDuplicate = this._isDuplicateError(record.errorMessage);
            record.isDuplicateError = isDuplicate;
            
            // Check if this is a required field missing error
            const missingFields = this._extractMissingRequiredFields(record.errorMessage, null);
            record.isMissingRequiredFields = missingFields.length > 0;
            record.missingFieldsApiNames = missingFields;
            record.missingFieldsList = missingFields.join(', ');
            
            record.hasNonDuplicateError = !isDuplicate && !record.isMissingRequiredFields;
            
            console.error('Save error full:', e);
            console.error('Save error body:', e?.body);
            console.error('Save error message:', e?.message);
            this._log('Save exception', { message: record.errorMessage, error: e, isDuplicate, missingFields });
            
            // Show toast on mobile for better visibility
            if (showToasts && this.isMobile) {
                if (isDuplicate) {
                    this._showToast('Duplicate Detected', 'A similar record may already exist.', 'warning', 'sticky');
                } else {
                    this._showToast('Error', record.errorMessage, 'error', 'sticky');
                }
            }
            
            return { success: false, message: record.errorMessage, isDuplicate };
        } finally {
            record.isSaving = false;
            this._recordGroups = [...this._recordGroups];
        }
    }

    /**
     * Format error message from DML result
     */
    _formatErrorMessage(result) {
        if (!result) return 'No response from server';
        
        let message = result.message || 'Error saving record';
        
        // Add field-level errors if available
        if (result.fieldErrors && result.fieldErrors.length > 0) {
            const fieldMessages = result.fieldErrors
                .map(fe => `${fe.fieldApiName}: ${fe.message}`)
                .join('; ');
            if (!message.includes(fieldMessages)) {
                message += ` (${fieldMessages})`;
            }
        }
        
        this._log('Formatted error message', message);
        return message;
    }

    /**
     * Extract error message from exception
     */
    _extractErrorMessage(error) {
        if (!error) return 'Unknown error';
        
        // AuraHandledException format
        if (error.body?.message) {
            return error.body.message;
        }
        
        // Standard Error format
        if (error.message) {
            return error.message;
        }
        
        // Array of errors (from wire adapters)
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join('; ');
        }
        
        // Fallback to string conversion
        return String(error);
    }

    // ========== HELPERS ==========

    _getObjectIcon(objectType) {
        // Special cases where icon name differs from object API name
        const specialIcons = {
            'Product2': 'standard:product',
            'Pricebook2': 'standard:pricebook',
            'OpportunityLineItem': 'standard:product',
            'CampaignMember': 'standard:campaign_members',
            'ContentDocument': 'standard:file',
            'ContentVersion': 'standard:file',
            'FeedItem': 'standard:feed',
            'EmailMessage': 'standard:email'
        };
        
        // Check special cases first, then generate dynamically
        if (specialIcons[objectType]) {
            return specialIcons[objectType];
        }
        
        // Dynamic: convert ObjectType to standard:objecttype (lowercase)
        return `standard:${objectType.toLowerCase()}`;
    }

    _getRecordTitle(record, objectType) {
        // Try common name fields
        if (record.Name) return record.Name;
        if (record.Subject) return record.Subject;
        if (record.FirstName || record.LastName) {
            return `${record.FirstName || ''} ${record.LastName || ''}`.trim();
        }
        return record.Id ? `${objectType} (Update)` : `New ${objectType}`;
    }

    _formatLabel(apiName) {
        // Convert CamelCase/snake_case to readable label
        // For reference fields (ending in Id), remove the "Id" suffix since we show the name
        let label = apiName;
        
        // Special handling for lookup fields - remove Id suffix
        if (apiName.endsWith('Id') && apiName !== 'Id' && apiName.length > 2) {
            label = apiName.slice(0, -2); // Remove 'Id' suffix
        }
        
        return label
            .replace(/([A-Z])/g, ' $1')
            .replace(/_/g, ' ')
            .trim();
    }

    /**
     * Get a friendly label for an object API name
     */
    _getObjectLabel(objectApiName) {
        // Common object labels
        const labelMap = {
            'Account': 'Account',
            'Contact': 'Contact',
            'Lead': 'Lead',
            'Opportunity': 'Opportunity',
            'Case': 'Case',
            'Campaign': 'Campaign',
            'User': 'User',
            'Task': 'Task',
            'Event': 'Event',
            'Contract': 'Contract',
            'Order': 'Order',
            'Product2': 'Product',
            'Asset': 'Asset',
            'Solution': 'Solution'
        };
        
        return labelMap[objectApiName] || objectApiName.replace(/__c$/, '').replace(/_/g, ' ');
    }

    /**
     * Detect the object type from a Salesforce ID using key prefix
     */
    _detectObjectTypeFromId(recordId, possibleObjects) {
        if (!recordId || recordId.length < 3) return null;
        
        // Common Salesforce ID prefixes
        const prefixMap = {
            '001': 'Account',
            '003': 'Contact',
            '00Q': 'Lead',
            '006': 'Opportunity',
            '500': 'Case',
            '701': 'Campaign',
            '005': 'User',
            '00T': 'Task',
            '00U': 'Event',
            '800': 'Contract',
            '801': 'Order',
            '01t': 'Product2',
            '02i': 'Asset',
            '501': 'Solution'
        };
        
        const prefix = recordId.substring(0, 3);
        const detectedObject = prefixMap[prefix];
        
        // Return detected object only if it's in the list of possible objects
        if (detectedObject && possibleObjects.includes(detectedObject)) {
            return detectedObject;
        }
        
        return null;
    }

    _inferDataType(fieldName, value) {
        if (fieldName.endsWith('Id') || fieldName === 'Id') return 'REFERENCE';
        if (fieldName.includes('Date')) return 'DATE';
        if (fieldName.includes('DateTime')) return 'DATETIME';
        if (typeof value === 'boolean') return 'BOOLEAN';
        if (typeof value === 'number') return 'DOUBLE';
        if (fieldName === 'Description') return 'TEXTAREA';
        return 'STRING';
    }

    _generateUuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            const r = Math.random() * 16 | 0;
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    _showToast(title, message, variant, mode = 'dismissible') {
        this.dispatchEvent(new ShowToastEvent({ 
            title, 
            message, 
            variant,
            mode // 'dismissible', 'pester', or 'sticky'
        }));
    }

    /**
     * Check if error message indicates duplicate detection
     */
    _isDuplicateError(errorMessage) {
        if (!errorMessage) return false;
        const msg = errorMessage.toLowerCase();
        return msg.includes('use one of these records') || 
               msg.includes('duplicate') ||
               msg.includes('matching record') ||
               msg.includes('already exists');
    }

    /**
     * Extract missing required field names from error message or field errors
     */
    _extractMissingRequiredFields(errorMessage, fieldErrors) {
        const missingFields = [];
        
        // Check field errors first (most reliable)
        if (fieldErrors && fieldErrors.length > 0) {
            fieldErrors.forEach(fe => {
                if (fe.message && (
                    fe.message.toLowerCase().includes('required') ||
                    fe.message.toLowerCase().includes('must enter') ||
                    fe.message.toLowerCase().includes('cannot be blank') ||
                    fe.message.toLowerCase().includes('must be filled')
                )) {
                    missingFields.push(fe.fieldApiName);
                }
            });
        }
        
        // Also check the main error message for REQUIRED_FIELD_MISSING pattern
        if (errorMessage) {
            const msg = errorMessage.toLowerCase();
            if (msg.includes('required field') || msg.includes('required_field_missing')) {
                // Try to extract field names from message like "Required fields are missing: [StageName, CloseDate]"
                const match = errorMessage.match(/\[([^\]]+)\]/);
                if (match && match[1]) {
                    const fields = match[1].split(',').map(f => f.trim());
                    fields.forEach(f => {
                        if (!missingFields.includes(f)) {
                            missingFields.push(f);
                        }
                    });
                }
            }
        }
        
        return missingFields;
    }

    /**
     * Handle opening the record picker modal (for duplicates)
     */
    async handleOpenDuplicateModal(event) {
        const groupIndex = parseInt(event.target.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.target.dataset.recordIndex, 10);
        await this._openRecordPickerModal(groupIndex, recordIndex, 'duplicate');
    }

    /**
     * Handle "Link to Existing" button click
     */
    async handleLinkToExisting(event) {
        const groupIndex = parseInt(event.currentTarget.dataset.groupIndex, 10);
        const recordIndex = parseInt(event.currentTarget.dataset.recordIndex, 10);
        await this._openRecordPickerModal(groupIndex, recordIndex, 'link');
    }

    /**
     * Open the record picker modal
     */
    async _openRecordPickerModal(groupIndex, recordIndex, mode) {
        const group = this._recordGroups[groupIndex];
        const record = group.records[recordIndex];
        
        this._recordPickerModalGroupIndex = groupIndex;
        this._recordPickerModalRecordIndex = recordIndex;
        this._recordPickerModalObjectType = group.objectType;
        this._recordPickerModalMode = mode;
        this._suggestedRecords = [];
        this._recordPickerModalLoading = true;
        this._recordPickerSearchTerm = '';
        
        if (mode === 'duplicate') {
            this._recordPickerModalTitle = 'Similar Records Found';
            this._recordPickerModalSubtitle = 'Select a record to update instead of creating a duplicate';
            this._recordPickerModalAllowCreate = true;
        } else {
            this._recordPickerModalTitle = `Select ${group.label}`;
            this._recordPickerModalSubtitle = `Choose an existing ${group.label} to link, or create a new one`;
            this._recordPickerModalAllowCreate = true; // Always allow creating new from link modal
        }
        
        this._isRecordPickerModalOpen = true;
        
        try {
            let records = [];
            
            // If duplicate detection provided IDs, fetch those first
            if (mode === 'duplicate' && record.duplicateRecordIds && record.duplicateRecordIds.length > 0) {
                const duplicates = await getDuplicateRecords({
                    objectApiName: group.objectType,
                    recordIds: record.duplicateRecordIds
                });
                records = duplicates || [];
            } else {
                // Fetch related records from the Account
                records = await this._fetchRelatedRecords(group.objectType, '');
            }
            
            this._suggestedRecords = records.map(d => ({
                ...d,
                showPreview: false,
                isFullLayout: false,
                subtitle: this._buildRecordSubtitle(d, group.objectType)
            }));
            
            this._log('Fetched records for modal', { count: this._suggestedRecords.length, objectType: group.objectType });
        } catch (e) {
            console.error('Error fetching records:', e);
        }
        
        this._recordPickerModalLoading = false;
    }

    /**
     * Fetch related records from the Account
     */
    async _fetchRelatedRecords(objectApiName, searchTerm) {
        try {
            const records = await getRelatedRecords({
                objectApiName: objectApiName,
                accountId: this.accountId || null,
                searchTerm: searchTerm || null,
                limitRecords: 20
            });
            return records || [];
        } catch (e) {
            console.error('Error fetching related records:', e);
            return [];
        }
    }

    /**
     * Build a subtitle for suggested records based on object type
     */
    _buildRecordSubtitle(record, objectType) {
        const parts = [];
        const fields = record.fields || {};
        
        // Object-specific subtitle building
        if (objectType === 'Opportunity') {
            if (fields.StageName) parts.push(fields.StageName);
            if (fields.Amount) parts.push('$' + Number(fields.Amount).toLocaleString());
            if (fields.CloseDate) parts.push(fields.CloseDate);
        } else if (objectType === 'Contact') {
            if (fields.Title) parts.push(fields.Title);
            if (fields.Email) parts.push(fields.Email);
            if (fields.Phone) parts.push(fields.Phone);
        } else if (objectType === 'Case') {
            if (fields.Status) parts.push(fields.Status);
            if (fields.Subject) parts.push(fields.Subject);
        } else if (objectType === 'Task' || objectType === 'Event') {
            if (fields.Status) parts.push(fields.Status);
            if (fields.Subject) parts.push(fields.Subject);
        } else {
            // Generic fallback
            if (fields.Email) parts.push(fields.Email);
            if (fields.Phone) parts.push(fields.Phone);
            if (fields.Title) parts.push(fields.Title);
            if (fields.Status) parts.push(fields.Status);
        }
        
        return parts.join(' • ');
    }

    /**
     * Handle closing the record picker modal
     */
    handleCloseRecordPickerModal() {
        this._isRecordPickerModalOpen = false;
        this._recordPickerModalGroupIndex = null;
        this._recordPickerModalRecordIndex = null;
        this._recordPickerModalObjectType = null;
        this._suggestedRecords = [];
        this._recordPickerSearchTerm = '';
    }

    /**
     * Handle preview button click
     */
    handlePreviewRecord(event) {
        const recordId = event.target.dataset.recordId;
        this._suggestedRecords = this._suggestedRecords.map(r => ({
            ...r,
            showPreview: r.recordId === recordId ? !r.showPreview : r.showPreview
        }));
    }

    /**
     * Handle toggling preview layout (Full/Compact)
     */
    handleTogglePreviewLayout(event) {
        const recordId = event.target.dataset.recordId;
        this._suggestedRecords = this._suggestedRecords.map(r => ({
            ...r,
            isFullLayout: r.recordId === recordId ? !r.isFullLayout : r.isFullLayout
        }));
    }

    /**
     * Handle selecting a record from the list
     */
    handleSelectRecord(event) {
        const recordId = event.target.dataset.recordId;
        if (!recordId) return;
        this._selectRecordAndClose(recordId);
    }

    /**
     * Handle search input
     */
    handleRecordPickerSearch(event) {
        this._recordPickerSearchTerm = event.target.value;
        
        // Debounce search
        if (this._searchTimeout) {
            clearTimeout(this._searchTimeout);
        }
        
        this._searchTimeout = setTimeout(() => {
            this._performSearch();
        }, 300);
    }

    /**
     * Perform the search
     */
    async _performSearch() {
        const groupIndex = this._recordPickerModalGroupIndex;
        if (groupIndex === null) return;
        
        const group = this._recordGroups[groupIndex];
        this._recordPickerModalLoading = true;
        
        try {
            const records = await this._fetchRelatedRecords(group.objectType, this._recordPickerSearchTerm);
            this._suggestedRecords = records.map(d => ({
                ...d,
                showPreview: false,
                isFullLayout: false,
                subtitle: this._buildRecordSubtitle(d, group.objectType)
            }));
        } catch (e) {
            console.error('Error searching records:', e);
        }
        
        this._recordPickerModalLoading = false;
    }

    /**
     * Select a record and close modal
     */
    _selectRecordAndClose(recordId) {
        const groupIndex = this._recordPickerModalGroupIndex;
        const recordIndex = this._recordPickerModalRecordIndex;
        const group = this._recordGroups[groupIndex];
        const record = group.records[recordIndex];
        
        this._log('Record selected', { recordId, groupIndex, recordIndex });
        
        // Get the selected record's name from suggested records
        const selectedSuggestedRecord = this._suggestedRecords.find(r => r.recordId === recordId);
        
        // Close the modal
        this.handleCloseRecordPickerModal();
        
        // Clear error state
        record.hasError = false;
        record.errorMessage = null;
        record.isDuplicateError = false;
        record.hasNonDuplicateError = false;
        record.isMissingRequiredFields = false;
        record.cardClass = '';
        record.showUpdatedLabels = false; // Reset since we're linking to new record
        
        // Convert to existing/update mode with the selected record
        record.id = recordId;
        record.isNew = false;
        record.isExisting = true;
        record.hasProposedChanges = true;
        record.isLayoutFull = false;
        record.isEditMode = false;
        record.isSaved = false;
        record.isNotSaved = true;
        
        // Update the record name/title from the selected record
        if (selectedSuggestedRecord && selectedSuggestedRecord.name) {
            record.existingName = selectedSuggestedRecord.name;
            record.title = selectedSuggestedRecord.name;
            this._log('Updated record name to', selectedSuggestedRecord.name);
        }
        
        // Fetch the existing record data to show comparison
        this._fetchExistingRecordDataForDuplicate(record, group);
        
        this._showToast('Record Linked', 'The record will be updated with the proposed values.', 'success');
        
        this._recordGroups = [...this._recordGroups];
    }

    /**
     * Handle "Create New Instead" from modal
     * This handles both:
     * 1. Duplicate detection - user wants to create anyway
     * 2. Link mode - user wants to create new instead of linking to existing
     */
    handleCreateNewFromModal() {
        const groupIndex = this._recordPickerModalGroupIndex;
        const recordIndex = this._recordPickerModalRecordIndex;
        const group = this._recordGroups[groupIndex];
        const record = group.records[recordIndex];
        const mode = this._recordPickerModalMode;
        
        // Close the modal
        this.handleCloseRecordPickerModal();
        
        // Clear error state
        record.hasError = false;
        record.errorMessage = null;
        record.isDuplicateError = false;
        record.hasNonDuplicateError = false;
        record.isMissingRequiredFields = false;
        record.cardClass = '';
        
        if (mode === 'duplicate') {
            // Duplicate mode - just allow creating with duplicates
            record.allowDuplicates = true;
            this._showToast('Ready', 'Click Save to create the record.', 'info');
        } else {
            // Link mode - convert to new record creation
            record.id = null;
            record.isNew = true;
            record.isExisting = false;
            record.hasProposedChanges = false;
            record.showUpdatedLabels = false;
            record.existingRecordData = null;
            record.existingName = null;
            record.allowDuplicates = true; // Allow duplicates since user explicitly wants to create new
            
            // Clear old values from fields since this is now a new record
            record.fields.forEach(f => {
                f.oldValue = null;
                f.hasOldValue = false;
                f.isChanged = false;
                f.preSaveValue = null;
                f.newValue = this._sanitizeForFieldValue(f.newValue);
            });
            
            // Update title
            record.title = `New ${group.label}`;
            
            this._showToast('Creating New', `This will create a new ${group.label} instead of updating an existing one.`, 'info');
        }
        
        this._recordGroups = [...this._recordGroups];
    }

    /**
     * Fetch existing record data for duplicate resolution
     */
    async _fetchExistingRecordDataForDuplicate(record, group) {
        try {
            const fieldApiNames = record.fields.map(f => f.apiName);
            const existingData = await getRecordData({ 
                recordId: record.id, 
                fieldApiNames: fieldApiNames 
            });
            
            if (existingData && existingData.fieldValues) {
                // Update fields with old values from existing record
                record.fields.forEach(f => {
                    const oldValue = existingData.fieldValues[f.apiName];
                    f.oldValue = oldValue !== undefined ? this._sanitizeDisplayValue(oldValue) : '';
                    f.hasOldValue = true;
                    f.isChanged = f.newValue !== f.oldValue;
                });
                
                // Get the record name
                const nameField = existingData.fieldValues.Name || 
                                  existingData.fieldValues.Subject ||
                                  existingData.fieldValues.Title;
                if (nameField) {
                    record.existingName = nameField;
                }
                
                this._recordGroups = [...this._recordGroups];
            }
        } catch (e) {
            console.error('Error fetching existing record for duplicate:', e);
        }
    }

    /**
     * Handle dismissing error message
     */
    handleDismissError(event) {
        // Find the button element with data attributes (click target might be a child element like SVG)
        let target = event.target;
        while (target && !target.dataset.groupIndex) {
            target = target.parentElement;
        }
        if (!target) {
            console.error('Dismiss Error: Could not find data attributes on target');
            return;
        }
        
        const groupIndex = parseInt(target.dataset.groupIndex, 10);
        const recordIndex = parseInt(target.dataset.recordIndex, 10);
        
        if (isNaN(groupIndex) || isNaN(recordIndex)) {
            console.error('Dismiss Error: Invalid group or record index', { groupIndex, recordIndex });
            return;
        }
        
        const record = this._recordGroups[groupIndex]?.records?.[recordIndex];
        if (!record) {
            console.error('Dismiss Error: Record not found', { groupIndex, recordIndex });
            return;
        }
        
        // Clear all error states
        record.hasError = false;
        record.errorMessage = null;
        record.isMissingRequiredFields = false;
        record.isDuplicateError = false;
        record.hasNonDuplicateError = false;
        record.missingFieldsList = '';
        record.missingFieldsApiNames = [];
        record.cardClass = '';
        
        this._recordGroups = [...this._recordGroups];
    }

    /**
     * Toggle error info tooltip visibility
     */
    _showErrorInfoTooltip = false;
    
    handleShowErrorInfo() {
        this._showErrorInfoTooltip = !this._showErrorInfoTooltip;
        
        // Auto-hide after 5 seconds
        if (this._showErrorInfoTooltip) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this._showErrorInfoTooltip = false;
            }, 5000);
        }
    }

    /**
     * Create a field object from metadata
     */
    _createFieldFromMetadata(fieldMeta, value, objectType) {
        const dataType = fieldMeta.dataType || 'STRING';
        const isReference = dataType === 'REFERENCE';
        const isPicklist = dataType === 'PICKLIST';
        const isMultiPicklist = dataType === 'MULTIPICKLIST';
        const isDate = dataType === 'DATE';
        const isDateTime = dataType === 'DATETIME';
        const isBoolean = dataType === 'BOOLEAN';
        const isCurrency = dataType === 'CURRENCY';
        const isNumber = dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'PERCENT';
        const isEmail = dataType === 'EMAIL';
        const isPhone = dataType === 'PHONE';
        const isUrl = dataType === 'URL';
        const isTextArea = dataType === 'TEXTAREA' || dataType === 'RICHTEXTAREA';
        const isTime = dataType === 'TIME';
        
        // Format picklist options
        let picklistOptions = [];
        if ((isPicklist || isMultiPicklist) && fieldMeta.picklistValues) {
            picklistOptions = fieldMeta.picklistValues.map(pv => ({
                label: pv.label,
                value: pv.value
            }));
        }
        
        return {
            apiName: fieldMeta.apiName,
            label: fieldMeta.label,
            dataType: dataType,
            isRequired: fieldMeta.isRequired || false,
            newValue: value || '',
            oldValue: null,
            hasOldValue: false,
            isSelected: true,
            isChanged: false,
            hasError: false,
            errorMessage: null,
            displayValue: null,
            // Type flags
            isString: !isReference && !isPicklist && !isMultiPicklist && !isDate && !isDateTime && !isBoolean && !isCurrency && !isNumber && !isEmail && !isPhone && !isUrl && !isTextArea && !isTime,
            isReference,
            isPicklist,
            isMultiPicklist,
            isDate,
            isDateTime,
            isBoolean,
            isCurrency,
            isNumber,
            isEmail,
            isPhone,
            isUrl,
            isTextArea,
            isTime,
            picklistOptions,
            // Reference field specifics
            isPolymorphicReference: isReference && fieldMeta.referenceTo && fieldMeta.referenceTo.length > 1,
            referenceTo: fieldMeta.referenceTo || [],
            polymorphicObjectOptions: [],
            selectedPolymorphicObject: null,
            rowClass: 'field-row slds-m-bottom_small' + ((this._currentNewFieldDataType === 'DATE' || this._currentNewFieldDataType === 'DATETIME') ? ' field-row-date' : '')
        };
    }

    _log(message, data) {
        if (DEBUG_MODE) {
            console.log(`[AiRecordSuggestions] ${message}`, data || '');
        }
    }
}