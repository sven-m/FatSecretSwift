// Copyright 2018 Sven Meyer

import Foundation

enum FatSecretResponse<T>: Decodable where T : Decodable
{
    case error(FatSecretErrorResponse)
    case valid(T)
    
    enum CodingKeys: String, CodingKey
    {
        case error, valid
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.error)
        {
            self = .error(try container.decode(FatSecretErrorResponse.self, forKey: .error))
        }
        else
        {
            self = .valid(try T.init(from: decoder))
        }
    }
}

public struct FatSecretErrorResponse: Decodable, Equatable
{
    public var code: Int
    public var message: String
    
    init(code: Int, message: String)
    {
        self.code = code
        self.message = message
    }
}
