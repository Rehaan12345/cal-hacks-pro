//
//  CrimeRecsResponse.swift
//  Safety-Buddy
//
//  Created by Om Chachad on 25/10/25.
//


struct CrimeRecsResponse: Codable {
    let status: Int
    let data: CrimeData
}

struct CrimeData: Codable {
    let recommendations: [String]
    let crime_amount: Int
}
