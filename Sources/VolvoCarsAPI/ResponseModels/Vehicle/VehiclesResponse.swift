//
//  VehiclesResponse.swift
//  VolvoCarsAPI
//
//  Created by William Alexander on 23/12/2025.
//

import Foundation

struct VehiclesResponse: Codable {
    let data: [Vehicle]

    struct Vehicle: Codable {
        let vin: String
    }
}
