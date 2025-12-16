/**
 * @description Dynamic picklist for Voice Assistant Config Profiles
 *              Used in Flow Screen Components and App Builder
 * @author Marc Tietze
 */
global class mt_ConfigProfilePicklist extends VisualEditor.DynamicPickList {
    
    /**
     * @description Returns the default value for the picklist
     */
    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('Default (Standard)', 'Default');
    }
    
    /**
     * @description Returns all available config profiles as picklist values
     */
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows picklistRows = new VisualEditor.DynamicPickListRows();
        
        // Always add Default as first option
        picklistRows.addRow(new VisualEditor.DataRow('Default (Standard)', 'Default'));
        
        // Query all active config profiles
        List<MT_VoiceAssistantConfig__mdt> configs = [
            SELECT DeveloperName, MasterLabel, IsActive__c, TranscriptionProvider__c
            FROM MT_VoiceAssistantConfig__mdt
            WHERE IsActive__c = true
            ORDER BY MasterLabel
        ];
        
        for (MT_VoiceAssistantConfig__mdt config : configs) {
            // Skip if it's already the Default we added
            if (config.DeveloperName == 'Default') {
                continue;
            }
            
            String label = config.MasterLabel;
            if (String.isNotBlank(config.TranscriptionProvider__c)) {
                label += ' (' + config.TranscriptionProvider__c + ')';
            }
            picklistRows.addRow(new VisualEditor.DataRow(label, config.DeveloperName));
        }
        
        return picklistRows;
    }
}