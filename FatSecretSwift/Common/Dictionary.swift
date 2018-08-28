// Copyright 2018 Sven Meyer

import Foundation

extension Dictionary
{
    enum MergeStrategy
    {
        case ignore
        case overwrite
    }
    
    func merging(_ other: [Key: Value], strategy: MergeStrategy) -> [Key: Value]
    {
        return merging(other, uniquingKeysWith: { left, right in
            switch strategy
            {
            case .ignore: return left
            case .overwrite: return right
            }
        })
    }
}
