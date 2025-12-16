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

import { LightningElement, track, api, wire } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getAccessToken from '@salesforce/apex/mt_TranscribeController.getAccessToken';
import getBaseUrl from '@salesforce/apex/mt_TranscribeController.getBaseUrl';
import getRelatedAccount from '@salesforce/apex/mt_TranscribeController.getRelatedAccount';
import getConfig from '@salesforce/apex/mt_TranscribeController.getConfig';
import transcribeWithWhisper from '@salesforce/apex/mt_TranscribeController.transcribeWithWhisper';
// New API feature imports (optional features) - Commented out until methods are implemented
// import discoverVoices from '@salesforce/apex/mt_TranscribeController.discoverVoices';
// import synthesizeSpeechV2 from '@salesforce/apex/mt_TranscribeController.synthesizeSpeechV2';
// import transcribeV2 from '@salesforce/apex/mt_TranscribeController.transcribeV2';
// import createTranscriptionJob from '@salesforce/apex/mt_TranscribeController.createTranscriptionJob';
// import getTranscriptionJobStatus from '@salesforce/apex/mt_TranscribeController.getTranscriptionJobStatus';
// import translateText from '@salesforce/apex/mt_TranscribeController.translateText';
// import translateDocument from '@salesforce/apex/mt_TranscribeController.translateDocument';
// import importTerminology from '@salesforce/apex/mt_TranscribeController.importTerminology';
// import getTerminology from '@salesforce/apex/mt_TranscribeController.getTerminology';
// import deleteTerminology from '@salesforce/apex/mt_TranscribeController.deleteTerminology';
// import deleteAllTerminologies from '@salesforce/apex/mt_TranscribeController.deleteAllTerminologies';
// Default visualization
import {
	initializeVisualization,
	startAnimation,
	stopAnimation,
	clearCanvas
} from './audioVisualisationHelper';

// Alternative visualizations for comparison
import {
	initializeVisualization as initViz1,
	startAnimation as startAnim1,
	stopAnimation as stopAnim1,
	clearCanvas as clearCanvas1
} from './audioVisualisationHelper_opt1';

import {
	initializeVisualization as initViz2,
	startAnimation as startAnim2,
	stopAnimation as stopAnim2,
	clearCanvas as clearCanvas2
} from './audioVisualisationHelper_opt2';

import {
	initializeVisualization as initViz3,
	startAnimation as startAnim3,
	stopAnimation as stopAnim3,
	clearCanvas as clearCanvas3
} from './audioVisualisationHelper_opt3';

export default class MtEinsteinTranscribe extends LightningElement {
	// ==========================================================================
	// COMPONENT STATE
	// ==========================================================================
	
	isLoading = false;
	error = null;
	audioSrc = '';
	isRecording = false;
	@track textareaStyle = '';
	@track showConfirmation = false;
	@track _showSubmitWarning = false;
	@track _appendMode = false; // When true, append new transcription to existing text
	@track _processingStep = ''; // Current processing step message
	BASE_API_URL;

	// ==========================================================================
	// PUBLIC API PROPERTIES (Configurable from Flow/App Builder)
	// ==========================================================================
	
	/** @description Output text from transcription or input for synthesis */
    @api outputText = '';
	
	/** @description Operating mode: 'speech-to-text', 'text-to-speech', or 'both' */
    @api mode = 'speech-to-text';
	
	/** @description Label displayed for the component */
    @api label = 'Transcription/Synthesis Result';
	
	/** @description Whether the transcription field is required */
	@api required = false;
	
	/** @description Placeholder text for the textarea */
	@api placeholder = 'Result will appear here';
	
	/** @description Number of rows for the textarea */
	@api rows = 8;
	
	/** @description Error message shown when required validation fails */
	@api fieldRequiredMessage = 'This field is required';
	
	/** @description Toggle for Einstein Transcribe feature */
	@api einsteinTranscribe = false;
	
	/** @description Show all visualizers for comparison (test mode) */
	@api showAllVisualizers = false;
	
	/** @description Configuration profile name (e.g., 'Default', 'Sales_Config') */
	@api configName = 'Default';
	
	/** @description Record ID to find related Account from */
	@api recordId;
	
	/** @description The resolved Account SObject (output for Flow) */
	@api account;
	
	/** @description The resolved Account ID (output) */
	@api accountId;
	
	/** @description The resolved Account Name (output) */
	@api accountName;
	
	/** @description The object type of the input record */
	@api sourceObjectType;
	
	/** @description Current date, time and day of week when transcription completed */
	@api currentDateTime;
	
	/** @description Enable image input feature (can be set via Flow or config profile) */
	@api enableImageInput = false;
	
	/** @description Show provider selector dropdown (can be set via property or config profile) */
	@api showProviderSelectorProp = false;
	
	/** @description Internal flag for provider selector (set from config) */
	_showProviderSelectorFromConfig = false;
	
	/** @description Internal flag for image input (set from config) */
	_enableImageInputFromConfig = false;
	
	/**
	 * @description Check if provider selector should be shown
	 *              Returns true if either @api property OR config profile enables it
	 */
	get showProviderSelector() {
		return this.showProviderSelectorProp === true || this._showProviderSelectorFromConfig === true;
	}
	
	/** @description Provider options for dropdown */
	providerOptions = [
		{ label: 'Einstein Transcribe', value: 'Einstein' },
		{ label: 'OpenAI Whisper', value: 'Whisper' }
	];
	
	// ==========================================================================
	// SINGLE IMAGE OUTPUT (for Flow)
	// ==========================================================================
	
	/** @description Number of images attached (0 or 1) */
	@api imageCount = 0;
	
	/** @description Image analysis instructions - kept for backwards compatibility */
	@api imageInstructions = '';
	
	/** @description Image base64 data (output for Flow) */
	@api imageBase64 = '';
	/** @description Image filename (output for Flow) */
	@api imageFileName = '';
	/** @description Image MIME type (output for Flow) */
	@api imageMimeType = '';
	
	// Backwards compatibility properties (expose even though single-file UI)
	// These are needed because existing flow versions reference them
	@api imageData1 = '';
	@api imageFileName1 = '';
	@api imageMimeType1 = '';
	@api imageData2 = '';
	@api imageFileName2 = '';
	@api imageMimeType2 = '';
	@api imageData3 = '';
	@api imageFileName3 = '';
	@api imageMimeType3 = '';
	@api imageData4 = '';
	@api imageFileName4 = '';
	@api imageMimeType4 = '';
	@api imageData5 = '';
	@api imageFileName5 = '';
	@api imageMimeType5 = '';

	// ==========================================================================
	// INTERNAL STATE
	// ==========================================================================
	
	showErrorMessage = false;
	_accountResolved = false;
	_accountError = null;
	
	// Configuration state
	_config = null;
	_configLoaded = false;
	_transcriptionProvider = 'Einstein'; // Default provider
	
	// Additional visualization contexts for test mode
	vizContext1 = null;
	vizContext2 = null;
	vizContext3 = null;
	formElementClass = 'slds-form-element';
	showAudioVisualization = false;

