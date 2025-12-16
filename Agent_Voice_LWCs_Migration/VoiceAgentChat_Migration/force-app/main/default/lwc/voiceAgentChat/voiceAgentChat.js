import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AGENTFORCE_ICON from '@salesforce/resourceUrl/agentforce_icon';
import getAccessToken from '@salesforce/apex/TTSService.getAccessToken';
import getAllAgents from '@salesforce/apex/AgentChatService.getAllAgents';
import createSession from '@salesforce/apex/AgentChatService.createSession';
import sendMessage from '@salesforce/apex/AgentChatService.sendMessage';
import endSession from '@salesforce/apex/AgentChatService.endSession';

export default class VoiceAgentChat extends LightningElement {
    // ========== AGENT STATE ==========
    @track agents = [];
    @track selectedAgentId = null;
    @track selectedAgentName = 'Select an Agent';
    @track sessionId = null;
    @track sequenceId = 0;
    @track isLoadingAgents = false;
    showAgentList = false;
    
    // ========== CONNECTION STATE ==========
    connected = false;
    isConnecting = false;
    isMuted = false;
    statusText = 'Select an agent to start';
    statusDetail = '';
    errorMessage = '';
    
    // ========== SPEECH STATE ==========
    isTalking = false;
    currentState = 'idle'; // idle, listening, speaking, connected
    micLevel = 0;
    speakerLevel = 0;
    initialized = false;
    micAnalyser = null;
    speakerAnalyser = null;
    
    // ========== STT SETTINGS ==========
    @track sttEngine = 'deepgram_falcon';
    @track sttModel = 'nova-2-phonecall';
    @track sttLanguage = 'en-US';
    @track sttSmartFormat = true;
    @track sttProfanityFilter = false;
    @track sttUtteranceEndEnabled = false;
    @track sttUtteranceEndMs = '1000';
    @track sttKeywords = '';
    sttWebsocket = null;
    sttAccessToken = null;
    mediaStream = null;
    audioContext = null;
    scriptProcessor = null;
    currentTranscript = '';
    
    // ========== TTS SETTINGS ==========
    @track ttsEngine = 'elevenlabs';
    @track ttsVoice = 'JBFqnCBsd6RMkjVDRZzb'; // George
    @track ttsLanguageCode = 'en';
    @track ttsStability = '0.50';
    @track ttsSimilarityBoost = '0.75';
    @track ttsStyle = '0.00';
    @track ttsSpeed = '1.00';
    @track ttsUseSpeakerBoost = false;
    @track ttsEnableSsml = false;
    @track ttsTextNormalization = 'on';
    ttsWebsocket = null;
    ttsAccessToken = null;
    audioQueue = [];
    nextStartTime = 0;
    isPlayingTTS = false;
    ttsSynthesisComplete = false; // Track when synthesis is done (but audio may still be playing)
    audioChunksPlaying = 0; // Track number of audio chunks currently playing
    speakerLevelCheckInterval = null; // Monitor speaker level to detect true end of audio
    hasStartedSpeakerMonitoring = false; // Track if we've started monitoring for this synthesis
    
    // ========== UI STATE ==========
    @track showSettings = false;
    @track showConversation = true;
    @track conversationMessages = [];
    interimMessage = null;
    
    // ========== KEEP-ALIVE ==========
    sttKeepAliveInterval = null;
    ttsKeepAliveInterval = null;
    
    // Track if we're actively using the connections
    isSendingAudio = false;
    
    // ========== STT CONFIGURATION ==========
    sttConfig = {
        deepgram_falcon: {
            name: 'Deepgram Falcon',
            models: {
                'nova-2-phonecall': {
                    description: 'Phone calls',
                    languages: ['en-US', 'en-GB', 'en-AU']
                },
                'nova-3': {
                    description: 'Multilingual',
                    languages: ['multi']
                }
            }
        },
        deepgram_remote: {
            name: 'Deepgram Remote',
            models: {
                'nova-3': {
                    description: 'Multilingual',
                    languages: ['multi']
                },
                'nova-3-general': {
                    description: 'General English',
                    languages: ['en-US', 'en-GB', 'en-AU']
                },
                'nova-3-medical': {
                    description: 'Medical terminology',
                    languages: ['en-US', 'en-GB', 'en-AU']
                },
                'nova-2-general': {
                    description: 'General English (legacy)',
                    languages: ['en-US', 'en-GB', 'en-AU']
                }
            }
        },
        aws: {
            name: 'AWS Transcribe',
            models: null,
            languages: ['en-US', 'en-GB', 'es-US', 'fr-FR', 'de-DE', 'multi']
        }
    };
    
    languageNames = {
        'en-US': '🇺🇸 English (US)',
        'en-GB': '🇬🇧 English (UK)',
        'en-AU': '🇦🇺 English (AU)',
        'es-US': '🇺🇸 Spanish (US)',
        'fr-FR': '🇫🇷 French',
        'de-DE': '🇩🇪 German',
        'multi': '🌍 Multi-language'
    };
    
    // localStorage key for persisting settings
    SETTINGS_STORAGE_KEY = 'voiceAgentChat_settings';
    
    // ========== LIFECYCLE ==========
    connectedCallback() {
        this.loadSettingsFromStorage();
        this.loadAgents();
        this.startWaveformAnimation();
    }
    
    disconnectedCallback() {
        this.fullDisconnect();
    }
    
    // Load settings from localStorage
    loadSettingsFromStorage() {
        try {
            const stored = localStorage.getItem(this.SETTINGS_STORAGE_KEY);
            console.log('📥 RAW stored string:', stored);
            if (stored) {
                const settings = JSON.parse(stored);
                console.log('📥 Parsed settings object:', JSON.stringify(settings, null, 2));
                
                // Restore STT settings
                this.sttEngine = settings.sttEngine || 'deepgram_falcon';
                
                // Validate STT model coherence with engine
                const engineConfig = this.sttConfig[this.sttEngine];
                if (engineConfig && engineConfig.models) {
                    const validModels = Object.keys(engineConfig.models);
                    const isModelValid = settings.sttModel && validModels.includes(settings.sttModel);
                    
                    if (isModelValid) {
                        this.sttModel = settings.sttModel;
                    } else {
                        this.sttModel = validModels[0];
                        console.warn(`⚠️ Model "${settings.sttModel}" not valid for engine "${this.sttEngine}", reset to: ${this.sttModel}`);
                    }
                    
                    // Validate language for the selected model
                    const modelConfig = engineConfig.models[this.sttModel];
                    if (modelConfig && modelConfig.languages) {
                        const isLanguageValid = settings.sttLanguage && modelConfig.languages.includes(settings.sttLanguage);
                        
                        if (isLanguageValid) {
                            this.sttLanguage = settings.sttLanguage;
                        } else {
                            this.sttLanguage = modelConfig.languages[0];
                            console.warn(`⚠️ Language "${settings.sttLanguage}" not valid for model "${this.sttModel}", reset to: ${this.sttLanguage}`);
                        }
                    }
                } else if (engineConfig && engineConfig.languages) {
                    // Engine has languages but no models (like AWS)
                    this.sttModel = null;
                    const isLanguageValid = settings.sttLanguage && engineConfig.languages.includes(settings.sttLanguage);
                    
                    if (isLanguageValid) {
                        this.sttLanguage = settings.sttLanguage;
                    } else {
                        this.sttLanguage = engineConfig.languages[0];
                        console.warn(`⚠️ Language "${settings.sttLanguage}" not valid for engine "${this.sttEngine}", reset to: ${this.sttLanguage}`);
                    }
                }
                
                this.sttSmartFormat = settings.sttSmartFormat !== undefined ? settings.sttSmartFormat : true;
                this.sttProfanityFilter = settings.sttProfanityFilter !== undefined ? settings.sttProfanityFilter : false;
                this.sttUtteranceEndEnabled = settings.sttUtteranceEndEnabled || false;
                this.sttUtteranceEndMs = settings.sttUtteranceEndMs || '1000';
                this.sttKeywords = settings.sttKeywords || '';
                
                // Restore TTS settings
                this.ttsEngine = settings.ttsEngine || 'elevenlabs';
                
                // Validate voice coherence with engine
                const voiceOptions = this.getVoiceOptionsForEngine(this.ttsEngine);
                const isVoiceValid = voiceOptions.some(opt => opt.value === settings.ttsVoice);
                
                if (isVoiceValid) {
                    this.ttsVoice = settings.ttsVoice;
                } else {
                    // Reset to first valid voice for this engine
                    this.ttsVoice = voiceOptions[0].value;
                    console.warn(`⚠️ Voice "${settings.ttsVoice}" not valid for engine "${this.ttsEngine}", reset to: ${this.ttsVoice}`);
                }
                
                this.ttsLanguageCode = settings.ttsLanguageCode || 'en';
                this.ttsStability = settings.ttsStability || '0.50';
                this.ttsSimilarityBoost = settings.ttsSimilarityBoost || '0.75';
                this.ttsStyle = settings.ttsStyle || '0.00';
                this.ttsSpeed = settings.ttsSpeed || '1.00';
                this.ttsUseSpeakerBoost = settings.ttsUseSpeakerBoost !== undefined ? settings.ttsUseSpeakerBoost : false;
                this.ttsEnableSsml = settings.ttsEnableSsml !== undefined ? settings.ttsEnableSsml : false;
                this.ttsTextNormalization = settings.ttsTextNormalization || 'on';
                
                console.log('✅ Settings restored to component properties:', JSON.stringify({
                    sttEngine: this.sttEngine,
                    sttModel: this.sttModel,
                    sttLanguage: this.sttLanguage,
                    sttSmartFormat: this.sttSmartFormat,
                    sttProfanityFilter: this.sttProfanityFilter,
                    sttUtteranceEndEnabled: this.sttUtteranceEndEnabled,
                    sttUtteranceEndMs: this.sttUtteranceEndMs,
                    sttKeywords: this.sttKeywords,
                    ttsEngine: this.ttsEngine,
                    ttsVoice: this.ttsVoice,
                    ttsLanguageCode: this.ttsLanguageCode,
                    ttsStability: this.ttsStability,
                    ttsSimilarityBoost: this.ttsSimilarityBoost,
                    ttsStyle: this.ttsStyle,
                    ttsSpeed: this.ttsSpeed,
                    ttsUseSpeakerBoost: this.ttsUseSpeakerBoost,
                    ttsEnableSsml: this.ttsEnableSsml,
                    ttsTextNormalization: this.ttsTextNormalization
                }, null, 2));
            } else {
                console.log('ℹ️ No saved settings found, using defaults');
            }
        } catch (error) {
            console.error('❌ Error loading settings from localStorage:', error);
        }
    }
    
