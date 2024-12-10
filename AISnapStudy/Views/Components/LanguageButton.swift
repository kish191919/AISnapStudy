import SwiftUI

// Add new supporting view for Language Button
struct LanguageButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji(for: language))
                    .font(.title2)
                Text(displayName(for: language))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
    }
    
    private func emoji(for language: Language) -> String {
        switch language {
        case .auto: return "🌐"
        case .english: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .russian: return "🇷🇺"
        case .italian: return "🇮🇹"
        }
    }
    
    private func displayName(for language: Language) -> String {
        switch language {
        case .auto: return "Auto"
        default: return language.rawValue
        }
    }
}



struct LanguageSection: View {
    @Binding var selectedLanguage: Language
    @State private var isExpanded: Bool = false
    @State private var showLanguageMenu = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose the language in which you want the questions to be generated. The generated questions will appear in your selected language regardless of the input language.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        
                    Text("Current: \(selectedLanguage.displayName) \(selectedLanguage.emoji)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            },
            label: {
                HStack {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Language")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    // 별도의 버튼으로 분리
                    Button(action: {
                        showLanguageMenu = true
                    }) {
                        HStack(spacing: 4) {
                            Text(selectedLanguage.emoji)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        )
        .sheet(isPresented: $showLanguageMenu) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage)
        }
    }
}

// LanguageSelectionView는 더 깔끔한 UI로 업데이트
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Language.allCases) { language in
                    LanguageRow(
                        language: language,
                        isSelected: language == selectedLanguage,
                        onSelect: {
                            selectedLanguage = language
                            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .presentationDetents([.medium, .large])
    }
}

// 별도의 LanguageRow 컴포넌트
struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(language.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(language.displayName)
                        .foregroundColor(.primary)
                    Text(language.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// Language.swift (새로운 파일)
enum Language: String, CaseIterable, Identifiable {
    case auto = "AUTO"
    case english = "english"
    case korean = "korean"
    case japanese = "japanese"
    case chinese = "chinese"
    case spanish = "spanish"
    case french = "french"
    case german = "german"
    case russian = "russian"
    case italian = "italian"
    
    var id: String { self.rawValue }
    
    // OpenAI API에서 사용할 언어 코드
    var languageCode: String {
        switch self {
        case .auto: return "auto"
        case .english: return "en"
        case .korean: return "ko"
        case .japanese: return "ja"
        case .chinese: return "zh"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .russian: return "ru"
        case .italian: return "it"
        }
    }
}

// Update Language enum to include display names and emojis
extension Language {
    var displayName: String {
        switch self {
        case .auto: return "Automatic"
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        case .italian: return "Italiano"
        }
    }
    
    var emoji: String {
        switch self {
        case .auto: return "🌐"
        case .english: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .russian: return "🇷🇺"
        case .italian: return "🇮🇹"
        }
    }
    var codeName: String {
        switch self {
        case .auto: return "automatic"
        case .english: return "english"
        case .korean: return "korean"
        case .japanese: return "japanese"
        case .chinese: return "chinese"
        case .spanish: return "spanish"
        case .french: return "french"
        case .german: return "german"
        case .russian: return "russian"
        case .italian: return "italian"
        }
    }
}

extension Language {
    var description: String {
        switch self {
        case .auto:
            return "Detect language automatically"
        case .english:
            return "English"
        case .korean:
            return "한국어 (Korean)"
        case .japanese:
            return "日本語 (Japanese)"
        case .chinese:
            return "中文 (Chinese)"
        case .spanish:
            return "Español (Spanish)"
        case .french:
            return "Français (French)"
        case .german:
            return "Deutsch (German)"
        case .russian:
            return "Русский (Russian)"
        case .italian:
            return "Italiano (Italian)"
        }
    }
}
