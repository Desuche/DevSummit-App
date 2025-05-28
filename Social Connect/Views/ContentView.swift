//
//  ContentView.swift
//  Social Connect
//
//  Created by f1201609 on 18/11/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @StateObject var tagService = TagService()
    
    var body : some View{
        if !authManager.isAuthenticated {
            LoginView()
        } else {
            TabView{
                VideoListView(tagService: tagService, authManager: authManager).tabItem {
                    Image(systemName: "house")
                    Text("Home").onAppear {
                        tagService.authManager = authManager
                        tagService.fetch()
                    }
                }
                EventsView(authManager: authManager)
                    .tabItem{
                        Image(systemName: "calendar")
                        Text("Events")
                    }
                MentorListView(authManager: authManager)
                    .tabItem{
                        Image(systemName: "person.2.circle")
                        Text("Mentors")
                    }
                SettingsView()
                    .tabItem{
                        Image(systemName: "gear")
                        Text("Settings")
                    }
               
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
