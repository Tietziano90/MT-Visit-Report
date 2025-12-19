/*
================================================================================
MT VISIT REPORT MANAGER - Lightning Web Component
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
 * MT VISIT REPORT MANAGER - Lightning Web Component
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
 * Main component for the Visit Report Manager app. Displays pending and
 * processed visit report drafts with beautiful UI matching the Voice Assistant
 * Setup page style. Allows users to review AI-generated suggestions and create
 * records with full tracking of created record IDs.
 * 
 * @features
 * - Beautiful setup-page inspired design
 * - "How It Works" info section with flow diagram
 * - Pending/Processed tabs
 * - Review modal with mtRecordSuggestion component
 * - Automatic record ID tracking
 * - Real-time refresh after processing
 * 
 * @usage
 * Used as home page component in MT Visit Report Manager app
 * Displays all drafts for current user
 * 
 * ============================================================================
 */
import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyPendingDrafts from '@salesforce/apex/mt_VisitReportService.getMyPendingDrafts';
import getMyProcessedDrafts from '@salesforce/apex/mt_VisitReportService.getMyProcessedDrafts';
import updateDraftStatus from '@salesforce/apex/mt_VisitReportService.updateDraftStatus';
import updateDraftWithRecords from '@salesforce/apex/mt_VisitReportService.updateDraftWithRecords';

export default class MtVisitReportManager extends LightningElement {
    @track pendingDrafts = [];
    @track processedDrafts = [];
    @track selectedDraft = null;
    @track showReviewModal = false;
    @track isLoading = false;
    @track activeTab = 'pending';
    
    wiredPendingResult;
    wiredProcessedResult;
    
    // Wire pending drafts
    @wire(getMyPendingDrafts)
    wiredPending(result) {
        this.wiredPendingResult = result;
        if (result.data) {
            this.pendingDrafts = result.data.map(draft => this.enrichDraft(draft));
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Error loading pending drafts: ' + result.error.body.message, 'error');
            this.isLoading = false;
        }
    }
    
    // Wire processed drafts
    @wire(getMyProcessedDrafts)
    wiredProcessed(result) {
        this.wiredProcessedResult = result;
        if (result.data) {
            this.processedDrafts = result.data.map(draft => this.enrichDraft(draft));
        } else if (result.error) {
            this.showToast('Error', 'Error loading processed drafts: ' + result.error.body.message, 'error');
        }
    }
    
    // Enrich draft with formatted data
    enrichDraft(draft) {
        return {
            ...draft,
            formattedDate: this.formatDate(draft.CreatedDate),
            formattedProcessedDate: this.formatDate(draft.Processed_Date__c),
            truncatedSummary: this.truncateSummary(draft.Summary__c),
            accountName: draft.Account__r ? draft.Account__r.Name : 'Unknown Account',
            statusVariant: this.getStatusVariant(draft.Status__c),
            statusIcon: this.getStatusIcon(draft.Status__c)
        };
    }
    
    // Getters
    get hasPendingDrafts() {
        return this.pendingDrafts && this.pendingDrafts.length > 0;
    }
    
    get hasProcessedDrafts() {
        return this.processedDrafts && this.processedDrafts.length > 0;
    }
    
    get noPendingDrafts() {
        return !this.hasPendingDrafts;
    }
    
    get noProcessedDrafts() {
        return !this.hasProcessedDrafts;
    }
    
    get isPendingTab() {
        return this.activeTab === 'pending';
    }
    
    get isProcessedTab() {
        return this.activeTab === 'processed';
    }
    
    get pendingCount() {
        return this.pendingDrafts ? this.pendingDrafts.length : 0;
    }
    
    get processedCount() {
        return this.processedDrafts ? this.processedDrafts.length : 0;
    }
    
    // Formatting helpers
    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    
    truncateSummary(summary) {
        if (!summary) return 'No summary available';
        // Strip HTML tags and truncate
        const stripped = summary.replace(/<[^>]*>/g, '');
        return stripped.length > 150 ? stripped.substring(0, 150) + '...' : stripped;
    }
    
    getStatusVariant(status) {
        switch(status) {
            case 'Ready': return 'success';
            case 'Processed': return 'success';
            case 'Rejected': return 'error';
            case 'Processing': return 'warning';
            default: return 'default';
        }
    }
    
    getStatusIcon(status) {
        switch(status) {
            case 'Ready': return 'utility:notification';
            case 'Processed': return 'utility:check';
            case 'Rejected': return 'utility:close';
            case 'Processing': return 'utility:sync';
            default: return 'utility:info';
        }
    }
    
    // Tab handlers
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }
    
    // Action handlers
    handleReview(event) {
        const draftId = event.target.dataset.id;
        const draft = [...this.pendingDrafts, ...this.processedDrafts].find(d => d.Id === draftId);
        this.selectedDraft = draft;
        this.showReviewModal = true;
    }
    
    handleReject(event) {
        const draftId = event.target.dataset.id;
        this.isLoading = true;
        
        updateDraftStatus({ draftId: draftId, status: 'Rejected' })
            .then(() => {
                this.showToast('Success', 'Visit report draft rejected', 'success');
                return Promise.all([
                    refreshApex(this.wiredPendingResult),
                    refreshApex(this.wiredProcessedResult)
                ]);
            })
            .catch(error => {
                this.showToast('Error', 'Error rejecting draft: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handleModalClose() {
        this.showReviewModal = false;
        this.selectedDraft = null;
    }
    
    handleRecordsSaved(event) {
        // Records were saved by mtRecordSuggestion component
        // Get the saved record IDs from the child component
        const recordSuggestionCmp = this.template.querySelector('c-mt-record-suggestion');
        
        if (!recordSuggestionCmp) {
            this.showToast('Error', 'Could not find record suggestion component', 'error');
            return;
        }
        
        // Collect all saved record IDs by type
        const savedRecordIds = {
            contactIds: recordSuggestionCmp.savedContactIds || [],
            opportunityIds: recordSuggestionCmp.savedOpportunityIds || [],
            taskIds: recordSuggestionCmp.savedTaskIds || [],
            eventIds: recordSuggestionCmp.savedEventIds || [],
            leadIds: recordSuggestionCmp.savedLeadIds || []
        };
        
        this.isLoading = true;
        
        // Update draft with saved record IDs and status
        updateDraftWithRecords({ 
            draftId: this.selectedDraft.Id, 
            contactIds: savedRecordIds.contactIds.join(','),
            opportunityIds: savedRecordIds.opportunityIds.join(','),
            taskIds: savedRecordIds.taskIds.join(','),
            eventIds: savedRecordIds.eventIds.join(','),
            leadIds: savedRecordIds.leadIds.join(',')
        })
        .then(() => {
            this.showToast('Success', 'Visit report processed successfully', 'success');
            this.handleModalClose();
            return Promise.all([
                refreshApex(this.wiredPendingResult),
                refreshApex(this.wiredProcessedResult)
            ]);
        })
        .catch(error => {
            this.showToast('Error', 'Error updating draft: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}

