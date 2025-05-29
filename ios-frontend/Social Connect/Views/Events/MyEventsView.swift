//
//  MyEventsView.swift
//  Social Connect
//
//  Created by f1201609 on 23/11/2024.
//

import SwiftUI

struct MyEventsView: View {
    @EnvironmentObject var eventService: EventService
    @State var myEvents : [Event] = []
    @State var isLoading = false
    
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea(.all)
            .overlay{
                VStack{
                    Divider()
                    if (isLoading){
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        List(myEvents){
                            event in
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
                        }
                    }
                }
                .onAppear{eventService.fetchMyEvents(myEvents: $myEvents, isLoading: $isLoading)}
                .navigationTitle("My Events")
                .navigationBarTitleDisplayMode(.large)
            }
    }
}
