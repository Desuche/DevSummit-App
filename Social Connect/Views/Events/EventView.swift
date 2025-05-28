//
//  EventView.swift
//  Social Connect
//
//  Created by f1201609 on 23/11/2024.
//
import Foundation
import SwiftUI

struct EventView: View {
    var eventId: String
    @EnvironmentObject var eventService : EventService
    @State var event : Event? = nil
    @State var shouldReload = false
    @State var isLoading = false
    
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: 16) {
                if (isLoading){
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                Text(event?.name ?? "Loading...")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Date: \(Event.dateDisplayFormat(date: event?.date ?? Date()))")
                    .font(.headline)
                    .foregroundColor(.gray)
                ScrollView{
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                        Text(event?.description  ?? "Loading...")
                            .font(.title3)
                        
                        Spacer()
                        Divider()
                        Text("Organiser")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(" \(event?.organiser  ?? "Loading...")")
                            .font(.title3)
                        
                        Divider()
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("\(event?.location  ?? "Loading")")
                            .font(.title3)
                        EventMapComponent(latitude: event?.latitude ?? 10.0, longitude: event?.longitude ?? 10.0)
                        
                        Spacer()
                        
                    }
                }
                // Buttons for Register and Unregister
                    HStack {
                        if (event != nil){
                            if (event?.attendees.count ?? -1 == 0){
                                Button(action: {
                                    // Action for Register button
                                    eventService.registerForEvent(eventId: eventId, shouldReload: $shouldReload)
                                }) {
                                    Text("Register for Event")
                                        .frame(maxWidth: .infinity) // Make the button take the full width
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            if (event?.attendees.count ?? -1 > 0){
                                
                                Button(action: {
                                    // Action for Unregister button
                                    eventService.unregisterForEvent(eventId: eventId, shouldReload: $shouldReload)
                                }) {
                                    Text("Cancel your registration")
                                        .frame(maxWidth: .infinity) // Make the button take the full width
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                .padding(.top, 16) // Add some space above the buttons
                }
            }
            .padding()
            .onAppear{
                eventService.fetchSingleEvent(eventId: eventId, event: $event, isLoading: $isLoading)
            }
            .onChange(of: shouldReload){
                eventService.fetchSingleEvent(eventId: eventId, event: $event, isLoading: $isLoading)
            }
        
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper function to format the date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}




