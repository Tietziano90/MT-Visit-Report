# Language Support Implementation Guide

## ✅ Completed

### 1. Custom Labels for German Translation
- Created `CustomLabels.labels-meta.xml` with English and German translations
- Covers all button labels, badges, and UI text
- Labels include:
  - Save/Saving/Saved → Speichern/Wird gespeichert/Gespeichert
  - Edit/Cancel → Bearbeiten/Abbrechen
  - Link/Refresh → Verknüpfen/Aktualisieren
  - Add Field → Feld hinzufügen
  - New/Update badges → Neu/Aktualisierung
  - Show All/Fewer Fields → Alle Felder anzeigen/Weniger Felder anzeigen

### 2. Custom Metadata Fields
- Added three new fields to `MT_VoiceAssistantConfig__mdt`:
  - `DefaultSpokenLanguage__c` - Language of speech input (ISO 639-1 codes: en, de, fr, es)
  - `DefaultTranscriptionLanguage__c` - Language for transcription output
  - `AllowLanguageOverride__c` - Allow users to override language settings

### 3. Configuration Updated
- Updated `MT_VoiceAssistantConfig.Default` with new language fields
- Default: Auto-detect from user language (fields left blank)
- Language override enabled by default

## 🚧 Next Steps (To Be Implemented)

### 4. Update mtEinsteinTranscribe LWC

#### Add Language Selectors to HTML
Add after the provider selector (around line 73):

```html
<!-- Language Selection (shown when allowLanguageOverride is true) -->
<template lwc:if={showLanguageSelector}>
    <div class="language-selector-container">
        <div class="slds-grid slds-gutters slds-wrap">
            <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-2">
                <lightning-combobox
                    name="spokenLanguage"
                    label={labels.spokenLanguage}
                    value={selectedSpokenLanguage}
                    options={languageOptions}
                    onchange={handleSpokenLanguageChange}
                    class="language-dropdown">
                </lightning-combobox>
            </div>
            <div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-2">
                <lightning-combobox
                    name="transcriptionLanguage"
                    label={labels.transcriptionLanguage}
                    value={selectedTranscriptionLanguage}
                    options={languageOptions}
                    onchange={handleTranscriptionLanguageChange}
                    class="language-dropdown">
                </lightning-combobox>
            </div>
        </div>
    </div>
</template>
```

#### Add to JavaScript (mtEinsteinTranscribe.js)

```javascript
// Import Custom Labels
import LABEL_SPOKEN_LANGUAGE from '@salesforce/label/c.MT_Language_SpokenLanguage';
import LABEL_TRANSCRIPTION_LANGUAGE from '@salesforce/label/c.MT_Language_TranscriptionLanguage';
import LABEL_AUTO from '@salesforce/label/c.MT_Language_Auto';

// Import User Language
import USER_LANGUAGE from '@salesforce/i18n/lang';

// Add properties
@api allowLanguageOverride = true;
@track selectedSpokenLanguage = '';
@track selectedTranscriptionLanguage = '';
@track showLanguageSelector = false;

// Add labels object
labels = {
    spokenLanguage: LABEL_SPOKEN_LANGUAGE,
    transcriptionLanguage: LABEL_TRANSCRIPTION_LANGUAGE,
    auto: LABEL_AUTO
};

// Add language options
get languageOptions() {
    return [
        { label: this.labels.auto, value: '' },
        { label: 'English', value: 'en' },
        { label: 'Deutsch (German)', value: 'de' },
        { label: 'Français (French)', value: 'fr' },
        { label: 'Español (Spanish)', value: 'es' },
        { label: 'Italiano (Italian)', value: 'it' },
        { label: 'Português (Portuguese)', value: 'pt' },
        { label: 'Nederlands (Dutch)', value: 'nl' },
        { label: '日本語 (Japanese)', value: 'ja' },
        { label: '中文 (Chinese)', value: 'zh' },
        { label: 'العربية (Arabic)', value: 'ar' }
    ];
}

// Add handlers
handleSpokenLanguageChange(event) {
    this.selectedSpokenLanguage = event.detail.value;
}

handleTranscriptionLanguageChange(event) {
    this.selectedTranscriptionLanguage = event.detail.value;
}

// Update connectedCallback to get user language
connectedCallback() {
    // ... existing code ...
    
    // Set default language from user
    if (!this.selectedSpokenLanguage) {
        this.selectedSpokenLanguage = this.getUserLanguageCode();
    }
    if (!this.selectedTranscriptionLanguage) {
        this.selectedTranscriptionLanguage = this.getUserLanguageCode();
    }
}

// Add helper method
getUserLanguageCode() {
    // USER_LANGUAGE returns format like "en-US", we need "en"
    return USER_LANGUAGE ? USER_LANGUAGE.split('-')[0] : 'en';
}

// Update handleLoadConfig to set language settings
handleLoadConfig() {
    // ... existing code ...
    
    if (this.config) {
        // Set language settings
        if (this.config.DefaultSpokenLanguage__c) {
            this.selectedSpokenLanguage = this.config.DefaultSpokenLanguage__c;
        }
        if (this.config.DefaultTranscriptionLanguage__c) {
            this.selectedTranscriptionLanguage = this.config.DefaultTranscriptionLanguage__c;
        }
        this.showLanguageSelector = this.config.AllowLanguageOverride__c === true;
    }
}
```

