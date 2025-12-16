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

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

// Apex methods
import isAdminUser from '@salesforce/apex/mt_TranscribeController.isAdminUser';
import getOrgDomainUrl from '@salesforce/apex/mt_TranscribeController.getOrgDomainUrl';
import getAllConfigs from '@salesforce/apex/mt_TranscribeController.getAllConfigs';
import saveOpenAIApiKey from '@salesforce/apex/mt_TranscribeController.saveOpenAIApiKey';
import testEinsteinConnection from '@salesforce/apex/mt_TranscribeController.testEinsteinConnection';
import testWhisperConnection from '@salesforce/apex/mt_TranscribeController.testWhisperConnection';
import saveConfiguration from '@salesforce/apex/mt_ConfigMetadataService.saveConfiguration';
import saveObjectConfiguration from '@salesforce/apex/mt_ConfigMetadataService.saveObjectConfiguration';
import getObjectConfigs from '@salesforce/apex/mt_TranscribeController.getObjectConfigs';
import getAvailableObjects from '@salesforce/apex/mt_TranscribeController.getAvailableObjects';
import getObjectDescribe from '@salesforce/apex/mt_TranscribeController.getObjectDescribe';
import getObjectLayouts from '@salesforce/apex/mt_TranscribeController.getObjectLayouts';
import getFieldsForLayout from '@salesforce/apex/mt_TranscribeController.getFieldsForLayout';
import getSetupUrls from '@salesforce/apex/mt_TranscribeController.getSetupUrls';
import assignPermissionSetsToCurrentUser from '@salesforce/apex/mt_TranscribeController.assignPermissionSetsToCurrentUser';
import checkPermissionSetStatus from '@salesforce/apex/mt_TranscribeController.checkPermissionSetStatus';
import updateNamedCredentialUrl from '@salesforce/apex/mt_TranscribeController.updateNamedCredentialUrl';
import getConfig from '@salesforce/apex/mt_GetObjectConfigForPrompt.getConfig';
import getAvailablePromptTemplates from '@salesforce/apex/mt_TranscribeController.getAvailablePromptTemplates';

export default class MtVoiceAssistantAdmin extends NavigationMixin(LightningElement) {
    // ==========================================================================
    // STATE PROPERTIES
    // ==========================================================================
    
    @track isLoading = true;
    @track isAccessDenied = false;
    @track orgDomainUrl = '';
    @track configs = [];
    @track openAIApiKey = '';
    
    // API key save state
    @track isSavingApiKey = false;
    @track apiKeySaveMessage = '';
    @track apiKeySaveSuccess = false;
    
    // Connection test state
    @track isTestingEinstein = false;
    @track einsteinTestResult = '';
    @track einsteinTestSuccess = false;
    
    @track isTestingWhisper = false;
    @track whisperTestResult = '';
    @track whisperTestSuccess = false;
    
    // Inline connection test (for Setup Checklist Step 6)
    @track isTestingConnection = false;
    @track connectionTestResult = null;
    
    // Named Credential auto-update state (for Setup Checklist)
    @track isUpdatingNamedCredential = false;
    @track namedCredentialUpdated = false;
    @track namedCredentialNeedsUpdate = true; // Default to true until checked
    
    // Setup navigation URLs (direct links to setup components)
    @track setupUrls = {
        namedCredentialUrl: '/lightning/setup/NamedCredential/home',
        externalCredentialUrl: '/lightning/setup/NamedCredential/home',
        connectedAppUrl: '/lightning/setup/ConnectedApplication/home',
        connectedAppViewUrl: '/lightning/setup/ConnectedApplication/home',
        connectedAppManageUrl: '/lightning/setup/ConnectedApplication/home',
        permissionSetUrl: '/lightning/setup/PermSets/home'
    };
    
    // Permission set status (for automated setup)
    @track permSetStatus = {
        userAssigned: false,
        adminAssigned: false,
        allAssigned: false
    };
    @track isAssigningPermSets = false;
    
    // Tab navigation
    @track activeTabValue = 'setup';
    
    // Modal state
    @track isModalOpen = false;
    @track isEditMode = false;
    @track isSaving = false;
    @track savingMessage = 'Saving configuration...';
    @track formData = {
        label: '',
        developerName: '',
        provider: 'Einstein',
        promptTemplateName: '',
        einsteinNamedCredential: 'mt_EinsteinTranscribe',
        whisperNamedCredential: 'mt_OpenAI_Whisper',
        whisperModel: 'whisper-1',
        isActive: true,
        enableImageInput: true,
        description: ''
    };
    
    // Provider options for dropdown
    providerOptions = [
        { label: 'Einstein Transcribe', value: 'Einstein' },
        { label: 'OpenAI Whisper', value: 'Whisper' }
    ];
    
    // Object Configuration State
    @track selectedObjectConfigProfile = 'Default';
    @track objectConfigs = [];
    @track allObjectConfigs = {}; // Map of configName -> objectConfigs array
    @track availableObjects = [];
    @track availableFields = [];
    
    // Accordion State
    @track activeAccordionSections = ['Default'];
    
    // Preview Modal State
    @track isPreviewModalOpen = false;
    @track previewContent = '';
    @track previewConfigName = '';
    @track isLoadingPreview = false;
    
    // Prompt Template Options
    @track promptTemplateOptions = [];
    
    // Show Clone Instructions State
    @track showCloneInstructions = false;
    
    // Test Transcription Provider Selection
    @track testTranscriptionProvider = 'Einstein';
    @track testConfigName = 'Default';
    
    // Test Provider Options for dropdown
    testProviderOptions = [
        { label: 'Einstein Transcribe', value: 'Einstein' },
        { label: 'OpenAI Whisper', value: 'Whisper' }
    ];
    
    // Setup Steps Completion State
    @track setupSteps = {
        step1: false,
        step2: false,
        step3: false,
        step4: false,
        step5: false
    };
    
    // Object Modal State
    @track isObjectModalOpen = false;
    @track isObjectEditMode = false;
    @track isSavingObjectConfig = false;
    @track objectFormData = {
        objectApiName: '',
        allowedFields: [],
        mandatoryFields: [],
        allowCreate: true,
        allowEdit: true
    };
    
    // Layout Import State
    @track layoutOptions = [];
    @track selectedLayoutOption = '';
    @track isLoadingLayoutFields = false;
    @track isLoadingFieldInfo = false;
    
