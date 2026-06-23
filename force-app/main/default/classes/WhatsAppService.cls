public class WhatsAppService {

    private static final String ENDPOINT_URL = 'https://rengage.mcube.com/api/wpbox/sendtemplatemessage';
    private static final String AUTHORIZATION_HEADER = 'Bearer DGw6K3278c1e4y9aF0veYYt5uC90tk7wEVHDJk4G9270b2c2';
    
    // Method to send WhatsApp message
    public static void sendWhatsAppMessage(String phoneNumber, String templateName, String templateLanguage, String textMessage) {
        // Prepare the request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'phone' => phoneNumber,
            'template_name' => templateName,
            'template_language' => templateLanguage,
            'components' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'type' => 'body',
                    'parameters' => new List<Map<String, Object>>{
                        new Map<String, Object>{'type' => 'text', 'text' => textMessage}
                    }
                }
            }
        };
        
        // Convert the request body to JSON
        String requestBodyJson = JSON.serialize(requestBody);
        
        // Create an HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', AUTHORIZATION_HEADER);
        req.setBody(requestBodyJson);
        
        // Send the request and handle the response
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Check the response status
        if (res.getStatusCode() == 200) {
            System.debug('WhatsApp message sent successfully.');
        } else {
            System.debug('Failed to send WhatsApp message. Status: ' + res.getStatusCode() + ', Response: ' + res.getBody());
        }
    }
}