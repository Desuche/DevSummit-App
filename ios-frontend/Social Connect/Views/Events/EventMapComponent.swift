//
//  EventMapComponent.swift
//  Social Connect
//
//  Created by f1201609 on 25/11/2024.
//

import SwiftUI
import MapKit

struct EventMapComponent: View{
    let latitude: Double
    let longitude: Double

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: [EventMapLocation(longitude: longitude, latitude: latitude)]){ location in
                MapPin(coordinate: location.coordinate, tint: .blue)
            }
                .onAppear {
                    setRegion(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
                .frame(height: 200) // Adjust height as needed
                .cornerRadius(12)
                .shadow(radius: 5)
        }
    }

    private func setRegion(_ coordinate: CLLocationCoordinate2D) {
        region.center = coordinate
    }
}

struct EventMapLocation: Identifiable {
    let id = UUID()
    let longitude : Double
    let latitude : Double
    
    var coordinate : CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