    // Components Tab - Active Sections
    activeComponentSections = ['setup', 'accountflow', 'standaloneflow'];
    
    // ==========================================================================
    // COMPONENT DATA (for Components Tab)
    // ==========================================================================
    
    // Setup & Authentication Components
    setupComponents = [
        {
            name: 'mt_Einstein_Transcribe',
            type: 'Connected App',
            icon: 'utility:connected_apps',
            description: 'OAuth 2.0 Connected App for Einstein Transcribe API authentication. Provides client credentials for API access.',
            created: 'Nov 17, 2024',
            updated: 'Dec 3, 2025',
            changes: 'Updated callback URL and OAuth scopes'
        },
        {
            name: 'mt_EinsteinTranscribe',
            type: 'Named Credential',
            icon: 'utility:key',
            description: 'Stores the org domain URL for Einstein Transcribe API calls. Must be configured with your org URL after deployment.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Auto-detection of URL update requirement'
        },
        {
            name: 'mt_EinsteinTranscribe',
            type: 'External Credential',
            icon: 'utility:lock',
            description: 'OAuth 2.0 Client Credentials configuration. Requires client_id and client_secret from the Connected App.',
            created: 'Nov 17, 2024',
            updated: 'Dec 3, 2025',
            changes: null
        },
        {
            name: 'MT_Voice_Assistant_User',
            type: 'Permission Set',
            icon: 'utility:user',
            description: 'Grants access to Voice Assistant components for end users. Required for using the transcription features.',
            created: 'Nov 20, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Added External Credential Principal access'
        },
        {
            name: 'MT_Voice_Assistant_Admin',
            type: 'Permission Set',
            icon: 'utility:settings',
            description: 'Grants admin access to configuration settings. Required to access this Settings page.',
            created: 'Nov 20, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Auto-assigned to System Administrators'
        }
    ];
    
    // Account-Based Flow Components
    accountFlowComponents = [
        {
            name: 'MT_Visit_Report',
            type: 'Flow',
            icon: 'utility:flow',
            description: 'Main screen flow for Account-based voice transcription. Captures audio, transcribes, and generates record suggestions linked to the Account.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Dynamic configuration profile support'
        },
        {
            name: 'MT_Voice_Record_Suggestion',
            type: 'Prompt Template',
            icon: 'utility:einstein',
            description: 'AI prompt template that analyzes transcripts and generates record suggestions. Uses Account context to match existing Contacts and Opportunities.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Enhanced matching logic, HTML-formatted reasoning'
        }
    ];
    
    // Standalone Flow Components
    standaloneFlowComponents = [
        {
            name: 'MT_Visit_Report_Standalone',
            type: 'Flow',
            icon: 'utility:flow',
            description: 'Multi-modal AI flow with voice + image input. Analyzes transcripts AND images (business cards, notes, whiteboards) to create records.',
            created: 'Dec 5, 2025',
            updated: 'Dec 5, 2025',
            changes: 'Full multi-modal: uploads image to ContentDocument for AI analysis'
        },
        {
            name: 'MT_Voice_Record_Suggestion_Standalone',
            type: 'Prompt Template',
            icon: 'utility:einstein',
            description: 'Multi-modal AI prompt with File Input support. GPT-4 Omni analyzes both transcript text and uploaded images.',
            created: 'Dec 5, 2025',
            updated: 'Dec 5, 2025',
            changes: 'Added ContentDocument File Input for true image analysis'
        },
        {
            name: 'mt_ImageFileService',
            type: 'Apex Class',
            icon: 'utility:apex',
            description: 'Converts base64 images to ContentDocument records for Prompt Builder File Inputs. Supports JPG, PNG, GIF, WebP.',
            created: 'Dec 5, 2025',
            updated: 'Dec 5, 2025',
            changes: 'Initial release'
        }
    ];
    
    // Shared LWC Components
    lwcComponents = [
        {
            name: 'mtEinsteinTranscribe',
            type: 'LWC',
            icon: 'utility:mic',
            description: 'Voice recording and transcription component with optional image input. Supports Einstein Transcribe and OpenAI Whisper.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Added image input feature with presets (business card, notes, attendees)'
        },
        {
            name: 'mtRecordSuggestion',
            type: 'LWC',
            icon: 'utility:record_create',
            description: 'Displays AI-generated record suggestions with edit capability. Handles record creation and updates via DML.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Rich text reasoning display, relationship field handling'
        },
        {
            name: 'mtVoiceAssistantAdmin',
            type: 'LWC',
            icon: 'utility:settings',
            description: 'This admin settings page. Manages configuration profiles, object settings, and provides setup guidance.',
            created: 'Nov 20, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Added Components tab, standalone flow docs, auto-refresh'
        }
    ];
    
    // Apex Classes
    apexComponents = [
        {
            name: 'mt_TranscribeController',
            type: 'Apex Class',
            icon: 'utility:apex',
            description: 'Main controller for transcription operations. Handles API authentication, transcription calls, and admin data retrieval.',
            created: 'Nov 17, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Removed cacheable=true for config methods (auto-refresh fix)'
        },
        {
            name: 'mt_RecordService',
            type: 'Apex Class',
            icon: 'utility:apex',
            description: 'Handles record creation and updates. Performs DML operations for AI-suggested records.',
            created: 'Nov 17, 2024',
            updated: 'Dec 3, 2025',
            changes: 'Improved error handling for relationship fields'
        },
        {
            name: 'mt_ObjectMetadataService',
            type: 'Apex Class',
            icon: 'utility:apex',
            description: 'Provides object and field metadata. Used for dynamic field discovery and validation.',
            created: 'Nov 17, 2024',
            updated: 'Dec 3, 2025',
            changes: null
        },
        {
            name: 'mt_ConfigMetadataService',
            type: 'Apex Class',
            icon: 'utility:apex',
            description: 'Manages Custom Metadata deployment. Creates and updates configuration profiles via Metadata API.',
            created: 'Nov 25, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Added object configuration deployment'
        },
        {
            name: 'mt_GetObjectConfigForPrompt',
            type: 'Apex Invocable',
            icon: 'utility:apex',
            description: 'Flow-invocable action that retrieves object configuration and formats it for the AI prompt template.',
            created: 'Nov 25, 2024',
            updated: 'Dec 5, 2025',
            changes: 'Added Event to default objects'
        }
    ];
    
