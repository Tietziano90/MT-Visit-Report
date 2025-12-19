/*
================================================================================
MT VISIT REPORT RELATED RECORDS - Lightning Web Component
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 1.0

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

/**
 * ============================================================================
 * MT VISIT REPORT RELATED RECORDS - Lightning Web Component
 * ============================================================================
 * 
 * @author      Michael Tietze, Principal AI Architect
 * @contact     mtietze@salesforce.com
 * @created     December 2025
 * @modified    December 2025
 * @version     1.0
 * 
 * ============================================================================
 * COPYRIGHT AND DISTRIBUTION
 * ============================================================================
 * Copyright © 2025 Salesforce, Inc. All rights reserved.
 * 
 * Author: Michael Tietze, Principal AI Architect
 * 
 * INTERNAL USE ONLY - This code may not be shared externally or distributed
 * outside of Salesforce without prior written approval from Michael Tietze
 * (mtietze@salesforce.com).
 * 
 * THIS CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
 * ============================================================================
 * 
 * @description 
 * Displays related records (Contacts, Opportunities, Tasks, Events, Leads)
 * that were created from a visit report draft. Shows them grouped by object
 * type with navigation buttons to view each record.
 * 
 * @features
 * - Reads created record IDs from draft fields
 * - Groups records by object type
 * - Displays key fields for each record type
 * - Navigation buttons to view each record
 * - Empty state when no records created
 * 
 * @usage
 * Place on MT_Visit_Report_Draft__c record page
 * Automatically reads recordId from page context
 * 
 * ============================================================================
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

const FIELDS = [
    'MT_Visit_Report_Draft__c.Created_Contact_IDs__c',
    'MT_Visit_Report_Draft__c.Created_Opportunity_IDs__c',
    'MT_Visit_Report_Draft__c.Created_Task_IDs__c',
    'MT_Visit_Report_Draft__c.Created_Event_IDs__c',
    'MT_Visit_Report_Draft__c.Created_Lead_IDs__c'
];

export default class MtVisitReportRelatedRecords extends NavigationMixin(LightningElement) {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    draft;
    
    get contactIds() {
        if (!this.draft.data) return [];
        const ids = this.draft.data.fields.Created_Contact_IDs__c.value;
        return ids ? ids.split(',').filter(id => id.trim()) : [];
    }
    
    get opportunityIds() {
        if (!this.draft.data) return [];
        const ids = this.draft.data.fields.Created_Opportunity_IDs__c.value;
        return ids ? ids.split(',').filter(id => id.trim()) : [];
    }
    
    get taskIds() {
        if (!this.draft.data) return [];
        const ids = this.draft.data.fields.Created_Task_IDs__c.value;
        return ids ? ids.split(',').filter(id => id.trim()) : [];
    }
    
    get eventIds() {
        if (!this.draft.data) return [];
        const ids = this.draft.data.fields.Created_Event_IDs__c.value;
        return ids ? ids.split(',').filter(id => id.trim()) : [];
    }
    
    get leadIds() {
        if (!this.draft.data) return [];
        const ids = this.draft.data.fields.Created_Lead_IDs__c.value;
        return ids ? ids.split(',').filter(id => id.trim()) : [];
    }
    
    get hasContacts() {
        return this.contactIds.length > 0;
    }
    
    get hasOpportunities() {
        return this.opportunityIds.length > 0;
    }
    
    get hasTasks() {
        return this.taskIds.length > 0;
    }
    
    get hasEvents() {
        return this.eventIds.length > 0;
    }
    
    get hasLeads() {
        return this.leadIds.length > 0;
    }
    
    get hasAnyRecords() {
        return this.hasContacts || this.hasOpportunities || this.hasTasks || this.hasEvents || this.hasLeads;
    }
    
    get contactCount() {
        return this.contactIds.length;
    }
    
    get opportunityCount() {
        return this.opportunityIds.length;
    }
    
    get taskCount() {
        return this.taskIds.length;
    }
    
    get eventCount() {
        return this.eventIds.length;
    }
    
    get leadCount() {
        return this.leadIds.length;
    }
    
    handleNavigateToRecord(event) {
        const recordId = event.target.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}