    // Visualization references for Speech-to-Text
    audioContextSTT = null;
    analyserSTT = null;
    canvasElementSTT = null;
    canvasCtxSTT = null;

    // Visualization references for Text-to-Speech
    audioContextTTS = null;
    analyserTTS = null;
    canvasElementTTS = null;
    canvasCtxTTS = null;
    isTTSSpeaking = false;
    ttsSource = null;

	// Recording state
	mediaRecorder = null;
	audioChunks = [];
	recordingMimeType = 'audio/mp3';

	@track selectedLanguageTTS = 'Joanna';
	@track activeTab = 'speech-to-text';
	
	// Single Image Input State
	@track _attachedFile = null; // {file, previewUrl, base64, fileName, mimeType, size, isImage}
	@track _isProcessingFile = false; // Track if FileReader is working

	// ==========================================================================
	// TEXT-TO-SPEECH VOICE OPTIONS
	// ==========================================================================
	
	/**
	 * @description Available voices for text-to-speech synthesis
	 *              Organized by language/accent for easy selection
	 */
	languageOptionsTTS = [
		{ label: 'Arabic (Gulf) – Hala', value: 'Hala' },
		{ label: 'Arabic (Gulf) – Zayd', value: 'Zayd' },
		{ label: 'Belgian Dutch (Flemish) – Lisa', value: 'Lisa' },
		{ label: 'Catalan – Arlet', value: 'Arlet' },
		{ label: 'Czech – Jitka', value: 'Jitka' },
		{ label: 'Chinese (Cantonese) – Hiujin', value: 'Hiujin' },
		{ label: 'Chinese (Mandarin) – Zhiyu', value: 'Zhiyu' },
		{ label: 'Danish – Sofie', value: 'Sofie' },
		{ label: 'Dutch – Laura', value: 'Laura' },
		{ label: 'English (Australian) – Olivia', value: 'Olivia' },
		{ label: 'English (British) – Amy', value: 'Amy' },
		{ label: 'English (British) – Emma', value: 'Emma' },
		{ label: 'English (British) – Brian', value: 'Brian' },
		{ label: 'English (British) – Arthur', value: 'Arthur' },
		{ label: 'English (Indian) – Kajal', value: 'Kajal' },
		{ label: 'English (Irish) – Niamh', value: 'Niamh' },
		{ label: 'English (New Zealand) – Aria', value: 'Aria' },
		{ label: 'English (South African) – Ayanda', value: 'Ayanda' },
		{ label: 'English (US) – Danielle', value: 'Danielle' },
		{ label: 'English (US) – Gregory', value: 'Gregory' },
		{ label: 'English (US) – Ivy', value: 'Ivy' },
		{ label: 'English (US) – Joanna', value: 'Joanna' },
		{ label: 'English (US) – Kendra', value: 'Kendra' },
		{ label: 'English (US) – Kimberly', value: 'Kimberly' },
		{ label: 'English (US) – Salli', value: 'Salli' },
		{ label: 'English (US) – Joey', value: 'Joey' },
		{ label: 'English (US) – Justin', value: 'Justin' },
		{ label: 'English (US) – Kevin', value: 'Kevin' },
		{ label: 'English (US) – Matthew', value: 'Matthew' },
		{ label: 'English (US) – Ruth', value: 'Ruth' },
		{ label: 'English (US) – Stephen', value: 'Stephen' },
		{ label: 'Finnish – Suvi', value: 'Suvi' },
		{ label: 'French (Belgian) – Isabelle', value: 'Isabelle' },
		{ label: 'French (Canadian) – Gabrielle', value: 'Gabrielle' },
		{ label: 'French (Canadian) – Liam', value: 'Liam' },
		{ label: 'French – Léa', value: 'Léa' },
		{ label: 'French – Rémi', value: 'Rémi' },
		{ label: 'German – Vicki', value: 'Vicki' },
		{ label: 'German – Daniel', value: 'Daniel' },
		{ label: 'German (Austrian) – Hannah', value: 'Hannah' },
		{ label: 'German (Swiss) – Sabrina', value: 'Sabrina' },
		{ label: 'Hindi – Kajal', value: 'Kajal' },
		{ label: 'Italian – Bianca', value: 'Bianca' },
		{ label: 'Italian – Adriano', value: 'Adriano' },
		{ label: 'Japanese – Takumi', value: 'Takumi' },
		{ label: 'Japanese – Kazuha', value: 'Kazuha' },
		{ label: 'Japanese – Tomoko', value: 'Tomoko' },
		{ label: 'Korean – Seoyeon', value: 'Seoyeon' },
		{ label: 'Norwegian – Ida', value: 'Ida' },
		{ label: 'Polish – Ola', value: 'Ola' },
		{ label: 'Portuguese (Brazilian) – Camila', value: 'Camila' },
		{ label: 'Portuguese (Brazilian) – Vitória', value: 'Vitória' },
		{ label: 'Portuguese (Brazilian) – Thiago', value: 'Thiago' },
		{ label: 'Portuguese (European) – Inês', value: 'Inês' },
		{ label: 'Spanish (Spain) – Lucia', value: 'Lucia' },
		{ label: 'Spanish (Spain) – Sergio', value: 'Sergio' },
		{ label: 'Spanish (Mexican) – Mia', value: 'Mia' },
		{ label: 'Spanish (Mexican) – Andrés', value: 'Andrés' },
		{ label: 'Spanish (US) – Lupe', value: 'Lupe' },
		{ label: 'Spanish (US) – Pedro', value: 'Pedro' },
		{ label: 'Swedish – Elin', value: 'Elin' },
		{ label: 'Turkish – Burcu', value: 'Burcu' }
	];

	// ==========================================================================
	// COMPUTED PROPERTIES (Getters)
	// ==========================================================================

	/** @description Check if text-to-speech mode is active */
    get isTextToSpeechMode() {
        return this.mode === 'text-to-speech' || this.mode === 'both';
	}
	
	/** @description Check if speech-to-text mode is active */
    get isSpeechToTextMode() {
        return this.mode === 'speech-to-text' || this.mode === 'both';
    }
	
	/** @description Show tabs when both modes are enabled */
    get showTabs() {
        return this.mode === 'both';
	}
	
	/** @description Inverse of isRecording for disabled states */
	get isNotRecording() {
		return !this.isRecording;
	}
	
	/** @description Dynamic icon based on recording state */
	get recordingIcon() {
		return this.isRecording ? 'utility:stop' : 'utility:unmuted';
	}
	
	/** @description Dynamic button label based on recording state */
	get recordingButtonLabel() {
		return this.isRecording ? 'Stop Recording' : 'Start Recording';
	}
	
	/** @description Button variant changes based on recording state */
	get recordingButtonVariant() {
		return this.isRecording ? 'destructive' : 'brand';
	}
	
	/** @description Disable convert button when no text or loading */
	get isConvertButtonDisabled() {
		const text = Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
		return (!text || text.trim() === '') && !this.isLoading;
	}

