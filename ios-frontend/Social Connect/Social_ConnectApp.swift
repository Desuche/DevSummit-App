//
//  Social_ConnectApp.swift
//  Social Connect
//
//  Created by f1201609 on 18/11/2024.
//

import SwiftUI
import SwiftData

let VIDEO_BASE_URL = "https://videoios.f1201609.hkbu.app"
let EVENT_BASE_URL = "https://eventios.f1201609.hkbu.app"
let AUTH_BASE_URL = "https://authios.f1201609.hkbu.app"
let CHAT_WS_BASE_URL = "ws://chatios.f1201609.hkbu.app/chat"
let MENTOR_BASE_URL = "https://mentorios.f1201609.hkbu.app"

@main
struct Social_ConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate;
    @ObservedObject var authManager = AuthManager()
    
    var sharedModelContainer: ModelContainer = {
            let schema = Schema([
                SwiftDataChatMessage.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
                
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }.modelContainer(sharedModelContainer)
    }
}
