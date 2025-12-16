/*
================================================================================
MT RECORD SUGGESTION - Lightning Web Component
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 1.5

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

import { LightningElement, api } from 'lwc';

export default class MtDateInput extends LightningElement {
    @api label;
    @api required = false;
    @api disabled = false;

    _value;

    @api
    get value() {
        return this._value;
    }
    set value(v) {
        this._value = v ?? '';
    }

    inputId = `mtDateInput-${Math.random().toString(36).slice(2)}`;

    handleSelect(event) {
        // Prevent parent row click handlers from toggling selection off (iOS date picker causes extra click/focus events).
        event.stopPropagation();
        if (this.disabled) return;

        this.dispatchEvent(
            new CustomEvent('mtselect', {
                bubbles: true,
                composed: true
            })
        );
    }

    handleChange(event) {
        const newValue = event.target.value;
        this._value = newValue;

        // Bubble a "change" event that looks similar enough to lightning-input/lightning-input-field
        // so the parent can keep using its existing handleFieldChange.
        this.dispatchEvent(
            new CustomEvent('change', {
                bubbles: true,
                composed: true,
                detail: { value: newValue }
            })
        );
    }
}