### 5. Update Apex Controller (mt_TranscribeController.cls)

Add language parameters to transcription methods:

```apex
@AuraEnabled
public static String transcribeAudio(String audioBase64, String provider, String spokenLanguage, String transcriptionLanguage) {
    // ... existing code ...
    
    // Add language to request body
    if (String.isNotBlank(spokenLanguage)) {
        requestBody.put('language', spokenLanguage);
    }
    
    // For translation, add target language
    if (String.isNotBlank(transcriptionLanguage) && transcriptionLanguage != spokenLanguage) {
        requestBody.put('targetLanguage', transcriptionLanguage);
    }
    
    // ... rest of code ...
}

@AuraEnabled
public static String transcribeWithWhisper(String audioBase64, String model, String spokenLanguage) {
    // ... existing code ...
    
    // Add language parameter to Whisper API
    if (String.isNotBlank(spokenLanguage)) {
        formData.add('language', spokenLanguage);
    }
    
    // ... rest of code ...
}
```

### 6. Update mtRecordSuggestion LWC to Use Custom Labels

Import and use the custom labels:

```javascript
// Import labels
import LABEL_SAVE from '@salesforce/label/c.MT_Button_Save';
import LABEL_SAVING from '@salesforce/label/c.MT_Button_Saving';
import LABEL_SAVED from '@salesforce/label/c.MT_Button_Saved';
import LABEL_EDIT from '@salesforce/label/c.MT_Button_Edit';
import LABEL_CANCEL from '@salesforce/label/c.MT_Button_Cancel';
// ... import all other labels ...

// Add labels object
labels = {
    save: LABEL_SAVE,
    saving: LABEL_SAVING,
    saved: LABEL_SAVED,
    edit: LABEL_EDIT,
    cancel: LABEL_CANCEL,
    // ... all other labels ...
};

// Update HTML to use {labels.save} instead of hardcoded "Save"
```

## 📋 Supported Languages

### Einstein Transcribe API
- English (en)
- German (de)
- French (fr)
- Spanish (es)
- Italian (it)
- Portuguese (pt)
- Dutch (nl)

### OpenAI Whisper API
Supports 90+ languages including:
- All above languages
- Japanese (ja)
- Chinese (zh)
- Arabic (ar)
- Russian (ru)
- Korean (ko)
- And many more...

## 🎯 User Experience

### Default Behavior
1. System detects user's Salesforce language
2. Uses that as default for both spoken and transcription language
3. User can override if needed

### Configuration Options
1. **Admin sets default in Custom Metadata:**
   - `DefaultSpokenLanguage__c` = "de" (German)
   - `DefaultTranscriptionLanguage__c` = "en" (English)
   - Result: Speak German, get English transcription

2. **User overrides in UI:**
   - Dropdown shows "Auto-detect (User Language)" by default
   - User can select specific language
   - Selection persists for session

### Example Scenarios

**Scenario 1: German User, German Meeting**
- User Language: German
- Spoken Language: Auto (detects German)
- Transcription Language: Auto (German)
- Result: German → German

**Scenario 2: German User, English Meeting**
- User Language: German
- Spoken Language: English (manual selection)
- Transcription Language: German (manual selection)
- Result: English → German (translated)

**Scenario 3: Multilingual Team**
- Admin sets: Spoken=Auto, Transcription=English
- Result: Any language → English transcription

## 🚀 Deployment Steps

1. ✅ Deploy Custom Labels
2. ✅ Deploy Custom Metadata Fields
3. ✅ Update Configuration Records
4. ⏳ Update mtEinsteinTranscribe LWC (HTML + JS)
5. ⏳ Update mt_TranscribeController Apex
6. ⏳ Update mtRecordSuggestion LWC with labels
7. ⏳ Test with different languages
8. ⏳ Update documentation

## 📝 Testing Checklist

- [ ] Test auto-detection with German user
- [ ] Test manual language selection
- [ ] Test language override toggle
- [ ] Test German UI labels
- [ ] Test Einstein API with language parameter
- [ ] Test Whisper API with language parameter
- [ ] Test translation (different spoken vs transcription)
- [ ] Test configuration inheritance
- [ ] Test mobile responsiveness of language selectors

## 🔧 Configuration Examples

### German-Only Organization
```xml
<values>
    <field>DefaultSpokenLanguage__c</field>
    <value xsi:type="xsd:string">de</value>
</values>
<values>
    <field>DefaultTranscriptionLanguage__c</field>
    <value xsi:type="xsd:string">de</value>
</values>
<values>
    <field>AllowLanguageOverride__c</field>
    <value xsi:type="xsd:boolean">false</value>
</values>
```

### Multilingual Organization
```xml
<values>
    <field>DefaultSpokenLanguage__c</field>
    <value xsi:nil="true"/>  <!-- Auto-detect -->
</values>
<values>
    <field>DefaultTranscriptionLanguage__c</field>
    <value xsi:type="xsd:string">en</value>  <!-- Always English output -->
</values>
<values>
    <field>AllowLanguageOverride__c</field>
    <value xsi:type="xsd:boolean">true</value>
</values>
```
