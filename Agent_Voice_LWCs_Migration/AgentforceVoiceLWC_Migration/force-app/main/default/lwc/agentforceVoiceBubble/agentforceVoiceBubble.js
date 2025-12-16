import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import LIVEKIT_SDK from '@salesforce/resourceUrl/livekit_client';
import AGENTFORCE_ICON from '@salesforce/resourceUrl/agentforce_icon';
import getBootstrapToken from '@salesforce/apex/AgentforceVoiceController.getBootstrapToken';
import createSession from '@salesforce/apex/AgentforceVoiceController.createSession';
import joinSession from '@salesforce/apex/AgentforceVoiceController.joinSession';
import getAllBots from '@salesforce/apex/AgentforceDataService.getAllBots';
import checkVoiceCapability from '@salesforce/apex/AgentforceDataService.checkVoiceCapability';

export default class AgentforceVoiceBubble extends LightningElement {
    // Optional properties from page - if empty, we auto-detect
    @api instanceUrl = '';
    @api agentId = '';
    @api versionId = '';
    
    // Agent selection
    @track voiceAgents = [];
    @track selectedAgent = null;
    @track showAgentList = false;
    @track isLoadingAgents = false;
    
    // State
    @track showDebug = false;
    @track showConfig = false;
    @track connected = false;
    @track isConnecting = false;
    @track statusText = 'Click Connect to start';
    @track statusDetail = '';
    @track isMuted = false;
    
    // Configuration values (tracked for reactivity)
    @track configMicThreshold = 5;
    @track configSpeakerThreshold = 8;
    @track configPriorityMultiplier = 1.2;
    @track configSilenceThreshold = 500;
    @track configStateLock = 1200;
    
    // Active configuration (used in actual detection)
    MIC_THRESHOLD = 5;
    SPEAKER_THRESHOLD = 8;
    PRIORITY_MULTIPLIER = 1.2;
    USER_SILENCE_THRESHOLD = 500;
    STATE_LOCK = 1200;
    
    // Conversation messages (last 3 only)
    @track conversationMessages = [];
    interimMessage = null; // Temporary storage for interim transcripts
    
    // Click detection for triple-click
    clickTimes = [];
    
    // Getters
    get agentforceIconUrl() {
        return AGENTFORCE_ICON;
    }
    