    // Helper to get voice options for a specific engine
    getVoiceOptionsForEngine(engine) {
        const voices = engine === 'elevenlabs' ? [
            { label: 'George (Warm, authoritative)', value: 'JBFqnCBsd6RMkjVDRZzb' },
            { label: 'Aria (Friendly, energetic)', value: '9BWtsMINqrJLrRacOk9x' },
            { label: 'Roger (Confident, clear)', value: 'CwhRBWXzGAHq8TQ4Fs17' },
            { label: 'Sarah (Professional, calm)', value: 'EXAVITQu4vr4xnSDxMaL' },
            { label: 'Laura (Soothing, elegant)', value: 'FGY2WhTYpPnrIDTdsKH5' },
            { label: 'Charlie (Casual, upbeat)', value: 'IKne3meq5aSn9XLyUdCD' },
            { label: 'Callum (Conversational)', value: 'N2lVS1w4EtoT3dr4eOWO' },
            { label: 'Liam (Dynamic, engaging)', value: 'TX3LPaxmHKxFdv7VOQHJ' },
            { label: 'Charlotte (British, refined)', value: 'XB0fDUnXU5powFXDhCwa' },
            { label: 'Alice (Young, bright)', value: 'Xb7hH8MSUJpSbSDYk0k2' }
        ] : [
            { label: 'Joanna (US Female)', value: 'Joanna' },
            { label: 'Matthew (US Male)', value: 'Matthew' },
            { label: 'Ivy (US Child)', value: 'Ivy' },
            { label: 'Justin (US Male)', value: 'Justin' },
            { label: 'Kendra (US Female)', value: 'Kendra' },
            { label: 'Kevin (US Male Child)', value: 'Kevin' },
            { label: 'Salli (US Female)', value: 'Salli' },
            { label: 'Kimberly (US Female)', value: 'Kimberly' },
            { label: 'Joey (US Male)', value: 'Joey' },
            { label: 'Ruth (US Female)', value: 'Ruth' }
        ];
        
        // Add selected property to each voice option
        return voices.map(voice => ({
            ...voice,
            selected: this.ttsVoice === voice.value
        }));
    }
    
    // Save settings to localStorage
    saveSettingsToStorage() {
        try {
            const settings = {
                // STT Settings
                sttEngine: this.sttEngine,
                sttModel: this.sttModel,
                sttLanguage: this.sttLanguage,
                sttSmartFormat: this.sttSmartFormat,
                sttProfanityFilter: this.sttProfanityFilter,
                sttUtteranceEndEnabled: this.sttUtteranceEndEnabled,
                sttUtteranceEndMs: this.sttUtteranceEndMs,
                sttKeywords: this.sttKeywords,
                // TTS Settings
                ttsEngine: this.ttsEngine,
                ttsVoice: this.ttsVoice,
                ttsLanguageCode: this.ttsLanguageCode,
                ttsStability: this.ttsStability,
                ttsSimilarityBoost: this.ttsSimilarityBoost,
                ttsStyle: this.ttsStyle,
                ttsSpeed: this.ttsSpeed,
                ttsUseSpeakerBoost: this.ttsUseSpeakerBoost,
                ttsEnableSsml: this.ttsEnableSsml,
                ttsTextNormalization: this.ttsTextNormalization
            };
            console.log('💾 Current component properties before saving:', JSON.stringify({
                sttEngine: this.sttEngine,
                sttModel: this.sttModel,
                sttLanguage: this.sttLanguage,
                ttsEngine: this.ttsEngine,
                ttsVoice: this.ttsVoice
            }, null, 2));
            
            const settingsString = JSON.stringify(settings);
            localStorage.setItem(this.SETTINGS_STORAGE_KEY, settingsString);
            console.log('💾 Settings saved to localStorage as string:', settingsString);
        } catch (error) {
            console.error('❌ Error saving settings to localStorage:', error);
        }
    }
    
    // ========== COMPUTED PROPERTIES ==========
    get displayAgentName() {
        return this.selectedAgentName || 'Select an Agent';
    }
    
    get agentforceIconUrl() {
        return AGENTFORCE_ICON;
    }
    
    get connectButtonLabel() {
        if (this.isConnecting) return 'Connecting...';
        return this.connected ? 'Disconnect' : 'Connect';
    }
    
    get connectButtonClass() {
        if (this.isConnecting) return 'btn-connect connecting';
        return this.connected ? 'btn-disconnect' : 'btn-connect';
    }
    
    get muteButtonClass() {
        return this.isMuted ? 'btn-mute muted' : 'btn-mute';
    }
    
    get muteButtonTitle() {
        return this.isMuted ? 'Unmute microphone' : 'Mute microphone';
    }
    
    get muteIconName() {
        return this.isMuted ? 'utility:unmuted' : 'utility:muted';
    }
    
    get agentListClass() {
        return this.showAgentList ? 'agent-list-container show' : 'agent-list-container';
    }
    
    get displayMessages() {
        const messages = [...this.conversationMessages];
        if (this.interimMessage) {
            messages.push(this.interimMessage);
        }
        return messages.slice(-3); // Last 3 messages
    }
    
    get isElevenLabs() {
        const result = this.ttsEngine === 'elevenlabs';
        console.log(`🔍 isElevenLabs getter called: ttsEngine="${this.ttsEngine}" => ${result}`);
        return result;
    }
    