	/** @description Combined class for textarea form element */
	get textAreaClass() {
		return `${this.formElementClass} ${this.textareaStyle}`.trim();
	}

	/** @description Handle array or string output text for display */
	get displayedText() {
		return Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
	}

	/** @description Check if audio source is available for playback */
    get hasAudioSource() {
        return !!this.audioSrc;
	}

	/** @description Dynamic textarea height style based on rows property */
	get textareaHeightStyle() {
		const lineHeight = '1em';
		return `height: calc(${this.rows} * ${lineHeight});`;
	}
	
	// ==========================================================================
	// SINGLE IMAGE INPUT COMPUTED PROPERTIES
	// ==========================================================================
	
	/** @description Check if an image is attached */
	get hasImage() {
		return this._attachedFile !== null && this._attachedFile.base64;
	}
	
	/** @description Check if no image is attached (for hint display) */
	get noImageAttached() {
		return !this.hasImage && !this._isProcessingFile;
	}
	
	/** @description Check if attached file is an image (not PDF) */
	get isImageFile() {
		return this._attachedFile && this._attachedFile.isImage;
	}
	
	/** @description Get image preview URL */
	get imagePreviewUrl() {
		return this._attachedFile ? this._attachedFile.previewUrl : null;
	}
	
	/** @description Get attached file name */
	get attachedFileName() {
		return this._attachedFile ? this._attachedFile.fileName : '';
	}
	
	/** @description Get short file name for display (truncated) */
	get attachedFileNameShort() {
		if (!this._attachedFile) return '';
		const name = this._attachedFile.fileName;
		if (name.length <= 25) return name;
		const ext = name.split('.').pop();
		return name.substring(0, 20) + '...' + ext;
	}
	
	/** @description Get formatted file size */
	get attachedFileSize() {
		if (!this._attachedFile) return '';
		return this._formatFileSize(this._attachedFile.size);
	}
	
	/** @description Check if file is being processed */
	get isProcessingFile() {
		return this._isProcessingFile;
	}
	
	/** @description Format file size for display */
	_formatFileSize(bytes) {
		if (bytes < 1024) return `${bytes} B`;
		if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
		return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
	}
	
	// ==========================================================================
	// ACTION BAR COMPUTED PROPERTIES
	// ==========================================================================
	
	/** @description CSS class for image button */
	get imageButtonClass() {
		const base = 'btn-action-small';
		return this.hasImage ? `${base} btn-action-has-image` : base;
	}
	
	/** @description CSS class for main record button */
	get mainRecordButtonClass() {
		if (this.isRecording) return 'btn-action-recording';
		return 'btn-action-large';
	}
	
	/** @description CSS class for submit button */
	get submitButtonClass() {
		const base = 'btn-action-small';
		const hasContent = this._hasTranscriptContent();
		return hasContent ? `${base} btn-action-submit-enabled` : base;
	}
	
	/** @description Check if submit should be disabled (only during recording/loading) */
	get submitDisabled() {
		return this.isRecording || this.isLoading;
	}
	
	/** @description Status message for display */
	get statusMessage() {
		if (this.hasImage && this._hasTranscriptContent()) {
			return 'Ready with transcript and image';
		} else if (this._hasTranscriptContent()) {
			return 'Ready with transcript';
		} else if (this.hasImage) {
			return 'Ready with image';
		}
		return '';
	}
	
	/** @description Processing step message for display */
	get processingStepMessage() {
		return this._processingStep || 'Processing...';
	}
	
	/** @description Show processing note when ready to submit */
	get showProcessingNote() {
		return this._hasTranscriptContent() && !this.isRecording && !this.isLoading;
	}
	
	/** @description Dynamic processing note message based on whether image is attached */
	get processingNoteMessage() {
		const hasImage = this._attachedFile && this._attachedFile.base64;
		if (hasImage) {
			return 'The next step will process the transcript and image. This may take up to 20 seconds depending on complexity.';
		}
		return 'The next step will process the transcript. This may take up to 20 seconds depending on complexity.';
	}
	
	/** @description Check if there's transcript content */
	_hasTranscriptContent() {
		const text = Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
		return text && text.trim().length > 0;
	}

	// ==========================================================================
	// WIRE ADAPTERS
	// ==========================================================================
	
	/**
	 * @description Wire adapter to fetch base URL from custom metadata
	 */
	@wire(getBaseUrl)
	wiredBasedUrl({ error, data }) {
		if (data) {
			this.BASE_API_URL = data;
		} else if (error) {
			console.error('Error fetching base URL:', error);
		}
	}

	// ==========================================================================
	// LIFECYCLE HOOKS
	// ==========================================================================
	
	/**
	 * @description Initialize component state based on mode
	 */
	connectedCallback() {
        if (this.mode === 'text-to-speech') {
            this.activeTab = 'text-to-speech';
        } else {
            this.activeTab = 'speech-to-text';
        }
        
        // Set current date/time immediately so it's available for Flow
        this._setCurrentDateTime();
        
        // Load configuration profile
        this._loadConfig();
        
        // Resolve related Account if recordId is provided
        if (this.recordId) {
            this._resolveRelatedAccount();
        }
	}
	
	/**
	 * @description Load the configuration profile from Custom Metadata
	 */
	async _loadConfig() {
	    try {
	        const result = await getConfig({ configName: this.configName || 'Default' });
	        if (result.success) {
	            this._config = result;
	            this._transcriptionProvider = result.provider || 'Einstein';
	            this._enableImageInputFromConfig = result.enableImageInput === true;
	            this._showProviderSelectorFromConfig = result.showProviderSelector === true;
	            this._configLoaded = true;
	            console.log('Loaded config:', result.configName, '- Provider:', this._transcriptionProvider, '- Image Input:', this._enableImageInputFromConfig, '- Show Provider Selector:', this._showProviderSelectorFromConfig);
	        } else {
	            console.warn('Could not load config:', result.errorMessage);
	            // Fall back to defaults
	            this._transcriptionProvider = 'Einstein';
	            this._enableImageInputFromConfig = false;
	            this._showProviderSelectorFromConfig = false;
	            this._configLoaded = true;
	        }
	    } catch (error) {
	        console.error('Error loading config:', error);
	        this._transcriptionProvider = 'Einstein';
	        this._enableImageInputFromConfig = false;
	        this._showProviderSelectorFromConfig = false;
	        this._configLoaded = true;
	    }
	}
	
	/**
	 * @description Check if image input should be shown
	 *              Returns true if either @api property OR config profile enables it
	 */
	get showImageInput() {
	    return this.enableImageInput === true || this._enableImageInputFromConfig === true;
	}
	
	/**
	 * @description Handle manual text changes in textarea
	 */
	handleTextChange(event) {
	    this.outputText = event.target.value;
	    // Update date/time when text changes
	    this._setCurrentDateTime();
	    // Clear warning when user types
	    const textValue = this.outputText || '';
	    if (this._showSubmitWarning && textValue.trim().length > 0) {
	        this._showSubmitWarning = false;
	        this.error = null;
	    }
	}
	
