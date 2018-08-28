// Copyright 2018 Sven Meyer

import XCTest
import FatSecretSwift

class EndToEndTests: XCTestCase
{
    private static let keys: FatSecretAPIKeys = FatSecretAPIKeys(bundle: Bundle(for: EndToEndTests.self))!
    
    func testSearchBanana()
    {
        var result: (response: FoodSearchResponse?, error: FatSecretError?) = (nil, nil)
        let exp = apiCallExpectation()
        let fatSecret = FatSecret(consumerKey: type(of: self).keys.consumerKey,
                                  consumerSecret: type(of: self).keys.sharedSecret)
        
        fatSecret.foodSearch(query: "banana", completion: { response, error in
            result.response = response
            result.error = error
            
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertNotNil(result.response, "No response received")
        XCTAssertNil(result.error)
    }
    
    func testSearchInvalidKeys()
    {
        var result: (response: FoodSearchResponse?, error: FatSecretError?) = (nil, nil)
        let exp = apiCallExpectation()
        let fatSecret = FatSecret(consumerKey: "xyz",
                                  consumerSecret: "abc")
        
        fatSecret.foodSearch(query: "banana", completion: { response, error in
            result.response = response
            result.error = error
            
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertNil(result.response, "Unexpected response received")
        if case let FatSecretError.fatSecret(errorResponse)? = result.error
        {
            XCTAssertEqual(5, errorResponse.code)
        }
        else
        {
            XCTFail("Unexpected error: \(String(describing: result.error))")
        }
    }
    
    private func apiCallExpectation() -> XCTestExpectation
    {
        return expectation(description: "API call to return")
    }
}
