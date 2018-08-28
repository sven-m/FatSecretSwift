// Copyright 2018 Sven Meyer

import Foundation

public struct FoodSearchResponse
{
    var maximumResultsPerPage: Int
    var totalResults: Int
    var pageNumber: Int
}

extension FoodSearchResponse: Decodable
{
    private enum DecodingError: Error
    {
        case notAnInteger(String)
    }
    
    public init(from decoder: Decoder) throws
    {
        let integerOrThrow: (String) throws -> Int = {
            guard let int = Int($0) else { throw DecodingError.notAnInteger($0) }
            return int
        }
        
        let container = try decoder
            .container(keyedBy: CodingKeys.self)
            .nestedContainer(keyedBy: FoodsCodingKeys.self, forKey: .foods)
        
        maximumResultsPerPage = try integerOrThrow(container.decode(String.self, forKey: .maximumResultsPerPage))
        totalResults = try integerOrThrow(container.decode(String.self, forKey: .totalResults))
        pageNumber = try integerOrThrow(container.decode(String.self, forKey: .pageNumber))
    }
    
    enum CodingKeys: String, CodingKey
    {
        case foods
    }
    
    enum FoodsCodingKeys: String, CodingKey
    {
        case maximumResultsPerPage = "max_results"
        case totalResults = "total_results"
        case pageNumber = "page_number"
    }
}

private extension URLQueryItem
{
    static let foodSearchMethodParameter = URLQueryItem(name: "method", value: "foods.search")
    static let formatJsonParameter = URLQueryItem(name: "format", value: "json")
    static func searchExpression(_ expression: String) -> URLQueryItem
    {
        return URLQueryItem(name: "search_expression", value: expression)
    }
}
