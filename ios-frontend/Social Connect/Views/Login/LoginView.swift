//
//  LoginView.swift
//  Social Connect
//
//  Created by f1201609 on 18/11/2024.
//

import SwiftUI
import GoogleSignIn
import FBSDKLoginKit

struct LoginView : View {
    //Environment object for authentication services
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var pageMessage: String = ""
    
    @State private var phoneNumber: String = ""
    @State private var phoneNumberToken: String = ""
    @State private var tokenRequestFormIsVisible: Bool = false
    
    @State private var registrationName: String = ""
    @State private var registrationEmail: String = ""
    @State private var registrationPhoneNumber: String = ""
    @State private var registrationFormisVisible: Bool = false
    
    static let backendBaseUrl = AUTH_BASE_URL
    private var backendUrlForPhoneAuth: String = "\(backendBaseUrl)/auth/login/phone"
    private var backendUrlForPhoneRegistration: String = "\(backendBaseUrl)/auth/register/phone"
    private var backendUrlForCheckPhoneRegistration: String = "\(backendBaseUrl)/auth/checkregistration/phone"
    private var backendUrlForGoogleAuth: String = "\(backendBaseUrl)/auth/login/google"
    private var backendUrlForFacebookAuth: String = "\(backendBaseUrl)/auth/login/facebook"
    
    var body: some View {
        VStack {
            Spacer()
            Text("Social Connect")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            Spacer()
            
            Text("Log in to continue")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            VStack{
                
                // Phone Number Input
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                
                // Login with Phone Button
                Button(action: checkPhoneRegistrationStatus) {
                    Text("Login with Phone Number")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumber.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.bottom, 20)
                .disabled(phoneNumber.isEmpty)
                
                
                // Register with Phone Button
                Button(action: { registrationFormisVisible = true }) {
                    Text("Register with Phone Number")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background( Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.bottom, 30)
                .padding(.top, 20)
            }.padding(.horizontal, 30)
            
            VStack{
                
                Text("Log in with social media")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack{
                    
                    // Google Login Button
                    Button(action: loginWithGoogle) {
                        Image("google_logo") // Ensure you have a Google logo image in your assets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.all, 30)
                    
                    // Facebook Login Button
                    Button(action: loginWithFacebook) {
                        Image("facebook_logo") // Ensure you have a Facebook logo image in your assets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }.padding(.all, 30)
                }
            }.padding(.top, 50)
            
            Spacer()
            if (!pageMessage.isEmpty){
                Text(pageMessage)
                    .font(.headline)
                    .foregroundColor(pageMessage.contains("Successful") ? .green : .red)
                    .padding(.bottom, 20)
            }
            
            
        }
        .padding()
        .popover(isPresented: $registrationFormisVisible){
            registrationForm
        }
        .popover(isPresented: $tokenRequestFormIsVisible){
            tokenRequestForm
        }
    }
    
    var tokenRequestForm: some View {
        VStack{
            Spacer()
            Spacer()
            Text("Login")
                .font(.largeTitle)
                .fontWeight(.medium)
                .padding(.bottom, 40)
            Spacer()
            
            Text("Enter Token Sent to Your Phone")
                .font(.headline)
                .foregroundColor(.gray)
            
            // Phone Number Input
            TextField("Token", text: $phoneNumberToken)
                .keyboardType(.phonePad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .padding(.top, 20)
            
            HStack{
                // Cancel Button
                Button(action: cleanUpLoginTokenForm) {
                    Text("CANCEL")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.all, 20)
                
                // Send Token Button
                Button(action: authenticateAttemptedPhoneLogInWithBackend) {
                    Text("SEND")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumberToken.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.all, 20)
                .disabled(phoneNumberToken.isEmpty)
            }.padding(.horizontal, 20 )
            
            Spacer()
            
            Text("Resend Token")
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.red)
                .cornerRadius(10)
                .font(.headline)
            
            Spacer()
            Spacer()
            
            
        }.padding(.horizontal, 10)
    }
    
    var registrationForm: some View {
            VStack(alignment: .leading) {
                Spacer()
                Spacer()
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .padding(.bottom)
                
                Spacer()
                
                TextField("Name", text: $registrationName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom)
                
                TextField("Email", text: $registrationEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom)
                
                TextField("Phone Number", text: $registrationPhoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom)
                
                HStack {
                    Button("Cancel") {
                        cleanUpRegistrationForm()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Register") {
                        // Handle registration logic here
                        registerWithPhoneNumber()
                    }
                }
                .padding(.top)
                
                Spacer()
                Spacer()
            }
            .padding()
            .frame(width: 300) // Set a width for the popover
        }
    
    private func cleanUpLoginTokenForm(){
        phoneNumber = ""
        phoneNumberToken = ""
        tokenRequestFormIsVisible = false
    }
    
    private func cleanUpRegistrationForm(){
        registrationName = ""
        registrationEmail = ""
        registrationPhoneNumber = ""
        registrationFormisVisible = false
    }
    
    
    
}

extension LoginView {
    private func loginWithGoogle() {
        GIDSignIn.sharedInstance.signIn(withPresenting: UIApplication.shared.windows.first!.rootViewController!) { user, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            guard let user = user else { return }
            let idToken = user.user.idToken!
            authenticateAttemptedGoogleLogInWithBackend(googleIdToken: idToken.tokenString)
        }
    }
    
    private func loginWithFacebook() {
        let manager = LoginManager()
        manager.logIn(permissions: ["public_profile", "email"], from: UIApplication.shared.windows.first!.rootViewController!) { result, error in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            guard let result = result, !result.isCancelled else {
                print("User cancelled login.")
                return
            }
            // Successfully logged in
            print("Logged in:")
            if let token = AccessToken.current{
                authenticateAttemptedFacebookLogInWithBackend(accessToken: token.tokenString)
            }
            
        }
    }
    
    private func fetchUserIDFacebook(token: String) -> String {
        var userId = ""
        let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"])
        graphRequest.start { connection, result, error in
            if let error = error {
                print("Failed to fetch user info: \(error.localizedDescription)")
                return
            }
            
            guard let userInfo = result as? [String: Any] else {
                print("Invalid user info")
                return
            }
            
            if let id = userInfo["id"] as? String {
                print("User ID: \(id)")
                userId = id
            }
        }
        
        return userId
    }
    
    private func loginWithPhoneNumber() {
        guard !phoneNumber.isEmpty else {return}
        tokenRequestFormIsVisible = true
    }
    
    private func registerWithPhoneNumber(){
        guard !registrationName.isEmpty && !registrationEmail.isEmpty && !registrationPhoneNumber.isEmpty else { return }
        attemptPhoneRegistrationWithBackend()
    }
}


extension LoginView{
    private func authenticateAttemptedPhoneLogInWithBackend(){
        guard !phoneNumber.isEmpty else {return}
        guard !phoneNumberToken.isEmpty else {return}
        
        guard let url = URL(string: backendUrlForPhoneAuth) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["phone": phoneNumber, "token": phoneNumberToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending access token: \(error.localizedDescription)")
                return
            }
            
            // Handle response from the backend
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully logged in with Phone token.")
                if let data = data {
                    let decoder = JSONDecoder()
                    if let jwtToken = try? decoder.decode(JWT.self, from: data) {
                        print("Received JWT: \(jwtToken.jwt)")
                        // Handle successful login
                        authManager.login(with: jwtToken.jwt)
                        cleanUpLoginTokenForm()
                        
                    } else {
                        print("JWT decode failed")
                    }
                }
            } else {
                print("Failed to verify token.")
            }
        }
        
        task.resume()
    }
    
    private func authenticateAttemptedGoogleLogInWithBackend(googleIdToken: String){
        guard let url = URL(string: backendUrlForGoogleAuth) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["idToken": googleIdToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending access token: \(error.localizedDescription)")
                return
            }
            
            // Handle response from the backend
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully verified Google token.")
                if let data = data {
                    let decoder = JSONDecoder()
                    if let jwtToken = try? decoder.decode(JWT.self, from: data) {
                        print("Received JWT: \(jwtToken.jwt)")
                        // Handle successful login
                        authManager.login(with: jwtToken.jwt)
                        
                    } else {
                        print("JWT decode failed")
                    }
                }
            } else {
                print("Failed to verify token.")
            }
        }
        