    get connectButtonLabel() {
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
    
    get buttonText() {
        if (this.isConnecting) return 'Connecting...';
        return this.connected ? 'Stop Call' : 'Start Call';
    }
    
    get buttonClass() {
        return this.connected ? 'btn-stop' : 'btn-start';
    }
    
    get cardClass() {
        if (this.isConnecting) return 'voice-card connecting';
        if (this.currentState === 'listening') return 'voice-card listening';
        if (this.currentState === 'speaking') return 'voice-card speaking';
        return 'voice-card';
    }
    
    // Helper method to update status with forced UI refresh
    async updateStatus(main, detail = '') {
        this.statusText = String(main);
        this.statusDetail = String(detail);
        
        // Give the browser time to re-render
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    // Manage agent audio output to prevent interruptions during user speech
    manageAgentAudioOutput(currentTime) {
        if (!this.remoteAudioElement) {
            return;
        }

        // SIMPLE RULE: If user is muted, don't run any agent muting logic at all
        // Just keep agent at full volume and exit
        if (this.isMuted) {
            if (this.remoteAudioElement.volume !== 1) {
                this.remoteAudioElement.volume = 1;
            }
            return;
        }

        // Don't activate interruption prevention until after first exchange
        if (!this.hasHadFirstExchange) {
            if (this.remoteAudioElement.volume !== 1) {
                this.remoteAudioElement.volume = 1;
            }
            return;
        }

        // Initialize lastUserSpeechTime on first use
        if (this.lastUserSpeechTime === null) {
            this.lastUserSpeechTime = currentTime - 1000; // Set to 1 second ago
        }

        const timeSinceUserSpeech = currentTime - this.lastUserSpeechTime;
        const userIsRecentlySpeaking = timeSinceUserSpeech < this.USER_SILENCE_THRESHOLD;

        if (userIsRecentlySpeaking) {
            // User is speaking or just stopped - mute agent audio
            if (this.remoteAudioElement.volume !== 0) {
                this.remoteAudioElement.volume = 0;
            }
        } else {
            // User has been silent for 500ms+ - unmute agent audio
            if (this.remoteAudioElement.volume !== 1) {
                this.remoteAudioElement.volume = 1;
            }
        }
    }
    
    // Animation properties (no longer need canvas)
    animationFrame;
    currentIntensity = 0;
    targetIntensity = 0;
    currentState = 'idle';
    stateStartTime = Date.now();
    lastActivityTime = Date.now();
    
    // LiveKit connection
    livekitRoom = null;
    livekitLoaded = false;
    localAudioTrack = null;
    remoteAudioElement = null;
    
    // Separate raw microphone stream for level monitoring (not muted by LiveKit)
    rawMicStream = null;
    
    // Audio levels for animation
    micLevel = 0;
    speakerLevel = 0;
    
    // Voice activity detection for interruption prevention
    lastUserSpeechTime = null; // null = not yet initialized
    hasHadFirstExchange = false; // Only activate interruption prevention after first exchange
    audioContext = null;
    analyser = null;
    
    // localStorage key for persisting config
    CONFIG_STORAGE_KEY = 'agentforce_voice_config';
    
    async connectedCallback() {
        console.log('=== COMPONENT INITIALIZED ===');
        
        // Load configuration from localStorage
        this.loadConfigFromStorage();
        
        // Only load dynamically if properties are not set (check for empty string OR null/undefined)
        const hasInstanceUrl = this.instanceUrl && this.instanceUrl.trim() !== '';
        const hasAgentId = this.agentId && this.agentId.trim() !== '';
        const hasVersionId = this.versionId && this.versionId.trim() !== '';
        
        if (!hasInstanceUrl || !hasAgentId || !hasVersionId) {
            console.log('Properties not set, loading agents dynamically...');
            await this.loadVoiceAgents();
        } else {
            console.log('Using provided properties:', {
                instanceUrl: this.instanceUrl,
                agentId: this.agentId,
                versionId: this.versionId
            });
            this.statusText = 'Click Connect to start';
        }
    }
    
    // Load configuration from localStorage
    loadConfigFromStorage() {
        try {
            const stored = localStorage.getItem(this.CONFIG_STORAGE_KEY);
            if (stored) {
                const config = JSON.parse(stored);
                console.log('📥 Loaded config from localStorage:', config);
                
                // Update tracked values (for UI)
                this.configMicThreshold = config.micThreshold || 5;
                this.configSpeakerThreshold = config.speakerThreshold || 8;
                this.configPriorityMultiplier = config.priorityMultiplier || 1.2;
                this.configSilenceThreshold = config.silenceThreshold || 500;
                this.configStateLock = config.stateLock || 1200;
                
                // Update active values (for detection)
                this.MIC_THRESHOLD = this.configMicThreshold;
                this.SPEAKER_THRESHOLD = this.configSpeakerThreshold;
                this.PRIORITY_MULTIPLIER = this.configPriorityMultiplier;
                this.USER_SILENCE_THRESHOLD = this.configSilenceThreshold;
                this.STATE_LOCK = this.configStateLock;
                
                console.log('✅ Configuration applied:', {
                    mic: this.MIC_THRESHOLD,
                    speaker: this.SPEAKER_THRESHOLD,
                    priority: this.PRIORITY_MULTIPLIER,
                    silence: this.USER_SILENCE_THRESHOLD,
                    stateLock: this.STATE_LOCK
                });
            } else {
                console.log('ℹ️ No saved config found, using defaults');
            }
        } catch (error) {
            console.error('❌ Error loading config from localStorage:', error);
        }
    }
    
    // Save configuration to localStorage
    saveConfigToStorage() {
        try {
            const config = {
                micThreshold: this.configMicThreshold,
                speakerThreshold: this.configSpeakerThreshold,
                priorityMultiplier: this.configPriorityMultiplier,
                silenceThreshold: this.configSilenceThreshold,
                stateLock: this.configStateLock
            };
            localStorage.setItem(this.CONFIG_STORAGE_KEY, JSON.stringify(config));
            console.log('💾 Config saved to localStorage:', config);
        } catch (error) {
            console.error('❌ Error saving config to localStorage:', error);
        }
    }
    
    /**
     * Check if an agent has voice capability by calling the bootstrap endpoint
     * This is the REAL test - same method the voice component uses!
     */
    async checkHasVoiceCapability(agentId) {
        try {
            const hasVoice = await checkVoiceCapability({
                instanceUrl: this.instanceUrl,
                agentId: agentId
            });
            return hasVoice;
        } catch (error) {
            console.error(`Error checking voice capability for agent ${agentId}:`, error);
            return false;
        }
    }

    async loadVoiceAgents() {
        this.isLoadingAgents = true;
        try {
            const result = await getAllBots();
            
            console.log('=== RAW RESULT FROM APEX ===');
            console.log('Total agents fetched:', result.count);
            
            if (result.error) {
                console.error('Error loading agents:', result.error);
                this.statusText = 'Failed to load agents';
                return;
            }
            
            // Store instance URL
            this.instanceUrl = result.instanceUrl;
            console.log('Instance URL:', this.instanceUrl);
            
            const allBots = result.bots || [];
            console.log(`\n🔍 Checking ${allBots.length} agents for VOICE capability (via bootstrap)...`);
            
            // Check each bot for voice capability via bootstrap endpoint
            // This is the REAL test - same as what the voice component uses!
            const voiceChecks = await Promise.all(
                allBots.map(async (bot) => {
                    const hasVoice = await this.checkHasVoiceCapability(bot.id);
                    console.log(`  ${hasVoice ? '✅' : '❌'} ${bot.masterLabel} - Voice: ${hasVoice}`);
                    
                    return hasVoice ? bot : null;
                })
            );
            
            // Filter out null values (bots without voice capability)
            this.voiceAgents = voiceChecks.filter(bot => bot !== null);
            
            console.log(`\n✅ Found ${this.voiceAgents.length} TRULY voice-enabled agent(s):`);
            this.voiceAgents.forEach((bot, index) => {
                console.log(`  ${index + 1}. ${bot.masterLabel} (ID: ${bot.id})`);
            });
            
            // Auto-select first agent if available
            if (this.voiceAgents.length > 0) {
                this.selectAgent(this.voiceAgents[0]);
            } else {
                this.statusText = 'No voice agents available';
                console.warn('⚠️ No agents with voice capability found (bootstrap test)');
            }
            
        } catch (error) {
            console.error('Failed to load voice agents:', error);
            this.statusText = 'Agent loading failed';
        } finally {
            this.isLoadingAgents = false;
        }
    }
    
    selectAgent(agent) {
        console.log('Selecting agent:', agent.masterLabel);
        this.selectedAgent = agent;
        this.agentId = agent.id;
        this.versionId = agent.activeVersionId;
        this.showAgentList = false;
        this.statusText = 'Click Connect to start';
        
        console.log('Selected:', {
            name: agent.masterLabel,
            agentId: this.agentId,
            versionId: this.versionId
        });
    }
    
    toggleAgentList() {
        if (this.connected) {
            console.log('Cannot change agent while connected');
            return;
        }
        this.showAgentList = !this.showAgentList;
        
        // Position dropdown below the agent selector
        if (this.showAgentList) {
            setTimeout(() => {
                const container = this.template.querySelector('.agent-list-container');
                const selector = this.template.querySelector('.agent-selector');
                
                if (container && selector) {
                    const rect = selector.getBoundingClientRect();
                    container.style.top = `${rect.bottom + 8}px`;
                    container.style.left = `${rect.left}px`;
                }
            }, 10);
        }
    }
    
    handleAgentSelection(event) {
        const agentId = event.currentTarget.dataset.agentId;
        const agent = this.voiceAgents.find(a => a.id === agentId);
        if (agent) {
            this.selectAgent(agent);
        }
    }
    
    get displayAgentName() {
        return this.selectedAgent ? this.selectedAgent.masterLabel : 'Select Voice Agent';
    }
    
    get agentListClass() {
        return this.showAgentList ? 'agent-list-container show' : 'agent-list-container';
    }
    
    // Message management methods
    addMessage(text, sender, isFinal = true) {
        if (!text || text.trim().length === 0) return;
        
        if (!isFinal) {
            // Interim transcript - store temporarily (only for UI display)
            this.interimMessage = { text, sender, timestamp: Date.now(), interim: true };
        } else {
            // Final transcript - add to conversation
            this.interimMessage = null;
            
            // Activate interruption prevention after first agent message
            if (sender === 'agent' && !this.hasHadFirstExchange) {
                this.hasHadFirstExchange = true;
                console.log('✅ First agent message received - interruption prevention activated');
            }
            
            // Check if we should update last message (same sender)
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
                    id: Date.now() + Math.random()
                });
            }
            
            // Keep only last 3 messages
            if (this.conversationMessages.length > 3) {
                this.conversationMessages = this.conversationMessages.slice(-3);
            }
            
            // Force reactivity
            this.conversationMessages = [...this.conversationMessages];
        }
        
