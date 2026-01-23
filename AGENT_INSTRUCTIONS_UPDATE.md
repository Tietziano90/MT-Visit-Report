# Updated Agent Instructions for Better Confirmation

## Update the Topic Instructions:

Go to your **Visit Report Creation** topic and update the instructions:

### **Replace Instruction 5 with:**

**OLD:**
```
After the user finishes describing their visit, ask if there is anything else to add. Keep this question brief.
```

**NEW:**
```
After the user finishes describing their visit, ask if there is anything else to add. Keep this question brief. Do NOT repeat back what they said word-for-word.
```

### **Replace Instruction 6 with:**

**OLD:**
```
When creating the draft, use the Create Visit Report Draft action with the found account ID and the full transcript of what the user said about their visit.
```

**NEW:**
```
Before creating the draft, provide a SHORT SUMMARY confirmation (2-3 key points only). For example: "I'll create a report for: meeting with [Name], discussed [main topic], amount [X], next step [Y]." Then use the Create Visit Report Draft action with the account ID and the FULL DETAILED transcript (not just the summary).
```

### **Add New Instruction 8:**
```
When confirming the draft is created, be brief and friendly. Do NOT repeat the details again. Just say it's created and will be processed.
```

---

## Example of Better Confirmation:

**BEFORE (What it's doing now):**
```
To confirm, the report now includes: "Met with Peter Smith. He has a new position as Vice President. Discussed a new opportunity named All tools 500. The amount is 55,000. Next step is to involve management." Is this correct?
```

**AFTER (What you want):**
```
I'll create a report for: Peter Smith (new VP), opportunity "All Tools 500" for $55,000, next step: involve management. Correct?
```

---

## Alternative: Update System Instructions

Or add this to the **main Agent System Instructions**:

```
CONFIRMATION STYLE:
- When confirming details before creating the draft, provide a SHORT SUMMARY (2-3 bullet points max)
- Focus on: WHO you met, WHAT was discussed, KEY NUMBERS, NEXT STEPS
- Do NOT repeat the user's exact words back to them
- Keep confirmations under 20 words when possible
```

---

Would you like me to create a complete updated instruction set you can copy-paste into your agent?





