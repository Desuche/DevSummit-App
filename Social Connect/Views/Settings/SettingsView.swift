//
//  SettingsView.swift
//  Social Connect
//
//  Created by Des on 20/11/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account").font(.headline)) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authManager.authenticatedUser?.name ?? "User")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.authenticatedUser?.email ??  "example@example.com")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Preferences").font(.headline)) {
                    NavigationLink(destination: Text("Notifications Settings")) {
                        Text("Notifications")
                    }
                    NavigationLink(destination: Text("Privacy Settings")) {
                        Text("Privacy")
                    }
                    NavigationLink(destination: Text("About")) {
                        Text("About")
                    }
                }
                
                Section {
                    Button(action: {
                        // Log out action
                        authManager.logout()
                    }) {
                        Text("Log Out")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .listRowBackground(Color.clear) // Clear background for the button section
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle()) // Modern appearance
        }
        .navigationViewStyle(StackNavigationViewStyle()) // For better handling on iPad
    }
}