        task.resume()
    }
    
    private func authenticateAttemptedFacebookLogInWithBackend(accessToken: String) {
        
        guard let url = URL(string: backendUrlForFacebookAuth) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["accessToken": accessToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending Facebook token: \(error.localizedDescription)")
                return
            }
            
            // Handle response from the backend
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response.")
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("Successfully verified Facebook token.")
                if let data = data {
                    let decoder = JSONDecoder()
                    if let jwtToken = try? decoder.decode(JWT.self, from: data) {
                        print("Received JWT: \(jwtToken.jwt)")
                        // Handle successful login
                        authManager.login(with: jwtToken.jwt)
                        
                    } else {
                        print("JWT decode failed")
                    }
                }
            case 401:
                print("Failed to verify token: Unauthorized.")
            default:
                print("Failed to verify token with status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }
}


extension LoginView {
    private func attemptPhoneRegistrationWithBackend() {
        // Define the backend URL
        guard let url = URL(string: backendUrlForPhoneRegistration) else { return }
        
        // Create the registration data dictionary
        let registrationData: [String: Any] = [
            "name": registrationName,
            "email": registrationEmail,
            "phone": registrationPhoneNumber
        ]
        
        // Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the registration data to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: registrationData, options: [])
        } catch {
            print("Error encoding registration data: \(error.localizedDescription)")
            return
        }
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during registration: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response received")
                return
            }
            
            // Switch on the response status code
            switch httpResponse.statusCode {
            case 200:
                // Successful registration
                print("Registration successful!")
                pageMessage = "Registration Successful. Please Login"
                cleanUpRegistrationForm()
                
            case 404:
                // Not found
                print("Error: Endpoint not found (404)")
                // Handle 404 error (e.g., show an alert to the user)
                
            default:
                // Handle other response codes
                print("Unexpected response code: \(httpResponse.statusCode)")
                // Handle any other error (e.g., show a generic error message)
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    func checkPhoneRegistrationStatus() {
        guard !phoneNumber.isEmpty else { return }
        // Define the API endpoint URL
        guard let url = URL(string: backendUrlForCheckPhoneRegistration) else {
            print("Invalid URL")
            return // URL is invalid
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the request body with the phone number
        let body: [String: Any] = ["phone": phoneNumber]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error encoding request body: \(error.localizedDescription)")
            return // Error in encoding
        }
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during registration check: \(error.localizedDescription)")
                return // Error occurred
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response received")
                return // Invalid response
            }
            
            // Check the response code
            switch httpResponse.statusCode {
            case 200:
                print("Registration check successful: Phone number is registered.")
                loginWithPhoneNumber()
            case 404:
                print("Registration check failed: Phone number not registered.")
                pageMessage = "Please Register"
            default:
                print("Unexpected response code: \(httpResponse.statusCode)")
            }
        }
        
        // Start the network request
        task.resume()
    }

}


//#Preview {
//    LoginView()
//        .environmentObject(AuthManager())
//}


