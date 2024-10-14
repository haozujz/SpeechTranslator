//
//  AvailabilityChecker.swift
//  SpeechTranslator
//
//  Created by Joseph Zhu on 13/10/2024.
//

import Foundation
import SwiftUI
import Translation
import Speech

extension View {
    func checkTranslationPairSupport(from source: Locale.Language, to target: Locale.Language) async -> Bool {
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)


        switch status {
        case .installed, .supported:
            return true
        case .unsupported:
            return false
        @unknown default:
            return false
        }
    }
    
    func checkTranslationPairSupportLocaleToLanguage(from source: Locale, to target: Locale.Language) async -> Bool {
        // Safely extract the language code from the Locale
        guard let inputLanguageCode = source.language.languageCode else {
            return false
        }
        
        guard let outputLanguageCode = target.languageCode else {
            return false
        }

        let isPairSupported = await checkTranslationPairSupport(from: Locale.Language(identifier: inputLanguageCode.identifier), to: Locale.Language(identifier: outputLanguageCode.identifier))

        print(isPairSupported)
        return isPairSupported
    }
    
    func checkSupportForBothSpeechAndTranslationFrameworks() async {
        // SF: SpeechFramework, TF: TranslationFramework

        // Fetch all supported translation languages asynchronously
        let supportedTFLanguages = await LanguageAvailability().supportedLanguages  // Returns Array<Locale.language>
        
        // Helper function to extract language identifiers from TF's Array<Locale.Language
        func extractLanguageIdentifiers(from languages: [Locale.Language]) -> [String] {
            return languages.compactMap { $0.languageCode?.identifier }
        }
        
        let supportedTFLanguageIdentifiers = extractLanguageIdentifiers(from: supportedTFLanguages)

        // Fetch all locales supported by the Speech Framework
        let supportedSFLocales = SFSpeechRecognizer.supportedLocales()

        // Helper function to extract base language code from a locale identifier from SF
        func baseLanguageCode(from localeIdentifier: String) -> String {
            return localeIdentifier.split(separator: "-").first.map(String.init) ?? localeIdentifier
        }
        
        //
        func baseLanguageCode(from locale: Locale) -> String {
            return locale.language.languageCode?.identifier ?? locale.identifier
        }
        //

        // Iterate over each speech locale
        for locale in supportedSFLocales {
            // Extract the base language code (e.g., "en" from "en-AU")
            let baseCode = baseLanguageCode(from: locale.identifier)

            // Check if the corresponding language is supported by Translation Framework
            if supportedTFLanguageIdentifiers.contains(baseCode) {
                print("\(locale.identifier): Supported by both Speech and Translation.")
            } else {
                print("\(locale.identifier): Supported only by Speech.")
            }
        }
    }

   
    func getLanguageDescription(from identifier: String) -> String? {
        // Extract the base language code (e.g., "en" from "en-US")
        let baseCode = identifier.split(separator: "-").first.map(String.init) ?? identifier
        
        // Get the user-friendly language name
        let readableName = Locale.current.localizedString(forLanguageCode: baseCode)
        
        return readableName
    }
    
    func getLanguageCodeForTranslationFramework(from identifier: String) -> Locale.Language? {
        //  Extract the base language code (e.g., "en" from "en-US")
        let baseCode = identifier.split(separator: "-").first.map(String.init) ?? identifier
        
        // Create a Translation-Framework-compatible Locale.Language
        let language = Locale.Language(languageCode: Locale.LanguageCode(baseCode))
        
        return language
    }
}



/* Map Speech Framework's Locales to Translation Framework's Languages
 
 Apple's Speech framework uses Locale objects (e.g., "en-US" for American English), while the Translation framework uses Language objects, which represent broader language identifiers without regional specificity (e.g., "en" for English).
 To make this consistent, extract the language code from the locale (Locale.languageCode) and compare it with the supported languages from LanguageAvailability.
 
 
 
 */
