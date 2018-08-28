// Copyright 2018 Sven Meyer

import XCTest

class FatSecretSwiftUnitTests: XCTestCase
{
    var httpResponse: HTTPResponse?
    var error: Error?
    var url: URL?
    
    let now = Date()
    let nonce = "abc"
    let signature = "signature"
    
    func testURLParameters()
    {
        let requestor = FakeHTTPRequestor(error: TestError.shared)
        let now = Date()
        let service = FatSecretService(httpRequestor: requestor,
                                       clock: { now },
                                       nonce: { "abc" },
                                       signer: FakeSigner("signature"),
                                       consumerKey: "testkey",
                                       consumerSecret: "testsecret")
        
        service.get(method: "test", parameters: ["~!@#$%^&*()":")(*&^%$#@!"], completion: { (_:TestResponse?,_) in })
        
        if let url = requestor.url,
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        {
            let expectedTimestamp = String(Int(now.timeIntervalSince1970))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "oauth_timestamp", value: expectedTimestamp)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "oauth_nonce", value: "abc" + expectedTimestamp)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "oauth_consumer_key", value: "testkey")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "method", value: "test")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "~!@#$%^&*()", value: ")(*&^%$#@!")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "oauth_signature", value: "signature".data(using: .utf8)?.base64EncodedString())))
        }
        else
        {
            XCTFail("Incorrect url: \(String(describing: requestor.url))")
        }
    }
    
    override func tearDown()
    {
        httpResponse = nil
        error = nil
        url = nil
        
        super.tearDown()
    }
    
    func testTransportError()
    {
        let requestor = FakeHTTPRequestor(error: TestError.shared)
        let service = FatSecretService(httpRequestor: requestor,
                                       clock: { Date() },
                                       nonce: { "abc" },
                                       signer: FakeSigner("signature"),
                                       consumerKey: "testkey",
                                       consumerSecret: "testsecret")
        let helper = FatSecretServiceHelper()
        
        service.get(method: "test", completion: helper.completion)
        
        XCTAssertNil(helper.response)
        XCTAssert(helper.error?.transportError as? TestError === TestError.shared, "\(String(describing: helper.error))")
    }
    
    func testResponseError()
    {
        let requestor = FakeHTTPRequestor(httpResponse: HTTPResponse(statusCode: 400, body: nil))
        let service = FatSecretService(httpRequestor: requestor,
                                       clock: { Date() },
                                       nonce: { "abc" },
                                       signer: FakeSigner("signature"),
                                       consumerKey: "testkey",
                                       consumerSecret: "testsecret")
        let helper = FatSecretServiceHelper()
        
        service.get(method: "test", completion: helper.completion)
        
        XCTAssertNil(helper.response)
        XCTAssertEqual(400, helper.error?.responseError?.statusCode)
        XCTAssertNil(helper.error?.responseError?.body)
    }
    
    func testDecodingError()
    {
        let body = "{\"x\": 3}".data(using: .utf8)!
        
        let requestor = FakeHTTPRequestor(httpResponse: HTTPResponse(statusCode: 200, body: body))
        let service = FatSecretService(httpRequestor: requestor,
                                       clock: { Date() },
                                       nonce: { "abc" },
                                       signer: FakeSigner("signature"),
                                       consumerKey: "testkey",
                                       consumerSecret: "testsecret")
        let helper = FatSecretServiceHelper()
        
        service.get(method: "test", completion: helper.completion)
        
        XCTAssertNil(helper.response)
        XCTAssertNotNil(helper.error?.decodingError)
    }
    
    func testFatSecretError()
    {
        let body = "{\"error\": {\"code\": 1, \"message\":\"the message\"}}".data(using: .utf8)!
        let requestor = FakeHTTPRequestor(httpResponse: HTTPResponse(statusCode: 200, body: body))
        let service = FatSecretService(httpRequestor: requestor,
                                       clock: { Date() },
                                       nonce: { "abc" },
                                       signer: FakeSigner("signature"),
                                       consumerKey: "testkey",
                                       consumerSecret: "testsecret")
        let helper = FatSecretServiceHelper()
        
        service.get(method: "test", completion: helper.completion)
        
        XCTAssertNil(helper.response)
        XCTAssertEqual(FatSecretErrorResponse(code: 1, message: "the message"), helper.error?.fatSecretErrorResponse)
    }
}

fileprivate struct TestResponse: Decodable
{
    var value: String
}

fileprivate class FatSecretServiceHelper
{
    var response: TestResponse?
    var error: FatSecretError?
    
    func completion(response: TestResponse?, error: FatSecretError?)
    {
        self.response = response
        self.error = error
    }
}

fileprivate class FakeHTTPRequestor: HTTPRequestor
{
    let httpResponse: HTTPResponse?
    let error: Error?
    var url: URL?
    
    init(httpResponse: HTTPResponse)
    {
        self.httpResponse = httpResponse
        self.error = nil
    }
    
    init(error: Error)
    {
        self.httpResponse = nil
        self.error = error
    }
    
    func get(url: URL, completion: @escaping (HTTPResponse?, Error?) -> Void)
    {
        self.url = url
        completion(httpResponse, error)
    }
}

fileprivate class FakeSigner: Signer
{
    private let signature: String
    
    var key: Data?
    var data: Data?
    
    init (_ signature: String)
    {
        self.signature = signature
    }
    
    func sign(data: Data, key: Data) -> Data
    {
        self.data = data
        self.key = key
        
        return signature.data(using: .utf8)!
    }
}

fileprivate class TestError: Error
{
    static let shared = TestError()
}
