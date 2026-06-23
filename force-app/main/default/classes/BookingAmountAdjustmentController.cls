public with sharing class BookingAmountAdjustmentController {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getBooking(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Booking Id is required.');
            }

            Booking__c booking = [
                SELECT Id, Name, Project_Type__c,
                       Plot_Land_Cost__c, Construction_Cost__c,
                       Extra_Land_Amount__c, Total_Land_Amount__c,
                       Total_Amount__c
                FROM Booking__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            Integer scheduleCount = [
                SELECT COUNT()
                FROM Payment_schedule__c
                WHERE Booking__c = :recordId
            ];

            Map<String, Object> result = new Map<String, Object>();
            result.put('booking', booking);
            result.put('scheduleCount', scheduleCount);
            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to load booking: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveAdjustment(Id bookingId,
                                      Decimal newPlotLandCost,
                                      Decimal newConstructionCost) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (bookingId == null) {
                throw new AuraHandledException('Booking Id is required.');
            }
            if (newPlotLandCost == null || newPlotLandCost < 0) {
                throw new AuraHandledException('Plot Land Cost cannot be negative.');
            }
            if (newConstructionCost == null || newConstructionCost < 0) {
                throw new AuraHandledException('Construction Cost cannot be negative.');
            }

            Booking__c current = [
                SELECT Id, Plot_Land_Cost__c, Construction_Cost__c,
                       Extra_Land_Amount__c, Total_Amount__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            Decimal oldPlot = current.Plot_Land_Cost__c == null
                ? 0 : current.Plot_Land_Cost__c;
            Decimal oldConstruction = current.Construction_Cost__c == null
                ? 0 : current.Construction_Cost__c;

            Decimal delta = (newPlotLandCost - oldPlot)
                + (newConstructionCost - oldConstruction);
            if (delta.abs() > 0.01) {
                throw new AuraHandledException(
                    'Total booking amount must stay unchanged. '
                    + 'Adjust Construction Cost so it offsets the Plot Land Cost change exactly.');
            }

            update new Booking__c(
                Id = bookingId,
                Plot_Land_Cost__c = newPlotLandCost,
                Construction_Cost__c = newConstructionCost
            );

            Booking__c refreshed = [
                SELECT Id, Total_Land_Amount__c, Construction_Cost__c, Total_Amount__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            Decimal landTotal = refreshed.Total_Land_Amount__c == null
                ? 0 : refreshed.Total_Land_Amount__c;
            Decimal constTotal = refreshed.Construction_Cost__c == null
                ? 0 : refreshed.Construction_Cost__c;
            Decimal bookingTotal = refreshed.Total_Amount__c == null
                ? 0 : refreshed.Total_Amount__c;

            List<Payment_schedule__c> psList = [
                SELECT Id, Name, S_No__c, Type__c, Payment_percent__c, Amount__c,
                       Pending_Amount_Without_Tds__c,Received_Amount1__c
                FROM Payment_schedule__c
                WHERE Booking__c = :bookingId
            ];

            for (Payment_schedule__c ps : psList) {
                Decimal pct = ps.Payment_percent__c == null
                    ? 0 : ps.Payment_percent__c;
                Decimal base;
                if (ps.Type__c == 'Land') {
                    base = landTotal;
                } else if (ps.Type__c == 'Construction') {
                    base = constTotal;
                } else {
                    base = bookingTotal;
                }
                Decimal newAmount = (base * pct / 100)
                    .setScale(0, System.RoundingMode.HALF_UP);

                Decimal receivedAmount = ps.Received_Amount1__c == null
                    ? 0 : ps.Received_Amount1__c;
                if (receivedAmount > newAmount) {
                    throw new AuraHandledException(
                        'Payment Schedule S.No ' + ps.S_No__c + 
                        ' has a received amount of ₹' + receivedAmount + 
                        ', which exceeds the new scheduled amount of ₹' + newAmount + 
                        '. Please adjust the Plot Land Cost to accommodate already-received payments.'
                    );
                }

                ps.Amount__c = newAmount;
            }

            if (!psList.isEmpty()) {
                update psList;
            }
        } catch (AuraHandledException ahe) {
            Database.rollback(sp);
            throw ahe;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Save failed: ' + e.getMessage());
        }
    }
}