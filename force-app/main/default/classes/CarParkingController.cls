/****************************************************************
* Class Name : CarParkingController
* Company : Fingertipplus
* Created Date : 1-04-2025
* @description : This class is responsible for showing the data in Custom Tab Car Parking.
* @author : Praveen Kumar
* Used By : CarParkingLayoutComp Aura Component
* 
*
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Praveen Kumar | 1-04-2025 | Initial version
* -----------------------------------------------------------------------------
**************************************************************/
public with sharing class CarParkingController {
    
    // Wrapper class to return project data with statistics
    public class ProjectData {
        @AuraEnabled public List<Project__c> projects;
        @AuraEnabled public Integer totalProjects;
        @AuraEnabled public Integer totalVacant;
        @AuraEnabled public Integer totalSold;
    }

    // Wrapper class for parking counts (used in getParkingCounts)
    public class ParkingCounts {
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer vacantCount;
        @AuraEnabled public Integer soldCount;
    }

    // ===== Main Methods =====

    /**
     * Gets all projects with summary statistics (total, vacant, sold)
     * @return ProjectData wrapper with projects and counts
     */
    @AuraEnabled(cacheable=true)
    public static ProjectData getProjectsWithStats() {
        ProjectData data = new ProjectData();
        
        // Get all projects (with unit counts)
        data.projects = [SELECT Id, Name  FROM Project__c ORDER BY Name   ];
        
        data.totalProjects = data.projects.size();
        
        // Get parking counts using separate COUNT queries (best practice)
        ParkingCounts counts = getParkingCounts();
        data.totalVacant = counts.vacantCount;
        data.totalSold = counts.soldCount;
        
        return data;
    }

    /**
     * Gets parking records for a specific project
     * @param projectId The ID of the project to filter by
     * @return List of Car_Parking__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Car_Parking__c> getParkingRecordsByProject(Id projectId) {
        return [SELECT Id, Name, Project__c, Project__r.Name FROM Car_Parking__c  WHERE Project__c = :projectId  ORDER BY Sl_No__c];
    }

    // ===== Helper Methods =====

    /**
     * Gets counts of parking records (total, vacant, sold)
     * Uses separate COUNT queries for reliability
     * @return ParkingCounts wrapper with aggregated numbers
     */
    private static ParkingCounts getParkingCounts() {
        ParkingCounts counts = new ParkingCounts();
        
        // Get total count (all records)
        counts.totalCount = [SELECT COUNT() FROM Car_Parking__c];
        
        // Get vacant count (Status = 'Vacant')
        counts.vacantCount = [SELECT COUNT() FROM Car_Parking__c WHERE Car_Parking_Status__c = 'Not Alotted'];
        
        // Get sold count (Status = 'Sold')
        counts.soldCount = [SELECT COUNT() FROM Car_Parking__c WHERE Car_Parking_Status__c = 'Allotted'];
        
        return counts;
    }
    @AuraEnabled(cacheable=true)
public static ParkingCounts getProjectParkingStats(Id projectId) {
    ParkingCounts counts = new ParkingCounts();
    
    counts.totalCount = [SELECT COUNT() FROM Car_Parking__c WHERE Project__c = :projectId];
    counts.vacantCount = [SELECT COUNT() FROM Car_Parking__c 
                         WHERE Project__c = :projectId AND Car_Parking_Status__c = 'Not Alotted'];
    counts.soldCount = [SELECT COUNT() FROM Car_Parking__c 
                       WHERE Project__c = :projectId AND Car_Parking_Status__c = 'Allotted'];
    
    return counts;
}
    
    @auraEnabled
    Public static List<Project__c> getProjects(){
        return [SELECT Id,Project__c,Project_Address__c,Total_Car_Parking__c,Total_Blocked_Car_Parking__c,Total_Available_Car_Parking__c,Total_Alotted_Car_Parking__c FROM Project__c];
    }
    
    @auraEnabled
    Public static List<Car_Parking__c> getCarParkings(string Project){
        return [select id,Sl_No__c,REM__c,Project__c,Parking_Slot__c,Flat_Number__c,Car_Parking_Status__c  from Car_Parking__c  WHERE Project__c=:project order by Sl_No__c Asc];
    }
    /*
 @AuraEnabled
    public static List<Map<String, String>> getCarParkingPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        // Get the describe result for the object
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get the field describe result
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        
        // Get the picklist values
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) { 
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        system.debug(picklistValues);
        return picklistValues;
    }
    */
  @AuraEnabled 
    public static Map<String, String> getprojectFieldValue(){
        Map<String, String> options = new Map<String, String>();
        
        Schema.DescribeFieldResult fieldResult = Car_Parking__c.Car_Parking_Status__c.getDescribe();
        
        List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pValues) {
            options.put(p.getValue(), p.getLabel());
        }
        
        return options;
    }
  
}