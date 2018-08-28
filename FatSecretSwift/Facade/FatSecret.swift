// Copyright 2018 Sven Meyer

import Foundation

public class FatSecret
{
    private let service: FatSecretService
    
    public convenience init()
    {
        guard let keys = FatSecretAPIKeys(bundle: .main) else
        {
            fatalError("Error: cannot load API keys from main bundle.")
        }
        
        self.init(consumerKey: keys.consumerKey, consumerSecret: keys.sharedSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String)
    {
        self.service = FatSecretService(httpRequestor: URLSessionHTTPRequestor(),
                                        clock: { Date() },
                                        nonce: { "nonce" },
                                        signer: Sha1Signer(),
                                        consumerKey: consumerKey,
                                        consumerSecret: consumerSecret)
    }
    
    public func foodSearch(query: String, completion: @escaping (FoodSearchResponse?, FatSecretError?) -> Void)
    {
        service.get(method: "foods.search", completion: completion)
    }
}

private class Sha1Signer: Signer
{
    func sign(data: Data, key: Data) -> Data
    {
        return data.sha1signed(key: key)
    }
}
