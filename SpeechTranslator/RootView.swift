//
//  RootView.swift
//  SpeechTranslator
//
//  Created by Joseph Zhu on 7/10/2024.
//



import SwiftUI
import Speech

struct RootView: View {
    @State var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var selectedInputLocale: Locale = Locale.current
    @State private var selectedOutputLocale: Locale = Locale.current

    var body: some View {
        NavigationSplitView {
            NavigationStack {
                VStack(spacing: 20) {
                    // Language Selector for Input
                    Menu {
                        ForEach(SFSpeechRecognizer.supportedLocales().sorted(by: { $0.identifier < $1.identifier }), id: \.self) { locale in
                            Button(action: {
                                selectedInputLocale = locale
                                speechRecognizer.changeLocale(to: locale)
                            }) {
                                Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedInputLocale.localizedString(forIdentifier: selectedInputLocale.identifier) ?? "Input Language")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                            Image(systemName: "chevron.right") // Add indicator here
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)


                    // Larger text box for input speech
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                        .overlay(
                            Text(speechRecognizer.transcript.isEmpty ? "Waiting for speech..." : speechRecognizer.transcript)
                                .padding()
                                .foregroundColor(.black)
                        )
                        .frame(height: UIScreen.main.bounds.height * 0.25) // Adjusted height
                        .padding(.horizontal)

                    // Language Selector for Output
                    Menu {
                        ForEach(SFSpeechRecognizer.supportedLocales().sorted(by: { $0.identifier < $1.identifier }), id: \.self) { locale in
                            Button(action: {
                                selectedOutputLocale = locale
                                // Add functionality for changing the output locale
                            }) {
                                Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedOutputLocale.localizedString(forIdentifier: selectedOutputLocale.identifier) ?? "Output Language")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                            Image(systemName: "chevron.right") // Chevron indicator
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)

                    // Larger text box for translation (output)
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                        .overlay(
                            Text("Translation will appear here...") // Placeholder for future translation logic
                                .padding()
                                .foregroundColor(.gray)
                        )
                        .frame(height: UIScreen.main.bounds.height * 0.25) // Adjusted height
                        .padding(.horizontal)

                    Spacer()

                    // Circular microphone button
                    Button(action: {
                        if !isRecording {
                            speechRecognizer.transcribe()
                        } else {
                            speechRecognizer.stopTranscribing()
                        }
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                            .background(isRecording ? Color.red : Color.blue)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            speechRecognizer.reset()
                        }) {
                            Text("Reset")
                        }
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    RootView()
}





