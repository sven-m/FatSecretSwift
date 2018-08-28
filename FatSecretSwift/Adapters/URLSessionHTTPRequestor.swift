// Copyright 2018 Sven Meyer

import Foundation

class URLSessionHTTPRequestor: HTTPRequestor
{
    public init() {}
    
    public func get(url: URL, completion: @escaping (HTTPResponse?, Error?) -> Void)
    {
        URLSession.shared.dataTask(with: url) { data, response, error in
            let httpURLResponse = response as? HTTPURLResponse
            completion(httpURLResponse.map { HTTPResponse(statusCode: $0.statusCode, body: data) }, error)
        }.resume()
    }
    
    
}
