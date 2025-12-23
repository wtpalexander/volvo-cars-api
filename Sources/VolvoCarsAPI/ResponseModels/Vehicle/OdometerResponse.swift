//
//  OdometerResponse.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

public struct OdometerResponse: Codable {
    public let data: OdometerData

    public struct OdometerData: Codable {
        public let odometer: Odometer?

        public struct Odometer: Codable {
            public let value: Double
            public let unit: String
            public let timestamp: String?
        }
    }
}
