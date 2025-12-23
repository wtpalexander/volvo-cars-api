//
//  VehicleDetailsResponse.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

public struct VehicleDetailsResponse: Codable {
    public let data: VehicleDetails

    public struct VehicleDetails: Codable {
        public let vin: String
        public let modelYear: Int?
        public let descriptions: Descriptions?
        public let images: Images?

        public struct Descriptions: Codable {
            public let model: String?
        }

        public struct Images: Codable {
            public let exterior: ExteriorImages?

            public struct ExteriorImages: Codable {
                public let imageUrl: String?

                enum CodingKeys: String, CodingKey {
                    case imageUrl = "url"
                }
            }
        }
    }
}