        // Auto-scroll to bottom after message is added
        this.scrollToBottom();
    }
    
    scrollToBottom() {
        // Use setTimeout to ensure DOM is updated
        setTimeout(() => {
            const container = this.template.querySelector('.conversation-container');
            if (container) {
                container.scrollTop = container.scrollHeight;
            }
        }, 50);
    }
    
    clearMessages() {
        this.conversationMessages = [];
        this.interimMessage = null;
    }
    
    get displayMessages() {
        // Return last 3 final messages + interim if exists
        const messages = [...this.conversationMessages];
        if (this.interimMessage) {
            messages.push(this.interimMessage);
        }
        return messages.slice(-3);
    }
    
    renderedCallback() {
        // Initialize waveform animation
        if (!this.initialized) {
            console.log('=== COMPONENT RENDERED ===');
            this.initialized = true;
            this.startWaveformAnimation();
        }
    }
    
    startWaveformAnimation() {
        // Update waveform bars based on audio levels AND manage state
        const animate = () => {
            const now = Date.now();
            const timeInState = now - this.stateStartTime;
            const timeSinceActivity = now - this.lastActivityTime;
            
            // Use real audio levels
            const micLevel = this.micLevel;
            const speakerLevel = this.speakerLevel;
            
            // State management (from original startAnimation)
            if (this.connected) {
                // When muted, force state to 'connected' but still allow agent speaking detection
                if (this.isMuted) {
                    // Check only speaker activity when muted
                    const isSpeakerActive = speakerLevel > this.SPEAKER_THRESHOLD;
                    
                    if (isSpeakerActive) {
                        this.lastActivityTime = now;
                    }
                    
                    let desiredState;
                    if (isSpeakerActive) {
                        desiredState = 'speaking';
                    } else if (timeSinceActivity < 2000) {
                        desiredState = this.currentState === 'speaking' ? 'speaking' : 'connected';
                    } else {
                        desiredState = 'connected';
                    }
                    
                    const canChangeState = timeInState >= this.STATE_LOCK ||
                        (desiredState === 'speaking' && this.currentState === 'connected');
                    
                    if (canChangeState && desiredState !== this.currentState) {
                        console.log('State change (muted):', this.currentState, '->', desiredState, 'Speaker:', speakerLevel);
                        this.currentState = desiredState;
                        this.stateStartTime = now;
                    }
                    
                    // Update status text for muted state
                    if (this.currentState === 'speaking') {
                        if (this.statusText !== 'Speaking') {
                            this.updateStatus('Speaking', 'Agent is responding...');
                        }
                    } else {
                        if (this.statusText !== 'Muted') {
                            this.updateStatus('Muted', 'Microphone is off');
                        }
                    }
                } else {
                    // Normal state detection when NOT muted
                    const isMicActive = micLevel > this.MIC_THRESHOLD;
                    const isSpeakerActive = speakerLevel > this.SPEAKER_THRESHOLD;
                    
                    // Manage agent audio output based on user speech
                    // Note: manageAgentAudioOutput handles the muted case internally
                    this.manageAgentAudioOutput(now);
                    
                    // Track user speech for interruption prevention (ONLY when NOT muted)
                    // Only count as user speech if mic is significantly louder than speaker (20% rule)
                    // This prevents ambient noise during agent speech from being mistaken as user speech
                    if (!this.isMuted) {
                        const userIsSpeaking = isMicActive && micLevel > speakerLevel * this.PRIORITY_MULTIPLIER;
                        
                        if (userIsSpeaking) {
                            this.lastUserSpeechTime = now;
                        }
                    }
                    
                    if (isMicActive || isSpeakerActive) {
                        this.lastActivityTime = now;
                    }
                    
                    let desiredState;
                    if (isMicActive && micLevel > speakerLevel * this.PRIORITY_MULTIPLIER) {
                        desiredState = 'listening';
                    } else if (isSpeakerActive) {
                        desiredState = 'speaking';
                    } else if (timeSinceActivity < 2000) {
                        desiredState = this.currentState;
                    } else {
                        desiredState = 'connected';
                    }
                    
                    const canChangeState = timeInState >= this.STATE_LOCK ||
                        ((desiredState === 'listening' || desiredState === 'speaking') && this.currentState === 'connected');
                    
                    if (canChangeState && desiredState !== this.currentState) {
                        this.currentState = desiredState;
                        this.stateStartTime = now;
                    }
                    
                    // Update status text
                    if (this.currentState === 'listening') {
                        if (this.statusText !== 'Listening') {
                            this.updateStatus('Listening', 'I can hear you...');
                        }
                    } else if (this.currentState === 'speaking') {
                        if (this.statusText !== 'Speaking') {
                            this.updateStatus('Speaking', 'Agent is responding...');
                        }
                    } else {
                        if (this.statusText !== 'Connected') {
                            this.updateStatus('Connected', 'Speak to begin');
                        }
                    }
                }
            } else if (!this.isConnecting) {
                if (this.statusText !== 'Click Connect to start') {
                    this.updateStatus('Click Connect to start', '');
                }
            }
            
            // Update card class
            const card = this.template.querySelector('.voice-card');
            if (card) {
                card.className = this.cardClass;
            }
            
            // Update bar heights based on audio amplitude
            const bars = this.template.querySelectorAll('.waveform-bar');
            if (bars && bars.length > 0 && (this.currentState === 'listening' || this.currentState === 'speaking')) {
                const level = this.currentState === 'listening' ? micLevel : speakerLevel;
                const baseHeight = 12;
                const maxHeight = 70;
                
                bars.forEach((bar, index) => {
                    // Create wave pattern with audio-reactive amplitude
                    const wavePhase = (now / 500) + (index * 0.3);
                    const wave = Math.sin(wavePhase) * 0.5 + 0.5;
                    
                    // Mix wave pattern with audio level
                    // Divide by 2 to reduce scaling and prevent clipping
                    const audioFactor = Math.max(level / 60, 0.3); // Normalized and reduced by half
                    const heightVariation = (maxHeight - baseHeight) * wave * audioFactor;
                    const height = Math.min(maxHeight, baseHeight + heightVariation); // Cap at maxHeight
                    
                    bar.style.height = `${height}px`;
                });
            } else if (bars && bars.length > 0) {
                // Reset to CSS animation when idle/connecting
                bars.forEach(bar => {
                    bar.style.height = '';
                });
            }
            
            this.animationFrame = requestAnimationFrame(animate);
        };
        animate();
    }
    
    toggleConnection() {
        console.log('=== TOGGLE CONNECTION CLICKED ===');
        
        if (this.isConnecting) {
            console.log('Already connecting, ignoring click');
            return;
        }
        
        if (this.connected) {
            console.log('Disconnecting...');
            this.disconnect();
        } else {
            console.log('Connecting...');
            this.connect();
        }
    }
    
    toggleMute() {
        console.log('=== TOGGLE MUTE CLICKED ===');

        if (!this.connected) {
            console.log('Not connected, cannot mute');
            return;
        }

        this.isMuted = !this.isMuted;

        // Mute/unmute the local audio track
        if (this.localAudioTrack) {
            if (this.isMuted) {
                this.localAudioTrack.mute();
                console.log('🔇 Microphone muted - agent will play normally');
            } else {
                this.localAudioTrack.unmute();
                console.log('🔊 Microphone unmuted - resetting everything like fresh connect');
                
                // COMPLETE RESET: When unmuting, reset all speech detection variables
                // This is like pressing connect for the first time
                this.lastUserSpeechTime = null; // Reset to uninitialized
                this.micLevel = 0;
                this.speakerLevel = 0;
            }

            // Reset state timing
            this.currentState = 'connected';
            this.stateStartTime = Date.now();
            this.lastActivityTime = Date.now();
        }
    }
    
    toggleDebug() {
        console.log('Toggling debug panel. Current state:', this.showDebug);
        this.showDebug = !this.showDebug;
        console.log('New debug panel state:', this.showDebug);
    }
    
    toggleConfig() {
        console.log('Toggling config panel. Current state:', this.showConfig);
        this.showConfig = !this.showConfig;
        console.log('New config panel state:', this.showConfig);
    }
    
    handleOverlayClick() {
        // Close config when clicking overlay (outside panel)
        this.showConfig = false;
    }
    
    handlePanelClick(event) {
        // Prevent overlay click from closing when clicking inside panel
        event.stopPropagation();
    }
    
    // Configuration change handlers
    handleMicThresholdChange(event) {
        this.configMicThreshold = parseInt(event.target.value, 10);
    }
    
    handleMicThresholdInput(event) {
        this.configMicThreshold = parseInt(event.target.value, 10);
    }
    
    handleSpeakerThresholdChange(event) {
        this.configSpeakerThreshold = parseInt(event.target.value, 10);
    }
    
    handleSpeakerThresholdInput(event) {
        this.configSpeakerThreshold = parseInt(event.target.value, 10);
    }
    
    handlePriorityMultiplierChange(event) {
        this.configPriorityMultiplier = parseFloat(event.target.value);
    }
    
    handlePriorityMultiplierInput(event) {
        this.configPriorityMultiplier = parseFloat(event.target.value);
    }
    
    handleSilenceThresholdChange(event) {
        this.configSilenceThreshold = parseInt(event.target.value, 10);
    }
    
    handleSilenceThresholdInput(event) {
        this.configSilenceThreshold = parseInt(event.target.value, 10);
    }
    
    handleStateLockChange(event) {
        this.configStateLock = parseInt(event.target.value, 10);
    }
    
    handleStateLockInput(event) {
        this.configStateLock = parseInt(event.target.value, 10);
    }
    
    handleResetConfig() {
        console.log('🔄 Resetting configuration to defaults');
        this.configMicThreshold = 5;
        this.configSpeakerThreshold = 8;
        this.configPriorityMultiplier = 1.2;
        this.configSilenceThreshold = 500;
        this.configStateLock = 1200;
    }
    
    handleConfirmConfig() {
        console.log('✅ Applying configuration');
        
        // Apply to active values
        this.MIC_THRESHOLD = this.configMicThreshold;
        this.SPEAKER_THRESHOLD = this.configSpeakerThreshold;
        this.PRIORITY_MULTIPLIER = this.configPriorityMultiplier;
        this.USER_SILENCE_THRESHOLD = this.configSilenceThreshold;
        this.STATE_LOCK = this.configStateLock;
        
        // Save to localStorage
        this.saveConfigToStorage();
        
        // Close panel
        this.showConfig = false;
        
        console.log('🎯 New configuration active:', {
            mic: this.MIC_THRESHOLD,
            speaker: this.SPEAKER_THRESHOLD,
            priority: this.PRIORITY_MULTIPLIER,
            silence: this.USER_SILENCE_THRESHOLD,
            stateLock: this.STATE_LOCK
        });
    }
    
    async toggleConnection() {
        console.log('=== TOGGLE CONNECTION ===');
        console.log('Current connected state:', this.connected);
        console.log('Current isConnecting state:', this.isConnecting);
        
        if (this.isConnecting) {
            console.log('Already connecting, ignoring click');
            return;
        }
        
        if (this.connected) {
            console.log('Disconnecting...');
            this.disconnect();
        } else {
            console.log('Connecting...');
            // Force immediate UI update
            await this.updateStatus('Starting...', 'Initializing connection');
            await this.connect();
        }
    }
    
    // Helper method to retry session operations
    async retryOperation(operationFn, operationName, maxRetries = 3) {
        let lastError;
        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                console.log(`🔄 ${operationName} attempt ${attempt}/${maxRetries}`);
                if (attempt > 1) {
                    await this.updateStatus('Connecting...', `Retrying ${operationName.toLowerCase()} (${attempt}/${maxRetries})`);
                }
                const result = await operationFn();
                console.log(`✅ ${operationName} succeeded on attempt ${attempt}`);
                return result;
            } catch (error) {
                lastError = error;
                console.error(`❌ ${operationName} attempt ${attempt} failed:`, error.message);
                
                if (attempt < maxRetries) {
                    // Wait 1 second before retrying
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
            }
        }
        // If all retries failed, throw the last error
        throw lastError;
    }
    
    async connect() {
        console.log('=== AGENTFORCE VOICE: Connect initiated ===');
        console.log('Instance URL:', this.instanceUrl);
        console.log('Agent ID:', this.agentId);
        console.log('Version ID:', this.versionId);
        
        if (!this.instanceUrl || !this.agentId || !this.versionId) {
            await this.updateStatus('Config missing', 'Triple-click to configure');
            console.error('Missing configuration:', { instanceUrl: this.instanceUrl, agentId: this.agentId, versionId: this.versionId });
            return;
        }
        
        this.isConnecting = true;
        await this.updateStatus('Connecting...', 'Getting authentication');
        console.log('Step 1: Getting bootstrap token...');
        
        try {
            // Load LiveKit SDK if not already loaded
            if (!this.livekitLoaded) {
                await this.updateStatus('Connecting...', 'Loading audio library');
                console.log('Loading LiveKit from Static Resource:', LIVEKIT_SDK);
                await loadScript(this, LIVEKIT_SDK);
                this.livekitLoaded = true;
                console.log('✅ LiveKit SDK loaded');
            }
            
            // Step 1: Get bootstrap token
            await this.updateStatus('Connecting...', 'Authenticating');
            console.time('Bootstrap');
            const bootstrapResult = await getBootstrapToken({
                instanceUrl: this.instanceUrl,
                agentId: this.agentId
            });
            console.timeEnd('Bootstrap');
            console.log('Bootstrap result:', bootstrapResult);
            
            if (!bootstrapResult.success) {
                throw new Error('Authentication failed');
            }
            
            const voiceJwt = bootstrapResult.access_token || bootstrapResult.jwt;
            console.log('Got JWT (first 50 chars):', voiceJwt ? voiceJwt.substring(0, 50) + '...' : 'null');
            
            if (!voiceJwt) {
                throw new Error('No JWT received from bootstrap');
            }
            
            // Step 2: Create session (with retry)
            await this.updateStatus('Connecting...', 'Creating session');
            console.log('Step 2: Creating session with JWT...');
            console.time('CreateSession');
            const sessionResult = await this.retryOperation(
                () => createSession({
                    voiceJwt: voiceJwt,
                    agentId: this.agentId,
                    versionId: this.versionId,
                    instanceUrl: this.instanceUrl
                }),
                'Create session',
                3
            );
            console.timeEnd('CreateSession');
            console.log('Session result:', sessionResult);
            
            if (!sessionResult.success) {
                throw new Error('Session creation failed');
            }
            
            const sessionId = sessionResult.sessionId;
            console.log('Session ID:', sessionId);
            
            if (!sessionId) {
                throw new Error('No session ID received');
            }
            
            // Step 3: Join session (with retry)
            await this.updateStatus('Connecting...', 'Joining voice session');
            console.log('Step 3: Joining session:', sessionId);
            console.time('JoinSession');
            const joinResult = await this.retryOperation(
                () => joinSession({
                    voiceJwt: voiceJwt,
                    sessionId: sessionId,
                    versionId: this.versionId
                }),
                'Join session',
                3
            );
            console.timeEnd('JoinSession');
            console.log('Join result:', joinResult);
            
            if (!joinResult.success) {
                throw new Error('Failed to join session');
            }
            
            // Step 4: Connect to LiveKit
            await this.updateStatus('Connecting...', 'Connecting to audio');
            console.log('=== LIVEKIT CREDENTIALS ===');
            console.log('URL:', joinResult.url);
            console.log('Room:', joinResult.roomName);
            console.log('Token (first 50 chars):', joinResult.token ? joinResult.token.substring(0, 50) + '...' : 'null');
            console.log('===========================');
            
            await this.connectToLiveKit(joinResult.url, joinResult.token);
            
            this.connected = true;
            await this.updateStatus('Connected', 'Speak to begin');
            this.currentState = 'connected';
            
            console.log('=== CONNECTION SUCCESS ===');
            console.log('Full audio streaming active!');
            
        } catch (error) {
            const errorMsg = error.message || error.toString();
            await this.updateStatus('Connection failed', errorMsg, 'Error in connect()');
            console.error('=== CONNECTION FAILED ===');
            console.error('Error:', error);
            console.error('Stack:', error.stack);
        } finally {
            this.isConnecting = false;
            console.log('isConnecting set to false');
        }
    }
    
    setupTranscriptionListeners(LivekitClient) {
        try {
            console.log('Setting up transcription event listeners...');
            
            // Use the standard LiveKit event (only one to avoid duplicates)
            const eventName = LivekitClient.RoomEvent?.TranscriptionReceived || 'TranscriptionReceived';
            
            console.log('Registering listener for:', eventName);
            this.livekitRoom.on(eventName, (transcriptions, participant, publication) => {
                if (!transcriptions) return;
                
                // Handle array or single transcription
                const transcriptArray = Array.isArray(transcriptions) ? transcriptions : [transcriptions];
                
                transcriptArray.forEach(segment => {
                    const text = segment.text || segment.transcript || '';
                    const isFinal = segment.final !== false; // Default to final if not specified
                    
                    // Determine if this is agent or user
                    const participantId = participant?.identity || '';
                    const isAgent = participantId.toLowerCase().includes('agent') || 
                                   participantId.toLowerCase().includes('bot');
                    const sender = isAgent ? 'agent' : 'user';
                    
                    if (text && text.trim().length > 0) {
                        this.addMessage(text.trim(), sender, isFinal);
                    }
                });
            });
            
            // Also listen for data channel messages (alternative transcription method)
            this.livekitRoom.on(LivekitClient.RoomEvent.DataReceived, (payload, participant, kind) => {
                try {
                    const decoder = new TextDecoder();
                    const dataStr = decoder.decode(payload);
                    const data = JSON.parse(dataStr);
                    
                    console.log('📦 Data received:', data);
                    
                    // Check if it's transcription data
                    if (data.type === 'transcription' || data.transcript || data.text) {
                        const text = data.text || data.transcript;
                        const isFinal = data.isFinal !== false;
                        const participantId = participant?.identity || '';
                        const isAgent = participantId.toLowerCase().includes('agent');
                        const sender = isAgent ? 'agent' : 'user';
                        
                        console.log('📝 Transcript from data channel:', { text, sender, isFinal });
                        this.addMessage(text, sender, isFinal);
                    }
                } catch (e) {
                    // Not JSON or not transcription data, ignore
                }
            });
            
            console.log('✅ Transcription listeners set up');
            
        } catch (error) {
            console.error('Error setting up transcription listeners:', error);
        }
    }
    
    async connectToLiveKit(url, token) {
        try {
            await this.updateStatus('Connecting...', 'Setting up audio room');
            console.log('🎙️ Creating LiveKit Room...');
            
            // Access LiveKit from window (loaded from CDN)
            const LivekitClient = window.LivekitClient;
            if (!LivekitClient) {
                throw new Error('LiveKit SDK not loaded properly');
            }
            
            // Create room
            this.livekitRoom = new LivekitClient.Room({
                adaptiveStream: true,
                dynacast: true,
            });
            
            // Set up transcription event listeners
            console.log('🎤 Setting up transcription listeners...');
            this.setupTranscriptionListeners(LivekitClient);
            
            // Set up event handlers
            this.livekitRoom.on(LivekitClient.RoomEvent.TrackSubscribed, (track, publication, participant) => {
                console.log('📥 Track subscribed:', track.kind, 'from', participant.identity);
                
                if (track.kind === LivekitClient.Track.Kind.Audio) {
                    console.log('🔊 Playing agent audio...');
                    this.playRemoteAudio(track);
                }
            });
            
            this.livekitRoom.on(LivekitClient.RoomEvent.Disconnected, () => {
                console.log('🔌 LiveKit disconnected');
            });
            
            this.livekitRoom.on(LivekitClient.RoomEvent.ParticipantConnected, (participant) => {
                console.log('👤 Participant connected:', participant.identity);
            });
            
            // Connect to room
            console.log('🌐 Connecting to LiveKit room...');
            await this.livekitRoom.connect(url, token);
            console.log('✅ Connected to LiveKit room!');
            
            // Publish microphone
            await this.publishMicrophone(LivekitClient);
            
        } catch (error) {
            console.error('❌ LiveKit connection error:', error);
            throw error;
        }
    }
    
    async publishMicrophone(LivekitClient) {
        try {
            console.log('🎙️ Requesting microphone access...');
            await this.updateStatus('Connecting...', 'Requesting microphone');
            
            // Get raw microphone stream for level monitoring (independent of LiveKit)
            this.rawMicStream = await navigator.mediaDevices.getUserMedia({ 
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                } 
            });
            console.log('✅ Raw microphone stream obtained for monitoring');
            
            // Start monitoring the RAW stream (this will never be muted)
            this.startMicLevelMonitoring(this.rawMicStream);
            
            // Create LiveKit local audio track (this one will be muted/unmuted for transmission)
            this.localAudioTrack = await LivekitClient.createLocalAudioTrack({
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true,
            });
            
            console.log('✅ LiveKit audio track created');
            
            // Publish to room
            await this.livekitRoom.localParticipant.publishTrack(this.localAudioTrack);
            console.log('📤 Microphone published to room');
            
        } catch (error) {
            console.error('❌ Microphone error:', error);
            throw error;
        }
    }
    
    playRemoteAudio(track) {
        try {
            // Create audio element if it doesn't exist
            if (!this.remoteAudioElement) {
                this.remoteAudioElement = document.createElement('audio');
                this.remoteAudioElement.autoplay = true;
            }
            
            // Attach track to audio element for playback
            track.attach(this.remoteAudioElement);
            console.log('🔊 Remote audio attached and playing');
            
            // Start monitoring speaker level using the track's MediaStream directly
            this.startSpeakerLevelMonitoring(track);
            
        } catch (error) {
            console.error('❌ Audio playback error:', error);
        }
    }
    
    startMicLevelMonitoring(mediaStream) {
        try {
            console.log('🎚️ Starting mic level monitoring from raw stream');
            
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }
            
            const source = this.audioContext.createMediaStreamSource(mediaStream);
            const analyser = this.audioContext.createAnalyser();
            analyser.fftSize = 256;
            analyser.smoothingTimeConstant = 0.8;
            source.connect(analyser);
            
            const dataArray = new Uint8Array(analyser.frequencyBinCount);
            
            const updateMicLevel = () => {
                // Monitor as long as we have the raw stream
                if (this.rawMicStream) {
                    analyser.getByteFrequencyData(dataArray);
                    const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
                    this.micLevel = Math.min(100, average);
                    requestAnimationFrame(updateMicLevel);
                }
            };
            
            updateMicLevel();
            console.log('✅ Mic level monitoring started (independent of LiveKit mute)');
            
        } catch (error) {
            console.error('❌ Mic monitoring error:', error);
        }
    }
    
    startSpeakerLevelMonitoring(track) {
        try {
            console.log('🔊 Starting speaker level monitoring');
            
            // Create MediaStream from the LiveKit track
            const mediaStream = new MediaStream([track.mediaStreamTrack]);
            
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }
            
            // Resume audio context if suspended (browser autoplay policy)
            if (this.audioContext.state === 'suspended') {
                this.audioContext.resume();
            }
            
            // Create analyser from the MediaStream (not the audio element!)
            const source = this.audioContext.createMediaStreamSource(mediaStream);
            const analyser = this.audioContext.createAnalyser();
            analyser.fftSize = 256;
            analyser.smoothingTimeConstant = 0.8;
            source.connect(analyser);
            // Note: We don't connect to destination because LiveKit already handles playback
            
            const dataArray = new Uint8Array(analyser.frequencyBinCount);
            
            const updateSpeakerLevel = () => {
                // Don't check this.connected - the track itself is the source of truth
                if (this.remoteAudioElement) {
                    analyser.getByteFrequencyData(dataArray);
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
    
    disconnect() {
        console.log('=== DISCONNECT ===');
        this.connected = false;
        this.isMuted = false; // Reset mute state on disconnect
        this.updateStatus('Click Connect to start', '');
        this.currentState = 'idle';
        this.clearMessages(); // Clear conversation on disconnect
        console.log('Disconnected. State reset to idle. Messages cleared.');
        
        // Clean up LiveKit
        if (this.livekitRoom) {
            console.log('Cleaning up LiveKit room connection');
            this.livekitRoom.disconnect();
            this.livekitRoom = null;
        }
        
        // Stop LiveKit audio track
        if (this.localAudioTrack) {
            this.localAudioTrack.stop();
            this.localAudioTrack = null;
        }
        
        // Stop raw microphone stream
        if (this.rawMicStream) {
            this.rawMicStream.getTracks().forEach(track => track.stop());
            this.rawMicStream = null;
            console.log('Raw microphone stream stopped');
        }
        
        // Clean up audio elements
        if (this.remoteAudioElement) {
            this.remoteAudioElement.pause();
            this.remoteAudioElement = null;
        }
        
        // Reset audio levels
        this.micLevel = 0;
        this.speakerLevel = 0;
    }
    
    startAnimation() {
        const animate = () => {
            const now = Date.now();
            const timeInState = now - this.stateStartTime;
            const timeSinceActivity = now - this.lastActivityTime;
            
            // Use real audio levels
            const micLevel = this.micLevel;
            const speakerLevel = this.speakerLevel;
            
            // State management
            if (this.connected) {
                const isMicActive = micLevel > 1;  // Lowered threshold for mic
                const isSpeakerActive = speakerLevel > 3;  // Lowered threshold for speaker
                
                if (isMicActive || isSpeakerActive) {
                    this.lastActivityTime = now;
                }
                
                let desiredState;
                if (isMicActive && micLevel > speakerLevel * 0.7) {
                    desiredState = 'listening';
                } else if (isSpeakerActive) {
                    desiredState = 'speaking';
                } else if (timeSinceActivity < 1500) {
                    desiredState = this.currentState;
                } else {
                    desiredState = 'connected';
                }
                
                const canChangeState = timeInState >= 800 || 
                    ((desiredState === 'listening' || desiredState === 'speaking') && this.currentState === 'connected');
                
                if (canChangeState && desiredState !== this.currentState) {
                    this.currentState = desiredState;
                    this.stateStartTime = now;
                }
                
                // Set targets
                if (this.currentState === 'listening') {
                    this.targetIntensity = 0.6;
                    this.targetColor = [0, 255, 136]; // Green for listening
                    if (this.statusText !== 'Listening') {
                        this.updateStatus('Listening', 'I can hear you...');
                    }
                } else if (this.currentState === 'speaking') {
                    this.targetIntensity = 0.6;
                    this.targetColor = [0, 217, 255]; // Cyan for speaking
                    if (this.statusText !== 'Speaking') {
                        this.updateStatus('Speaking', 'Agent is responding...');
                    }
                } else {
                    this.targetIntensity = 0.2;
                    this.targetColor = [80, 80, 80]; // Dark gray for connected idle
                    if (this.statusText !== 'Connected') {
                        this.updateStatus('Connected', 'Speak to begin');
                    }
                }
            } else if (!this.isConnecting) {
                // Only update to "Click Connect to start" if we're not currently connecting
                this.targetIntensity = 0.15;
                this.targetColor = [0, 0, 0]; // Black for disconnected
                if (this.statusText !== 'Click Connect to start') {
                    this.updateStatus('Click Connect to start', '');
                }
            } else {
                // During connection, keep the pulsing animation but don't change status
                this.targetIntensity = 0.3;
                this.targetColor = [100, 100, 100]; // Gray for connecting
            }
            
            // Smooth transitions
            this.currentIntensity += (this.targetIntensity - this.currentIntensity) * 0.12;
            for (let i = 0; i < 3; i++) {
                this.currentColor[i] += (this.targetColor[i] - this.currentColor[i]) * 0.12;
            }
            
            const color = `rgb(${Math.round(this.currentColor[0])}, ${Math.round(this.currentColor[1])}, ${Math.round(this.currentColor[2])})`;
            
            // Draw circles
            if (this.ctx) {
                this.ctx.clearRect(0, 0, 500, 500);
                
                this.waveOffset += 0.08;
                const center = 250;
                const baseRadius = 70;
                
                for (let i = 0; i < 10; i++) {
                    const phase = (i / 10) * 2 * Math.PI;
                    const wave1 = Math.sin(this.waveOffset + phase);
                    const wave2 = Math.sin(this.waveOffset * 1.5 + phase * 0.7) * 0.5;
                    const wave3 = Math.sin(this.waveOffset * 0.8 + phase * 1.3) * 0.3;
                    const combinedWave = (wave1 + wave2 + wave3) / 1.8;
                    
                    const radiusVariation = 35 * this.currentIntensity * combinedWave;
                    const radius = baseRadius + (i * 9) + radiusVariation;
                    
                    const opacity = 1.0 - (i / 10) * 0.65;
                    const width = Math.max(1, 2.5 * opacity * (1 + this.currentIntensity * 0.8));
                    
                    this.ctx.strokeStyle = color;
                    this.ctx.globalAlpha = opacity;
                    this.ctx.lineWidth = width;
                    this.ctx.beginPath();
                    this.ctx.arc(center, center, radius, 0, 2 * Math.PI);
                    this.ctx.stroke();
                }
                
                this.ctx.globalAlpha = 1;
            }
            
            requestAnimationFrame(animate);
        };
        
        animate();
    }
}