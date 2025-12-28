//
//  TyresResponse.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 28/12/2025.
//

import Foundation

public struct TyresResponse: Codable {
    public let data: TyresData

    public struct TyresData: Codable {
        public let frontLeft: TyreStatus
        public let frontRight: TyreStatus
        public let rearLeft: TyreStatus
        public let rearRight: TyreStatus

        public struct TyreStatus: Codable {
            public let value: PressureLevel
            public let timestamp: String

            public enum PressureLevel: String, Codable {
                case unspecified = "UNSPECIFIED"
                case noWarning = "NO_WARNING"
                case veryLowPressure = "VERY_LOW_PRESSURE"
                case lowPressure = "LOW_PRESSURE"
                case highPressure = "HIGH_PRESSURE"
            }
        }
    }
}