    // Configuration & Metadata Components
    metadataComponents = [
        {
            name: 'MT_VoiceAssistantConfig__mdt',
            type: 'Custom Metadata',
            icon: 'utility:database',
            description: 'Stores configuration profiles with provider settings, prompt template references, and Named Credential configurations.',
            created: 'Nov 20, 2024',
            updated: 'Dec 3, 2025',
            changes: 'Added PromptTemplateName field'
        },
        {
            name: 'MT_VoiceAssistantObjectConfig__mdt',
            type: 'Custom Metadata',
            icon: 'utility:database',
            description: 'Stores object-level configuration including allowed fields, mandatory fields, and create/edit permissions.',
            created: 'Nov 25, 2024',
            updated: 'Dec 3, 2025',
            changes: null
        },
        {
            name: 'MT_VoiceAssistantSecrets__c',
            type: 'Custom Setting',
            icon: 'utility:lock',
            description: 'Hierarchy custom setting for storing API keys (OpenAI). Provides secure, user-level key storage.',
            created: 'Nov 20, 2024',
            updated: 'Nov 20, 2024',
            changes: null
        },
        {
            name: 'EinsteinTranscribeSettings__mdt',
            type: 'Custom Metadata',
            icon: 'utility:database',
            description: 'Stores Einstein Transcribe API settings including base URL and default configurations.',
            created: 'Nov 17, 2024',
            updated: 'Nov 17, 2024',
            changes: null
        }
    ];

    // ==========================================================================
    // COMPUTED PROPERTIES
    // ==========================================================================
    
    get hasConfigs() {
        return this.configs && this.configs.length > 0;
    }
    
    get modalTitle() {
        return this.isEditMode ? 'Edit Configuration' : 'New Configuration';
    }
    
    get apiKeySaveMessageClass() {
        return this.apiKeySaveSuccess 
            ? 'slds-text-color_success slds-m-left_small inline-message' 
            : 'slds-text-color_error slds-m-left_small inline-message';
    }
    
    get apiKeySaveIcon() {
        return this.apiKeySaveSuccess ? 'utility:success' : 'utility:error';
    }
    
    get einsteinTestResultClass() {
        return this.einsteinTestSuccess 
            ? 'slds-text-color_success slds-m-top_small inline-message' 
            : 'slds-text-color_error slds-m-top_small inline-message';
    }
    
    get einsteinTestIcon() {
        return this.einsteinTestSuccess ? 'utility:success' : 'utility:error';
    }
    
    get whisperTestResultClass() {
        return this.whisperTestSuccess 
            ? 'slds-text-color_success slds-m-top_small inline-message' 
            : 'slds-text-color_error slds-m-top_small inline-message';
    }
    
    get whisperTestIcon() {
        return this.whisperTestSuccess ? 'utility:success' : 'utility:error';
    }
    
    // Object Settings Computed Properties
    get hasObjectConfigs() {
        return this.objectConfigs && this.objectConfigs.length > 0;
    }
    
    get configProfileOptions() {
        return this.configs.map(config => ({
            label: config.label || config.configName,
            value: config.configName
        }));
    }
    
    get objectModalTitle() {
        return this.isObjectEditMode ? 'Edit Object Configuration' : 'Add Object Configuration';
    }
    
    get availableObjectOptions() {
        return this.availableObjects.map(obj => ({
            label: obj.label,
            value: obj.value
        }));
    }
    
    get availableFieldOptions() {
        return this.availableFields.map(field => ({
            label: field.label + (field.isRequired ? ' *' : ''),
            value: field.value
        }));
    }
    
    get allowedFieldOptionsForMandatory() {
        // Only show fields that are already in allowedFields
        const allowed = new Set(this.objectFormData.allowedFields || []);
        return this.availableFields
            .filter(field => allowed.has(field.value))
            .map(field => ({
                label: field.label,
                value: field.value
            }));
    }
    
    /**
     * @description Combined configs with their object configurations for accordion display
     */
    get configsWithObjects() {
        return this.configs.map(config => {
            const objects = this.allObjectConfigs[config.configName] || [];
            return {
                ...config,
                accordionLabel: `${config.label || config.configName}`,
                objects: objects.map(obj => ({
                    ...obj,
                    objectIcon: this._getObjectIcon(obj.objectApiName),
                    objectLabel: obj.objectApiName,
                    allowedFieldsDisplay: obj.allowedFields ? obj.allowedFields.join(', ') : '—',
                    mandatoryFieldsDisplay: obj.mandatoryFields ? obj.mandatoryFields.join(', ') : '—'
                })),
                hasObjects: objects.length > 0,
                objectCount: objects.length
            };
        });
    }

    // ==========================================================================
    // LIFECYCLE HOOKS
    // ==========================================================================
    
    async connectedCallback() {
        await this.checkAccess();
    }
    
    // ==========================================================================
    // DATA LOADING METHODS
    // ==========================================================================
    