	/**
	 * @description Handle provider change from dropdown
	 */
	handleProviderChange(event) {
		this._transcriptionProvider = event.detail.value;
		console.log('[MtEinsteinTranscribe] Provider changed to:', this._transcriptionProvider);
	}
	
	/**
	 * @description Resolves the related Account from the provided recordId
	 */
	async _resolveRelatedAccount() {
	    try {
	        console.log('Resolving related Account for recordId:', this.recordId);
	        const result = await getRelatedAccount({ recordId: this.recordId });
	        
	        if (result.success) {
	            this.account = result.account;  // Full Account SObject for Flow
	            this.accountId = result.accountId;
	            this.accountName = result.accountName;
	            this.sourceObjectType = result.objectType;
	            this._accountResolved = true;
	            this._accountError = null;
	            console.log('Related Account found:', this.accountName, '(', this.accountId, ')');
	        } else {
	            this._accountError = result.errorMessage;
	            this._accountResolved = false;
	            console.warn('Could not resolve Account:', result.errorMessage);
	        }
	    } catch (error) {
	        this._accountError = error.body?.message || error.message || 'Unknown error';
	        this._accountResolved = false;
	        console.error('Error resolving Account:', error);
	    }
	}

	// ==========================================================================
	// HELPER METHODS
	// ==========================================================================

	/**
	 * @description Build API endpoint URL
	 * @param {string} path - API path segment
	 * @returns {string} Full endpoint URL
	 */
	getEndpoint(path) {
		return `${this.BASE_API_URL}/${path}`;
	}

	/**
	 * @description Build authorization headers for API calls
	 * @param {string} accessToken - OAuth access token
	 * @returns {Object} Headers object
	 */
	buildHeaders(accessToken) {
		return {
			Authorization: `Bearer ${accessToken}`,
			'x-sfdc-app-context': 'EinsteinGPT',
			'x-client-feature-id': 'external-edc',
		};
	}

	/**
	 * @description Prepare FormData for API request
	 * @param {Blob|string} input - Audio blob or text string
	 * @param {string} type - 'audio' or 'text'
	 * @param {string} fileName - Filename for text input
	 * @returns {FormData} Prepared form data
	 */
	prepareFormData(input, type = 'audio', fileName = 'audioRecordingInput.txt') {
		const formData = new FormData();
		if (type === 'audio') {
			formData.append('input', input);
		} else if (type === 'text') {
			const textBlob = new Blob([input], { type: 'text/plain' });
			formData.append('input', textBlob, fileName);
		}
		formData.append('language', 'english');
		if (type === 'text') {
			formData.append('voiceId', this.selectedLanguageTTS);
		}
		return formData;
	}

	/**
	 * @description Generic API call handler
	 * @param {string} endpoint - API endpoint
	 * @param {FormData} formData - Request body
	 * @returns {Promise<Object>} API response
	 */
	async callApi(endpoint, formData) {
		try {
			const accessToken = await getAccessToken();
			const fetchOptions = {
				method: 'POST',
				headers: this.buildHeaders(accessToken),
				body: formData,
			};

			const response = await fetch(endpoint, fetchOptions);
			const responseBody = await response.json();

			if (!response.ok)
				throw new Error(responseBody.message || 'Unexpected error');
			return responseBody;
		} catch (error) {
			throw new Error(`API call failed: ${error.message}`);
		}
	}

	/**
	 * @description Handle and display error
	 * @param {string} errorMessage - Error message to display
	 */
	handleError(errorMessage) {
		this.error = errorMessage;
		console.error(errorMessage);
	}

	/**
	 * @description Sets current date/time when transcription completes
	 * @private
	 */
	_setCurrentDateTime() {
		const now = new Date();
		
		// Format: "Friday, November 28, 2025 at 15:30"
		const dayOfWeek = now.toLocaleDateString('en-US', { weekday: 'long' });
		const date = now.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
		const time = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
		
		this.currentDateTime = `${dayOfWeek}, ${date} at ${time}`;
		
		console.log('DateTime set:', this.currentDateTime);
	}

	/**
	 * @description Reset component to initial state
	 */
	resetState() {
		this.isLoading = false;
		this.error = null;
		this.audioSrc = '';
        this.stopTTSVisualization();
	}

	// ==========================================================================
	// SPEECH-TO-TEXT METHODS
	// ==========================================================================
	
	/**
	 * @description Send recorded audio to transcription API (Einstein or Whisper based on config)
	 * @param {Blob} audioBlob - Recorded audio data
	 */
	async sendAudioToApi(audioBlob) {
		this.isLoading = true;
		this.error = null;

		try {
			// Route to appropriate provider based on configuration
			if (this._transcriptionProvider === 'Whisper') {
				await this._transcribeWithWhisper(audioBlob);
			} else {
				await this._transcribeWithEinstein(audioBlob);
			}
			
			// Set current date/time when transcription completes
			this._setCurrentDateTime();
		} catch (err) {
			this.handleError(`Failed to transcribe audio: ${err.message}`);
		} finally {
			this.isLoading = false;
		}
	}
	
	/**
	 * @description Transcribe audio using Einstein Transcribe API
	 * @param {Blob} audioBlob - Recorded audio data
	 */
	async _transcribeWithEinstein(audioBlob) {
		const formData = this.prepareFormData(audioBlob, 'audio');
		const responseBody = await this.callApi(this.getEndpoint('transcriptions'), formData);
		const newText = responseBody.transcription || 'No transcription received.';
		
		// Append or replace based on mode
		if (this._appendMode && this.outputText) {
			const existingText = Array.isArray(this.outputText) ? this.outputText.join(' ') : (this.outputText || '');
			this.outputText = existingText.trim() + ' ' + newText;
		} else {
			this.outputText = newText;
		}
		this._appendMode = false; // Reset after use
	}
	
	/**
	 * @description Transcribe audio using OpenAI Whisper API via Apex
	 * @param {Blob} audioBlob - Recorded audio data
	 */
	async _transcribeWithWhisper(audioBlob) {
		// Convert blob to base64
		const reader = new FileReader();
		const base64Promise = new Promise((resolve, reject) => {
			reader.onloadend = () => {
				// Remove data URL prefix (e.g., "data:audio/webm;base64,")
				const base64 = reader.result.split(',')[1];
				resolve(base64);
			};
			reader.onerror = reject;
		});
		reader.readAsDataURL(audioBlob);
		
		const audioBase64 = await base64Promise;
		
		// Call Apex method to transcribe via Whisper
		const result = await transcribeWithWhisper({ 
			audioBase64: audioBase64, 
			configName: this.configName || 'Default' 
		});
		
		if (result.success) {
			const newText = result.transcription || 'No transcription received.';
			
			// Append or replace based on mode
			if (this._appendMode && this.outputText) {
				const existingText = Array.isArray(this.outputText) ? this.outputText.join(' ') : (this.outputText || '');
				this.outputText = existingText.trim() + ' ' + newText;
			} else {
				this.outputText = newText;
			}
			this._appendMode = false; // Reset after use
		} else {
			throw new Error(result.errorMessage || 'Whisper transcription failed');
		}
	}

