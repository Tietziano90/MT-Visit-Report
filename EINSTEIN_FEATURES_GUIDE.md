# Einstein Platform Features & Models Guide

## Available Features (Based on Documentation)

### 1. **Transcription Services**

#### Micro-batch Transcription
- **Endpoint:** `/einstein/platform/v1/models/transcribeInternalV1/transcriptions`
- **Models:**
  - `transcribeInternalV1` - Einstein native transcription
  - `transcribeAWSV1` - AWS-based transcription (batch only)
- **Engines:**
  - `internal` - Einstein's native engine
  - `aws` - Amazon Transcribe
- **Languages:** english, german, french, spanish, italian, portuguese, dutch, japanese, chinese, arabic, russian, korean
- **Features:**
  - Real-time transcription
  - Language detection
  - Multi-language support

#### Batch Transcription
- **Endpoint:** `/einstein/platform/v1/jobs`
- **Capability:** `Transcriptions`
- **Model:** `transcribeAWSV1`
- **Additional Features:**
  - Diarization (speaker identification)
  - S3 input/output
  - Presigned URLs
  - Async processing

#### Streaming Transcription
- **Endpoint:** `wss://api.salesforce.com/einstein/platform/v1/stream` (WebSocket)
- **Features:**
  - Real-time streaming
  - Low latency
  - Continuous transcription

### 2. **Speech Synthesis (Text-to-Speech)**

