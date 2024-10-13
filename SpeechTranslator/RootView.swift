//
//  RootView.swift
//  SpeechTranslator
//
//  Created by Joseph Zhu on 7/10/2024.
//

import SwiftUI
import Speech
import Translation

struct RootView: View {
    @State var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var selectedInputLocale: Locale = Locale.current
    @State private var selectedOutputLanguage: Locale.Language = Locale.current.language
    
    //@State private var selectedOutputLocale: Locale = Locale.current
    
    @State private var isKeyboardVisible = false
    
    @State private var translationSession: TranslationSession.Configuration?
    @State private var supportedOutputLanguages: [Locale.Language] = []

    private let languageAvailability = LanguageAvailability()
    //@State private var supportedLanguages: [Locale.Language] = []
    
    @State private var outputText = ""
    
    @State private var isTranslationDisabled = true
    
    @State private var timer: Timer? = nil
    
    private func description(for language: Locale.Language) -> String {
        // Get the language code
        let languageCode = language.languageCode?.identifier ?? ""
        
        // Create a locale using the language code
        let languageLocale = Locale(identifier: languageCode)
        
        // Get the localized description of the language in its own language
        let localizedDescription = languageLocale.localizedString(forLanguageCode: languageCode)
        
        return localizedDescription ?? "No description"
    }

    //private func check
    
    private func triggerTranslation() {
        guard translationSession == nil else {
            translationSession?.invalidate()
            print("Invalidated translationSession")
            
            translationSession = nil//
            return
        }
        print("Started translationSession")

        // Let the framework automatically determine the language pairing.
        //translationSession = .init()
        
        // Safely extract the language code from the Locale
        guard let inputLanguageCode = selectedInputLocale.language.languageCode else {
            return
        }
        
        guard let outputLanguageCode = selectedOutputLanguage.languageCode else {
            return
        }

        print("input")
        print(inputLanguageCode.identifier)
        print("output")
        print(outputLanguageCode.identifier)
        
        translationSession = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "ja")
        )
        
        //print(translationSession as Any)//
        
//        translationSession = TranslationSession.Configuration(
//            source: Locale.Language(identifier: inputLanguageCode.identifier),
//            target: Locale.Language(identifier: outputLanguageCode.identifier)
//        )
        
//        translationSession = TranslationSession.Configuration(
//            source: Locale.Language(languageCode: languageCode), //Locale.Language(languageCode: .english),
//            target: Locale.Language(languageCode: .japanese)
//        )
        
//        translationSession = TranslationSession.Configuration(
//            source: Locale.Language(identifier: languageCode.identifier),
//            target: Locale.Language(identifier: "ja_JP")
//        )
    }

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
                                
                                
                                //print(getLanguageCodeForTranslationFramework(from: <#T##String#>))
                                
                                // Safely extract the language code from the Locale
                                guard let languageCode = locale.language.languageCode else {
                                    return
                                }
                                
                                print(type(of: languageCode))
                                print(languageCode)
                                print(Locale.Language(identifier: selectedInputLocale.language.languageCode?.identifier ?? "pt_BR"))
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


                    // Input
                    TextEditor(text: $speechRecognizer.transcript)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(height: UIScreen.main.bounds.height * 0.25)
                        .padding(.horizontal)


                    // Language Selector for Output

                    Menu {
                        ForEach(supportedOutputLanguages, id:\.maximalIdentifier) { language in
                            Button(action: {
                                selectedOutputLanguage = language
                            }) {
                                Text(description(for: language))
                            }
                        }
                    } label: {
                        HStack {
//                            Text(selectedOutputLocale.localizedString(forIdentifier: selectedOutputLocale.identifier) ?? "Output Language")
                            Text(description(for: selectedOutputLanguage))
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)

                    // Output
                    TextEditor(text: $outputText)
                        .disabled(true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(height: UIScreen.main.bounds.height * 0.25)
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
                            .background(speechRecognizer.isRecognizerAvailable ? Color.blue : Color.gray)
                            .clipShape(Circle())
                    }
                    .disabled(!speechRecognizer.isRecognizerAvailable)
                    .onChange(of: speechRecognizer.isRecognizerAvailable) { _, newState in
                        isRecording = newState
                    }

                    Spacer()
                    
                    Button(action: {
                        triggerTranslation()
                    }) {
                        Label(isTranslationDisabled ? "Translation not Available" : "Start translation", systemImage: "arrow.down.circle.fill")
                            .foregroundStyle(.white)
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                            .padding(8)
                            .background(.gray)
                            .cornerRadius(8)
                    }
                    .disabled(isTranslationDisabled)

                }
                .task {
                    supportedOutputLanguages = await languageAvailability.supportedLanguages
                    //print(supportedOutputLanguages)
                    
                    await checkSupportForBothSpeechAndTranslationFrameworks()
                }
                .onChange(of: speechRecognizer.transcript) {
                    timer?.invalidate()  // Cancel any previous timer
                    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        triggerTranslation()
                    }
                    
                    //triggerTranslation()
                }
                .onChange(of: selectedInputLocale) {
                    isTranslationDisabled = true
                    timer?.invalidate()
                    
                    Task {
                        let isSupported = await checkTranslationPairSupportLocaleToLanguage(from: selectedInputLocale, to: selectedOutputLanguage)
                        isTranslationDisabled = !isSupported
                    }
                }
                .onChange(of: selectedOutputLanguage) {
                    isTranslationDisabled = true
                    timer?.invalidate()
                    
                    Task {
                        let isSupported = await checkTranslationPairSupportLocaleToLanguage(from: selectedInputLocale, to: selectedOutputLanguage)
                        isTranslationDisabled = !isSupported
                    }
                }
                // Pass the configuration to the task.
                .translationTask(translationSession) { session in
                    do {
                        try await session.prepareTranslation()//
                        
                        // Use the session the task provides to translate the text.
                        let response = try await session.translate(speechRecognizer.transcript)

                        // Update the view with the translated result.
                        outputText = response.targetText
                    } catch let error {
                        print(error)
                    }
                }
                .onAppear {
                    // Observe keyboard notifications
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                        isKeyboardVisible = true
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        isKeyboardVisible = false
                    }
                }
                .onDisappear {
                    // Remove observers
                    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
                }
                .toolbar {
                    // Show a Done button to dismiss the keyboard if it is visible
                    ToolbarItem(placement: .navigationBarLeading) {
                        if isKeyboardVisible {
                            Button("Done") {
                                UIApplication.shared.endEditing() // Dismiss keyboard
                            }
                        }
                    }
                    
                    // Hide reset button when keyboard is visible
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !isKeyboardVisible {
                            Button(action: {
                                speechRecognizer.reset()
                            }) {
                                Text("Reset")
                            }
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


