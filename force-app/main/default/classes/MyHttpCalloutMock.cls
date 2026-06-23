public class MyHttpCalloutMock {
 public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"success", "message":"Mock response"}');
        res.setStatusCode(200);
        return res;
    }
}