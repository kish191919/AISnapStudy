import SwiftUI

// Add new supporting view for Language Button
struct LanguageButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(language.emoji)
                    .font(.title2)
                Text(language.displayName)
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
    case portuguese = "portuguese"
    case vietnamese = "vietnamese"
    case thai = "thai"
    case indonesian = "indonesian"
    case arabic = "arabic"
    case hindi = "hindi"
    case turkish = "turkish"
    case dutch = "dutch"
    case polish = "polish"
    case swedish = "swedish"
    case greek = "greek"
    // 새로운 언어들 추가
    case ukrainian = "ukrainian"
    case czech = "czech"
    case romanian = "romanian"
    case hungarian = "hungarian"
    case finnish = "finnish"
    case danish = "danish"
    case norwegian = "norwegian"
    case hebrew = "hebrew"
    case bengali = "bengali"
    case urdu = "urdu"
    case malayalam = "malayalam"
    case tamil = "tamil"
    case telugu = "telugu"
    case marathi = "marathi"
    case kannada = "kannada"
    case persian = "persian"
    case malay = "malay"
    case tagalog = "tagalog"
    case mongolian = "mongolian"
    case khmer = "khmer"
    case lao = "lao"
    case burmese = "burmese"
    case slovak = "slovak"
    case croatian = "croatian"
    case bulgarian = "bulgarian"
    
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
        case .portuguese: return "pt"
        case .vietnamese: return "vi"
        case .thai: return "th"
        case .indonesian: return "id"
        case .arabic: return "ar"
        case .hindi: return "hi"
        case .turkish: return "tr"
        case .dutch: return "nl"
        case .polish: return "pl"
        case .swedish: return "sv"
        case .greek: return "el"
        case .ukrainian: return "uk"
        case .czech: return "cs"
        case .romanian: return "ro"
        case .hungarian: return "hu"
        case .finnish: return "fi"
        case .danish: return "da"
        case .norwegian: return "no"
        case .hebrew: return "he"
        case .bengali: return "bn"
        case .urdu: return "ur"
        case .malayalam: return "ml"
        case .tamil: return "ta"
        case .telugu: return "te"
        case .marathi: return "mr"
        case .kannada: return "kn"
        case .persian: return "fa"
        case .malay: return "ms"
        case .tagalog: return "tl"
        case .mongolian: return "mn"
        case .khmer: return "km"
        case .lao: return "lo"
        case .burmese: return "my"
        case .slovak: return "sk"
        case .croatian: return "hr"
        case .bulgarian: return "bg"
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
        case .portuguese: return "Português"
        case .vietnamese: return "Tiếng Việt"
        case .thai: return "ไทย"
        case .indonesian: return "Bahasa Indonesia"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        case .turkish: return "Türkçe"
        case .dutch: return "Nederlands"
        case .polish: return "Polski"
        case .swedish: return "Svenska"
        case .greek: return "Ελληνικά"
        case .ukrainian: return "Українська"
        case .czech: return "Čeština"
        case .romanian: return "Română"
        case .hungarian: return "Magyar"
        case .finnish: return "Suomi"
        case .danish: return "Dansk"
        case .norwegian: return "Norsk"
        case .hebrew: return "עברית"
        case .bengali: return "বাংলা"
        case .urdu: return "اردو"
        case .malayalam: return "മലയാളം"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .marathi: return "मराठी"
        case .kannada: return "ಕನ್ನಡ"
        case .persian: return "فارسی"
        case .malay: return "Bahasa Melayu"
        case .tagalog: return "Tagalog"
        case .mongolian: return "Монгол"
        case .khmer: return "ខ្មែរ"
        case .lao: return "ລາວ"
        case .burmese: return "မြန်မာ"
        case .slovak: return "Slovenčina"
        case .croatian: return "Hrvatski"
        case .bulgarian: return "Български"
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
        case .portuguese: return "🇵🇹"
        case .vietnamese: return "🇻🇳"
        case .thai: return "🇹🇭"
        case .indonesian: return "🇮🇩"
        case .arabic: return "🇸🇦"
        case .hindi: return "🇮🇳"
        case .turkish: return "🇹🇷"
        case .dutch: return "🇳🇱"
        case .polish: return "🇵🇱"
        case .swedish: return "🇸🇪"
        case .greek: return "🇬🇷"
        case .ukrainian: return "🇺🇦"
        case .czech: return "🇨🇿"
        case .romanian: return "🇷🇴"
        case .hungarian: return "🇭🇺"
        case .finnish: return "🇫🇮"
        case .danish: return "🇩🇰"
        case .norwegian: return "🇳🇴"
        case .hebrew: return "🇮🇱"
        case .bengali: return "🇧🇩"
        case .urdu: return "🇵🇰"
        case .malayalam: return "🇮🇳"
        case .tamil: return "🇮🇳"
        case .telugu: return "🇮🇳"
        case .marathi: return "🇮🇳"
        case .kannada: return "🇮🇳"
        case .persian: return "🇮🇷"
        case .malay: return "🇲🇾"
        case .tagalog: return "🇵🇭"
        case .mongolian: return "🇲🇳"
        case .khmer: return "🇰🇭"
        case .lao: return "🇱🇦"
        case .burmese: return "🇲🇲"
        case .slovak: return "🇸🇰"
        case .croatian: return "🇭🇷"
        case .bulgarian: return "🇧🇬"
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
        case .portuguese: return "portuguese"
        case .vietnamese: return "vietnamese"
        case .thai: return "thai"
        case .indonesian: return "indonesian"
        case .arabic: return "arabic" // 오타 수정
        case .hindi: return "hindi"
        case .turkish: return "turkish"
        case .dutch: return "dutch"
        case .polish: return "polish"
        case .swedish: return "swedish"
        case .greek: return "greek"
        case .ukrainian: return "ukrainian"
        case .czech: return "czech"
        case .romanian: return "romanian"
        case .hungarian: return "hungarian"
        case .finnish: return "finnish"
        case .danish: return "danish"
        case .norwegian: return "norwegian"
        case .hebrew: return "hebrew"
        case .bengali: return "bengali"
        case .urdu: return "urdu"
        case .malayalam: return "malayalam"
        case .tamil: return "tamil"
        case .telugu: return "telugu"
        case .marathi: return "marathi"
        case .kannada: return "kannada"
        case .persian: return "persian"
        case .malay: return "malay"
        case .tagalog: return "tagalog"
        case .mongolian: return "mongolian"
        case .khmer: return "khmer"
        case .lao: return "lao"
        case .burmese: return "burmese"
        case .slovak: return "slovak"
        case .croatian: return "croatian"
        case .bulgarian: return "bulgarian"
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
        case .portuguese:
            return "Português (Portuguese)"
        case .vietnamese:
            return "Tiếng Việt (Vietnamese)"
        case .thai:
            return "ไทย (Thai)"
        case .indonesian:
            return "Bahasa Indonesia (Indonesian)"
        case .arabic:
            return "العربية (Arabic)"
        case .hindi:
            return "हिन्दी (Hindi)"
        case .turkish:
            return "Türkçe (Turkish)"
        case .dutch:
            return "Nederlands (Dutch)"
        case .polish:
            return "Polski (Polish)"
        case .swedish:
            return "Svenska (Swedish)"
        case .greek:
            return "Ελληνικά (Greek)"
        case .ukrainian:
            return "Українська (Ukrainian)"
        case .czech:
            return "Čeština (Czech)"
        case .romanian:
            return "Română (Romanian)"
        case .hungarian:
            return "Magyar (Hungarian)"
        case .finnish:
            return "Suomi (Finnish)"
        case .danish:
            return "Dansk (Danish)"
        case .norwegian:
            return "Norsk (Norwegian)"
        case .hebrew:
            return "עברית (Hebrew)"
        case .bengali:
            return "বাংলা (Bengali)"
        case .urdu:
            return "اردو (Urdu)"
        case .malayalam:
            return "മലയാളം (Malayalam)"
        case .tamil:
            return "தமிழ் (Tamil)"
        case .telugu:
            return "తెలుగు (Telugu)"
        case .marathi:
            return "मराठी (Marathi)"
        case .kannada:
            return "ಕನ್ನಡ (Kannada)"
        case .persian:
            return "فارسی (Persian)"
        case .malay:
            return "Bahasa Melayu (Malay)"
        case .tagalog:
            return "Tagalog (Filipino)"
        case .mongolian:
            return "Монгол (Mongolian)"
        case .khmer:
            return "ខ្មែរ (Khmer)"
        case .lao:
            return "ລາວ (Lao)"
        case .burmese:
            return "မြန်မာ (Burmese)"
        case .slovak:
            return "Slovenčina (Slovak)"
        case .croatian:
            return "Hrvatski (Croatian)"
        case .bulgarian:
            return "Български (Bulgarian)"
        }
    }
}
