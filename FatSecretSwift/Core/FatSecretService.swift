// Copyright 2018 Sven Meyer

import Foundation

typealias Clock = () -> Date
typealias Nonce = () -> String

protocol Signer
{
    func sign(data: Data, key: Data) -> Data
}

class FatSecretService
{
    static let oauthVersion = "1.0"
    static let signatureMethod = "HMAC-SHA1"
    static let httpMethod = "GET"
    static let baseURLString = "http://platform.fatsecret.com/rest/server.api"
    
    private let httpRequestor: HTTPRequestor
    private let clock: Clock
    private let nonce: Nonce
    private let signer: Signer
    private let consumerKey: String
    private let consumerSecret: String
    
    init(httpRequestor: HTTPRequestor,
         clock: @escaping Clock,
         nonce: @escaping Nonce,
         signer: Signer,
         consumerKey: String,
         consumerSecret: String)
    {
        self.httpRequestor = httpRequestor
        self.clock = clock
        self.nonce = nonce
        self.signer = signer
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
    
    func get<Response>(method: String,
                       parameters: [String: String] = [:],
                       completion: @escaping (Response?, FatSecretError?) -> Void)
        where Response: Decodable
    {
        guard let url = url(method: method, parameters: parameters) else
        {
            return completion(nil, .invalidRequest)
        }
        
        httpRequestor.get(url: url) { response, error in
            guard error == nil else
            {
                completion(nil, .transport(error!))
                return
            }
            
            guard let response = response else
            {
                fatalError("Response cannot be nil when error is nil")
            }
            
            guard response.statusCode == 200 else
            {
                completion(nil, .response(statusCode: response.statusCode, body: response.body))
                return
            }
            
            guard let data = response.body else
            {
                fatalError("Data argument must not be nil")
            }
            
            let decodedResponse: FatSecretResponse<Response>
            do
            {
                decodedResponse = try JSONDecoder().decode(type(of: decodedResponse), from: data)
            }
            catch
            {
                completion(nil, .decoding(error))
                return
            }
            
            switch decodedResponse
            {
            case .error(let error):
                completion(nil, .fatSecret(error))
            case .valid(let fatSecretResponse):
                completion(fatSecretResponse, nil)
            }
        }
    }
    
    private func url(method: String, parameters: [String: String]) -> URL?
    {
        let allParameters = parameters
            .merging(defaultParameters(method: method), strategy: .ignore)
            .merging(oauthParameters(), strategy: .overwrite)
        
        guard let signature = oauthSignature(parameters: allParameters) else
        {
            return nil
        }
        
        let allParametersWithSignature = allParameters.merging(["oauth_signature": signature], strategy: .overwrite)
        
        let queryString = allParametersWithSignature
            .map { "\($0.key.rfc3986Encoded)=\($0.value.rfc3986Encoded)" }
            .joined(separator: "&")
        
        return URL(string: type(of: self).baseURLString + "?" + queryString)
    }
    
    private func defaultParameters(method: String) -> [String: String]
    {
        return ["format": "json", "method": method]
    }
    
    private func oauthParameters() -> [String: String]
    {
        let timestamp = String(Int(clock().timeIntervalSince1970))
        return ["oauth_consumer_key": consumerKey,
                "oauth_signature_method": type(of: self).signatureMethod,
                "oauth_timestamp": timestamp,
                "oauth_nonce": nonce() + timestamp,
                "oauth_version": type(of: self).oauthVersion]
    }
    
    private func oauthSignature(parameters: [String: String]) -> String?
    {
        let signatureBaseString = oauthSignatureBaseString(parameters: parameters)
        
        guard
            let stringData = signatureBaseString.data(using: .utf8),
            let keyData = (consumerSecret + "&").data(using: .utf8) else
        {
            return nil
        }
        
        return signer.sign(data: stringData, key: keyData).base64EncodedString()
    }
    
    private func oauthSignatureBaseString(parameters: [String: String]) -> String
    {
        let normalizedParams = parameters
            .map { "\($0.key.rfc3986Encoded)=\($0.value.rfc3986Encoded)" }
            .sorted()
            .joined(separator: "&")
        
        let httpMethod = type(of: self).httpMethod
        let uri = type(of: self).baseURLString
        
        return "\(httpMethod.rfc3986Encoded)&\(uri.rfc3986Encoded)&\(normalizedParams.rfc3986Encoded)"
    }
}

fileprivate extension CharacterSet
{
    static let rfc3986Allowed = CharacterSet(charactersIn: Unicode.Scalar("A")...Unicode.Scalar("Z"))
        .union(CharacterSet(charactersIn: Unicode.Scalar("a")...Unicode.Scalar("z")))
        .union(CharacterSet(charactersIn: Unicode.Scalar("0")...Unicode.Scalar("9")))
        .union(CharacterSet(charactersIn: "-._~"))
}

fileprivate extension String
{
    var rfc3986Encoded: String
    {
        return addingPercentEncoding(withAllowedCharacters: .rfc3986Allowed) ?? ""
    }
}
