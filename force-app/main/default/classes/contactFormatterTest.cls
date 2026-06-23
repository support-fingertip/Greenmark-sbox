@isTest
public class contactFormatterTest {

    @isTest
    Public static void method1(){
        string mn='9382728392';
        string en='';
        contactFormatter.getformated(en);
        contactFormatter.geAllPhoneNumbers(en);
    }
     @isTest
    Public static void method2(){
        string mn=null;
        string en=null;
        contactFormatter.getformated(mn);
        contactFormatter.geAllPhoneNumbers(en);
    }
}