    get isAwsPolly() {
        const result = this.ttsEngine === 'aws';
        console.log(`🔍 isAwsPolly getter called: ttsEngine="${this.ttsEngine}" => ${result}`);
        return result;
    }
    
    get isSttDeepgramFalcon() {
        return this.sttEngine === 'deepgram_falcon';
    }
    
    get isSttDeepgramRemote() {
        return this.sttEngine === 'deepgram_remote';
    }
    
    get isSttAws() {
        return this.sttEngine === 'aws';
    }
    
    get showSttModel() {
        const engineConfig = this.sttConfig[this.sttEngine];
        return engineConfig && engineConfig.models !== null;
    }
    
    get showSttSmartFormat() {
        return this.sttEngine !== 'aws';
    }
    
    get showSttUtteranceEnd() {
        return this.sttEngine !== 'aws';
    }
    
    get showSttKeywords() {
        return this.sttEngine === 'deepgram_falcon';
    }
    
    get sttModelOptions() {
        const engineConfig = this.sttConfig[this.sttEngine];
        if (!engineConfig || !engineConfig.models) return [];
        return Object.keys(engineConfig.models).map(key => ({
            label: `${key} - ${engineConfig.models[key].description}`,
            value: key,
            selected: this.sttModel === key
        }));
    }
    
    get sttLanguageOptions() {
        const engineConfig = this.sttConfig[this.sttEngine];
        if (!engineConfig) return [];
        
        let languages = [];
        if (engineConfig.models && this.sttModel) {
            const modelConfig = engineConfig.models[this.sttModel];
            languages = modelConfig ? modelConfig.languages : [];
        } else {
            languages = engineConfig.languages || [];
        }
        
        return languages.map(lang => ({
            label: this.languageNames[lang] || lang,
            value: lang,
            selected: this.sttLanguage === lang
        }));
    }
    
    get ttsVoiceOptions() {
        const options = this.getVoiceOptionsForEngine(this.ttsEngine);
        console.log(`🔍 ttsVoiceOptions getter called: ttsEngine="${this.ttsEngine}", returning ${options.length} voices:`, 
            options.map(o => o.value).join(', '));
        return options;
    }
    
    get ttsLanguageOptions() {
        const languages = [
            { label: '🌐 Auto-detect', value: 'auto' },
            { label: '🇺🇸 English', value: 'en' },
            { label: '🇸🇦 Arabic', value: 'ar' },
            { label: '🇧🇬 Bulgarian', value: 'bg' },
            { label: '🇨🇳 Chinese', value: 'zh' },
            { label: '🇭🇷 Croatian', value: 'hr' },
            { label: '🇨🇿 Czech', value: 'cs' },
            { label: '🇩🇰 Danish', value: 'da' },
            { label: '🇳🇱 Dutch', value: 'nl' },
            { label: '🇵🇭 Filipino', value: 'tl' },
            { label: '🇫🇮 Finnish', value: 'fi' },
            { label: '🇫🇷 French', value: 'fr' },
            { label: '🇩🇪 German', value: 'de' },
            { label: '🇬🇷 Greek', value: 'el' },
            { label: '🇮🇳 Hindi', value: 'hi' },
            { label: '🇭🇺 Hungarian', value: 'hu' },
            { label: '🇮🇩 Indonesian', value: 'id' },
            { label: '🇮🇹 Italian', value: 'it' },
            { label: '🇯🇵 Japanese', value: 'ja' },
            { label: '🇰🇷 Korean', value: 'ko' },
            { label: '🇲🇾 Malay', value: 'ms' },
            { label: '🇳🇴 Norwegian', value: 'no' },
            { label: '🇵🇱 Polish', value: 'pl' },
            { label: '🇵🇹 Portuguese', value: 'pt' },
            { label: '🇷🇴 Romanian', value: 'ro' },
            { label: '🇷🇺 Russian', value: 'ru' },
            { label: '🇸🇰 Slovak', value: 'sk' },
            { label: '🇪🇸 Spanish', value: 'es' },
            { label: '🇸🇪 Swedish', value: 'sv' },
            { label: '🇮🇳 Tamil', value: 'ta' },
            { label: '🇹🇷 Turkish', value: 'tr' },
            { label: '🇺🇦 Ukrainian', value: 'uk' },
            { label: '🇻🇳 Vietnamese', value: 'vi' }
        ];
        
        return languages.map(lang => ({
            ...lang,
            selected: this.ttsLanguageCode === lang.value
        }));
    }
    
    get ttsNormalizationOptions() {
        const options = [
            { label: 'On', value: 'on' },
            { label: 'Off', value: 'off' },
            { label: 'Auto', value: 'auto' }
        ];
        
        return options.map(opt => ({
            ...opt,
            selected: this.ttsTextNormalization === opt.value
        }));
    }
    
    // ========== AGENT MANAGEMENT ==========
    async loadAgents() {
        this.isLoadingAgents = true;
        try {
            const result = await getAllAgents();
            this.agents = result || [];
            console.log('Loaded agents:', this.agents.length);
            
            // Auto-select first agent
            if (this.agents.length > 0) {
                this.selectAgent(this.agents[0]);
            }
        } catch (error) {
            console.error('Error loading agents:', error);
            this.errorMessage = 'Failed to load agents';
        } finally {
            this.isLoadingAgents = false;
        }
    }
    
    selectAgent(agent) {
        this.selectedAgentId = agent.id;
        this.selectedAgentName = agent.masterLabel;
        this.showAgentList = false;
        this.statusText = 'Click Connect to start';
        console.log('Selected agent:', agent.masterLabel);
    }
    
    toggleAgentList() {
        if (this.connected) return;
        this.showAgentList = !this.showAgentList;
    }
    
    handleAgentSelection(event) {
        const agentId = event.currentTarget.dataset.agentId;
        const agent = this.agents.find(a => a.id === agentId);
        if (agent) {
            this.selectAgent(agent);
        }
    }
    
    // ========== CONNECTION MANAGEMENT ==========
    async toggleConnection() {
        if (this.isConnecting) return;
        
        if (this.connected) {
            this.fullDisconnect();
        } else {
            await this.fullConnect();
        }
    }
    