    /**
     * @description Check if current user has admin access
     */
    async checkAccess() {
        this.isLoading = true;
        try {
            const hasAccess = await isAdminUser();
            if (hasAccess) {
                this.isAccessDenied = false;
                await this.loadData();
            } else {
                this.isAccessDenied = true;
            }
        } catch (error) {
            console.error('Error checking admin access:', error);
            this.isAccessDenied = true;
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * @description Load all admin data
     */
    async loadData() {
        try {
            // Load org domain URL
            this.orgDomainUrl = await getOrgDomainUrl();
            
            // Load setup navigation URLs (direct links to setup components)
            try {
                const urls = await getSetupUrls();
                if (urls && urls.success) {
                    this.setupUrls = {
                        namedCredentialUrl: urls.namedCredentialUrl || '/lightning/setup/NamedCredential/home',
                        externalCredentialUrl: urls.externalCredentialUrl || '/lightning/setup/NamedCredential/home',
                        connectedAppUrl: urls.connectedAppUrl || '/lightning/setup/ConnectedApplication/home',
                        permissionSetUrl: urls.permissionSetUrl || '/lightning/setup/PermSets/home',
                        permissionSets: urls.permissionSets || []
                    };
                    // Check if Named Credential URL needs to be updated
                    this.namedCredentialNeedsUpdate = urls.namedCredentialNeedsUpdate === true;
                    // If URL is already correct, mark as updated
                    if (!this.namedCredentialNeedsUpdate) {
                        this.namedCredentialUpdated = true;
                    }
                }
            } catch (urlError) {
                console.warn('Could not load setup URLs, using defaults:', urlError);
            }
            
            // Check permission set status for current user
            await this.loadPermissionSetStatus();
            
            // Load configuration profiles
            const configResults = await getAllConfigs();
            this.configs = configResults.map(config => ({
                ...config,
                providerIcon: config.provider === 'Einstein' ? 'utility:einstein' : 'utility:voice',
                promptTemplateDisplay: config.promptTemplateName || '—',
                descriptionDisplay: config.description || '—'
            }));
            
            // Set default profile if we have configs
            if (this.configs.length > 0 && !this.selectedObjectConfigProfile) {
                this.selectedObjectConfigProfile = this.configs[0].configName;
            }
            
            // Set default accordion sections to expand the first config
            if (this.configs.length > 0) {
                this.activeAccordionSections = [this.configs[0].configName];
            }
            
            // Load object configs for ALL profiles (for accordion view)
            await this.loadAllObjectConfigs();
            
            // Also load for selected profile (backwards compatibility)
            await this.loadObjectConfigs();
            
            // Load available objects
            this.availableObjects = await getAvailableObjects();
            
            // Load available prompt templates
            await this.loadPromptTemplates();
            
        } catch (error) {
            console.error('Error loading admin data:', error);
            this.showToast('Error', 'Failed to load settings data: ' + (error.body?.message || error.message), 'error');
        }
    }
    
    /**
     * @description Load object configurations for the selected profile
     */
    async loadObjectConfigs() {
        try {
            const results = await getObjectConfigs({ configName: this.selectedObjectConfigProfile });
            this.objectConfigs = results.map(config => ({
                ...config,
                objectIcon: this._getObjectIcon(config.objectApiName),
                objectLabel: config.objectApiName, // Will be updated with proper label
                allowedFieldsDisplay: config.allowedFields ? config.allowedFields.join(', ') : '—',
                mandatoryFieldsDisplay: config.mandatoryFields ? config.mandatoryFields.join(', ') : '—'
            }));
        } catch (error) {
            console.error('Error loading object configs:', error);
        }
    }
    
    /**
     * @description Load object configurations for ALL profiles (for accordion view)
     */
    async loadAllObjectConfigs() {
        try {
            const allConfigs = {};
            // Load object configs for each profile in parallel
            const promises = this.configs.map(async (config) => {
                const results = await getObjectConfigs({ configName: config.configName });
                allConfigs[config.configName] = results;
            });
            await Promise.all(promises);
            this.allObjectConfigs = allConfigs;
        } catch (error) {
            console.error('Error loading all object configs:', error);
        }
    }
    
    /**
     * @description Load available prompt templates
     */
    async loadPromptTemplates() {
        try {
            const templates = await getAvailablePromptTemplates();
            this.promptTemplateOptions = templates.map(t => ({
                label: t.label || t.name,
                value: t.name
            }));
        } catch (error) {
            console.warn('Could not load prompt templates:', error);
            // Default option if loading fails
            this.promptTemplateOptions = [
                { label: 'MT_Voice_Record_Suggestion', value: 'MT_Voice_Record_Suggestion' }
            ];
        }
    }
    
    /**
     * @description Get icon name for an object
     */
    _getObjectIcon(objectApiName) {
        const iconMap = {
            'Account': 'standard:account',
            'Contact': 'standard:contact',
            'Opportunity': 'standard:opportunity',
            'Lead': 'standard:lead',
            'Case': 'standard:case',
            'Task': 'standard:task',
            'Event': 'standard:event',
            'Campaign': 'standard:campaign',
            'Contract': 'standard:contract',
            'Order': 'standard:orders',
            'Product2': 'standard:product',
            'Quote': 'standard:quotes'
        };
        return iconMap[objectApiName] || 'standard:record';
    }

    // ==========================================================================
    // CONFIGURATION MODAL HANDLERS
    // ==========================================================================
    
    /**
     * @description Open modal for new configuration
     */
    handleNewConfig() {
        this.isEditMode = false;
        // Reset clone instructions state
        this.showCloneInstructions = false;
        
        this.formData = {
            label: '',
            developerName: '',
            provider: 'Einstein',
            promptTemplateName: 'MT_Voice_Record_Suggestion',
            einsteinNamedCredential: 'mt_EinsteinTranscribe',
            whisperNamedCredential: 'mt_OpenAI_Whisper',
            whisperModel: 'whisper-1',
            isActive: true,
            enableImageInput: true,
            description: ''
        };
        this.isModalOpen = true;
    }
    
    /**
     * @description Open modal for editing existing configuration
     */
    handleEditConfig(event) {
        const configName = event.currentTarget.dataset.configName;
        const config = this.configs.find(c => c.configName === configName);
        
        if (config) {
            this.isEditMode = true;
            this.formData = {
                label: config.label || config.configName,
                developerName: config.configName,
                provider: config.provider || 'Einstein',
                promptTemplateName: config.promptTemplateName || '',
                einsteinNamedCredential: config.einsteinNamedCredential || 'mt_EinsteinTranscribe',
                whisperNamedCredential: config.whisperNamedCredential || 'mt_OpenAI_Whisper',
                whisperModel: config.whisperModel || 'whisper-1',
                isActive: config.isActive !== false,
                enableImageInput: config.enableImageInput === true,
                description: config.description || ''
            };
            this.isModalOpen = true;
        }
    }
    
    /**
     * @description Close the modal
     */
    handleCloseModal() {
        this.isModalOpen = false;
        this.isSaving = false;
    }
    
    /**
     * @description Handle form field changes
     */
    handleFormChange(event) {
        const field = event.currentTarget.dataset.field;
        let value;
        
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = event.detail?.value ?? event.target.value;
        }
        
        this.formData = { ...this.formData, [field]: value };
        
        // Auto-generate developer name from label for new configs
        if (field === 'label' && !this.isEditMode) {
            const devName = value
                .replace(/[^a-zA-Z0-9\s]/g, '')
                .replace(/\s+/g, '_')
                .replace(/^[0-9]/, 'Config_$&');
            this.formData = { ...this.formData, developerName: devName };
        }
    }
    
    /**
     * @description Toggle clone instructions visibility
     */
    handleToggleCloneInstructions() {
        this.showCloneInstructions = !this.showCloneInstructions;
    }
    
    /**
     * @description Get label for clone instructions toggle button
     */
    get cloneInstructionsButtonLabel() {
        return this.showCloneInstructions ? 'Hide Instructions' : 'Show Instructions';
    }
    
    /**
     * @description Save configuration via Metadata API
     */
    async handleSaveConfig() {
        // Validate required fields
        if (!this.formData.label || !this.formData.developerName || !this.formData.provider) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }
        
        // Validate developer name format
        if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(this.formData.developerName)) {
            this.showToast('Error', 'API Name must start with a letter and contain only letters, numbers, and underscores', 'error');
            return;
        }
        
