trigger InspectionTrigger on Inspection__c (before update,
                                            after insert, after update,
                                            after delete, after undelete) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        InspectionTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        InspectionTriggerHandler.sendCompletionEmail(Trigger.new, Trigger.oldMap);
    }

    // On create, share the Inspection with the Booking Owner (Read/Write).
    if (Trigger.isAfter && Trigger.isInsert) {
        InspectionTriggerHandler.shareWithBookingOwner(Trigger.new);
    }

    // Keep Booking__c.Open_Inspections__c in sync with the number of OPEN
    // inspections (Failed / In Progress / Scheduled) on every change.
    if (Trigger.isAfter) {
        InspectionTriggerHandler.updateBookingOpenInspections(Trigger.new, Trigger.old);
    }
}