	// ==========================================================================
	// TEXT-TO-SPEECH METHODS
	// ==========================================================================
	
	/**
	 * @description Convert text to speech using Einstein API
	 */
	async handleTextToSpeech() {
		this.isLoading = true;
		this.error = null;

		try {
			const inputText = Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
			const formData = this.prepareFormData(inputText, 'text', 'voice.txt');
			const responseBody = await this.callApi(this.getEndpoint('speech-synthesis'), formData);

			if (responseBody.audioStream) {
				const byteArray = Uint8Array.from(
					atob(responseBody.audioStream),
					c => c.charCodeAt(0)
				);
				const blob = new Blob([byteArray], { type: 'audio/mp3' });
				this.audioSrc = URL.createObjectURL(blob);
                this.startTTSVisualization();
			} else {
				this.error = 'No audio data received from the API.';
			}
		} catch (error) {
			this.handleError(`Error in text-to-speech: ${error.message}`);
		} finally {
			this.isLoading = false;
		}
	}

	// ==========================================================================
	// NEW API FEATURES - OPTIONAL IMPLEMENTATIONS (Backend Only, No UI)
	// ==========================================================================

	/**
	 * @description Discover available voices from the API
	 * @param {string} engine Optional filter by engine (aws, elevenlabs)
	 * @returns {Promise<Object>} Voice discovery result
	 */
	async discoverVoices(engine = null) {
		try {
			const result = await discoverVoices({ engine });
			return result;
		} catch (error) {
			console.error('Error discovering voices:', error);
			throw error;
		}
	}

	/**
	 * @description Enhanced TTS v2 with advanced voice settings
	 * @param {string} text Text to synthesize
	 * @param {Object} requestParams Request parameters object
	 * @returns {Promise<Object>} TTS v2 result with audio content
	 */
	async synthesizeSpeechV2(text, requestParams = {}) {
		try {
			// Convert text to base64
			const textBlob = new Blob([text], { type: 'text/plain' });
			const textBase64 = await this.blobToBase64(textBlob);
			
			// Build request JSON
			const requestJson = JSON.stringify({
				engine: requestParams.engine || 'aws',
				language: requestParams.language || 'en-US',
				voiceIdString: requestParams.voiceIdString || 'Joanna',
				voiceSettingsObject: requestParams.voiceSettingsObject || {},
				seed: requestParams.seed,
				output_format: requestParams.output_format || 'mp3_44100_128',
				sample_rate: requestParams.sample_rate,
				model_id: requestParams.model_id
			});

			const result = await synthesizeSpeechV2({ 
				textBase64, 
				requestJson 
			});
			return result;
		} catch (error) {
			console.error('Error synthesizing speech v2:', error);
			throw error;
		}
	}

	/**
	 * @description Transcribe audio with diarization (v2)
	 * @param {Blob} audioBlob Audio blob to transcribe
	 * @param {Object} requestParams Request parameters object
	 * @returns {Promise<Object>} Transcription v2 result with transcript and segments
	 */
	async transcribeV2(audioBlob, requestParams = {}) {
		try {
			// Convert blob to base64
			const audioBase64 = await this.blobToBase64(audioBlob);
			
			// Build request JSON
			const requestJson = JSON.stringify({
				engine: requestParams.engine || 'aws',
				language: requestParams.language || 'en-US',
				diarizationEnabled: requestParams.diarizationEnabled || false,
				modelMetadata: requestParams.modelMetadata || {}
			});

			const result = await transcribeV2({ 
				audioBase64, 
				requestJson 
			});
			return result;
		} catch (error) {
			console.error('Error transcribing v2:', error);
			throw error;
		}
	}

	/**
	 * @description Create an asynchronous transcription job
	 * @param {Blob} audioBlob Audio blob to transcribe
	 * @param {Object} requestParams Request parameters object
	 * @returns {Promise<Object>} Job creation result with jobId
	 */
	async createTranscriptionJob(audioBlob, requestParams = {}) {
		try {
			// Convert blob to base64
			const audioBase64 = await this.blobToBase64(audioBlob);
			
			// Build request JSON
			const requestJson = JSON.stringify({
				engine: requestParams.engine || 'aws',
				language: requestParams.language || 'en-US',
				sourceLocation: requestParams.sourceLocation,
				targetLocation: requestParams.targetLocation,
				settings: requestParams.settings || {}
			});

			const result = await createTranscriptionJob({ 
				audioBase64, 
				requestJson 
			});
			return result;
		} catch (error) {
			console.error('Error creating transcription job:', error);
			throw error;
		}
	}

	/**
	 * @description Get transcription job status and results
	 * @param {string} jobId The transcription job ID
	 * @returns {Promise<Object>} Job status result
	 */
	async getTranscriptionJobStatus(jobId) {
		try {
			const result = await getTranscriptionJobStatus({ jobId });
			return result;
		} catch (error) {
			console.error('Error getting job status:', error);
			throw error;
		}
	}

	/**
	 * @description Translate text using translation API
	 * @param {string} text Text to translate
	 * @param {Object} requestParams Request parameters object
	 * @returns {Promise<Object>} Translation result
	 */
	async translateText(text, requestParams = {}) {
		try {
			const requestJson = JSON.stringify({
				input: text,
				sourceLanguage: requestParams.sourceLanguage || 'auto',
				targetLanguage: requestParams.targetLanguage,
				engine: requestParams.engine || 'aws',
				settings: requestParams.settings || {},
				terminologyNames: requestParams.terminologyNames || []
			});

			const result = await translateText({ requestJson });
			return result;
		} catch (error) {
			console.error('Error translating text:', error);
			throw error;
		}
	}

	/**
	 * @description Translate a document using translation API
	 * @param {Blob} documentBlob Document blob to translate
	 * @param {Object} requestParams Request parameters object
	 * @returns {Promise<Object>} Document translation result
	 */
	async translateDocument(documentBlob, requestParams = {}) {
		try {
			// Convert blob to base64
			const documentBase64 = await this.blobToBase64(documentBlob);
			
			// Build request JSON
			const requestJson = JSON.stringify({
				sourceLanguage: requestParams.sourceLanguage,
				targetLanguage: requestParams.targetLanguage,
				contentType: requestParams.contentType,
				engine: requestParams.engine || 'aws',
				settings: requestParams.settings || {},
				terminologyNames: requestParams.terminologyNames || []
			});

			const result = await translateDocument({ 
				documentBase64, 
				requestJson 
			});
			return result;
		} catch (error) {
			console.error('Error translating document:', error);
			throw error;
		}
	}

