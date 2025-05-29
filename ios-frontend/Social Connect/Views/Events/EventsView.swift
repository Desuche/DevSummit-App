//
//  EventsView.swift
//  Social Connect
//
//  Created by f1201609 on 23/11/2024.
//

import SwiftUI

// Main Events View
struct EventsView: View {
    @StateObject var eventService: EventService
    @State var events : [Event] = []
    @State var isLoading = false
    
    init(authManager : AuthManager) {
        _eventService = StateObject(wrappedValue: EventService(authManager: authManager))
    }
    
    
    var body: some View {
        
        NavigationView {
            Color(.white)
                .ignoresSafeArea(.all)
                .overlay{
                    VStack{
                        VStack{
                            Section {
                                Divider()
                                
                                NavigationLink(destination: CalendarEventsView(events: $events)) {
                                    HStack {
                                        Text("Events Calendar")
                                            .foregroundColor(.black)
                                            .font(.headline)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.red)
                                            .fontWeight(.heavy)
                                    }
                                }
                                .padding(.top, 10)
                                
                                
                                
                                Divider()
                                NavigationLink(destination: MyEventsView()) {
                                    HStack {
                                        Text("My Events")
                                            .foregroundColor(.black)
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .fontWeight(.heavy)
                                    }
                                }.padding(.top, 15)
                                
                                Divider()
                            }
                        }.padding(.horizontal, 20)
                            .padding(.bottom, 10)
                        
                        VStack {
                            if (isLoading){
                                Spacer()
                                ProgressView()
                                Spacer()
                            } else {
                                List(events) { event in
                                    NavigationLink(destination: EventView(eventId: event._id)){
                                        VStack(alignment: .leading){
                                            Text(event.name)
                                                .font(.headline)
                                            Text(event.location)
                                                .font(.subheadline)
                                            Text(Event.dateDisplayFormat(date: event.date))
                                                .font(.caption)
                                        }
                                        .padding()
                                    }
                                    
                                    
                                }.background()
                                
                                
                            }
                        }
                        
                    }
                    .onAppear{eventService.fetchAllEvents(events: $events, isLoading: $isLoading)}
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle("Events")
                }
        }.environmentObject(eventService)
        
    }
}



extension EventsView {
    
}



#Preview{
    EventsView(authManager: AuthManager())
}
