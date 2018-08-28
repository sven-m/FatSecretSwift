// Copyright 2018 Sven Meyer

import Foundation
import CommonCrypto

extension Data
{
    func sha1signed(key: Data) -> Data
    {
        let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        defer { hashBytes.deallocate() }
        
        withUnsafeBytes { bytes -> Void in
            key.withUnsafeBytes { keyBytes -> Void in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyBytes, key.count, bytes, count, hashBytes)
            }
        }
        
        return Data(bytes: hashBytes, count: Int(CC_SHA1_DIGEST_LENGTH))
    }
}