	/**
	 * @description Import terminology for translation
	 * @param {Blob} fileBlob Terminology file blob
	 * @param {string} name Terminology name
	 * @param {string} engine Translation engine (default: aws)
	 * @returns {Promise<Object>} Terminology import result
	 */
	async importTerminology(fileBlob, name, engine = 'aws') {
		try {
			// Convert blob to base64
			const fileBase64 = await this.blobToBase64(fileBlob);

			const result = await importTerminology({ 
				fileBase64, 
				name, 
				engine 
			});
			return result;
		} catch (error) {
			console.error('Error importing terminology:', error);
			throw error;
		}
	}

	/**
	 * @description Get terminology by name
	 * @param {string} name Terminology name
	 * @param {string} engine Translation engine (default: aws)
	 * @returns {Promise<Object>} Terminology result
	 */
	async getTerminology(name, engine = 'aws') {
		try {
			const result = await getTerminology({ name, engine });
			return result;
		} catch (error) {
			console.error('Error getting terminology:', error);
			throw error;
		}
	}

	/**
	 * @description Delete terminology by name
	 * @param {string} name Terminology name
	 * @param {string} engine Translation engine (default: aws)
	 * @returns {Promise<Object>} Deletion result
	 */
	async deleteTerminology(name, engine = 'aws') {
		try {
			const result = await deleteTerminology({ name, engine });
			return result;
		} catch (error) {
			console.error('Error deleting terminology:', error);
			throw error;
		}
	}

	/**
	 * @description Delete all terminologies for an engine
	 * @param {string} engine Translation engine (default: aws)
	 * @returns {Promise<Object>} Deletion result
	 */
	async deleteAllTerminologies(engine = 'aws') {
		try {
			const result = await deleteAllTerminologies({ engine });
			return result;
		} catch (error) {
			console.error('Error deleting all terminologies:', error);
			throw error;
		}
	}

