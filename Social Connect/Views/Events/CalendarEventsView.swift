//
//  EventsView.swift
//  Social Connect
//
//  Created by f1201609 on 23/11/2024.
//

import Foundation
import Combine
import SwiftUI


struct CalendarEventsView: View {
    @EnvironmentObject var eventService : EventService
    @State var selectedDate: Date = Date()
    @Binding var events : [Event]
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startDate = Date()
        let endComponents = DateComponents(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return startDate
        ...
        calendar.date(from:endComponents)!
    }()
    
    func eventsForSelectedDate() -> [Event] {
        return events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        VStack {
            VStack {
                DatePicker(
                    "Selected Date",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            }
            
            if (eventsForSelectedDate().isEmpty){
                Spacer()
                Text("No Events on \($selectedDate.wrappedValue.formatted(date: .abbreviated, time: .omitted))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List(eventsForSelectedDate()) { event in
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
        .padding()
        .navigationTitle("Events Calendar")
        .navigationBarTitleDisplayMode(.automatic)
    }
    
}



