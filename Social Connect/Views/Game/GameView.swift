//
//  GameUploadView.swift
//  Social Connect
//
//  Created by Vanessa Chan on 28/5/2025.
//


import SwiftUI
import CoreImage

struct GameView: View {
    @StateObject private var apiClient = GameApiClient()
    @StateObject private var objectDetector = GameObjectDetector()
    @State private var selectedGameType: String = "Set"
    @State private var userImage: Image? = nil
    @State private var showImagePicker: Bool = false
    @State private var message: String = ""
    @State private var messages: [GameMessageView] = []
    @State private var scrollViewProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            Text("Game Helper")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            HStack(spacing: 5) {
                Text("What game are you playing?")
                    .font(.headline)

                Picker("Game Type", selection: $selectedGameType) {
                    Text("Mahjong").tag("Mahjong")
                    Text("Chess").tag("Chess")
                    Text("Set").tag("Set")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()

            // User picture area
            if let userImage = userImage {
                userImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIScreen.main.bounds.height * 0.3)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
            } else {
                Button(action: {
                    showImagePicker.toggle()
                }) {
                    Text("Click to upload a photo of your game")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding()
                }
                .frame(height: UIScreen.main.bounds.height * 0.3)
            }

            // Chat interface
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack {
                        ForEach(messages) { message in
                            message
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    scrollViewProxy = scrollView
                    scrollToBottom(animated: false)
                }
                .onChange(of: messages) { _ in
                    scrollToBottom(animated: true)
                }
            }

            // Input bar
            HStack {
                TextField("Ask the game bot for help...", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    sendMessage()
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $userImage)
                .onDisappear {
                    processGame()
                }
        }
    }

    private func processGame() {
        guard let selectedImage = userImage else { return }
        
        // Convert SwiftUI Image to CIImage for the object detector
        let uiImage = selectedImage.asUIImage() // Convert to UIImage
        guard let ciImage = CIImage(image: uiImage) else { return }
        
        // Detect numbers using the ObjectDetector
        print("Entering model")
        let gameStateNumbers = objectDetector.detect(ciImage: ciImage)
        print("GAME STATE:")
        print(gameStateNumbers)
        
        // Start a new game with the detected numbers
        apiClient.startNewGame(with: gameStateNumbers) { result in
            switch result {
            case .success(let hint):
                let hintMessage = GameMessageView(message: hint, sender: .gameBot)
                DispatchQueue.main.async {
                    messages.append(hintMessage)
                }
            case .failure(let error):
                let errorMessage = GameMessageView(message: "Error: \(error.localizedDescription)", sender: .gameBot)
                DispatchQueue.main.async {
                    messages.append(errorMessage)
                }
            }
        }
    }

    private func sendMessage() {
        if !message.isEmpty {
            let newMessage = GameMessageView(message: message, sender: .user)
            messages.append(newMessage)
            let userMessage = message
            message = ""

            apiClient.sendMessage(userMessage) { result in
                switch result {
                case .success(let reply):
                    let responseMessage = GameMessageView(message: reply, sender: .gameBot)
                    DispatchQueue.main.async {
                        messages.append(responseMessage)
                    }
                case .failure(let error):
                    let errorMessage = GameMessageView(message: "Error: \(error.localizedDescription)", sender: .gameBot)
                    DispatchQueue.main.async {
                        messages.append(errorMessage)
                    }
                }
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard let proxy = scrollViewProxy else { return }
        if let lastMessage = messages.last {
            if animated {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

extension Image {
    func asUIImage() -> UIImage {
        // Convert SwiftUI Image to UIImage (implement this method)
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = CGSize(width: 300, height: 300) // Adjust as needed
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: Image?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = Image(uiImage: uiImage)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct GameMessageView: View, Identifiable, Equatable {
    enum Sender {
        case user, gameBot
    }
    var id = UUID()

    var message: String
    var sender: Sender

    var body: some View {
        HStack {
            if sender == .user {
                Spacer()
            }
            
            Text(message)
                .padding()
                .foregroundColor(.white)
                .background(sender == .user ? Color.blue : Color.green)
                .cornerRadius(10)
                .frame(maxWidth: 300, alignment: sender == .user ? .trailing : .leading)

            if sender == .gameBot {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