#### V1 API
- **Endpoint:** `/einstein/platform/v1/models/transcribeInternalV1/speech-synthesis`
- **Engine:** `aws` (Amazon Polly)
- **Voices:** See [AWS Polly Voices](https://docs.aws.amazon.com/polly/latest/dg/available-voices.html)
- **Popular Voices:**
  - Joanna (US English, Female)
  - Matthew (US English, Male)
  - Amy (British English, Female)
  - Brian (British English, Male)
  - Hans (German, Male)
  - Marlene (German, Female)
  - Celine (French, Female)
  - Mathieu (French, Male)

#### V2 API
- **Endpoint:** `/einstein/platform/v1/models/transcribeInternalV1/speech-synthesis`
- **Engines:**
  - `aws` - Amazon Polly
  - `elevenlabs` - ElevenLabs (higher quality)
- **Features:**
  - Better voice quality
  - More natural speech
  - Emotion control (ElevenLabs)

### 3. **Translation Services**

#### Real-time Translation
- **Endpoint:** `/einstein/platform/v1/models/transcribeInternalV1/translations`
- **Engine:** `aws` (Amazon Translate)
- **Features:**
  - Text translation
  - Source/target language pairs
  - Settings:
    - `brevity`: ON/OFF
    - `formality`: FORMAL/INFORMAL
    - `profanity`: MASK/UNMASK

#### Batch Translation
- **Endpoint:** `/einstein/platform/v1/jobs`
- **Capability:** `Translations`
- **Model:** `sfdc_ai__DefaultAgentforceGPT`
- **Features:**
  - CSV/HTML input
  - S3 input/output
  - Field mapping
  - Bulk processing

## How to Check for New Features

### 1. **Salesforce Release Notes**
Check quarterly release notes for Einstein Platform updates:
- Winter/Spring/Summer releases
- Look for "Einstein AI" or "Agentforce" sections

### 2. **Internal Slack Channels** (if you have access)
- `#speech-foundations-public`
- `#ai-gateway`
- `#salesforce-api-platform-support`

### 3. **API Versioning**
Watch for new API versions:
- Current: `/v1/`
- Future: `/v2/`, `/v3/`, etc.

### 4. **Model Names**
New models typically follow patterns:
- `transcribeInternalV2` (next version)
- `transcribeInternalV1` (current)
- `transcribeAWSV1` (AWS-based)

### 5. **Test Discovery Script**
Run the included `test-einstein-discovery.sh` script:

```bash
# Get your access token first
ACCESS_TOKEN=$(sf org display --target-org YOUR_ORG --json | jq -r '.result.accessToken')

# Run discovery
./test-einstein-discovery.sh $ACCESS_TOKEN
```

## Current Capabilities Matrix

| Feature | Micro-batch | Batch | Streaming | Status |
|---------|------------|-------|-----------|--------|
| **Transcription** | ✅ | ✅ | ✅ | Production |
| **Speech Synthesis** | ✅ | ❌ | ❌ | Production |
| **Translation** | ✅ | ✅ | ❌ | Production |
| **Diarization** | ❌ | ✅ | ✅ | Production |
| **Real-time Insights** | ❌ | ❌ | ✅ | Beta |

## Engines Comparison

### Transcription Engines

| Engine | Speed | Quality | Cost | Languages |
|--------|-------|---------|------|-----------|
| `internal` | Fast | Good | Low | 12+ |
| `aws` | Medium | Very Good | Medium | 30+ |

### Speech Synthesis Engines

| Engine | Quality | Naturalness | Cost | Voices |
|--------|---------|-------------|------|--------|
| `aws` | Good | Good | Low | 60+ |
| `elevenlabs` | Excellent | Excellent | High | 100+ |

## Feature Flags & Permissions

To use these features, your org needs:

1. **EinsteinGPT License/App**
   - Check: Setup → Company Information → Features
   - Look for "Einstein GPT" or "Agentforce"

2. **SFAP API Scope**
   - Connected App must have `sfap_api` scope
   - JWT must include routing hints (`sfap_rh`)

3. **Feature Flags** (in JWT `sfap_op`)
   - `EinsteinHawkingC2CEnabled`
   - `EGptForDevsAvailable`
   - `EinsteinGenerativeService`

## Experimental Features (May Not Be Available)

Based on the documentation, these might be coming:

1. **Real-time Insights** - Live conversation analysis
2. **Custom Voice Training** - Train custom voices
3. **Advanced Diarization** - Better speaker identification
4. **Sentiment Analysis** - Emotion detection in speech
5. **Terminology Management** - Custom translation dictionaries

## How to Request New Features

1. **Internal Users:**
   - Post in `#speech-foundations-public`
   - Create ticket at `#salesforce-api-platform-support`
   - Tag: Dima Statz, Leon Kravetsky, Roy Shahaf

2. **External Users:**
   - Contact Salesforce Support
   - Submit idea on IdeaExchange
   - Work with your Account Executive

## Monitoring & Limits

### Rate Limits
- Check response headers for rate limit info
- Typical limits: 100 requests/minute (varies by org)

### Usage Tracking
- Monitor via Setup → Einstein Usage
- Check API logs in Event Monitoring

## Best Practices

1. **Use appropriate engine for use case:**
   - `internal` for speed
   - `aws` for quality
   - `elevenlabs` for premium quality

2. **Choose right API type:**
   - Micro-batch: < 1 minute audio
   - Batch: > 1 minute or bulk processing
   - Streaming: Real-time needs

3. **Language selection:**
   - Specify language when known
   - Use `auto` for detection (slower)

4. **Error handling:**
   - Implement retry logic
   - Handle 429 (rate limit) gracefully
   - Log errors for debugging

## Testing New Features

When new features are announced:

1. **Check API version compatibility**
2. **Test in sandbox first**
3. **Review new parameters/options**
4. **Update error handling**
5. **Monitor performance/quality**
6. **Update documentation**

## Resources

- **Official Docs:** (Internal) Speech Foundations Quick Start Guide
- **API Reference:** `https://api.salesforce.com/einstein/platform/v1/`
- **Slack:** `#speech-foundations-public`
- **Support:** `#salesforce-api-platform-support`

## Version History

- **V1** (Current)
  - Transcription: ✅
  - Speech Synthesis: ✅
  - Translation: ✅
  - Batch Jobs: ✅

- **V2** (Rumored/Partial)
  - Enhanced Speech Synthesis
  - Better streaming support
  - More language support
