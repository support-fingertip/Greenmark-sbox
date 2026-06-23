@isTEST
public class CarParkingControllerTest {
@isTest
    public static void testmethodd(){
         Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        
        Test.StartTest();
      CarParkingController.ProjectData pc =  CarParkingController.getProjectsWithStats();
        List<Car_Parking__c> cp = CarParkingController.getParkingRecordsByProject(pjt.Id);
        List<Car_Parking__c> cp1 = CarParkingController.getCarParkings(pjt.Project__c);
        
        List<Project__c> cps = CarParkingController.getProjects();
        CarParkingController.ParkingCounts ps = CarParkingController.getProjectParkingStats(pjt.Id);
        Map<String, String> pci = CarParkingController.getprojectFieldValue();
        Test.StopTest();
    }
}