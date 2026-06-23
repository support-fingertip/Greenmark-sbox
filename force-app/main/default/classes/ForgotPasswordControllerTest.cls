@isTest
public class ForgotPasswordControllerTest {

    @isTest
    public static void testForgotPasswordSuccess() {
        ForgotPasswordController ctrl = new ForgotPasswordController();
        ctrl.username = 'test@example.com';

        // Mock success result
        ctrl.mockResult = true;

        Test.startTest();
        PageReference pr = ctrl.forgotPassword();
        Test.stopTest();

        System.assertNotEquals(null, pr, 'Should return PageReference on success');
       System.assertEquals(
    '/apex/forgotpasswordconfirm',
    pr.getUrl().toLowerCase(),
    'Redirect to correct page'
);
        System.assert(pr.getRedirect(), 'Should be redirect');
    }

    @isTest
    public static void testForgotPasswordFailure() {
        ForgotPasswordController ctrl = new ForgotPasswordController();
        ctrl.username = 'invalid@example.com';

        // Mock failure result
        ctrl.mockResult = false;

        Test.startTest();
        PageReference pr = ctrl.forgotPassword();
        Test.stopTest();

        System.assertEquals(null, pr, 'Should return null on failure');
    }
}