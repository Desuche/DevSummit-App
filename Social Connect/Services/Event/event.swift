//
//  EventService.swift
//  Social Connect
//
//  Created by f1201609 on 26/11/2024.
//

import Foundation
import Combine
import SwiftUI

class EventService: ObservableObject {
    private let authManager: AuthManager
    private let eventsBaseApi = EVENT_BASE_URL
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    
    func fetchSingleEvent(eventId: String, event:  Binding<Event?>, isLoading: Binding<Bool>) {
        isLoading.wrappedValue = true
        print("Fetching event with ID: \(eventId)")
        guard let bearerToken = authManager.getBearerToken() , bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(eventsBaseApi)/event/id/\(eventId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching event: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error with status code: \(String(describing: response))")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                let eventResponse = try JSONDecoder().decode(EventResponse.self, from: data)
                if let fetchedEvent = Event(from: eventResponse) {
                    DispatchQueue.main.async {
                        event.wrappedValue = fetchedEvent // Store the fetched event
                        print("Successfully fetched event: \(eventId)")
                    }
                } else {
                    print("Failed to initialize Event from response.")
                }
            } catch {
                print("Error decoding event: \(error)")
            }
            isLoading.wrappedValue = false
        }
        task.resume()
    }
    
    func fetchAllEvents(events:  Binding<[Event]>, isLoading: Binding<Bool>) {
        isLoading.wrappedValue = true
        print("Fetching events...")
        guard let bearerToken = authManager.getBearerToken(), bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(eventsBaseApi)/event/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
     
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching events: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error with status code: \(String(describing: response))")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                let eventResponses = try JSONDecoder().decode([EventResponse].self, from: data)
                let parsedEvents = eventResponses.compactMap { Event(from: $0) } // Use compactMap to filter out nil values
                DispatchQueue.main.async {
                    events.wrappedValue = parsedEvents
                    print("Successfully fetched events: \( events.wrappedValue.count)")
                }
            } catch {
                print("Error decoding events: \(error)")
            }
            isLoading.wrappedValue = false
        }
        task.resume()
    }
    
    func fetchMyEvents(myEvents:  Binding<[Event]>, isLoading: Binding<Bool>) {
        isLoading.wrappedValue = true
        print("Fetching my registered events...")
        guard let bearerToken = authManager.getBearerToken() , bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(eventsBaseApi)/event/registered") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching my events: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error with status code: \(String(describing: response))")
                return
            }
            
            guard let data = data else {
                print("No data received.")
                return
            }
            
            do {
                let eventResponses = try JSONDecoder().decode([EventResponse].self, from: data)
                let events = eventResponses.compactMap { Event(from: $0) } // Use compactMap to filter out nil values
                DispatchQueue.main.async {
                    myEvents.wrappedValue = events // Update the events state
                    print("Successfully fetched my events: \(myEvents.wrappedValue.count)")
                }
            } catch {
                print("Error decoding my events: \(error)")
            }
            isLoading.wrappedValue = false
        }
        task.resume()
    }
    
    func registerForEvent(eventId: String, shouldReload: Binding<Bool>) {
        print("Registering for event with ID: \(eventId)")
        
        guard let bearerToken = authManager.getBearerToken() , bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(eventsBaseApi)/event/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the JSON body
        let body: [String: Any] = ["eventId": eventId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error registering for event: \(error)")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error with status code: \(String(describing: response))")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            guard data != nil else {
                print("No data received.")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            // Optionally, you could decode the response if needed
            // Here we simply acknowledge registration success
            DispatchQueue.main.async {
                shouldReload.wrappedValue.toggle() // Trigger reload
                print("Successfully registered for event: \(eventId)")
            }
        }
        
        task.resume()
    }

    func unregisterForEvent(eventId: String, shouldReload: Binding<Bool>) {
        print("Unregistering for event with ID: \(eventId)")
        
        guard let bearerToken = authManager.getBearerToken() , bearerToken != "" else {
            print("Token unavailable")
            return
        }
        
        guard let url = URL(string: "\(eventsBaseApi)/event/unregister") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the JSON body
        let body: [String: Any] = ["eventId": eventId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error unregistering from event: \(error)")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error with status code: \(String(describing: response))")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            guard let data = data else {
                print("No data received.")
                DispatchQueue.main.async {
                    shouldReload.wrappedValue.toggle() // Trigger reload
                }
                return
            }
            
            // Optionally, you could decode the response if needed
            // Here we simply acknowledge unregistration success
            DispatchQueue.main.async {
                shouldReload.wrappedValue.toggle() // Trigger reload
                print("Successfully unregistered from event: \(eventId)")
            }
        }
        
        task.resume()
    }
}

struct EventResponse: Decodable {
    let _id: String
    let name: String
    let date: String
    let description: String
    let location: String
    let latitude: Double
    let longitude: Double
    let organiser: String
    let attendees: [String]
}

struct Event: Identifiable {
    let _id: String
    let id = UUID()
    let name: String
    let date: Date
    let description: String
    let location: String
    let latitude: Double
    let longitude: Double
    let organiser: String
    let attendees: [String]
    
    // Custom initializer to convert from EventResponse
    init?(from response: EventResponse) {
        self._id = response._id
        self.name = response.name
        
        // Attempt to parse the date string
        guard let parsedDate = Event.dateFormatter.date(from: response.date) else {
            print(response.date)
            print("Warning: Date format not recognized for event: \(response.name), using current date instead.")
            self.date = Date() // Fallback to current date
            return nil // Return nil to skip this event
        }
        
        self.date = parsedDate
        self.description = response.description
        self.location = response.location
        self.latitude = response.latitude
        self.longitude = response.longitude
        self.organiser = response.organiser
        self.attendees = response.attendees
    }
}

extension Event {
    static var dateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }
    
    static func dateDisplayFormat(date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium // Set date style to medium
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
}
