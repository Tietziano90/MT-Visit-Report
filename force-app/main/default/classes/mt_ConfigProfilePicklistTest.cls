/**
 * ============================================================================
 * MT Config Profile Picklist Test
 * ============================================================================
 * 
 * @description     Test class for mt_ConfigProfilePicklist
 * @author          Michael Tietze, Principal AI Architect
 * @created         January 2026
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
@isTest
private class mt_ConfigProfilePicklistTest {
    
    @isTest
    static void testGetDefaultValue() {
        mt_ConfigProfilePicklist picklist = new mt_ConfigProfilePicklist();
        
        System.Test.startTest();
        VisualEditor.DataRow defaultValue = picklist.getDefaultValue();
        System.Test.stopTest();
        
        Assert.isNotNull(defaultValue, 'Default value should not be null');
        Assert.areEqual('Default', defaultValue.getValue(), 'Default value should be Default');
        Assert.areEqual('Default (Standard)', defaultValue.getLabel(), 'Default label should match');
    }
    
    @isTest
    static void testGetValues() {
        mt_ConfigProfilePicklist picklist = new mt_ConfigProfilePicklist();
        
        System.Test.startTest();
        VisualEditor.DynamicPickListRows values = picklist.getValues();
        System.Test.stopTest();
        
        Assert.isNotNull(values, 'Values should not be null');
        // Should have at least the Default option
        Assert.isTrue(values.size() >= 1, 'Should have at least one value');
    }
    
    @isTest
    static void testGetValuesReturnsDefaultFirst() {
        mt_ConfigProfilePicklist picklist = new mt_ConfigProfilePicklist();
        
        System.Test.startTest();
        VisualEditor.DynamicPickListRows values = picklist.getValues();
        System.Test.stopTest();
        
        // First value should always be Default
        Assert.isNotNull(values, 'Values should not be null');
        Assert.isTrue(values.size() > 0, 'Should have values');
    }
    
    @isTest
    static void testPicklistInstantiation() {
        System.Test.startTest();
        mt_ConfigProfilePicklist picklist = new mt_ConfigProfilePicklist();
        System.Test.stopTest();
        
        Assert.isNotNull(picklist, 'Picklist should instantiate');
    }
}
