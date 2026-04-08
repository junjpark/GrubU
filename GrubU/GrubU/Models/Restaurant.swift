//
//  Restaurant.swift
//  GrubU
//
//  Created by Julie Baguio on 4/7/26.
//

import FirebaseFirestore


struct Restaurant: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var location: String
    var items: [MenuItem]
}


