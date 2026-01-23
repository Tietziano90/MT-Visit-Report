# Einstein Transcribe Configuration Options Guide

## Overview

Your Voice Assistant now supports multiple transcription endpoints, engines, and advanced features from the Agentforce Speech Foundations API. This guide explains all available options and how to configure them.

## Feature IDs (Unchanged)

Your current feature IDs remain the same:
- `x-client-feature-id`: `external-edc`
- `x-sfdc-app-context`: `EinsteinGPT`

These identify your app as an External Einstein Data Cloud client within the EinsteinGPT ecosystem.

## Configuration Fields

All options are configured in **Custom Metadata Type**: `MT_VoiceAssistantConfig__mdt`

### 1. Transcription Endpoint

**Field**: `TranscriptionEndpoint__c`

**Options**:
- **`v1`** (default) - Basic Transcription
  - Fast, simple speech-to-text
  - Returns plain text transcription
  - Best for: Quick transcriptions, simple use cases
  
- **`v2`** - With Diarization
  - Includes speaker identification (diarization)
  - Returns transcript with speaker segments
  - Best for: Meetings with multiple speakers, interviews
  
- **`streaming`** - Real-time WebSocket
  - Real-time transcription as you speak
  - Low latency, continuous transcription
  - Best for: Live conversations, real-time applications
  - *Note: Requires WebSocket implementation (not yet implemented in LWC)*

### 2. Transcription Engine

**Field**: `TranscriptionEngine__c`

**Options**:
- **`internal`** (default) - Einstein Native
  - Fast processing
  - Good quality
  - Lower cost
  - Best for: Most use cases
  
- **`aws`** - Amazon Transcribe
  - Higher quality
  - More language support (30+ languages)
  - Slower processing
  - Best for: High-accuracy requirements
  
- **`deepgram_remote`** - Deepgram API
  - High-quality transcription
  - Fast processing
  - Advanced features
  - Best for: Professional transcription needs
  
- **`deepgram_falcon`** - Deepgram Falcon
  - Optimized for speed
  - Automatic failover to remote
  - Best for: Performance-critical applications
  
- **`deepgram_sagemaker`** - Deepgram via SageMaker
  - Deployed on AWS SageMaker
  - Enterprise-grade performance
  - Best for: Large-scale deployments

### 3. Enable Diarization

**Field**: `EnableDiarization__c`

**Type**: Checkbox

**Description**: Enable speaker identification to distinguish between different speakers in the audio.

**Requirements**:
- Only works with `v2` endpoint or `streaming` with `show-speaker-label` parameter
- Adds speaker labels to transcription segments

**Use Cases**:
- Meeting transcriptions
- Interviews
- Multi-party conversations
- Call center recordings

### 4. Transcription Model

**Field**: `TranscriptionModel__c`

**Type**: Text (100 characters)

**Description**: Specify the transcription model to use (primarily for Deepgram engines).

**Common Values**:
- `nova-2-phonecall` (default for Deepgram) - Optimized for phone calls
- `nova-3` - Latest model with multi-language support
- Leave blank to use engine default

**Multi-Language Detection**:
- For Deepgram engines with multi-language detection:
  - Set `TranscriptionModel__c` to `nova-3`
  - Set spoken language to `multi` (if supported)

## Configuration Examples

### Example 1: Basic Setup (Default)

```xml
<values>
    <field>TranscriptionEndpoint__c</field>
    <value xsi:type="xsd:string">v1</value>
</values>
<values>
    <field>TranscriptionEngine__c</field>
    <value xsi:type="xsd:string">internal</value>
</values>
<values>
    <field>EnableDiarization__c</field>
    <value xsi:type="xsd:boolean">false</value>
</values>
```

**Use Case**: Simple transcription, fast processing, good for most scenarios

---

### Example 2: High-Quality Meeting Transcription

```xml
<values>
    <field>TranscriptionEndpoint__c</field>
    <value xsi:type="xsd:string">v2</value>
</values>
<values>
    <field>TranscriptionEngine__c</field>
    <value xsi:type="xsd:string">aws</value>
</values>
<values>
    <field>EnableDiarization__c</field>
    <value xsi:type="xsd:boolean">true</value>
</values>
```

**Use Case**: Meeting with multiple speakers, need to know who said what

---

### Example 3: Professional Transcription with Deepgram

```xml
<values>
    <field>TranscriptionEndpoint__c</field>
    <value xsi:type="xsd:string">v2</value>
</values>
<values>
    <field>TranscriptionEngine__c</field>
    <value xsi:type="xsd:string">deepgram_remote</value>
</values>
<values>
    <field>EnableDiarization__c</field>
    <value xsi:type="xsd:boolean">true</value>
</values>
<values>
    <field>TranscriptionModel__c</field>
    <value xsi:type="xsd:string">nova-3</value>
</values>
```

**Use Case**: Professional transcription with latest model and speaker identification

---

### Example 4: Multi-Language Detection

```xml
<values>
    <field>TranscriptionEndpoint__c</field>
    <value xsi:type="xsd:string">v2</value>
</values>
<values>
    <field>TranscriptionEngine__c</field>
    <value xsi:type="xsd:string">deepgram_remote</value>
</values>
<values>
    <field>TranscriptionModel__c</field>
    <value xsi:type="xsd:string">nova-3</value>
</values>
<values>
    <field>DefaultSpokenLanguage__c</field>
    <value xsi:type="xsd:string">multi</value>
</values>
```

**Use Case**: Conversations that switch between multiple languages

## Engine Comparison Matrix

