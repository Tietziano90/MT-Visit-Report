/**
 * ============================================================================
 * MT Visit Report Queue - Lightning Web Component
 * ============================================================================
 * 
 * @description     Displays pending AND processed visit report drafts for an 
 *                  Account in separate tabs. Allows users to review and approve
 *                  them using a modal with the mtRecordSuggestion component.
 * 
 * @author          Michael Tietze, Principal AI Architect
 * @created         December 2025
 * @contact         mtietze@salesforce.com
 * 
 * ============================================================================
 */
import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDrafts from '@salesforce/apex/mt_VisitReportService.getDraftsForAccount';
import updateDraftStatus from '@salesforce/apex/mt_VisitReportService.updateDraftStatus';
import updateDraftWithRecords from '@salesforce/apex/mt_VisitReportService.updateDraftWithRecords';

export default class MtVisitReportQueue extends LightningElement {
    @api recordId; // Account ID from record page
    @track pendingDrafts = [];
    @track processedDrafts = [];
    @track selectedDraft = null;
    @track showReviewModal = false;
    @track isLoading = false;
    
    wiredDraftsResult;
    
    @wire(getDrafts, { accountId: '$recordId' })
    wiredDrafts(result) {
        this.wiredDraftsResult = result;
        if (result.data) {
            // Separate into pending and processed
            this.pendingDrafts = result.data
                .filter(draft => draft.Status__c === 'Ready')
                .map(draft => this.enrichDraft(draft));
            
            this.processedDrafts = result.data
                .filter(draft => draft.Status__c === 'Processed')
                .map(draft => this.enrichDraft(draft));
            
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Error loading drafts: ' + result.error.body.message, 'error');
            this.isLoading = false;
        }
    }
    
    enrichDraft(draft) {
        return {
            ...draft,
            formattedDate: this.formatDate(draft.CreatedDate),
            formattedProcessedDate: this.formatDate(draft.Processed_Date__c),
            truncatedSummary: this.truncateSummary(draft.Summary__c),
            accountName: draft.Account__r ? draft.Account__r.Name : 'Unknown Account'
        };
    }
    
    get hasPendingDrafts() {
        return this.pendingDrafts && this.pendingDrafts.length > 0;
    }
    
    get noPendingDrafts() {
        return !this.hasPendingDrafts;
    }
    
    get hasProcessedDrafts() {
        return this.processedDrafts && this.processedDrafts.length > 0;
    }
    
    get noProcessedDrafts() {
        return !this.hasProcessedDrafts;
    }
    
    get pendingCount() {
        return this.pendingDrafts ? this.pendingDrafts.length : 0;
    }
    
    get processedCount() {
        return this.processedDrafts ? this.processedDrafts.length : 0;
    }
    
    get pendingTabLabel() {
        return `Pending (${this.pendingCount})`;
    }
    
    get processedTabLabel() {
        return `Processed (${this.processedCount})`;
    }
    
    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    
    truncateSummary(summary) {
        if (!summary) return 'No summary available';
        // Strip HTML tags and truncate
        const stripped = summary.replace(/<[^>]*>/g, '');
        return stripped.length > 100 ? stripped.substring(0, 100) + '...' : stripped;
    }
    
    handleReview(event) {
        const draftId = event.target.dataset.id;
        this.selectedDraft = this.drafts.find(d => d.Id === draftId);
        this.showReviewModal = true;
    }
    
    handleReject(event) {
        const draftId = event.target.dataset.id;
        this.isLoading = true;
        
        updateDraftStatus({ draftId: draftId, status: 'Rejected' })
            .then(() => {
                this.showToast('Success', 'Visit report draft rejected', 'success');
                return refreshApex(this.wiredDraftsResult);
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
    
    handleMarkAsProcessed() {
        if (!this.selectedDraft) {
            return;
        }
        
        this.isLoading = true;
        
        // Update draft status to Processed
        updateDraftStatus({ 
            draftId: this.selectedDraft.Id, 
            status: 'Processed' 
        })
        .then(() => {
            this.showToast('Success', 'Visit report marked as processed!', 'success');
            // Refresh the drafts list
            return refreshApex(this.wiredDraftsResult);
        })
        .then(() => {
            // Close modal
            this.handleModalClose();
        })
        .catch(error => {
            this.showToast('Error', 'Error marking draft as processed: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    
    handleRecordsSaved(event) {
        // Records were saved by mtRecordSuggestion component
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
            this.showToast('Success', 'Visit report processed successfully! Moving to Processed tab...', 'success');
            return refreshApex(this.wiredDraftsResult);
        })
        .then(() => {
            // Close modal after refresh completes
            setTimeout(() => {
                this.handleModalClose();
            }, 1000);
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



