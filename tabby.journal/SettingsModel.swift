import Foundation
import Combine

class SettingsModel: ObservableObject {
    // Keys for UserDefaults
    private let intentionOnKey = "isIntentionReminderOn"
    private let intentionTimeKey = "intentionReminderTime"
    private let reflectionOnKey = "isReflectionReminderOn"
    private let reflectionTimeKey = "reflectionReminderTime"
    
    @Published var isIntentionReminderOn: Bool {
        didSet { UserDefaults.standard.set(isIntentionReminderOn, forKey: intentionOnKey) }
    }
    @Published var intentionReminderTime: Date {
        didSet { UserDefaults.standard.set(intentionReminderTime, forKey: intentionTimeKey) }
    }
    @Published var isReflectionReminderOn: Bool {
        didSet { UserDefaults.standard.set(isReflectionReminderOn, forKey: reflectionOnKey) }
    }
    @Published var reflectionReminderTime: Date {
        didSet { UserDefaults.standard.set(reflectionReminderTime, forKey: reflectionTimeKey) }
    }
    
    init() {
        // Load from UserDefaults or use defaults
        self.isIntentionReminderOn = UserDefaults.standard.bool(forKey: intentionOnKey)
        self.intentionReminderTime = UserDefaults.standard.object(forKey: intentionTimeKey) as? Date ?? Self.defaultMorningTime
        self.isReflectionReminderOn = UserDefaults.standard.bool(forKey: reflectionOnKey)
        self.reflectionReminderTime = UserDefaults.standard.object(forKey: reflectionTimeKey) as? Date ?? Self.defaultEveningTime
    }
    
    // Default times: 9:00 AM and 9:00 PM
    static var defaultMorningTime: Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    static var defaultEveningTime: Date {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
} 