        this.isSaving = true;
        this.savingMessage = 'Deploying configuration...';
        
        try {
            // Call Apex to deploy the configuration
            await saveConfiguration({ 
                configData: JSON.stringify(this.formData) 
            });
            
            // Wait a few seconds for the async deployment to complete
            this.savingMessage = 'Waiting for deployment to complete...';
            await this.delay(4000);
            
            this.showToast('Success', 'Configuration saved successfully! Refreshing...', 'success');
            this.isModalOpen = false;
            this.isSaving = false;
            
            // Reload configurations
            await this.loadData();
            
        } catch (error) {
            console.error('Error saving configuration:', error);
            this.showToast('Error', 'Failed to save configuration: ' + (error.body?.message || error.message), 'error');
            this.isSaving = false;
        }
    }
    
    /**
     * @description Helper to delay execution
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // ==========================================================================
    // EVENT HANDLERS
    // ==========================================================================
    
    /**
     * @description Refresh all data
     */
    async handleRefresh() {
        this.isLoading = true;
        // Clear previous test results
        this.einsteinTestResult = '';
        this.whisperTestResult = '';
        this.apiKeySaveMessage = '';
        
        await this.loadData();
        this.isLoading = false;
        this.showToast('Success', 'Settings refreshed', 'success');
    }
    
    /**
     * @description Copy org URL to clipboard
     */
    handleCopyUrl() {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(this.orgDomainUrl)
                .then(() => {
                    this.showToast('Success', 'URL copied to clipboard', 'success');
                })
                .catch(err => {
                    console.error('Failed to copy:', err);
                    this.showToast('Error', 'Failed to copy URL', 'error');
                });
        }
    }
    
    /**
     * @description Copy arbitrary text to clipboard (from data attribute)
     */
    handleCopyText(event) {
        const textToCopy = event.currentTarget.dataset.copyValue;
        if (navigator.clipboard && textToCopy) {
            navigator.clipboard.writeText(textToCopy)
                .then(() => {
                    this.showToast('Copied', `"${textToCopy}" copied to clipboard`, 'success');
                })
                .catch(err => {
                    console.error('Failed to copy:', err);
                    this.showToast('Error', 'Failed to copy text', 'error');
                });
        }
    }
    
    /**
     * @description Get contextual error tip based on connection error message
     */
    get connectionErrorTip() {
        if (!this.connectionTestResult || this.connectionTestResult.success) {
            return null;
        }
        
        const error = (this.connectionTestResult.error || '').toLowerCase();
        
        if (error.includes('no client credentials') || error.includes('client_credentials')) {
            return 'Go back to <b>Step 2</b> and make sure you clicked <b>Save</b> after setting the Run As user.';
        }
        if (error.includes('invalid_client') || error.includes('invalid client')) {
            return 'Check that <b>client_id</b> and <b>client_secret</b> values are correct in the External Credential (Step 4).';
        }
        if (error.includes('named credential') || error.includes('callout')) {
            return 'Verify the Named Credential URL matches your org domain (Step 3).';
        }
        if (error.includes('unauthorized') || error.includes('401')) {
            return 'Authentication failed. Re-check your Consumer Key/Secret and Run As user settings.';
        }
        if (error.includes('timeout') || error.includes('timed out')) {
            return 'The request timed out. Try again or check your network connection.';
        }
        
        // Generic fallback
        return 'Review the setup steps above to ensure all configurations are complete.';
    }
    
    /**
     * @description Handle API key input change
     */
    handleApiKeyChange(event) {
        this.openAIApiKey = event.target.value;
        this.apiKeySaveMessage = ''; // Clear previous message
    }
    
    /**
     * @description Save OpenAI API key to Custom Settings
     */
    async handleSaveApiKey() {
        if (!this.openAIApiKey || this.openAIApiKey.trim() === '') {
            this.apiKeySaveSuccess = false;
            this.apiKeySaveMessage = 'Please enter an API key';
            return;
        }
        
        this.isSavingApiKey = true;
        this.apiKeySaveMessage = '';
        
        try {
            const success = await saveOpenAIApiKey({ apiKey: this.openAIApiKey });
            if (success) {
                this.apiKeySaveSuccess = true;
                this.apiKeySaveMessage = 'API key saved successfully';
                this.openAIApiKey = ''; // Clear the field for security
            } else {
                this.apiKeySaveSuccess = false;
                this.apiKeySaveMessage = 'Failed to save API key';
            }
        } catch (error) {
            console.error('Error saving API key:', error);
            this.apiKeySaveSuccess = false;
            this.apiKeySaveMessage = 'Error: ' + (error.body?.message || error.message);
        } finally {
            this.isSavingApiKey = false;
        }
    }
    
    /**
     * @description Test Einstein API connection
     */
    async handleTestEinstein() {
        this.isTestingEinstein = true;
        this.einsteinTestResult = '';
        
        try {
            const result = await testEinsteinConnection();
            this.einsteinTestSuccess = result.success;
            this.einsteinTestResult = result.message;
        } catch (error) {
            console.error('Error testing Einstein connection:', error);
            this.einsteinTestSuccess = false;
            this.einsteinTestResult = 'Error: ' + (error.body?.message || error.message);
        } finally {
            this.isTestingEinstein = false;
        }
    }
    
    /**
     * @description Test Whisper API connection
     */
    async handleTestWhisper() {
        this.isTestingWhisper = true;
        this.whisperTestResult = '';
        
        try {
            const result = await testWhisperConnection();
            this.whisperTestSuccess = result.success;
            this.whisperTestResult = result.message;
        } catch (error) {
            console.error('Error testing Whisper connection:', error);
            this.whisperTestSuccess = false;
            this.whisperTestResult = 'Error: ' + (error.body?.message || error.message);
        } finally {
            this.isTestingWhisper = false;
        }
    }

    // ==========================================================================
    // OBJECT CONFIGURATION HANDLERS
    // ==========================================================================
    
    /**
     * @description Handle profile selection change for object configs
     */
    async handleObjectConfigProfileChange(event) {
        this.selectedObjectConfigProfile = event.detail.value;
        await this.loadObjectConfigs();
    }
    
    /**
     * @description Open modal for new object configuration
     */
    async handleNewObjectConfig() {
        this.isObjectEditMode = false;
        this.objectFormData = {
            objectApiName: '',
            allowedFields: [],
            mandatoryFields: [],
            allowCreate: true,
            allowEdit: true
        };
        this.availableFields = [];
        this.isObjectModalOpen = true;
    }
    
    /**
     * @description Open modal for editing existing object configuration
     */
    async handleEditObjectConfig(event) {
        const objectApiName = event.currentTarget.dataset.objectName;
        const config = this.objectConfigs.find(c => c.objectApiName === objectApiName);
        
        if (config) {
            this.isObjectEditMode = true;
            this.objectFormData = {
                objectApiName: config.objectApiName,
                allowedFields: config.allowedFields || [],
                mandatoryFields: config.mandatoryFields || [],
                allowCreate: config.allowCreate !== false,
                allowEdit: config.allowEdit !== false
            };
            
            // Load fields for this object
            await this.loadFieldsForObject(config.objectApiName);
            
            this.isObjectModalOpen = true;
        }
    }
    
    /**
     * @description Open modal for new object configuration for a specific profile (from accordion)
     */
    async handleNewObjectConfigForProfile(event) {
        const configName = event.currentTarget.dataset.configName;
        // Set the selected profile to the one clicked
        this.selectedObjectConfigProfile = configName;
        
        this.isObjectEditMode = false;
        this.objectFormData = {
            objectApiName: '',
            allowedFields: [],
            mandatoryFields: [],
            allowCreate: true,
            allowEdit: true
        };
        this.availableFields = [];
        this.isObjectModalOpen = true;
    }
    
    /**
     * @description Open modal for editing object config in accordion context
     */
    async handleEditObjectConfigInAccordion(event) {
        const configName = event.currentTarget.dataset.configName;
        const objectApiName = event.currentTarget.dataset.objectName;
        
        // Set the selected profile
        this.selectedObjectConfigProfile = configName;
        
        // Get the object configs for this profile
        const profileObjects = this.allObjectConfigs[configName] || [];
        const config = profileObjects.find(c => c.objectApiName === objectApiName);
        
        if (config) {
            this.isObjectEditMode = true;
            this.objectFormData = {
                objectApiName: config.objectApiName,
                allowedFields: config.allowedFields || [],
                mandatoryFields: config.mandatoryFields || [],
                allowCreate: config.allowCreate !== false,
                allowEdit: config.allowEdit !== false
            };
            
            // Load fields for this object
            await this.loadFieldsForObject(config.objectApiName);
            
            this.isObjectModalOpen = true;
        }
    }
    
    /**
     * @description Preview prompt data for a configuration profile
     */
    async handlePreviewPromptData(event) {
        const configName = event.currentTarget.dataset.configName;
        this.previewConfigName = configName;
        this.isLoadingPreview = true;
        this.isPreviewModalOpen = true;
        
        try {
            const result = await getConfig({ configName: configName });
            if (result && result.allowedObjectsConfig) {
                this.previewContent = result.allowedObjectsConfig;
            } else {
                this.previewContent = 'No configuration data available for this profile.';
            }
        } catch (error) {
            console.error('Error loading preview:', error);
            this.previewContent = 'Error loading preview: ' + (error.body?.message || error.message);
        } finally {
            this.isLoadingPreview = false;
        }
    }
    
    /**
     * @description Close the preview modal
     */
    handleClosePreviewModal() {
        this.isPreviewModalOpen = false;
        this.previewContent = '';
        this.previewConfigName = '';
    }
    
    /**
     * @description Copy preview content to clipboard
     */
    handleCopyPreviewContent() {
        navigator.clipboard.writeText(this.previewContent).then(() => {
            this.showToast('Success', 'Copied to clipboard', 'success');
        }).catch(err => {
            console.error('Failed to copy:', err);
            this.showToast('Error', 'Failed to copy to clipboard', 'error');
        });
    }
    
    /**
     * @description Close the object modal
     */
    handleCloseObjectModal() {
        this.isObjectModalOpen = false;
        this.isSavingObjectConfig = false;
    }
    
    /**
     * @description Handle form field changes for object config
     */
    async handleObjectFormChange(event) {
        const field = event.currentTarget.dataset.field;
        let value;
        
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = event.detail?.value ?? event.target.value;
        }
        
        this.objectFormData = { ...this.objectFormData, [field]: value };
        
        // If object changed, load its fields
        if (field === 'objectApiName' && value) {
            await this.loadFieldsForObject(value);
        }
    }
    
    /**
     * @description Handle allowed fields change
     */
    handleAllowedFieldsChange(event) {
        this.objectFormData = { 
            ...this.objectFormData, 
            allowedFields: event.detail.value 
        };
        
        // Filter mandatory fields to only include allowed fields
        const allowedSet = new Set(event.detail.value);
        const filteredMandatory = (this.objectFormData.mandatoryFields || [])
            .filter(f => allowedSet.has(f));
        
        this.objectFormData = { 
            ...this.objectFormData, 
            mandatoryFields: filteredMandatory 
        };
    }
    
    /**
     * @description Handle mandatory fields change
     */
    handleMandatoryFieldsChange(event) {
        this.objectFormData = { 
            ...this.objectFormData, 
            mandatoryFields: event.detail.value 
        };
    }
    
    /**
     * @description Load fields for a specific object
     */
    async loadFieldsForObject(objectApiName) {
        try {
            // Load fields
            const result = await getObjectDescribe({ objectApiName });
            if (result.success) {
                this.availableFields = result.fields || [];
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
            
            // Load layout options
            const layoutResult = await getObjectLayouts({ objectApiName });
            if (layoutResult.success) {
                this.layoutOptions = layoutResult.layoutOptions || [];
            }
            
            // Reset selected layout
            this.selectedLayoutOption = '';
            
        } catch (error) {
            console.error('Error loading fields:', error);
            this.showToast('Error', 'Failed to load fields: ' + (error.body?.message || error.message), 'error');
        }
    }
    
    /**
     * @description Handle layout option selection change
     */
    handleLayoutOptionChange(event) {
        this.selectedLayoutOption = event.detail.value;
    }
    
    /**
     * @description Import fields from selected layout option
     */
    async handleImportFromLayout() {
        if (!this.selectedLayoutOption) {
            this.showToast('Info', 'Please select a field set option first', 'info');
            return;
        }
        
        if (!this.objectFormData.objectApiName) {
            this.showToast('Error', 'Please select an object first', 'error');
            return;
        }
        
        this.isLoadingLayoutFields = true;
        
        try {
            const result = await getFieldsForLayout({ 
                objectApiName: this.objectFormData.objectApiName,
                layoutOption: this.selectedLayoutOption
            });
            
            if (result.success) {
                const fields = result.fields || [];
                const requiredFields = result.requiredFields || [];
                
                // Update allowed fields
                this.objectFormData = {
                    ...this.objectFormData,
                    allowedFields: fields,
                    mandatoryFields: requiredFields
                };
                
                this.showToast('Success', `Imported ${fields.length} fields (${requiredFields.length} required)`, 'success');
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            console.error('Error importing fields:', error);
            this.showToast('Error', 'Failed to import fields: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoadingLayoutFields = false;
        }
    }
    
    /**
     * @description Import required fields to mandatory fields list
     */
    async handleImportRequiredFields() {
        if (!this.objectFormData.objectApiName) {
            this.showToast('Error', 'Please select an object first', 'error');
            return;
        }
        
        this.isLoadingFieldInfo = true;
        
        try {
            const result = await getFieldsForLayout({ 
                objectApiName: this.objectFormData.objectApiName,
                layoutOption: 'REQUIRED_ONLY'
            });
            
            if (result.success) {
                const requiredFields = result.requiredFields || [];
                
                // Get current allowed fields
                const currentAllowed = this.objectFormData.allowedFields || [];
                const currentMandatory = this.objectFormData.mandatoryFields || [];
                
                // Filter required fields to only those in allowed list
                const newMandatory = requiredFields.filter(f => currentAllowed.includes(f));
                
                // Merge with existing mandatory (avoid duplicates)
                const mergedMandatory = [...new Set([...currentMandatory, ...newMandatory])];
                
                // Also add required fields to allowed if not already there
                const mergedAllowed = [...new Set([...currentAllowed, ...requiredFields])];
                
                this.objectFormData = {
                    ...this.objectFormData,
                    allowedFields: mergedAllowed,
                    mandatoryFields: mergedMandatory
                };
                
                const addedCount = mergedMandatory.length - currentMandatory.length;
                this.showToast('Success', `Added ${addedCount} required field(s) to mandatory list`, 'success');
            } else {
                this.showToast('Error', result.errorMessage || 'Failed to get required fields', 'error');
            }
        } catch (error) {
            console.error('Error importing required fields:', error);
            this.showToast('Error', 'Failed to import required fields: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoadingFieldInfo = false;
        }
    }
    
    /**
     * @description Save object configuration
     */
    async handleSaveObjectConfig() {
        // Validate
        if (!this.objectFormData.objectApiName) {
            this.showToast('Error', 'Please select an object', 'error');
            return;
        }
        if (!this.objectFormData.allowedFields || this.objectFormData.allowedFields.length === 0) {
            this.showToast('Error', 'Please select at least one allowed field', 'error');
            return;
        }
        
        this.isSavingObjectConfig = true;
        
        try {
            const configData = {
                configProfile: this.selectedObjectConfigProfile,
                objectApiName: this.objectFormData.objectApiName,
                allowedFields: this.objectFormData.allowedFields,
                mandatoryFields: this.objectFormData.mandatoryFields,
                allowCreate: this.objectFormData.allowCreate,
                allowEdit: this.objectFormData.allowEdit
            };
            
            await saveObjectConfiguration({ objectConfigData: JSON.stringify(configData) });
            
            // Wait for deployment
            await this.delay(4000);
            
            this.showToast('Success', 'Object configuration saved! Refreshing...', 'success');
            this.isObjectModalOpen = false;
            this.isSavingObjectConfig = false;
            
            // Reload both single profile and all object configs (for accordion)
            await this.loadObjectConfigs();
            await this.loadAllObjectConfigs();
            
        } catch (error) {
            console.error('Error saving object config:', error);
            this.showToast('Error', 'Failed to save: ' + (error.body?.message || error.message), 'error');
            this.isSavingObjectConfig = false;
        }
    }

    // ==========================================================================
    // NAVIGATION HANDLERS (All open in new tab)
    // ==========================================================================
    
    /**
     * @description Navigate to Connected App VIEW page (Step 2 - Get Consumer Credentials)
     * Opens in new tab
     */
    handleNavigateConnectedApp() {
        const url = this.setupUrls?.connectedAppViewUrl || this.setupUrls?.connectedAppUrl || '/lightning/setup/ConnectedApplication/home';
        window.open(url, '_blank');
    }
    
    /**
     * @description Navigate to Connected App MANAGE/EDIT page (Step 3 - Client Credentials Flow)
     * Opens in new tab
     */
    handleNavigateConnectedAppManage() {
        const url = this.setupUrls?.connectedAppManageUrl || this.setupUrls?.connectedAppUrl || '/lightning/setup/ConnectedApplication/home';
        window.open(url, '_blank');
    }
    
    /**
     * @description Navigate directly to External Credential (Step 5)
     * Opens in new tab
     */
    handleNavigateExternalCredential() {
        const url = this.setupUrls?.externalCredentialUrl || '/lightning/setup/NamedCredential/home';
        window.open(url, '_blank');
    }
    
    /**
     * @description Navigate directly to Named Credential (Step 4)
     * Opens in new tab
     */
    handleNavigateNamedCredential() {
        const url = this.setupUrls?.namedCredentialUrl || '/lightning/setup/NamedCredential/home';
        window.open(url, '_blank');
    }
    
    /**
     * @description Navigate directly to Permission Set
     * Opens in new tab
     */
    handleNavigatePermissionSet() {
        const url = this.setupUrls?.permissionSetUrl || '/lightning/setup/PermSets/home';
        window.open(url, '_blank');
    }
    
    /**
     * @description Navigate to Lightning Experience App Manager
     * Opens in new tab
     */
    handleNavigateAppManager() {
        window.open('/lightning/setup/NavigationMenus/home', '_blank');
    }
    
    /**
     * @description Navigate to the Configurations tab
     */
    handleGoToConfigurations() {
        this.activeTabValue = 'configurations';
    }
    
    /**
     * @description Check Named Credential URL and open setup if manual update needed (Step 4)
     */
    async handleAutoUpdateNamedCredential() {
        this.isUpdatingNamedCredential = true;
        
        try {
            const result = await updateNamedCredentialUrl();
            
            if (result.success && result.alreadyCorrect) {
                this.namedCredentialUpdated = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Named Credential URL is already correct!',
                        variant: 'success'
                    })
                );
            } else if (result.requiresManualUpdate) {
                // Open Named Credential in new tab for manual update
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Manual Update Required',
                        message: 'Opening Named Credential setup. Please update the URL to: ' + result.requiredUrl,
                        variant: 'warning',
                        mode: 'sticky'
                    })
                );
                // Open the Named Credential page
                window.open(this.setupUrls?.namedCredentialUrl || '/lightning/setup/NamedCredential/home', '_blank');
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Info',
                        message: result.message || 'Please check the Named Credential configuration',
                        variant: 'info'
                    })
                );
            }
        } catch (error) {
            console.error('Error checking Named Credential:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || error.message || 'Failed to check Named Credential',
                    variant: 'error'
                })
            );
        } finally {
            this.isUpdatingNamedCredential = false;
        }
    }
    
    /**
     * @description Test Einstein connection inline (Step 6 in Setup Checklist)
     */
    async handleTestConnectionInline() {
        this.isTestingConnection = true;
        this.connectionTestResult = null;
        
        try {
            const result = await testEinsteinConnection();
            this.connectionTestResult = {
                success: result.success,
                error: result.success ? null : result.message
            };
        } catch (error) {
            console.error('Error testing connection:', error);
            this.connectionTestResult = {
                success: false,
                error: error.body?.message || error.message || 'Connection test failed'
            };
        } finally {
            this.isTestingConnection = false;
        }
    }

    // ==========================================================================
    // AUTOMATED SETUP METHODS
    // ==========================================================================
    
    /**
     * @description Load permission set status for current user
     */
    async loadPermissionSetStatus() {
        try {
            const result = await checkPermissionSetStatus();
            if (result && result.success) {
                const permSets = result.permissionSets || {};
                this.permSetStatus = {
                    userAssigned: permSets['mt_Einstein_Transcribe'] || false,
                    adminAssigned: permSets['mt_VoiceAssistant_Admin'] || false,
                    allAssigned: result.allAssigned || false
                };
            }
        } catch (error) {
            console.warn('Could not check permission set status:', error);
        }
    }
    
    /**
     * @description Automatically assign permission sets to current user
     */
    async handleAssignPermissionSets() {
        this.isAssigningPermSets = true;
        try {
            const result = await assignPermissionSetsToCurrentUser();
            if (result && result.success) {
                this.showToast('Success', result.message, 'success');
                // Reload permission set status
                await this.loadPermissionSetStatus();
            } else {
                this.showToast('Error', result.message || 'Failed to assign permission sets', 'error');
            }
        } catch (error) {
            console.error('Error assigning permission sets:', error);
            this.showToast('Error', 'Failed to assign permission sets: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isAssigningPermSets = false;
        }
    }
    
    /**
     * @description Getter for permission set button label
     */
    get permSetButtonLabel() {
        if (this.isAssigningPermSets) {
            return 'Assigning...';
        }
        if (this.permSetStatus.allAssigned) {
            return '✓ Already Assigned';
        }
        return 'Auto-Assign to System Admins';
    }
    
    /**
     * @description Getter for permission set button variant
     */
    get permSetButtonVariant() {
        return this.permSetStatus.allAssigned ? 'success' : 'brand';
    }
    
    /**
     * @description Getter for permission set button disabled state
     */
    get permSetButtonDisabled() {
        return this.isAssigningPermSets || this.permSetStatus.allAssigned;
    }

    /**
     * @description Getter to check if Named Credential URL is already correct
     */
    get namedCredentialUrlCorrect() {
        return this.namedCredentialUpdated || !this.namedCredentialNeedsUpdate;
    }

    /**
     * @description Getter to determine if Named Credential step should be shown
     */
    get showNamedCredentialStep() {
        return this.namedCredentialNeedsUpdate && !this.namedCredentialUpdated;
    }

    /**
     * @description Dynamic step number for External Credential step (3 if NC step hidden, 4 if shown)
     */
    get externalCredentialStepNumber() {
        return this.showNamedCredentialStep ? 4 : 3;
    }

    /**
     * @description Dynamic step number for Test Connection step
     */
    get testConnectionStepNumber() {
        return this.showNamedCredentialStep ? 5 : 4;
    }
    
    /**
     * @description Dynamic step label for External Credential
     */
    get externalCredentialStepLabel() {
        const num = this.showNamedCredentialStep ? 4 : 3;
        return `${num}. Configure External Credential`;
    }
    
    /**
     * @description Dynamic step label for Test Connection
     */
    get testConnectionStepLabel() {
        const num = this.showNamedCredentialStep ? 5 : 4;
        return `${num}. Test Connection`;
    }
    
    /**
     * @description Total number of setup steps
     */
    get totalStepsCount() {
        return this.showNamedCredentialStep ? 5 : 4;
    }
    
    /**
     * @description Number of completed setup steps
     */
    get completedStepsCount() {
        let count = 0;
        if (this.setupSteps.step1) count++;
        if (this.setupSteps.step2) count++;
        if (this.showNamedCredentialStep && this.setupSteps.step3) count++;
        if (this.setupSteps.step4) count++;
        if (this.setupSteps.step5) count++;
        return count;
    }
    
    /**
     * @description Handle step completion checkbox change
     */
    handleStepComplete(event) {
        const step = event.currentTarget.dataset.step;
        const checked = event.target.checked;
        this.setupSteps = { ...this.setupSteps, [step]: checked };
    }
    
    /**
     * @description Handle transcription provider change for test section
     */
    handleTestProviderChange(event) {
        this.testTranscriptionProvider = event.detail.value;
        console.log('[MtVoiceAssistantAdmin] Test provider changed to:', this.testTranscriptionProvider);
    }

    // ==========================================================================
    // UTILITY METHODS
    // ==========================================================================
    
    /**
     * @description Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}