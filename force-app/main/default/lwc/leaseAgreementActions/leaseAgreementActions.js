import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import jsPdfResource from '@salesforce/resourceUrl/jsPDF';
import getAgreement from '@salesforce/apex/LeaseAgreementController.getAgreement';
import sendAgreementPdf from '@salesforce/apex/LeaseAgreementController.sendAgreementPdf';

export default class LeaseAgreementActions extends LightningElement {
    @api recordId;
    jsPdfReady = false;

    async renderedCallback() {
        if (this.jsPdfReady) {
            return;
        }
        await loadScript(this, jsPdfResource);
        this.jsPdfReady = true;
    }

    async buildPdf() {
        const agreement = await getAgreement({ agreementId: this.recordId });
        const jsPDF = window.jspdf?.jsPDF;
        if (!jsPDF) {
            throw new Error('jsPDF static resource is not loaded. Replace the placeholder static resource with jspdf.umd.min.js.');
        }

        const doc = new jsPDF();
        doc.setFontSize(16);
        doc.text(`Lease Agreement ${agreement.Name}`, 20, 20);
        doc.setFontSize(11);
        doc.text(`Tenant: ${agreement.Tenant__r?.Name || ''}`, 20, 35);
        doc.text(`Property: ${agreement.Property__r?.Name || ''}`, 20, 45);
        doc.text(`Address: ${agreement.Property__r?.Address__c || ''}, ${agreement.Property__r?.City__c || ''}`, 20, 55);
        doc.text(`Rent: ${agreement.Agreed_Monthly_Rent__c}`, 20, 65);
        doc.text(`Start Date: ${agreement.Start_Date__c}`, 20, 75);
        doc.text(`End Date: ${agreement.End_Date__c}`, 20, 85);
        doc.text('Terms:', 20, 100);
        doc.text(doc.splitTextToSize(agreement.Terms__c || '', 170), 20, 110);
        return doc;
    }

    async downloadPdf() {
        try {
            const doc = await this.buildPdf();
            doc.save(`lease-${this.recordId}.pdf`);
        } catch (error) {
            this.toast('Unable to download PDF', error.message, 'error');
        }
    }

    async sendPdf() {
        try {
            const doc = await this.buildPdf();
            const dataUri = doc.output('datauristring');
            const pdfBase64 = dataUri.split(',')[1];
            await sendAgreementPdf({ agreementId: this.recordId, pdfBase64 });
            this.toast('PDF sent', 'The lease agreement was emailed to the tenant.', 'success');
        } catch (error) {
            this.toast('Unable to send PDF', error.body?.message || error.message, 'error');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