    // Helper method to retry WebSocket connections
    async connectWithRetry(name, connectFn, maxRetries = 3) {
        let lastError;
        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                console.log(`🔄 ${name} connection attempt ${attempt}/${maxRetries}`);
                this.statusDetail = `Connecting ${name}...` + (attempt > 1 ? ` (attempt ${attempt}/${maxRetries})` : '');
                await connectFn();
                console.log(`✅ ${name} connected on attempt ${attempt}`);
                return;
            } catch (error) {
                lastError = error;
                console.error(`❌ ${name} connection attempt ${attempt} failed:`, error.message);
                
                if (attempt < maxRetries) {
                    this.statusDetail = `${name} failed, retrying in 1s...`;
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }
        }
        throw new Error(`${name} connection failed after ${maxRetries} attempts: ${lastError.message}`);
    }
    
    // Helper method to retry session creation
    async createSessionWithRetry(maxRetries = 3) {
        let lastError;
        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                console.log(`🔄 Session creation attempt ${attempt}/${maxRetries}`);
                if (attempt > 1) {
                    this.statusDetail = `Retrying session creation (${attempt}/${maxRetries})...`;
                }
                const session = await createSession({ agentId: this.selectedAgentId });
                console.log(`✅ Session created on attempt ${attempt}`);
                return session;
            } catch (error) {
                lastError = error;
                console.error(`❌ Session creation attempt ${attempt} failed:`, error.message);
                
                if (attempt < maxRetries) {
                    // Wait 1 second before retrying
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }
        }
        // If all retries failed, throw the last error
        throw lastError;
    }
    
    async fullConnect() {
        if (!this.selectedAgentId) {
            this.showToast('Warning', 'Please select an agent first', 'warning');
            return;
        }
        
        this.isConnecting = true;
        this.errorMessage = ''; // Clear any previous errors
        this.statusText = 'Connecting...';
        this.statusDetail = 'Initializing connections';
        
        try {
            // Step 1: Get access tokens
            this.statusDetail = 'Getting access tokens...';
            const token = await getAccessToken();
            this.sttAccessToken = token;
            this.ttsAccessToken = token;
            console.log('✅ Access tokens obtained');
            
            // Step 2: Connect STT WebSocket (with retry)
            await this.connectWithRetry('STT', () => this.connectSTT(), 3);
            
            // Step 3: Connect TTS WebSocket (with retry)
            await this.connectWithRetry('TTS', () => this.connectTTS(), 3);
            
            // Step 4: Create Agent Session (with retry logic)
            this.statusDetail = 'Creating agent session...';
            const session = await this.createSessionWithRetry(3);
            this.sessionId = session.sessionId;
            this.sequenceId = 0;
            console.log('✅ Agent session created:', this.sessionId);
            
            // Step 5: Initialize AudioContext
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
                    sampleRate: 16000
                });
            }
            
            this.connected = true;
            this.statusText = 'Connected';
            this.statusDetail = 'Hold the waveform to speak';
            this.currentState = 'connected';
            console.log('🎉 Full connection established!');
            
            this.showToast('Success', 'Connected to ' + this.selectedAgentName, 'success');
            
        } catch (error) {
            console.error('Connection error:', error);
            this.statusText = 'Connection failed';
            this.statusDetail = error.message || 'Unknown error';
            this.errorMessage = error.body?.message || error.message || 'Connection failed';
            this.fullDisconnect();
        } finally {
            this.isConnecting = false;
        }
    }
    
    fullDisconnect() {
        console.log('=== FULL DISCONNECT ===');
        
        // Disconnect STT
        this.disconnectSTT();
        
        // Disconnect TTS
        this.disconnectTTS();
        
        // End agent session
        if (this.sessionId) {
            endSession({ sessionId: this.sessionId }).catch(error => {
                console.error('Error ending session:', error);
            });
            this.sessionId = null;
        }
        
        this.connected = false;
        this.isMuted = false;
        this.isTalking = false;
        this.statusText = 'Click Connect to start';
        this.statusDetail = '';
        this.currentState = 'idle';
        this.conversationMessages = [];
        this.interimMessage = null;
        this.currentTranscript = '';
        
        console.log('✅ Full disconnect complete');
    }
    
    // ========== STT CONNECTION ==========
    async connectSTT() {
        const baseUrl = 'wss://api.salesforce.com/einstein/platform/v1/models/transcribeV1/streaming-transcriptions';
        const params = [];
        
        params.push(`engine=${this.sttEngine}`);
        params.push(`language-code=${this.sttLanguage}`);
        
        if (this.sttModel) {
            params.push(`model=${this.sttModel}`);
        }
        
        if (this.showSttSmartFormat) {
            params.push(`smart-format=${this.sttSmartFormat}`);
        }
        params.push(`profanity-filter=${this.sttProfanityFilter}`);
        
        if (this.showSttUtteranceEnd && this.sttUtteranceEndEnabled) {
            params.push(`utterance-end-ms=${this.sttUtteranceEndMs}`);
        }
        
        if (this.showSttKeywords && this.sttKeywords && this.sttKeywords.trim() !== '') {
            params.push(`keywords=${encodeURIComponent(this.sttKeywords)}`);
        }
        
        const websocketUrl = `${baseUrl}?${params.join('&')}`;
        console.log('🔊 STT WebSocket URL:', websocketUrl);
        
        const protocols = [
            'native',
            'jwt.bearer.authorization.' + this.sttAccessToken,
            'x-sfdc-app-context.EinsteinGPT'
        ];
        
        return new Promise((resolve, reject) => {
            this.sttWebsocket = new WebSocket(websocketUrl, protocols);
            
            this.sttWebsocket.onopen = () => {
                console.log('✅ STT WebSocket connected');
                
                // Start keep-alive by sending silence frames every 3 seconds when not recording
                this.sttKeepAliveInterval = setInterval(() => {
                    if (this.sttWebsocket && 
                        this.sttWebsocket.readyState === WebSocket.OPEN && 
                        !this.isSendingAudio) {
                        // Send silence buffer (1024 samples of silence at 16-bit PCM)
                        const silenceBuffer = new Int16Array(1024); // All zeros = silence
                        this.sttWebsocket.send(silenceBuffer.buffer);
                        console.log('💓 STT keep-alive (silence) sent (readyState:', this.sttWebsocket.readyState, ')');
                    } else if (this.sttWebsocket) {
                        console.log('⏸️ STT keep-alive skipped (readyState:', this.sttWebsocket.readyState, 'isSendingAudio:', this.isSendingAudio, ')');
                    }
                }, 3000); // Every 3 seconds (more frequent)
                
                resolve();
            };
            
            this.sttWebsocket.onmessage = (event) => {
                this.handleSTTMessage(event);
            };
            
            this.sttWebsocket.onclose = (event) => {
                console.log('⚠️ STT WebSocket closed:', event.code, 'reason:', event.reason, 'connected:', this.connected);
                this.isSendingAudio = false;
                
                // ALWAYS auto-reconnect if we're still connected (unless user explicitly disconnected)
                // This ensures STT stays alive even if the server closes the connection
                if (this.connected && !this.isConnecting) {
                    console.log('🔄 STT reconnecting immediately (STT should never close while connected)...');
                    const prevStatus = this.statusText;
                    const prevDetail = this.statusDetail;
                    this.statusText = 'Reconnecting...';
                    this.statusDetail = 'STT connection lost, reconnecting...';
                    
                    setTimeout(async () => {
                        if (this.connected) {
                            try {
                                await this.connectWithRetry('STT', () => this.connectSTT(), 3);
                                // Restore previous status if still connected
                                if (this.connected) {
                                    this.statusText = prevStatus === 'Reconnecting...' ? 'Connected' : prevStatus;
                                    this.statusDetail = prevDetail === 'STT connection lost, reconnecting...' ? 'Hold the waveform to speak' : prevDetail;
                                }
                                console.log('✅ STT reconnected successfully');
                            } catch (err) {
                                console.error('❌ STT reconnect failed after retries:', err);
                                this.statusText = 'Connection issue';
                                this.statusDetail = 'STT reconnection failed';
                                this.showToast('Warning', 'STT connection lost. Please reconnect.', 'warning');
                            }
                        }
                    }, 500); // Quick reconnect
                } else {
                    console.log('ℹ️ STT closed intentionally (connected=' + this.connected + ')');
                }
            };
            
            this.sttWebsocket.onerror = (error) => {
                console.error('STT WebSocket error:', error);
                reject(new Error('STT WebSocket connection failed'));
            };
        });
    }
    
    disconnectSTT() {
        // Stop microphone
        this.stopMicrophone();
        
        // Clear keep-alive interval
        if (this.sttKeepAliveInterval) {
            clearInterval(this.sttKeepAliveInterval);
            this.sttKeepAliveInterval = null;
        }
        
        // Close WebSocket
        if (this.sttWebsocket) {
            this.sttWebsocket.close();
            this.sttWebsocket = null;
        }
        
        console.log('✅ STT disconnected');
    }
    
    handleSTTMessage(event) {
        try {
            const message = JSON.parse(event.data);
            const transcriptData = message.transcript && typeof message.transcript === 'object' && message.transcript.results 
                ? message.transcript 
                : message;
            
            if (transcriptData.results && transcriptData.results.length > 0) {
                const result = transcriptData.results[0];
                
                if (result.alternatives && result.alternatives.length > 0) {
                    const transcriptText = result.alternatives[0].transcript;
                    const isPartial = result.isPartial !== false;
                    const isFinal = !isPartial;
                    
                    if (transcriptText) {
                        if (isFinal) {
                            // Append to current transcript
                            const oldTranscript = this.currentTranscript;
                            this.currentTranscript += (this.currentTranscript ? ' ' : '') + transcriptText;
                            this.addMessage(transcriptText, 'user', true);
                            console.log('📝 Final STT:', transcriptText);
                            console.log('✅ Current transcript now:', this.currentTranscript);
                        } else {
                            // Show interim
                            this.addMessage(transcriptText, 'user', false);
                            console.log('💭 Interim STT:', transcriptText);
                        }
                    }
                }
            }
        } catch (e) {
            console.error('Error parsing STT message:', e);
        }
    }
    
    // ========== TTS CONNECTION ==========
    async connectTTS() {
        const baseUrl = 'wss://api.salesforce.com/einstein/platform/v1/models/ttsV1/streaming-synthesis';
        const params = [];
        
        params.push(`engine=${this.ttsEngine}`);
        params.push(`voice_id=${this.ttsVoice}`);
        
        if (this.ttsEngine === 'elevenlabs') {
            params.push(`language_code=${this.ttsLanguageCode}`);
            params.push(`stability=${this.ttsStability}`);
            params.push(`similarity_boost=${this.ttsSimilarityBoost}`);
            params.push(`style=${this.ttsStyle}`);
            params.push(`speed=${this.ttsSpeed}`);
            params.push(`use_speaker_boost=${this.ttsUseSpeakerBoost}`);
            params.push(`enable_ssml_parsing=${this.ttsEnableSsml}`);
            params.push(`apply_text_normalization=${this.ttsTextNormalization}`);
        } else {
            // AWS Polly only supports speed and text normalization
            params.push(`speed=${this.ttsSpeed}`);
            params.push(`apply_text_normalization=${this.ttsTextNormalization}`);
        }
        
        const websocketUrl = `${baseUrl}?${params.join('&')}`;
        console.log('🔊 TTS WebSocket URL:', websocketUrl);
        
        const protocols = [
            'native',
            'jwt.bearer.authorization.' + this.ttsAccessToken,
            'x-sfdc-app-context.EinsteinGPT'
        ];
        
        return new Promise((resolve, reject) => {
            this.ttsWebsocket = new WebSocket(websocketUrl, protocols);
            
            this.ttsWebsocket.onopen = () => {
                console.log('✅ TTS WebSocket connected');
                
                // Start keep-alive ping every 3 seconds ALWAYS to prevent idle timeout
                this.ttsKeepAliveInterval = setInterval(() => {
                    if (this.ttsWebsocket && this.ttsWebsocket.readyState === WebSocket.OPEN) {
                        // Send empty synthesis request as keep-alive (ALWAYS, even when playing)
                        this.ttsWebsocket.send(JSON.stringify({ 
                            text: ' ',  // Single space
                            flush: false 
                        }));
                        console.log('💓 TTS keep-alive sent (readyState:', this.ttsWebsocket.readyState, 'isPlaying:', this.isPlayingTTS, ')');
                    } else {
                        console.warn('⚠️ TTS keep-alive skipped - WebSocket not open (readyState:', this.ttsWebsocket?.readyState, ')');
                    }
                }, 3000); // Every 3 seconds (reduced for more frequent pings)
                
                resolve();
            };
            
            this.ttsWebsocket.onmessage = (event) => {
                this.handleTTSMessage(event);
            };
            
            this.ttsWebsocket.onclose = (event) => {
                console.log('⚠️ TTS WebSocket closed:', event.code, 'reason:', event.reason);
                this.isPlayingTTS = false;
                
                // Auto-reconnect on ANY closure except explicit disconnect (1000)
                // Including 1001 (idle timeout) which should never happen with our keep-alive
                if (this.connected && !this.isConnecting && event.code !== 1000) {
                    console.log('🔄 TTS reconnecting immediately (code:', event.code, ')...');
                    const prevStatus = this.statusText;
                    const prevDetail = this.statusDetail;
                    this.statusText = 'Reconnecting...';
                    this.statusDetail = 'TTS connection lost, reconnecting...';
                    
                    setTimeout(async () => {
                        if (this.connected) {
                            try {
                                await this.connectWithRetry('TTS', () => this.connectTTS(), 3);
                                // Restore previous status if still connected
                                if (this.connected) {
                                    this.statusText = prevStatus === 'Reconnecting...' ? 'Connected' : prevStatus;
                                    this.statusDetail = prevDetail === 'TTS connection lost, reconnecting...' ? 'Hold the waveform to speak' : prevDetail;
                                }
                                console.log('✅ TTS reconnected successfully');
                            } catch (err) {
                                console.error('❌ TTS reconnect failed after retries:', err);
                                this.statusText = 'Connection issue';
                                this.statusDetail = 'TTS reconnection failed';
                                this.showToast('Warning', 'TTS connection lost. Please reconnect.', 'warning');
                            }
                        }
                    }, 500); // Reconnect quickly
                }
            };
            
            this.ttsWebsocket.onerror = (error) => {
                console.error('TTS WebSocket error:', error);
                reject(new Error('TTS WebSocket connection failed'));
            };
        });
    }
    
    disconnectTTS() {
        // Clear keep-alive interval
        if (this.ttsKeepAliveInterval) {
            clearInterval(this.ttsKeepAliveInterval);
            this.ttsKeepAliveInterval = null;
        }
        
        // Clear speaker level monitoring interval
        if (this.speakerLevelCheckInterval) {
            clearInterval(this.speakerLevelCheckInterval);
            this.speakerLevelCheckInterval = null;
        }
        
        if (this.ttsWebsocket) {
            this.ttsWebsocket.close();
            this.ttsWebsocket = null;
        }
        
        this.audioQueue = [];
        this.nextStartTime = 0;
        this.isPlayingTTS = false;
        this.ttsSynthesisComplete = false; // Reset flag on disconnect
        this.audioChunksPlaying = 0; // Reset chunk counter
        this.hasStartedSpeakerMonitoring = false; // Reset monitoring flag
        
        console.log('✅ TTS disconnected');
    }
    
    checkSpeakerLevelAndTransitionToIdle() {
        // CRITICAL: Don't transition to idle if user is actively talking!
        if (this.isTalking || this.isSendingAudio) {
            console.log('⏸️ Speaker level check skipped - user is talking (isTalking=' + this.isTalking + ', isSendingAudio=' + this.isSendingAudio + ')');
            return;
        }
        
        // CRITICAL: Don't transition if audio chunks are STILL PLAYING (even with temporary silence dips)
        if (this.audioChunksPlaying > 0) {
            console.log('⏸️ Speaker level check skipped - audio chunks still playing (chunksPlaying=' + this.audioChunksPlaying + ', speakerLevel=' + this.speakerLevel.toFixed(2) + ')');
            return;
        }
        
        // Use actual speaker level to determine if audio is truly finished
        // Even if chunks report "ended", audio might still be playing through the buffer
        const SILENCE_THRESHOLD = 2.0; // Speaker level below this is considered silent
        const isSilent = this.speakerLevel < SILENCE_THRESHOLD;
        const allChunksDone = this.audioChunksPlaying <= 0;
        
        console.log('🔍 Speaker level check: level=' + this.speakerLevel.toFixed(2), 
                    'threshold=' + SILENCE_THRESHOLD,
                    'isSilent=' + isSilent, 
                    'synthesisComplete=' + this.ttsSynthesisComplete,
                    'chunksPlaying=' + this.audioChunksPlaying);
        
        // Only transition if ALL chunks are done AND speaker is silent
        if (allChunksDone && isSilent && this.ttsSynthesisComplete) {
            console.log('✅ TRANSITIONING TO IDLE - All chunks done (chunksPlaying=' + this.audioChunksPlaying + '), speaker silent (level=' + this.speakerLevel.toFixed(2) + '), synthesis complete');
            this.transitionToIdle();
        } 
        // FALLBACK: If all chunks done and silent, even without isFinal (in case it never arrives)
        else if (allChunksDone && isSilent && this.isPlayingTTS) {
            console.log('⚠️ FALLBACK TRANSITION - All chunks done and speaker silent (level=' + this.speakerLevel.toFixed(2) + ') even without isFinal');
            this.transitionToIdle();
        } 
        else if (!isSilent) {
            console.log('⏳ STILL PLAYING - Speaker level is ' + this.speakerLevel.toFixed(2) + ' (threshold: ' + SILENCE_THRESHOLD + ')');
        } 
        else if (!this.ttsSynthesisComplete) {
            console.log('⏳ STILL SYNTHESIZING (chunks: ' + this.audioChunksPlaying + ', speaker level: ' + this.speakerLevel.toFixed(2) + ')');
        }
    }
    
    transitionToIdle() {
        // CRITICAL: Don't transition to idle if user is actively talking!
        if (this.isTalking || this.isSendingAudio) {
            console.log('⚠️ BLOCKED transition to idle - user is talking (isTalking=' + this.isTalking + ', isSendingAudio=' + this.isSendingAudio + ')');
            return;
        }
        
        console.log('🎯 TRANSITIONING TO IDLE STATE');
        
        // Stop speaker level monitoring
        if (this.speakerLevelCheckInterval) {
            clearInterval(this.speakerLevelCheckInterval);
            this.speakerLevelCheckInterval = null;
        }
        
        this.isPlayingTTS = false;
        this.ttsSynthesisComplete = false;
        this.audioChunksPlaying = 0;
        this.speakerLevel = 0;
        this.hasStartedSpeakerMonitoring = false; // Reset for next synthesis
        this.currentState = 'connected';
        this.statusText = 'Connected';
        this.statusDetail = 'Hold the waveform to speak';
    }
    
    handleTTSMessage(event) {
        try {
            const message = JSON.parse(event.data);
            
            if (message.audio && message.audio !== null) {
                console.log('🔊 TTS audio chunk received (chunksPlaying:', this.audioChunksPlaying, ')');
                
                // Start speaker level monitoring when FIRST audio chunk arrives (not before!)
                if (!this.hasStartedSpeakerMonitoring && this.isPlayingTTS) {
                    this.hasStartedSpeakerMonitoring = true;
                    if (this.speakerLevelCheckInterval) {
                        clearInterval(this.speakerLevelCheckInterval);
                    }
                    console.log('🎬 Starting speaker level monitoring interval (checks every 200ms) - FIRST CHUNK RECEIVED');
                    this.speakerLevelCheckInterval = setInterval(() => {
                        if (this.isPlayingTTS) {
                            // Check if we should transition to idle based on actual speaker output
                            this.checkSpeakerLevelAndTransitionToIdle();
                        } else {
                            console.log('⏸️ Speaker level check skipped - isPlayingTTS is false');
                        }
                    }, 200); // Check every 200ms
                }
                
                this.playAudioChunk(message.audio);
            }
            
            if (message.isFinal === true) {
                console.log('✅ TTS synthesis COMPLETE - waiting for', this.audioChunksPlaying, 'audio chunks to finish playing');
                this.ttsSynthesisComplete = true;
                // Don't reset state yet - wait for all audio chunks to finish playing
            }
        } catch (e) {
            console.log('TTS non-JSON data received');
        }
    }
    
    async playAudioChunk(base64Audio) {
        try {
            const binaryString = atob(base64Audio);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            
            const audioBuffer = await this.audioContext.decodeAudioData(bytes.buffer);
            const source = this.audioContext.createBufferSource();
            source.buffer = audioBuffer;
            
            // Initialize speaker analyser if not already done
            if (!this.speakerAnalyser) {
                this.startSpeakerLevelMonitoring();
            }
            
            // Connect source to both analyser and destination
            if (this.speakerAnalyser) {
                source.connect(this.speakerAnalyser);
                this.speakerAnalyser.connect(this.audioContext.destination);
            } else {
                source.connect(this.audioContext.destination);
            }
            
            const now = this.audioContext.currentTime;
            const startTime = Math.max(now, this.nextStartTime);
            
            this.audioChunksPlaying++; // Increment active chunks
            console.log('🎵 Audio chunk starting (chunksPlaying:', this.audioChunksPlaying, 'duration:', audioBuffer.duration.toFixed(2), 's, speakerLevel:', this.speakerLevel.toFixed(2), ')');
            
            source.start(startTime);
            this.nextStartTime = startTime + audioBuffer.duration;
            
            // Listen for when this audio chunk finishes playing
            source.onended = () => {
                this.audioChunksPlaying = Math.max(0, this.audioChunksPlaying - 1); // Decrement, never go negative
                console.log('🎵 Audio chunk ended (chunksPlaying:', this.audioChunksPlaying, 'synthesisComplete:', this.ttsSynthesisComplete, 'speakerLevel:', this.speakerLevel.toFixed(2), ')');
                
                // Check if we should transition to idle by monitoring actual speaker output
                this.checkSpeakerLevelAndTransitionToIdle();
            };
            
        } catch (error) {
            console.error('❌ TTS playback error:', error);
            console.error('Error details:', {
                name: error.name,
                message: error.message,
                stack: error.stack,
                audioContextState: this.audioContext?.state,
                base64Length: base64Audio?.length
            });
            // Decrement since we incremented before the error, ensure never negative
            this.audioChunksPlaying = Math.max(0, this.audioChunksPlaying - 1);
        }
    }
    
    // ========== MICROPHONE (PUSH-TO-TALK) ==========
    async handleStartTalking(event) {
        event.preventDefault();
        if (!this.connected || this.isMuted || this.isTalking) return;
        
        console.log('🎤 Start talking');
        this.isTalking = true;
        this.currentState = 'listening';
        this.statusText = 'Listening';
        this.statusDetail = 'Speak now...';
        this.currentTranscript = '';
        
        await this.startMicrophone();
    }
    
    async handleStopTalking(event) {
        event.preventDefault();
        if (!this.isTalking) return;
        
        console.log('🛑 Stop talking - starting finalization process');
        this.isTalking = false;
        this.currentState = 'connected';
        this.statusText = 'Processing';
        this.statusDetail = 'Finalizing transcript...';
        
        // Continue streaming SILENCE for 500ms to allow STT to finalize
        // This gives STT time to convert interim transcript to final
        console.log('📡 Streaming silence to finalize transcript...');
        const silenceFrames = 25; // ~500ms of silence at 20ms per frame
        const silenceBuffer = new Int16Array(1024).fill(0); // Silence
        
        for (let i = 0; i < silenceFrames; i++) {
            if (this.sttWebsocket && this.sttWebsocket.readyState === WebSocket.OPEN) {
                this.sttWebsocket.send(silenceBuffer.buffer);
            }
            await new Promise(resolve => setTimeout(resolve, 20)); // 20ms between frames
        }
        
        // Now stop the microphone
        this.stopMicrophone();
        
        // Wait additional 500ms for final transcript to arrive from STT
        console.log('⏳ Waiting for final transcript...');
        this.statusDetail = 'Sending to agent...';
        await new Promise(resolve => setTimeout(resolve, 500));
        console.log('✅ Wait complete, sending to agent');
        
        // Send transcript to agent immediately
        await this.sendToAgent();
    }
    
    async startMicrophone() {
        try {
            // Request microphone if not already open
            if (!this.mediaStream) {
                this.mediaStream = await navigator.mediaDevices.getUserMedia({ 
                    audio: {
                        echoCancellation: true,
                        noiseSuppression: true,
                        autoGainControl: true
                    }
                });
                
                // Setup audio processing
                const source = this.audioContext.createMediaStreamSource(this.mediaStream);
                this.scriptProcessor = this.audioContext.createScriptProcessor(4096, 1, 1);
                
                this.scriptProcessor.onaudioprocess = (event) => {
                    if (!this.isTalking || !this.sttWebsocket) return;
                    
                    const inputData = event.inputBuffer.getChannelData(0);
                    const pcm16 = this.float32ToInt16(inputData);
                    
                    if (this.sttWebsocket.readyState === WebSocket.OPEN) {
                        this.sttWebsocket.send(pcm16);
                        this.isSendingAudio = true; // Mark that we're actively sending
                    }
                };
                
                source.connect(this.scriptProcessor);
                this.scriptProcessor.connect(this.audioContext.destination);
                
                // Start monitoring mic levels for waveform visualization
                this.startMicLevelMonitoring();
            }
            
            console.log('✅ Microphone streaming');
            
        } catch (error) {
            console.error('Microphone error:', error);
            this.errorMessage = 'Failed to access microphone: ' + error.message;
            this.isTalking = false;
        }
    }
    
    stopMicrophone() {
        // Don't close the stream, just stop sending audio
        // This keeps the mic open for next push-to-talk
        this.isSendingAudio = false; // Mark that we stopped sending
        console.log('🛑 Microphone paused');
    }
    
    cleanupMicrophone() {
        this.isSendingAudio = false;
        
        if (this.scriptProcessor) {
            this.scriptProcessor.disconnect();
            this.scriptProcessor = null;
        }
        
        if (this.mediaStream) {
            this.mediaStream.getTracks().forEach(track => track.stop());
            this.mediaStream = null;
        }
        
        console.log('✅ Microphone cleanup complete');
    }
    
    float32ToInt16(buffer) {
        let l = buffer.length;
        const buf = new Int16Array(l);
        while (l--) {
            buf[l] = Math.min(1, buffer[l]) * 0x7FFF;
        }
        return buf.buffer;
    }
    
    // ========== AGENT COMMUNICATION ==========
    async sendToAgent() {
        console.log('📋 Current transcript before send:', this.currentTranscript);
        
        if (!this.currentTranscript || this.currentTranscript.trim() === '') {
            console.log('❌ No transcript to send - skipping agent message');
            this.statusText = 'Connected';
            this.statusDetail = 'Hold the waveform to speak';
            return;
        }
        
        try {
            // Increment sequence ID BEFORE sending (first message should be 1, not 0)
            this.sequenceId++;
            
            console.log('📤 Sending to agent:', this.currentTranscript);
            console.log('📋 Session ID:', this.sessionId);
            console.log('📋 Sequence ID:', this.sequenceId);
            
            const response = await sendMessage({
                sessionId: this.sessionId,
                messageText: this.currentTranscript,  // Parameter name must match Apex method
                sequenceId: this.sequenceId
            });
            
            console.log('✅ Send successful, response:', response);
            
            // Handle response - it should be an array of messages
            if (response && response.length > 0) {
                // Get the last message which should be the agent response
                const lastMessage = response[response.length - 1];
                const agentText = lastMessage.message || '';
                
                if (agentText) {
                    this.addMessage(agentText, 'agent', true);
                    console.log('📥 Agent response:', agentText);
                    
                    // Synthesize agent response with TTS
                    await this.speakText(agentText);
                }
            } else {
                console.warn('⚠️ No messages in response');
            }
            
            // Reset for next interaction
            this.currentTranscript = '';
            this.statusText = 'Connected';
            this.statusDetail = 'Hold the waveform to speak';
            
        } catch (error) {
            console.error('❌ Error sending to agent:', error);
            console.error('❌ Error body:', JSON.stringify(error.body || {}));
            console.error('❌ Error message:', error.message);
            console.error('❌ Full error:', error);
            
            this.errorMessage = 'Failed to send message: ' + (error.body?.message || error.message);
            this.statusText = 'Error';
            this.statusDetail = 'Try again';
            this.showToast('Error', this.errorMessage, 'error');
        }
    }
    
    async speakText(text) {
        // Wait for TTS websocket to be ready (up to 3 seconds)
        const maxRetries = 30;
        const retryDelay = 100; // 100ms between retries
        
        for (let i = 0; i < maxRetries; i++) {
            if (this.ttsWebsocket && this.ttsWebsocket.readyState === WebSocket.OPEN) {
                break; // Websocket is ready!
            }
            
            if (i === 0) {
                console.log('⏳ Waiting for TTS WebSocket to be ready...');
            }
            
            await new Promise(resolve => setTimeout(resolve, retryDelay));
        }
        
        // Final check
        if (!this.ttsWebsocket || this.ttsWebsocket.readyState !== WebSocket.OPEN) {
            console.error('❌ TTS WebSocket not ready after waiting');
            this.showToast('Error', 'TTS connection not available', 'error');
            return;
        }
        
        console.log('🔊 Speaking:', text);
        this.isPlayingTTS = true;
        this.ttsSynthesisComplete = false; // Reset flag for new synthesis
        this.audioChunksPlaying = 0; // Reset chunk counter for new synthesis
        this.hasStartedSpeakerMonitoring = false; // Reset monitoring flag - will start when first chunk arrives
        this.currentState = 'speaking';
        this.statusText = 'Speaking';
        this.statusDetail = 'Agent is responding...';
        this.audioQueue = [];
        this.nextStartTime = this.audioContext.currentTime;
        
        // NOTE: Speaker level monitoring will start in handleTTSMessage when FIRST audio chunk arrives
        // This prevents false "silent" detection before audio actually starts playing
        
        try {
            const message = JSON.stringify({ 
                text: text,
                flush: true 
            });
            this.ttsWebsocket.send(message);
        } catch (error) {
            console.error('TTS error:', error);
            this.isPlayingTTS = false;
            this.currentState = 'connected';
            this.showToast('Error', 'Failed to speak response', 'error');
        }
    }
    
    // ========== MESSAGES ==========
    addMessage(text, sender, isFinal = true) {
        if (!text || text.trim().length === 0) return;
        
        if (!isFinal) {
            // Interim message
            this.interimMessage = { 
                text, 
                sender, 
                timestamp: Date.now(), 
                interim: true,
                id: 'interim-' + Date.now()
            };
        } else {
            // Final message
            this.interimMessage = null;
            
            const lastMsg = this.conversationMessages[this.conversationMessages.length - 1];
            if (lastMsg && lastMsg.sender === sender) {
                // Append to existing message
                lastMsg.text = lastMsg.text + ' ' + text;
            } else {
                // Add new message
                this.conversationMessages.push({
                    text: text,
                    sender: sender,
                    timestamp: Date.now(),
                    id: Date.now() + '-' + Math.random()
                });
            }
            
            // Keep only last 10 messages
            if (this.conversationMessages.length > 10) {
                this.conversationMessages = this.conversationMessages.slice(-10);
            }
            
            this.conversationMessages = [...this.conversationMessages];
        }
        
        this.scrollToBottom();
    }
    
    scrollToBottom() {
        setTimeout(() => {
            const container = this.template.querySelector('.conversation-container');
            if (container) {
                container.scrollTop = container.scrollHeight;
            }
        }, 50);
    }
    
    // ========== MUTE ==========
    toggleMute() {
        if (!this.connected) return;
        
        this.isMuted = !this.isMuted;
        console.log('🔇 Mute toggled:', this.isMuted);
        
        if (this.isMuted) {
            this.statusText = 'Muted';
            this.statusDetail = 'Microphone is off';
        } else {
            this.statusText = 'Connected';
            this.statusDetail = 'Hold the waveform to speak';
        }
    }
    
    // ========== SETTINGS ==========
    toggleSettings() {
        if (this.connected) {
            this.showToast('Warning', 'Disconnect before changing settings', 'warning');
            return;
        }
        
        // If closing settings, save them automatically
        if (this.showSettings) {
            console.log('💾 Auto-saving settings on close...');
            this.saveSettingsToStorage();
        } else {
            // If opening settings, reload them from storage
            console.log('📂 Loading settings...');
            this.loadSettingsFromStorage();
        }
        
        this.showSettings = !this.showSettings;
    }
    
    handleOverlayClick() {
        // Auto-save settings when clicking overlay to close
        if (this.showSettings) {
            console.log('💾 Auto-saving settings (overlay close)...');
            this.saveSettingsToStorage();
        }
        this.showSettings = false;
    }
    
    handlePanelClick(event) {
        event.stopPropagation();
    }
    
    // STT Settings Handlers
    handleSttEngineChange(event) {
        console.log('🔧 STT Engine changed to:', event.target.value);
        this.sttEngine = event.target.value;
        this.updateSttModelAndLanguage();
    }
    
    handleSttModelChange(event) {
        console.log('🔧 STT Model changed to:', event.target.value);
        this.sttModel = event.target.value;
        console.log('✅ STT Model is now:', this.sttModel);
    }
    
    handleSttLanguageChange(event) {
        this.sttLanguage = event.target.value;
    }
    
    handleSttSmartFormatChange(event) {
        this.sttSmartFormat = event.target.checked;
    }
    
    handleSttProfanityFilterChange(event) {
        this.sttProfanityFilter = event.target.checked;
    }
    
    handleSttUtteranceEndEnabledChange(event) {
        this.sttUtteranceEndEnabled = event.target.checked;
    }
    
    handleSttUtteranceEndMsChange(event) {
        this.sttUtteranceEndMs = event.target.value;
    }
    
    handleSttKeywordsChange(event) {
        this.sttKeywords = event.target.value;
    }
    
    updateSttModelAndLanguage() {
        const engineConfig = this.sttConfig[this.sttEngine];
        if (!engineConfig) return;
        
        // Set default model or validate current model
        if (engineConfig.models) {
            const models = Object.keys(engineConfig.models);
            if (models.length > 0) {
                // Check if current model is valid for this engine
                const isModelValid = this.sttModel && models.includes(this.sttModel);
                if (!isModelValid) {
                    // Only set default if current model is invalid for this engine
                    this.sttModel = models[0];
                    console.log('🔄 STT model reset to default:', this.sttModel, 'for engine:', this.sttEngine);
                } else {
                    console.log('✅ STT model preserved:', this.sttModel);
                }
            }
        } else {
            this.sttModel = null;
        }
        
        // Set default language
        const languageOpts = this.sttLanguageOptions;
        if (languageOpts.length > 0) {
            const currentLangValid = languageOpts.find(opt => opt.value === this.sttLanguage);
            if (!currentLangValid) {
                this.sttLanguage = languageOpts[0].value;
            }
        }
    }
    
    // TTS Settings Handlers
    handleTtsEngineChange(event) {
        this.ttsEngine = event.target.value;
        this.ttsVoice = this.ttsVoiceOptions[0].value;
    }
    
    handleTtsVoiceChange(event) {
        this.ttsVoice = event.target.value;
    }
    
    handleTtsLanguageCodeChange(event) {
        this.ttsLanguageCode = event.target.value;
    }
    
    handleTtsStabilityChange(event) {
        this.ttsStability = parseFloat(event.target.value).toFixed(2);
    }
    
    handleTtsSpeedChange(event) {
        this.ttsSpeed = parseFloat(event.target.value).toFixed(2);
    }
    
    handleTtsSimilarityBoostChange(event) {
        this.ttsSimilarityBoost = parseFloat(event.target.value).toFixed(2);
    }
    
    handleTtsStyleChange(event) {
        this.ttsStyle = parseFloat(event.target.value).toFixed(2);
    }
    
    handleTtsUseSpeakerBoostChange(event) {
        this.ttsUseSpeakerBoost = event.target.checked;
    }
    
    handleTtsEnableSsmlChange(event) {
        this.ttsEnableSsml = event.target.checked;
    }
    
    handleTtsTextNormalizationChange(event) {
        this.ttsTextNormalization = event.target.value;
    }
    
    handleResetSettings() {
        // STT defaults
        this.sttEngine = 'deepgram_falcon';
        this.sttModel = 'nova-2-phonecall';
        this.sttLanguage = 'en-US';
        this.sttSmartFormat = true;
        this.sttProfanityFilter = false;
        this.sttUtteranceEndEnabled = false;
        this.sttUtteranceEndMs = '1000';
        this.sttKeywords = '';
        
        // TTS defaults
        this.ttsEngine = 'elevenlabs';
        this.ttsVoice = 'JBFqnCBsd6RMkjVDRZzb';
        this.ttsLanguageCode = 'en';
        this.ttsStability = '0.50';
        this.ttsSimilarityBoost = '0.75';
        this.ttsStyle = '0.00';
        this.ttsSpeed = '1.00';
        this.ttsUseSpeakerBoost = false;
        this.ttsEnableSsml = false;
        this.ttsTextNormalization = 'on';
        
        // Save defaults to localStorage immediately
        this.saveSettingsToStorage();
        
        console.log('⚙️ Settings reset to defaults and saved');
        this.showToast('Success', 'Settings reset to defaults', 'success');
    }
    
    // ========== WAVEFORM ANIMATION ==========
    startWaveformAnimation() {
        const animate = () => {
            const now = Date.now();
            
            // Update card class
            const card = this.template.querySelector('.voice-card');
            if (card) {
                if (this.isConnecting) {
                    card.className = 'voice-card connecting';
                } else if (this.currentState === 'listening') {
                    card.className = 'voice-card listening';
                } else if (this.currentState === 'speaking') {
                    card.className = 'voice-card speaking';
                } else {
                    card.className = 'voice-card';
                }
            }
            
            // Update bar heights for active states - use real audio levels
            const bars = this.template.querySelectorAll('.waveform-bar');
            if (bars && bars.length > 0 && (this.currentState === 'listening' || this.currentState === 'speaking')) {
                const baseHeight = 12;
                const maxHeight = 70;
                // Use real audio levels from analyser nodes
                const level = this.currentState === 'listening' ? this.micLevel : this.speakerLevel;
                
                bars.forEach((bar, index) => {
                    const wavePhase = (now / 500) + (index * 0.3);
                    const wave = Math.sin(wavePhase) * 0.5 + 0.5;
                    // Divide by 2 to reduce scaling and prevent clipping
                    const audioFactor = Math.max(level / 60, 0.3); // Normalized and reduced by half
                    const heightVariation = (maxHeight - baseHeight) * wave * audioFactor;
                    const height = Math.min(maxHeight, baseHeight + heightVariation); // Cap at maxHeight
                    
                    bar.style.height = `${height}px`;
                });
            } else if (bars && bars.length > 0) {
                bars.forEach(bar => {
                    bar.style.height = '';
                });
            }
            
            requestAnimationFrame(animate);
        };
        animate();
    }
    
    // ========== AUDIO LEVEL MONITORING ==========
    startMicLevelMonitoring() {
        try {
            console.log('🎤 Starting mic level monitoring');
            
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
                    sampleRate: 16000
                });
            }
            
            if (!this.mediaStream) {
                console.warn('No media stream available for mic monitoring');
                return;
            }
            
            const source = this.audioContext.createMediaStreamSource(this.mediaStream);
            this.micAnalyser = this.audioContext.createAnalyser();
            this.micAnalyser.fftSize = 256;
            this.micAnalyser.smoothingTimeConstant = 0.8;
            source.connect(this.micAnalyser);
            
            const dataArray = new Uint8Array(this.micAnalyser.frequencyBinCount);
            
            const updateMicLevel = () => {
                if (this.mediaStream && this.micAnalyser) {
                    this.micAnalyser.getByteFrequencyData(dataArray);
                    const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
                    this.micLevel = Math.min(100, average);
                    requestAnimationFrame(updateMicLevel);
                }
            };
            
            updateMicLevel();
            console.log('✅ Mic level monitoring started');
            
        } catch (error) {
            console.error('❌ Mic monitoring error:', error);
        }
    }
    
    startSpeakerLevelMonitoring() {
        try {
            console.log('🔊 Starting speaker level monitoring');
            
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
                    sampleRate: 16000
                });
            }
            
            // Create a destination node for TTS audio playback
            this.speakerAnalyser = this.audioContext.createAnalyser();
            this.speakerAnalyser.fftSize = 256;
            this.speakerAnalyser.smoothingTimeConstant = 0.8;
            
            const dataArray = new Uint8Array(this.speakerAnalyser.frequencyBinCount);
            
            const updateSpeakerLevel = () => {
                if (this.speakerAnalyser) {
                    this.speakerAnalyser.getByteFrequencyData(dataArray);
                    const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
                    this.speakerLevel = Math.min(100, average);
                    requestAnimationFrame(updateSpeakerLevel);
                }
            };
            
            updateSpeakerLevel();
            console.log('✅ Speaker level monitoring started');
            
        } catch (error) {
            console.error('❌ Speaker monitoring error:', error);
        }
    }
    
    // ========== UTILITIES ==========
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}

