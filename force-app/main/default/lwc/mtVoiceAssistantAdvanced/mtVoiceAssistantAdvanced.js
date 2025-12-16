/*
================================================================================
MT VOICE ASSISTANT ADVANCED - Lightning Web Component
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 2.0

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccessToken from '@salesforce/apex/mt_TranscribeController.getAccessToken';
import getBaseUrl from '@salesforce/apex/mt_TranscribeController.getBaseUrl';
// New API feature imports
import discoverVoices from '@salesforce/apex/mt_TranscribeController.discoverVoices';
import synthesizeSpeechV2 from '@salesforce/apex/mt_TranscribeController.synthesizeSpeechV2';
import transcribeV2 from '@salesforce/apex/mt_TranscribeController.transcribeV2';
import createTranscriptionJob from '@salesforce/apex/mt_TranscribeController.createTranscriptionJob';
import getTranscriptionJobStatus from '@salesforce/apex/mt_TranscribeController.getTranscriptionJobStatus';
import translateText from '@salesforce/apex/mt_TranscribeController.translateText';
import translateDocument from '@salesforce/apex/mt_TranscribeController.translateDocument';
import importTerminology from '@salesforce/apex/mt_TranscribeController.importTerminology';
import getTerminology from '@salesforce/apex/mt_TranscribeController.getTerminology';
import deleteTerminology from '@salesforce/apex/mt_TranscribeController.deleteTerminology';
import deleteAllTerminologies from '@salesforce/apex/mt_TranscribeController.deleteAllTerminologies';

export default class MtVoiceAssistantAdvanced extends LightningElement {
    // ==========================================================================
    // COMPONENT STATE
    // ==========================================================================
    
    @track activeFeature = 'voice-discovery'; // Default feature tab
    @track isLoading = false;
    @track error = null;
    @track successMessage = null;
    
    BASE_API_URL;
    
    // Voice Discovery
    @track voices = [];
    @track voiceProviders = [];
    @track selectedEngine = '';
    @track voiceFilter = '';
    
    // Enhanced TTS v2
    @track ttsText = '';
    @track selectedVoiceId = '';
    @track voiceSettings = {
        stability: 0.5,
        similarityBoost: 0.8,
        style: 0.0,
        speed: 1.0,
        useSpeakerBoost: false
    };
    @track ttsEngine = 'aws';
    @track ttsOutputFormat = 'mp3_44100_128';
    @track ttsAudioSrc = '';
    
    // Transcription v2 with Diarization
    @track transcriptionAudioBlob = null;
    @track transcriptionResult = null;
    @track transcriptionSegments = [];
    @track diarizationEnabled = false;
    @track transcriptionEngine = 'aws';
    @track transcriptionLanguage = 'en-US';
    
    // Async Transcription Jobs
    @track jobAudioBlob = null;
    @track currentJobId = null;
    @track jobStatus = null;
    @track jobPollingInterval = null;
    @track jobEngine = 'aws';
    @track jobLanguage = 'en-US';
    
    // Translation
    @track translationText = '';
    @track translationSourceLang = 'auto';
    @track translationTargetLang = 'es';
    @track translationResult = null;
    @track translationDocumentBlob = null;
    @track translationDocumentResult = null;
    
    // Terminology Management
    @track terminologyFileBlob = null;
    @track terminologyName = '';
    @track terminologyEngine = 'aws';
    @track terminologyList = [];
    @track selectedTerminology = null;
    @track terminologyTerms = [];
    
    // ==========================================================================
    // LIFECYCLE HOOKS
    // ==========================================================================
    
    connectedCallback() {
        this.initializeBaseUrl();
        this.loadVoices();
    }
    
    disconnectedCallback() {
        if (this.jobPollingInterval) {
            clearInterval(this.jobPollingInterval);
        }
    }
    
    // ==========================================================================
    // INITIALIZATION
    // ==========================================================================
    
    async initializeBaseUrl() {
        try {
            this.BASE_API_URL = await getBaseUrl();
        } catch (error) {
            this.showError('Failed to initialize API URL: ' + error.message);
        }
    }
    
    // ==========================================================================
    // FEATURE NAVIGATION
    // ==========================================================================
    
    handleFeatureChange(event) {
        this.activeFeature = event.detail.value;
        this.error = null;
        this.successMessage = null;
        
        // Load voices when switching to voice discovery or TTS
        if (this.activeFeature === 'voice-discovery' || this.activeFeature === 'tts-v2') {
            this.loadVoices();
        }
    }
    
    // ==========================================================================
    // VOICE DISCOVERY
    // ==========================================================================
    
    async loadVoices() {
        this.isLoading = true;
        this.error = null;
        
        try {
            const result = await discoverVoices({ engine: this.selectedEngine || '' });
            
            if (result.success) {
                this.voices = result.voices || [];
                this.voiceProviders = result.providers || [];
                this.showSuccess(`Loaded ${result.totalCount || 0} voices`);
            } else {
                this.showError(result.errorMessage || 'Failed to load voices');
            }
        } catch (error) {
            this.showError('Error loading voices: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleEngineFilterChange(event) {
        this.selectedEngine = event.detail.value;
        this.loadVoices();
    }
    
    handleVoiceFilterChange(event) {
        this.voiceFilter = event.detail.value.toLowerCase();
    }
    
    get filteredVoices() {
        if (!this.voiceFilter) return this.voices;
        return this.voices.filter(voice => {
            const name = (voice.name || '').toLowerCase();
            const language = (voice.language || '').toLowerCase();
            const provider = (voice.provider || '').toLowerCase();
            return name.includes(this.voiceFilter) || 
                   language.includes(this.voiceFilter) || 
                   provider.includes(this.voiceFilter);
        });
    }
    
    get hasFilteredVoices() {
        return this.filteredVoices && this.filteredVoices.length > 0;
    }
    
    get voiceOptions() {
        return this.filteredVoices.map(voice => ({
            label: `${voice.name} (${voice.language}) - ${voice.provider}`,
            value: voice.voice_id
        }));
    }
    
    // ==========================================================================
    // ENHANCED TTS v2
    // ==========================================================================
    
    handleTTSVoiceChange(event) {
        this.selectedVoiceId = event.detail.value;
    }
    
    handleTTSEngineChange(event) {
        this.ttsEngine = event.detail.value;
    }
    
    handleVoiceSettingChange(event) {
        const field = event.target.dataset.field;
        let value;
        
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = parseFloat(event.target.value);
        }
        
        if (field && (value !== undefined && value !== null)) {
            this.voiceSettings = { ...this.voiceSettings, [field]: value };
        }
    }
    
    handleTTSOutputFormatChange(event) {
        this.ttsOutputFormat = event.detail.value;
    }
    
    async handleSynthesizeSpeech() {
        if (!this.ttsText.trim()) {
            this.showError('Please enter text to synthesize');
            return;
        }
        
        if (!this.selectedVoiceId) {
            this.showError('Please select a voice');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        this.ttsAudioSrc = '';
        
        try {
            // Convert text to base64
            const textBase64 = btoa(unescape(encodeURIComponent(this.ttsText)));
            
            // Build request JSON
            const requestJson = JSON.stringify({
                engine: this.ttsEngine,
                voice_id: this.selectedVoiceId,
                voice_settings: this.voiceSettings,
                output_format: this.ttsOutputFormat
            });
            
            const result = await synthesizeSpeechV2({
                textBase64: textBase64,
                requestJson: requestJson
            });
            
            if (result.success && result.audioContent) {
                // Convert base64 to blob URL
                const byteArray = Uint8Array.from(
                    atob(result.audioContent),
                    c => c.charCodeAt(0)
                );
                const blob = new Blob([byteArray], { type: result.contentType || 'audio/mp3' });
                this.ttsAudioSrc = URL.createObjectURL(blob);
                this.showSuccess(`Synthesized ${result.requestCharacters || 0} characters`);
            } else {
                this.showError(result.errorMessage || 'Failed to synthesize speech');
            }
        } catch (error) {
            this.showError('Error synthesizing speech: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    // ==========================================================================
    // TRANSCRIPTION v2 WITH DIARIZATION
    // ==========================================================================
    
    handleTranscriptionFileChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.transcriptionAudioBlob = files[0];
            this.showSuccess(`Audio file selected: ${files[0].name}`);
        }
    }
    
    handleDiarizationToggle(event) {
        this.diarizationEnabled = event.target.checked;
    }
    
    handleTranscriptionEngineChange(event) {
        this.transcriptionEngine = event.detail.value;
    }
    
    handleTranscriptionLanguageChange(event) {
        this.transcriptionLanguage = event.detail.value;
    }
    
    async handleTranscribeV2() {
        if (!this.transcriptionAudioBlob) {
            this.showError('Please select an audio file');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        this.transcriptionResult = null;
        this.transcriptionSegments = [];
        
        try {
            // Convert file to base64
            const audioBase64 = await this.blobToBase64(this.transcriptionAudioBlob);
            
            // Build request JSON
            const requestJson = JSON.stringify({
                engine: this.transcriptionEngine,
                language: this.transcriptionLanguage,
                diarization_enabled: this.diarizationEnabled
            });
            
            const result = await transcribeV2({
                audioBase64: audioBase64,
                requestJson: requestJson
            });
            
            if (result.success) {
                this.transcriptionResult = result.transcript;
                this.transcriptionSegments = result.segments || [];
                this.showSuccess('Transcription completed successfully');
            } else {
                this.showError(result.errorMessage || 'Failed to transcribe audio');
            }
        } catch (error) {
            this.showError('Error transcribing audio: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    // ==========================================================================
    // ASYNC TRANSCRIPTION JOBS
    // ==========================================================================
    
    handleJobFileChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.jobAudioBlob = files[0];
            this.showSuccess(`Audio file selected: ${files[0].name}`);
        }
    }
    
    handleJobEngineChange(event) {
        this.jobEngine = event.detail.value;
    }
    
    handleJobLanguageChange(event) {
        this.jobLanguage = event.detail.value;
    }
    
    async handleCreateJob() {
        if (!this.jobAudioBlob) {
            this.showError('Please select an audio file');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        
        try {
            // Convert file to base64
            const audioBase64 = await this.blobToBase64(this.jobAudioBlob);
            
            // Build request JSON
            const requestJson = JSON.stringify({
                engine: this.jobEngine,
                language: this.jobLanguage
            });
            
            const result = await createTranscriptionJob({
                audioBase64: audioBase64,
                requestJson: requestJson
            });
            
            if (result.success && result.jobId) {
                this.currentJobId = result.jobId;
                this.showSuccess(`Job created: ${result.jobId}`);
                this.startJobPolling();
            } else {
                this.showError(result.errorMessage || 'Failed to create job');
            }
        } catch (error) {
            this.showError('Error creating job: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    async startJobPolling() {
        if (!this.currentJobId) return;
        
        // Poll immediately
        await this.checkJobStatus();
        
        // Then poll every 5 seconds
        this.jobPollingInterval = setInterval(async () => {
            await this.checkJobStatus();
        }, 5000);
    }
    
    async checkJobStatus() {
        if (!this.currentJobId) return;
        
        try {
            const result = await getTranscriptionJobStatus({ jobId: this.currentJobId || '' });
            
            if (result.success) {
                this.jobStatus = result.status;
                
                if (result.status === 'COMPLETED') {
                    if (this.jobPollingInterval) {
                        clearInterval(this.jobPollingInterval);
                        this.jobPollingInterval = null;
                    }
                    this.transcriptionResult = result.transcript;
                    this.showSuccess('Job completed successfully');
                } else if (result.status === 'FAILED') {
                    if (this.jobPollingInterval) {
                        clearInterval(this.jobPollingInterval);
                        this.jobPollingInterval = null;
                    }
                    this.showError(result.errorMessage || 'Job failed');
                }
            }
        } catch (error) {
            console.error('Error checking job status:', error);
        }
    }
    
    // ==========================================================================
    // TRANSLATION
    // ==========================================================================
    
    handleTranslationTextChange(event) {
        this.translationText = event.detail.value;
    }
    
    handleTTSTextChange(event) {
        this.ttsText = event.detail.value;
    }
    
    handleSourceLangChange(event) {
        this.translationSourceLang = event.detail.value;
    }
    
    handleTargetLangChange(event) {
        this.translationTargetLang = event.detail.value;
    }
    
    async handleTranslateText() {
        if (!this.translationText.trim()) {
            this.showError('Please enter text to translate');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        this.translationResult = null;
        
        try {
            // Build request JSON
            const requestJson = JSON.stringify({
                text: this.translationText,
                source_language: this.translationSourceLang,
                target_language: this.translationTargetLang
            });
            
            const result = await translateText({ requestJson: requestJson });
            
            if (result.success) {
                this.translationResult = result.translatedText;
                this.showSuccess(`Translated from ${result.sourceLanguageCode} to ${result.targetLanguageCode}`);
            } else {
                this.showError(result.errorMessage || 'Failed to translate text');
            }
        } catch (error) {
            this.showError('Error translating text: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleTranslationDocumentChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.translationDocumentBlob = files[0];
            this.showSuccess(`Document selected: ${files[0].name}`);
        }
    }
    
    async handleTranslateDocument() {
        if (!this.translationDocumentBlob) {
            this.showError('Please select a document to translate');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        this.translationDocumentResult = null;
        
        try {
            // Convert file to base64
            const documentBase64 = await this.blobToBase64(this.translationDocumentBlob);
            
            // Build request JSON
            const requestJson = JSON.stringify({
                source_language: this.translationSourceLang,
                target_language: this.translationTargetLang,
                content_type: this.translationDocumentBlob.type
            });
            
            const result = await translateDocument({
                documentBase64: documentBase64,
                requestJson: requestJson
            });
            
            if (result.success && result.translatedDocument) {
                this.translationDocumentResult = result.translatedDocument;
                this.showSuccess('Document translated successfully');
            } else {
                this.showError(result.errorMessage || 'Failed to translate document');
            }
        } catch (error) {
            this.showError('Error translating document: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleDownloadTranslatedDocument() {
        if (!this.translationDocumentResult) return;
        
        const byteArray = Uint8Array.from(
            atob(this.translationDocumentResult),
            c => c.charCodeAt(0)
        );
        const blob = new Blob([byteArray], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'translated_document';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }
    
    // ==========================================================================
    // TERMINOLOGY MANAGEMENT
    // ==========================================================================
    
    handleTerminologyFileChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.terminologyFileBlob = files[0];
            this.showSuccess(`Terminology file selected: ${files[0].name}`);
        }
    }
    
    handleTerminologyNameChange(event) {
        this.terminologyName = event.target.value;
    }
    
    handleTerminologyEngineChange(event) {
        this.terminologyEngine = event.detail.value;
    }
    
    async handleImportTerminology() {
        if (!this.terminologyFileBlob) {
            this.showError('Please select a terminology file');
            return;
        }
        
        if (!this.terminologyName.trim()) {
            this.showError('Please enter a terminology name');
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        
        try {
            // Convert file to base64
            const fileBase64 = await this.blobToBase64(this.terminologyFileBlob);
            
            const result = await importTerminology({
                fileBase64: fileBase64,
                name: this.terminologyName,
                engine: this.terminologyEngine
            });
            
            if (result.success) {
                this.showSuccess(`Terminology "${result.name}" imported successfully`);
                this.terminologyName = '';
                this.terminologyFileBlob = null;
                this.loadTerminologyList();
            } else {
                this.showError(result.errorMessage || 'Failed to import terminology');
            }
        } catch (error) {
            this.showError('Error importing terminology: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    async loadTerminologyList() {
        // This would require a list endpoint - for now, we'll use getTerminology
        // In a real implementation, you might want to maintain a list manually
        this.terminologyList = [];
    }
    
    handleTerminologySelect(event) {
        this.selectedTerminology = event.detail.value;
        if (this.selectedTerminology) {
            this.loadTerminology();
        }
    }
    
    async loadTerminology() {
        if (!this.selectedTerminology) return;
        
        this.isLoading = true;
        this.error = null;
        
        try {
            const result = await getTerminology({
                name: this.selectedTerminology || '',
                engine: this.terminologyEngine
            });
            
            if (result.success) {
                this.terminologyTerms = result.terms || [];
                this.showSuccess(`Loaded terminology: ${result.name}`);
            } else {
                this.showError(result.errorMessage || 'Failed to load terminology');
            }
        } catch (error) {
            this.showError('Error loading terminology: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleDeleteTerminology() {
        if (!this.selectedTerminology) {
            this.showError('Please select a terminology to delete');
            return;
        }
        
        if (!confirm(`Are you sure you want to delete "${this.selectedTerminology}"?`)) {
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        
        try {
            const result = await deleteTerminology({
                name: this.selectedTerminology || '',
                engine: this.terminologyEngine
            });
            
            if (result.success) {
                this.showSuccess('Terminology deleted successfully');
                this.selectedTerminology = null;
                this.terminologyTerms = [];
                this.loadTerminologyList();
            } else {
                this.showError(result.errorMessage || 'Failed to delete terminology');
            }
        } catch (error) {
            this.showError('Error deleting terminology: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleDeleteAllTerminologies() {
        if (!confirm('Are you sure you want to delete ALL terminologies? This cannot be undone.')) {
            return;
        }
        
        this.isLoading = true;
        this.error = null;
        
        try {
            const result = await deleteAllTerminologies({ engine: this.terminologyEngine || '' });
            
            if (result.success) {
                this.showSuccess('All terminologies deleted successfully');
                this.selectedTerminology = null;
                this.terminologyTerms = [];
                this.loadTerminologyList();
            } else {
                this.showError(result.errorMessage || 'Failed to delete terminologies');
            }
        } catch (error) {
            this.showError('Error deleting terminologies: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    // ==========================================================================
    // HELPER METHODS
    // ==========================================================================
    
    blobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }
    
    showError(message) {
        this.error = message;
        this.successMessage = null;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }
    
    showSuccess(message) {
        this.successMessage = message;
        this.error = null;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }
    
    // ==========================================================================
    // GETTERS
    // ==========================================================================
    
    get featureOptions() {
        return [
            { label: 'Voice Discovery', value: 'voice-discovery', icon: 'utility:user' },
            { label: 'Enhanced TTS v2', value: 'tts-v2', icon: 'utility:volume_high' },
            { label: 'Transcription v2 (Diarization)', value: 'transcription-v2', icon: 'utility:mic' },
            { label: 'Async Transcription Jobs', value: 'async-jobs', icon: 'utility:clock' },
            { label: 'Text Translation', value: 'translation', icon: 'utility:translate' },
            { label: 'Document Translation', value: 'document-translation', icon: 'utility:file' },
            { label: 'Terminology Management', value: 'terminology', icon: 'utility:bookmark' }
        ];
    }
    
    get languageOptions() {
        return [
            { label: 'English (US)', value: 'en-US' },
            { label: 'English (UK)', value: 'en-GB' },
            { label: 'Spanish (US)', value: 'es-US' },
            { label: 'Spanish (Spain)', value: 'es-ES' },
            { label: 'French (France)', value: 'fr-FR' },
            { label: 'German', value: 'de-DE' },
            { label: 'Japanese', value: 'ja-JP' },
            { label: 'Chinese (Simplified)', value: 'zh-CN' },
            { label: 'Auto-detect', value: 'auto' }
        ];
    }
    
    get engineOptions() {
        return [
            { label: 'AWS', value: 'aws' },
            { label: 'ElevenLabs', value: 'elevenlabs' },
            { label: 'Internal', value: 'internal' }
        ];
    }
    
    get ttsOutputFormatOptions() {
        return [
            { label: 'MP3 44.1kHz 128kbps', value: 'mp3_44100_128' },
            { label: 'MP3 24kHz', value: 'mp3_24000' },
            { label: 'PCM 24kHz', value: 'pcm_24000' },
            { label: 'PCM 16kHz', value: 'pcm_16000' },
            { label: 'PCM 8kHz', value: 'pcm_8000' }
        ];
    }
    
    get hasTranscriptionSegments() {
        return this.transcriptionSegments && this.transcriptionSegments.length > 0;
    }
    
    get isJobInProgress() {
        return this.jobStatus === 'SUBMITTED' || this.jobStatus === 'IN_PROGRESS';
    }
    
    get isJobCompleted() {
        return this.jobStatus === 'COMPLETED';
    }
    
    get isJobFailed() {
        return this.jobStatus === 'FAILED';
    }
    
    get isLoadTerminologyDisabled() {
        return !this.selectedTerminology || this.isLoading;
    }
    
    get isDeleteTerminologyDisabled() {
        return !this.selectedTerminology || this.isLoading;
    }
    
    get hasTerminologyTerms() {
        return this.terminologyTerms && this.terminologyTerms.length > 0;
    }
}