	/**
	 * @description Helper: Convert blob to base64 string
	 * @param {Blob} blob Blob to convert
	 * @returns {Promise<string>} Base64 string
	 */
	blobToBase64(blob) {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onloadend = () => {
				// Remove data URL prefix (e.g., "data:audio/webm;base64,")
				const base64 = reader.result.split(',')[1];
				resolve(base64);
			};
			reader.onerror = reject;
			reader.readAsDataURL(blob);
		});
	}

	// ==========================================================================
	// RECORDING & VISUALIZATION (STT)
	// ==========================================================================
	
	/**
	 * @description Initialize audio stream with browser APIs
	 * @returns {Promise<MediaStream>} Media stream for recording
	 */
	async initializeAudioStream() {
		try {
			// Try multiple ways to access getUserMedia for Locker Service compatibility
			let stream = null;
			
			// Method 1: Standard API via window.navigator
			if (window.navigator && window.navigator.mediaDevices && window.navigator.mediaDevices.getUserMedia) {
				console.log('Using window.navigator.mediaDevices.getUserMedia');
				stream = await window.navigator.mediaDevices.getUserMedia({ audio: true });
			}
			// Method 2: Direct navigator access
			else if (navigator && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
				console.log('Using navigator.mediaDevices.getUserMedia');
				stream = await navigator.mediaDevices.getUserMedia({ audio: true });
			}
			// Method 3: Legacy getUserMedia (older browsers)
			else if (navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia) {
				console.log('Using legacy getUserMedia');
				const getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
				stream = await new Promise((resolve, reject) => {
					getUserMedia.call(navigator, { audio: true }, resolve, reject);
				});
			}
			else {
				throw new Error('No getUserMedia API available. Please use a modern browser.');
			}
			
			return stream;
		} catch (error) {
			// Provide more helpful error message
			let errorMsg;
			if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
				errorMsg = 'Microphone access denied. Please allow microphone access in your browser settings and try again.';
			} else if (error.name === 'NotFoundError' || error.name === 'DevicesNotFoundError') {
				errorMsg = 'No microphone found. Please connect a microphone and try again.';
			} else if (error.name === 'NotReadableError' || error.name === 'TrackStartError') {
				errorMsg = 'Microphone is in use by another application. Please close other apps using the microphone.';
			} else {
				errorMsg = `Failed to access microphone: ${error.message}`;
			}
			this.handleError(errorMsg);
			throw error;
		}
	}

	/**
	 * @description Setup MediaRecorder with appropriate MIME type
	 * @param {MediaStream} stream - Audio stream
	 * @param {Function} onDataAvailableCallback - Callback for data chunks
	 * @returns {MediaRecorder} Configured media recorder
	 */
	setupMediaRecorder(stream, onDataAvailableCallback) {
		let mimeType = 'audio/mp3';
		if (!MediaRecorder.isTypeSupported(mimeType))
			mimeType = 'audio/webm';

		this.recordingMimeType = mimeType;
		const mediaRecorder = new MediaRecorder(stream, { mimeType });
		mediaRecorder.ondataavailable = event => {
			if (event.data.size > 0)
				onDataAvailableCallback(event.data);
		};
		return mediaRecorder;
	}

	/**
	 * @description Toggle recording state (start/stop)
	 */
	handleRecordingToggle() {
		if (this.isRecording) {
			this.stopRecording();
		} else {
			const text = Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
			if (text.trim() !== '') {
				this.showConfirmation = true;
			} else {
				this.startRecording();
			}
		}
	}
	
	/**
	 * @description Handle submit button click - navigates to next flow screen
	 */
	async handleSubmitAndNavigate() {
		// Always require transcript content (image alone is not enough)
		if (!this._hasTranscriptContent()) {
			this._showSubmitWarning = true;
			this.error = 'Please record or type something before continuing.';
			return;
		}
		
		// Clear any previous warning
		this._showSubmitWarning = false;
		this.error = null;
		
		// Show processing steps
		this.isLoading = true;
		this._processingStep = 'Preparing data...';
		
		// Small delay to show the message
		await this._delay(300);
		this._processingStep = 'Calling AI Prompt...';
		
		await this._delay(200);
		this._processingStep = 'Processing...';
		
		// Trigger flow navigation to next screen
		const navigateNextEvent = new FlowNavigationNextEvent();
		this.dispatchEvent(navigateNextEvent);
		
		// Note: isLoading will be reset by flow navigation
	}
	
	/**
	 * @description Helper for async delays
	 */
	_delay(ms) {
		return new Promise(resolve => setTimeout(resolve, ms));
	}
	
	/**
	 * @description Handle confirmation dialog response
	 * @param {Event} event - Click event with confirmation data
	 */
	/**
	 * @description Handle "Start New" - clears existing text and starts fresh recording
	 */
	handleStartNew() {
		this.outputText = '';
		this.showConfirmation = false;
		this._appendMode = false;
		this.startRecording();
	}
	
	/**
	 * @description Handle "Add to Existing" - appends new recording to existing text
	 */
	handleAddToExisting() {
		this.showConfirmation = false;
		this._appendMode = true;
		this.startRecording();
	}

	/**
	 * @description Cancel confirmation dialog
	 */
	handleCancel() {
		this.showConfirmation = false;
	}

	/**
	 * @description Start audio recording with visualization
	 */
	async startRecording() {
		this.isRecording = true;
		this.placeholder = '';
		try {
			const stream = await this.initializeAudioStream();
			this.audioChunks = [];
			this.mediaRecorder = this.setupMediaRecorder(stream, chunk => this.audioChunks.push(chunk));
			this.mediaRecorder.start();

            this.canvasElementSTT = this.template.querySelector('.audio-visualizer-stt');
            const { audioContext, analyser, canvasCtx } = initializeVisualization(stream, this.canvasElementSTT);
            this.audioContextSTT = audioContext;
            this.analyserSTT = analyser;
            this.canvasCtxSTT = canvasCtx;

            startAnimation(this.analyserSTT, this.canvasCtxSTT, this.canvasElementSTT, () => this.isRecording);
            
            // Initialize additional visualizers if in test mode
            if (this.showAllVisualizers) {
                // Opt1 - Circular
                const canvas1 = this.template.querySelector('.audio-visualizer-opt1');
                if (canvas1) {
                    this.vizContext1 = initViz1(stream, canvas1);
                    startAnim1(this.vizContext1.analyser, this.vizContext1.canvasCtx, canvas1, () => this.isRecording);
                }
                
                // Opt2 - Thin waveform
                const canvas2 = this.template.querySelector('.audio-visualizer-opt2');
                if (canvas2) {
                    this.vizContext2 = initViz2(stream, canvas2);
                    startAnim2(this.vizContext2.analyser, this.vizContext2.canvasCtx, canvas2, () => this.isRecording);
                }
                
                // Opt3 - Waveform with bars
                const canvas3 = this.template.querySelector('.audio-visualizer-opt3');
                if (canvas3) {
                    this.vizContext3 = initViz3(stream, canvas3);
                    startAnim3(this.vizContext3.analyser, this.vizContext3.canvasCtx, canvas3, () => this.isRecording);
                }
            }

		} catch (error) {
			console.error(`Error starting recording: ${error.message}`, error);
			this.isRecording = false;
		}
	}

	/**
	 * @description Stop recording and send audio for transcription
	 */
	async stopRecording() {
		if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
			return;
		}

		this.isRecording = false;

		this.mediaRecorder.stop();
		this.mediaRecorder.stream.getTracks().forEach(track => track.stop());

		this.mediaRecorder.onstop = async () => {
			const audioBlob = new Blob(this.audioChunks, { type: this.recordingMimeType });
			await this.sendAudioToApi(audioBlob);

            if (this.canvasElementSTT && this.canvasCtxSTT)
                clearCanvas(this.canvasElementSTT, this.canvasCtxSTT);
		};

        if (this.audioContextSTT) {
			try {
                await this.audioContextSTT.close();
			} catch (closeError) {
				console.error("Error closing AudioContext:", closeError);
			}
            this.audioContextSTT = null;
		}
	}

	// ==========================================================================
	// VISUALIZATION (TTS)
	// ==========================================================================
	
	/**
	 * @description Start visualization for text-to-speech audio playback
	 */
    startTTSVisualization() {
        const audioElement = this.template.querySelector('.tts-audio');
        const canvasElement = this.template.querySelector('.audio-visualizer-tts');

        if (!audioElement || !canvasElement) {
            console.error('Audio or Canvas element not found for TTS visualization.');
            return;
        }

        const AudioContextClass = window.AudioContext || window.webkitAudioContext;
        if (!this.audioContextTTS) {
            this.audioContextTTS = new AudioContextClass();
        }
        if (!this.analyserTTS) {
        this.analyserTTS = this.audioContextTTS.createAnalyser();
        this.analyserTTS.fftSize = 2048;
        }

        // Disconnect previous source if exists
        if (this.ttsSource) {
            this.ttsSource.disconnect();
        }

        this.ttsSource = this.audioContextTTS.createMediaElementSource(audioElement);
        this.ttsSource.connect(this.analyserTTS);
        this.analyserTTS.connect(this.audioContextTTS.destination);

        this.canvasCtxTTS = canvasElement.getContext('2d');
        clearCanvas(canvasElement, this.canvasCtxTTS);
        this.isTTSSpeaking = true;
		startAnimation(this.analyserTTS, this.canvasCtxTTS, canvasElement, () => this.isTTSSpeaking && !audioElement.paused);

		audioElement.addEventListener('play', () => {
			if (!this.isTTSSpeaking) {
				this.isTTSSpeaking = true;
				startAnimation(this.analyserTTS, this.canvasCtxTTS, canvasElement, () => this.isTTSSpeaking && !audioElement.paused);
			}
		});

        audioElement.addEventListener('ended', () => {
            this.stopTTSVisualization();
        });
    }

	/**
	 * @description Stop TTS visualization and clear canvas
	 */
    stopTTSVisualization() {
        this.isTTSSpeaking = false;
        stopAnimation();
        if (this.canvasElementTTS && this.canvasCtxTTS) {
            clearCanvas(this.canvasElementTTS, this.canvasCtxTTS);
        }
    }

	// ==========================================================================
	// UI EVENT HANDLERS
	// ==========================================================================
	
	/**
	 * @description Handle text input changes
	 * @param {Event} event - Input change event
	 */
	handleTextChange(event) {
		this.outputText = event.target.value;
		if (!this.outputText || this.outputText.trim() === '') {
			this.placeholder = this.getAttribute('placeholder');
		} else {
			this.placeholder = '';
		}
	}

	/**
	 * @description Handle TTS language selection change
	 * @param {Event} event - Combobox change event
	 */
	handleTTSLanguageChange(event) {
		this.selectedLanguageTTS = event.target.value;
	}

	/**
	 * @description Handle tab switching between STT and TTS
	 * @param {Event} event - Tab change event
	 */
	handleTabChange(event) {
		this.activeTab = event.target.value;
		this.resetState();
	}

	/**
	 * @description Download generated TTS audio file
	 */
	handleDownloadAudio() {
		if (this.audioSrc) {
			const link = document.createElement('a');
			link.href = this.audioSrc;
			link.download = 'synthesized_audio.mp3';
			document.body.appendChild(link);
			link.click();
			document.body.removeChild(link);
		} else {
			this.handleError('No audio to download.');
		}
	}
	
	// ==========================================================================
	// SINGLE IMAGE INPUT HANDLERS
	// ==========================================================================
	
	/**
	 * @description Handle "Add Image" button click - opens file picker
	 */
	handleChooseFile() {
		const fileInput = this.template.querySelector('.file-input-single');
		if (fileInput) {
			fileInput.click();
		}
	}
	
	/**
	 * @description Handle file selection - sets the single attached file
	 */
	handleFileSelected(event) {
		const files = event.target.files;
		if (files && files.length > 0) {
			this._setAttachedFile(files[0]);
		}
		// Reset input for re-selection
		event.target.value = '';
	}
	
	/**
	 * @description Remove the attached image
	 */
	handleRemoveImage() {
		this._clearAttachedFile();
	}
	
	/**
	 * @description Clear the attached file
	 */
	_clearAttachedFile() {
		if (this._attachedFile && this._attachedFile.previewUrl) {
			URL.revokeObjectURL(this._attachedFile.previewUrl);
		}
		this._attachedFile = null;
		this._isProcessingFile = false;
		// Clear Flow outputs
		this.imageCount = 0;
		this.imageBase64 = '';
		this.imageFileName = '';
		this.imageMimeType = '';
		// Clear backwards compatibility outputs
		this.imageData1 = '';
		this.imageFileName1 = '';
		this.imageMimeType1 = '';
	}
	
	/**
	 * @description Set a new attached file (replaces any existing)
	 * @param {File} file - The file to attach
	 */
	_setAttachedFile(file) {
		// Clear any existing file first
		this._clearAttachedFile();
		
		// Validate file size (max 10MB)
		const maxSize = 10 * 1024 * 1024;
		if (file.size > maxSize) {
			this.handleError(`File is too large. Maximum size is 10MB.`);
			return;
		}
		
		// Validate file type
		const validImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
		const validPdfType = 'application/pdf';
		const isImage = validImageTypes.includes(file.type);
		const isPdf = file.type === validPdfType;
		
		if (!isImage && !isPdf) {
			this.handleError(`Invalid file format. Use JPG, PNG, GIF, WebP, or PDF.`);
			return;
		}
		
		// Create preview URL for images
		const previewUrl = isImage ? URL.createObjectURL(file) : null;
		
		// Set processing state
		this._isProcessingFile = true;
		
		// Create file entry
		this._attachedFile = {
			file: file,
			previewUrl: previewUrl,
			fileName: file.name,
			mimeType: file.type,
			size: file.size,
			isImage: isImage,
			isPdf: isPdf,
			base64: null
		};
		
		// For images on mobile, compress before converting to base64
		if (isImage && FORM_FACTOR === 'Small') {
			this._compressAndConvertImage(file);
		} else {
			// Convert to base64 asynchronously (desktop or PDF)
			const reader = new FileReader();
			reader.onload = () => {
				const base64 = reader.result.split(',')[1];
				// Update the file entry with base64
				this._attachedFile = { ...this._attachedFile, base64: base64 };
				this._isProcessingFile = false;
				// Update Flow outputs
				this.imageCount = 1;
				this.imageBase64 = base64;
				this.imageFileName = file.name;
				this.imageMimeType = file.type;
				// Also populate imageData1 for backwards compatibility
				this.imageData1 = base64;
				this.imageFileName1 = file.name;
				this.imageMimeType1 = file.type;
			};
			reader.onerror = () => {
				this._isProcessingFile = false;
				this._clearAttachedFile();
				this.handleError(`Failed to read file.`);
			};
			reader.readAsDataURL(file);
		}
	}
	
	/**
	 * @description Compress image for mobile to avoid flow payload limits
	 * @param {File} file - The image file to compress
	 */
	_compressAndConvertImage(file) {
		const reader = new FileReader();
		reader.onload = (e) => {
			const img = new Image();
			img.onload = () => {
				// Calculate new dimensions (max 1920px width, maintain aspect ratio)
				const maxWidth = 1920;
				const maxHeight = 1920;
				let width = img.width;
				let height = img.height;
				
				if (width > maxWidth || height > maxHeight) {
					const ratio = Math.min(maxWidth / width, maxHeight / height);
					width = Math.floor(width * ratio);
					height = Math.floor(height * ratio);
				}
				
				// Create canvas and compress
				const canvas = document.createElement('canvas');
				canvas.width = width;
				canvas.height = height;
				const ctx = canvas.getContext('2d');
				ctx.drawImage(img, 0, 0, width, height);
				
				// Convert to base64 with quality compression (0.85 for good quality/size balance)
				canvas.toBlob((blob) => {
					const compressedReader = new FileReader();
					compressedReader.onload = () => {
						const base64 = compressedReader.result.split(',')[1];
						// Update the file entry with compressed base64
						this._attachedFile = { ...this._attachedFile, base64: base64 };
						this._isProcessingFile = false;
						// Update Flow outputs
						this.imageCount = 1;
						this.imageBase64 = base64;
						this.imageFileName = file.name;
						this.imageMimeType = 'image/jpeg'; // Always JPEG after compression
						// Also populate imageData1 for backwards compatibility
						this.imageData1 = base64;
						this.imageFileName1 = file.name;
						this.imageMimeType1 = 'image/jpeg';
					};
					compressedReader.onerror = () => {
						this._isProcessingFile = false;
						this._clearAttachedFile();
						this.handleError(`Failed to compress image.`);
					};
					compressedReader.readAsDataURL(blob);
				}, 'image/jpeg', 0.85); // JPEG format with 85% quality
			};
			img.onerror = () => {
				this._isProcessingFile = false;
				this._clearAttachedFile();
				this.handleError(`Failed to load image.`);
			};
			img.src = e.target.result;
		};
		reader.onerror = () => {
			this._isProcessingFile = false;
			this._clearAttachedFile();
			this.handleError(`Failed to read file.`);
		};
		reader.readAsDataURL(file);
	}

	// ==========================================================================
	// FLOW VALIDATION
	// ==========================================================================
	
	/**
	 * @description Validate component for Flow progression
	 *              Called by Flow runtime before allowing navigation
	 *              FLEXIBLE: Allows transcript-only, image-only, or both
	 * @returns {Object} Validation result with isValid flag and errorMessage
	 */
	@api
	validate() {
		// Block navigation while file is being processed
		if (this._isProcessingFile) {
			this.showErrorMessage = true;
			this.error = 'Please wait - file still processing...';
			return {
				isValid: false,
				errorMessage: 'Please wait - file still processing...'
			};
		}
		
		const text = Array.isArray(this.outputText) ? this.outputText.join(' ') : this.outputText;
		const trimmedValue = text ? text.trim() : '';
		const hasTranscript = trimmedValue.length > 0;
		const hasImage = this._attachedFile && this._attachedFile.base64;
		
		// For speech-to-text mode: always require transcript (image is optional enhancement)
		if (this.mode === 'speech-to-text' || (this.mode === 'both' && this.activeTab === 'speech-to-text')) {
			// Transcript is always required - image alone is not enough
			if (!hasTranscript) {
				this.showErrorMessage = true;
				this.error = 'Please record or type something before continuing.';
				return {
					isValid: false,
					errorMessage: 'Please record or type something before continuing.'
				};
			}
		}
		
		// For text-to-speech mode: always require text
		if (this.mode === 'text-to-speech' || (this.mode === 'both' && this.activeTab === 'text-to-speech')) {
			if (!hasTranscript) {
				this.showErrorMessage = true;
				this.error = 'Please enter text to convert to speech.';
				return {
					isValid: false,
					errorMessage: 'Please enter text to convert to speech.'
				};
			}
		}
        
		this.showErrorMessage = false;
		this.error = null;
		return {
			isValid: true
		};
	}
}