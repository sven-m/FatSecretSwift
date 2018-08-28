// Copyright 2018 Sven Meyer

import Foundation

public enum FatSecretError: Error
{
    case invalidRequest
    case transport(Error)
    case response(statusCode: Int, body: Data?)
    case decoding(Error)
    case fatSecret(FatSecretErrorResponse)
}

extension FatSecretError
{
    var isInvalidRequest: Bool
    {
        guard case .invalidRequest = self else { return false }
        return true
    }
    
    var transportError: Error?
    {
        guard case let .transport(error) = self else { return nil }
        return error
    }
    
    var responseError: (statusCode: Int, body: Data?)?
    {
        guard case let .response(statusCode: statusCode, body: body) = self else
        {
            return nil
        }
        
        return (statusCode: statusCode, body: body)
    }
    
    var decodingError: Error?
    {
        guard case let .decoding(error) = self else { return nil }
        return error
    }
    
    var fatSecretErrorResponse: FatSecretErrorResponse?
    {
        guard case let .fatSecret(errorResponse) = self else { return nil }
        return errorResponse
    }
}
