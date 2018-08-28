// Copyright 2018 Sven Meyer

import Foundation

protocol HTTPRequestor
{
    func get(url: URL, completion: @escaping (HTTPResponse?, Error?) -> Void)
}

struct HTTPResponse
{
    var statusCode: Int
    var body: Data?
}
