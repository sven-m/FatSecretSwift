// Copyright 2018 Sven Meyer

import Foundation

public struct FatSecretAPIKeys
{
    public var consumerKey: String
    public var sharedSecret: String
}

public extension FatSecretAPIKeys
{
    private static let consumerKeyKey = "FatSecretConsumerKey"
    private static let sharedSecretKey = "FatSecretSharedSecret"
    
    public init?(bundle: Bundle)
    {
        guard let consumerKey = bundle.object(forInfoDictionaryKey: "FatSecretConsumerKey") as? String,
            let sharedSecret = bundle.object(forInfoDictionaryKey: "FatSecretSharedSecret") as? String else
        {
            return nil
        }
        
        self.init(consumerKey: consumerKey, sharedSecret: sharedSecret)
    }
}

public extension Bundle
{
    
}