| Feature | internal | aws | deepgram_remote | deepgram_falcon | deepgram_sagemaker |
|---------|----------|-----|-----------------|-----------------|---------------------|
| **Speed** | ⚡⚡⚡ Fast | ⚡⚡ Medium | ⚡⚡⚡ Fast | ⚡⚡⚡ Very Fast | ⚡⚡⚡ Fast |
| **Quality** | ⭐⭐⭐ Good | ⭐⭐⭐⭐ Very Good | ⭐⭐⭐⭐ Very Good | ⭐⭐⭐⭐ Very Good | ⭐⭐⭐⭐ Very Good |
| **Languages** | 12+ | 30+ | 30+ | 30+ | 30+ |
| **Diarization** | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cost** | 💰 Low | 💰💰 Medium | 💰💰 Medium | 💰💰💰 High | 💰💰💰 High |
| **Best For** | Quick tasks | High accuracy | Professional | Performance | Enterprise |

## Endpoint Comparison

| Endpoint | Response Type | Speaker ID | Real-time | Best For |
|----------|---------------|------------|-----------|----------|
| **v1** | Plain text | ❌ No | ❌ No | Simple transcription |
| **v2** | Segments + metadata | ✅ Yes | ❌ No | Meetings, interviews |
| **streaming** | Real-time chunks | ✅ Yes | ✅ Yes | Live conversations |

## Supported Languages

### All Engines Support:
- English (en, en-US, en-GB, en-AU)
- German (de, de-DE)
- French (fr, fr-FR, fr-CA)
- Spanish (es, es-ES, es-MX, es-US)
- Italian (it, it-IT)
- Portuguese (pt, pt-PT, pt-BR)
- Japanese (ja, ja-JP)
- Chinese (zh, zh-CN, zh-TW)
- Arabic (ar, ar-SA)
- Korean (ko, ko-KR)
- Russian (ru, ru-RU)

### AWS & Deepgram Additional Languages:
- Hindi (hi, hi-IN)
- Catalan (ca, ca-ES)
- Danish (da, da-DK)
- Dutch (nl, nl-NL)
- Hebrew (he, he-IL)
- Norwegian (no, no-NO)
- Swedish (sv, sv-SE)
- Finnish (fi, fi-FI)
- Bulgarian (bg, bg-BG)
- Croatian (hr, hr-HR)
- Czech (cs, cs-CZ)
- Estonian (et, et-ET)
- Greek (el, el-GR)
- Hungarian (hu, hu-HU)
- Polish (pl, pl-PL)
- Romanian (ro, ro-RO)
- Ukrainian (uk, uk-UA)

## How to Configure

### Via Salesforce UI:

1. Go to **Setup** → **Custom Metadata Types**
2. Click **Manage Records** next to `MT Voice Assistant Config`
3. Click **Edit** on your configuration (e.g., "Default")
4. Set the desired values:
   - **Transcription Endpoint**: v1, v2, or streaming
   - **Transcription Engine**: internal, aws, deepgram_remote, etc.
   - **Enable Diarization**: Check if you want speaker identification
   - **Transcription Model**: Enter model name (optional, for Deepgram)
5. Click **Save**

### Via Metadata XML:

Edit `/force-app/main/default/customMetadata/MT_VoiceAssistantConfig.Default.md-meta.xml`:

```xml
<values>
    <field>TranscriptionEndpoint__c</field>
    <value xsi:type="xsd:string">v2</value>
</values>
<values>
    <field>TranscriptionEngine__c</field>
    <value xsi:type="xsd:string">deepgram_remote</value>
</values>
<values>
    <field>EnableDiarization__c</field>
    <value xsi:type="xsd:boolean">true</value>
</values>
<values>
    <field>TranscriptionModel__c</field>
    <value xsi:type="xsd:string">nova-3</value>
</values>
```

Then deploy:

```bash
sf project deploy start --source-dir force-app/main/default/customMetadata
```

## Testing Different Configurations

### Test 1: Basic Transcription (Fast)
- Endpoint: v1
- Engine: internal
- Expected: Fast, simple text output

### Test 2: Meeting with Speakers (Quality)
- Endpoint: v2
- Engine: aws
- Diarization: Enabled
- Expected: Transcript with speaker labels

### Test 3: Professional Grade (Best Quality)
- Endpoint: v2
- Engine: deepgram_remote
- Model: nova-3
- Diarization: Enabled
- Expected: High-quality transcript with speaker identification

## Troubleshooting

### Issue: Diarization not working
**Solution**: Make sure you're using `v2` endpoint and `EnableDiarization__c` is checked.

### Issue: Model not recognized
**Solution**: `TranscriptionModel__c` only works with Deepgram engines. Leave blank for other engines.

### Issue: Language not detected
**Solution**: 
- For AWS: Use language detection parameters (not yet implemented in LWC)
- For Deepgram: Set model to `nova-3` and language to `multi`

### Issue: Slow transcription
**Solution**: 
- Try `internal` engine for faster processing
- Use `deepgram_falcon` for best speed/quality balance

## Future Enhancements

### Coming Soon:
1. **Streaming Support**: Real-time WebSocket transcription
2. **Batch Processing**: Transcribe multiple files at once
3. **Custom Models**: Support for custom-trained models
4. **Advanced Diarization**: Better speaker identification
5. **PII Redaction**: Automatic removal of sensitive information

## Additional Resources

- **Official Documentation**: Agentforce Speech Foundations Developer Guide (Spring '25)
- **API Reference**: `/Users/mtietze/Downloads/api (1).yaml`
- **Support**: Contact your Salesforce Account Team or `mtietze@salesforce.com`

## Version History

- **v1.6** (2026-01-15): Added endpoint, engine, diarization, and model configuration
- **v1.5** (2025-12-15): Added language selection and multi-language support
- **v1.0** (2025-11-01): Initial release with Einstein Transcribe v1

---

**Need Help?** Contact Michael Tietze (mtietze@salesforce.com) or your Salesforce Solution Engineer.
