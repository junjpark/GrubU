//
//  Restaurant.swift
//
//  A dining spot + its menu items for the request flow.
//
//  Created by Julie Baguio on 4/7/26.
//

import FirebaseFirestore


struct Restaurant: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var location: String
    /// HTTPS URL (e.g. Firebase Storage). Omit or leave empty for a placeholder tile.
    /// Any phone photo resolution works; the UI crops with `scaledToFill` inside a fixed aspect frame.
    var imageUrl: String?
    var items: [MenuItem]
}


