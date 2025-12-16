# Agentforce Voice LWC Migration Package

This package contains the **agentforceVoiceBubble**  (AgentforceVoice) Lightning Web Component and all its dependencies.

## Contents

### LWC Component
- `agentforceVoiceBubble` - Voice interface for Agentforce agents

### Apex Classes
- `AgentforceVoiceController` - Handles bootstrap, session creation, and joining voice sessions
- `AgentforceDataService` - Queries voice-enabled agents via Tooling API

### Static Resources
- `livekit_client.js` - LiveKit SDK for WebRTC voice communication
- `agentforce_icon.png` - Agentforce logo

### Named Credentials
- `APITooling` - For Tooling API access (OAuth client credentials)

### External Credentials
- `APITooling` - Authentication configuration for Named Credential

### Connected Apps
- `APITooling` - OAuth app for client credentials flow

### Auth Providers
- `AgentAPIIntegration` - Salesforce OAuth provider

### Remote Site Settings
- `Salesforce_API` - https://api.salesforce.com (Einstein Agent API)
- `Own_Org` - Your org URL (for bootstrap endpoint)

### CSP Trusted Sites
- `APITooling` - https://api.salesforce.com
- `SpeechFoundation` - wss://api.salesforce.com (WebSocket for LiveKit)

### CORS Whitelist Origins
- `https_api_salesforce_com` - https://api.salesforce.com

### Permission Sets
- `APITooling` - External Credential Principal access
- `ToolingAPIAccess` - Tooling API access

