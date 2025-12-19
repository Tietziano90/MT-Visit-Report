/**
 * ============================================================================
 * MT Visit Report Queue - Lightning Web Component
 * ============================================================================
 * 
 * @description     Displays pending visit report drafts for an Account and
 *                  allows users to review and approve them using a modal
 *                  with the mtRecordSuggestion component.
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

export default class MtVisitReportQueue extends LightningElement {
    @api recordId; // Account ID from record page
    @track drafts = [];
    @track selectedDraft = null;
    @track showReviewModal = false;
    @track isLoading = false;
    
    wiredDraftsResult;
    
    @wire(getDrafts, { accountId: '$recordId' })
    wiredDrafts(result) {
        this.wiredDraftsResult = result;
        if (result.data) {
            this.drafts = result.data.map(draft => ({
                ...draft,
                formattedDate: this.formatDate(draft.CreatedDate),
                truncatedSummary: this.truncateSummary(draft.Summary__c),
                accountName: draft.Account__r ? draft.Account__r.Name : 'Unknown Account'
            }));
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Error loading drafts: ' + result.error.body.message, 'error');
            this.isLoading = false;
        }
    }
    
    get hasDrafts() {
        return this.drafts && this.drafts.length > 0;
    }
    
    get noDrafts() {
        return !this.hasDrafts;
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
    
    handleRecordsSaved(event) {
        // Records were saved by mtRecordSuggestion component
        this.isLoading = true;
        
        updateDraftStatus({ 
            draftId: this.selectedDraft.Id, 
            status: 'Processed' 
        })
        .then(() => {
            this.showToast('Success', 'Visit report processed successfully', 'success');
            this.handleModalClose();
            return refreshApex(this.wiredDraftsResult);
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



