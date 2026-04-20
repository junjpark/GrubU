//
//  MenuItem.swift
//
//  Single menu line (name, price, blurb).
//
//  Created by Julie Baguio on 4/7/26.
//

struct MenuItem: Identifiable, Codable, Hashable {
    var id: String { name } // Using name as ID for simplicity
    var name: String
    var price: Double
    var description: String
}
