@IsTest
global class MockGeocodingResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"results":[{"geometry":{"location":{"lat":13.0827,"lng":80.2707}}}],"status":"OK"}');
        return response;
    }
}
