/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class ForgotPasswordController {
    public String username {get; set;}   

    // Allow override in tests
    @TestVisible private Boolean mockResult = null;

    public ForgotPasswordController() {}

    // Wrapper to allow mocking
    @TestVisible
    private Boolean doForgotPassword(String username) {
        if (mockResult != null) {
            return mockResult; // test override
        }
        return Site.forgotPassword(username);
    }
	
    public PageReference forgotPassword() {
        Boolean success = doForgotPassword(username);

        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);
        
        if (success) {
            return pr;
        }
        return null;
    }
}