# Voice Agent Chat LWC Migration Package

This package contains the **voiceAgentChat** (Agentforce Speech Foundation) Lightning Web Component and all its dependencies.

## What This Component Does

A push-to-talk voice chat interface for Agentforce agents using:
- **Speech-to-Text (STT)**: Deepgram or AWS Transcribe via Einstein Platform APIs
- **Text-to-Speech (TTS)**: ElevenLabs or AWS Polly via Einstein Platform APIs
- **Agent Chat API**: Einstein AI Agent API for conversation

## Contents

### LWC Component
- `voiceAgentChat` - Push-to-talk voice interface with STT/TTS

### Apex Classes
- `TTSService` - Gets OAuth access token for LWC WebSocket connections
- `AgentChatService` - Agent session management, message sending, agent listing

### Static Resources
- `agentforce_icon.png` - Agentforce logo

### Named Credentials
- `APITooling` - OAuth client credentials for Salesforce APIs

### External Credentials
- `APITooling` - Authentication configuration

### Connected Apps
- `APITooling` - OAuth app for client credentials flow

### Remote Site Settings
- `Salesforce_API` - https://api.salesforce.com (Agent Chat API)

### CSP Trusted Sites
- `APITooling` - https://api.salesforce.com (HTTP)
- `SpeechFoundation` - wss://api.salesforce.com (WebSocket for STT/TTS)

### CORS Whitelist Origins
- `https_api_salesforce_com` - https://api.salesforce.com

### Permission Sets
- `APITooling` - External Credential Principal access