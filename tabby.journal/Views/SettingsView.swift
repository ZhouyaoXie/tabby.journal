import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var settingsModel = SettingsModel()
    @State private var notificationPermissionDenied = false
    @State private var showBanner = false
    @State private var bannerMessage = ""
    @State private var exportButtonPressed = false
    @Environment(\.managedObjectContext) private var viewContext
    
    private let intentionId = "intention_reminder"
    private let reflectionId = "reflection_reminder"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PageBackground").edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Settings")
                        .font(.garamondBold(size: 32))
                        .foregroundColor(Color("CardText"))
                        .padding(.top, 32)
                        .padding(.leading, 16)
                        .padding(.bottom, 8)
                    
                    // Notification Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Notifications")
                            .font(.garamondBold(size: 20))
                            .foregroundColor(Color("CardText"))
                            .padding(.bottom, 4)
                        
                        // Intention Reminder Row
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(Color("CardText").opacity(0.7))
                                .font(.system(size: 20))
                            Text("Intention Reminder")
                                .font(.garamond(size: 16))
                                .foregroundColor(Color("CardText"))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settingsModel.isIntentionReminderOn },
                                set: { newValue in
                                    settingsModel.isIntentionReminderOn = newValue
                                    triggerLightHaptic()
                                })
                            )
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.6)))
                                .frame(width: 60)
                                .disabled(notificationPermissionDenied)
                                .animation(.easeInOut, value: settingsModel.isIntentionReminderOn)
                            DatePicker("", selection: $settingsModel.intentionReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .disabled(!settingsModel.isIntentionReminderOn || notificationPermissionDenied)
                                .frame(width: 110)
                                .background(Color.gray.opacity(settingsModel.isIntentionReminderOn ? 0.1 : 0.2))
                                .cornerRadius(8)
                                .foregroundColor(settingsModel.isIntentionReminderOn ? Color.blue : Color.gray)
                                .animation(.easeInOut, value: settingsModel.isIntentionReminderOn)
                        }
                        // Reflection Reminder Row
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(Color("CardText").opacity(0.7))
                                .font(.system(size: 20))
                            Text("Reflection Reminder")
                                .font(.garamond(size: 16))
                                .foregroundColor(Color("CardText"))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settingsModel.isReflectionReminderOn },
                                set: { newValue in
                                    settingsModel.isReflectionReminderOn = newValue
                                    triggerLightHaptic()
                                })
                            )
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.6)))
                                .frame(width: 60)
                                .disabled(notificationPermissionDenied)
                                .animation(.easeInOut, value: settingsModel.isReflectionReminderOn)
                            DatePicker("", selection: $settingsModel.reflectionReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .disabled(!settingsModel.isReflectionReminderOn || notificationPermissionDenied)
                                .frame(width: 110)
                                .background(Color.gray.opacity(settingsModel.isReflectionReminderOn ? 0.1 : 0.2))
                                .cornerRadius(8)
                                .foregroundColor(settingsModel.isReflectionReminderOn ? Color.blue : Color.gray)
                                .animation(.easeInOut, value: settingsModel.isReflectionReminderOn)
                        }
                    }
                    .padding(16)
                    .background(Color("CardBackground").opacity(0.85))
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 12)
                    
                    // Export Data Button with scale animation
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            exportButtonPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                exportButtonPressed = false
                            }
                            triggerExportHaptic()
                            exportData()
                        }
                    }) {
                        HStack() {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                            Text("Export data")
                                .font(.garamondBold(size: 20))
                                .foregroundColor(Color("CardText"))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("CardBackground").opacity(0.85))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 12)
                        .scaleEffect(exportButtonPressed ? 0.96 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: exportButtonPressed)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .alert(isPresented: $notificationPermissionDenied) {
                Alert(
                    title: Text("Notifications Disabled"),
                    message: Text("Please enable notifications in Settings to use reminders."),
                    primaryButton: .default(Text("Open Settings"), action: openAppSettings),
                    secondaryButton: .cancel(Text("OK"))
                )
            }
            .overlay(
                VStack {
                    if showBanner {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(bannerMessage)
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(16)
                        .padding(.top, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                    Spacer()
                }
            )
            .animation(.easeInOut(duration: 0.3), value: showBanner)
        }
        // Intention Reminder Logic
        .onChange(of: settingsModel.isIntentionReminderOn) { isOn in
            if isOn {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        scheduleIntentionNotification()
                        showBannerWithMessage("Intention reminder scheduled")
                    } else {
                        settingsModel.isIntentionReminderOn = false
                        notificationPermissionDenied = true
                    }
                }
            } else {
                NotificationManager.shared.cancelNotification(id: intentionId)
                showBannerWithMessage("Intention reminder canceled")
            }
        }
        .onChange(of: settingsModel.intentionReminderTime) { _ in
            if settingsModel.isIntentionReminderOn {
                scheduleIntentionNotification()
                showBannerWithMessage("Intention reminder updated")
            }
        }
        // Reflection Reminder Logic
        .onChange(of: settingsModel.isReflectionReminderOn) { isOn in
            if isOn {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        scheduleReflectionNotification()
                        showBannerWithMessage("Reflection reminder scheduled")
                    } else {
                        settingsModel.isReflectionReminderOn = false
                        notificationPermissionDenied = true
                    }
                }
            } else {
                NotificationManager.shared.cancelNotification(id: reflectionId)
                showBannerWithMessage("Reflection reminder canceled")
            }
        }
        .onChange(of: settingsModel.reflectionReminderTime) { _ in
            if settingsModel.isReflectionReminderOn {
                scheduleReflectionNotification()
                showBannerWithMessage("Reflection reminder updated")
            }
        }
    }
    
    private func scheduleIntentionNotification() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: settingsModel.intentionReminderTime)
        NotificationManager.shared.scheduleNotification(
            id: intentionId,
            title: "Set your intention",
            body: "Take a moment to set your intention for the day.",
            dateComponents: components
        )
    }
    
    private func scheduleReflectionNotification() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: settingsModel.reflectionReminderTime)
        NotificationManager.shared.scheduleNotification(
            id: reflectionId,
            title: "Reflect on your day",
            body: "Take a moment to reflect on your day.",
            dateComponents: components
        )
    }
    
    private func showBannerWithMessage(_ message: String) {
        bannerMessage = message
        withAnimation {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showBanner = false
            }
        }
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // Haptic feedback for toggles
    private func triggerLightHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
    // Haptic feedback for export
    private func triggerExportHaptic(success: Bool = true) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
        #endif
    }
    
    private func exportData() {
        // Defensive: Ensure context is valid and not running in preview
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            bannerMessage = "Export not available in preview."
            withAnimation { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showBanner = false }
            }
            return
        }
        #endif
        guard viewContext.persistentStoreCoordinator != nil else {
            bannerMessage = "Export failed: Data store not available."
            withAnimation { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showBanner = false }
            }
            triggerExportHaptic(success: false)
            return
        }
        DispatchQueue.main.async {
            do {
                let url = try JournalBackupManager.shared.backupAllEntries(context: viewContext)
                // Ensure file exists and is non-empty before presenting
                if FileManager.default.fileExists(atPath: url.path),
                   let fileData = try? Data(contentsOf: url), fileData.count > 0 {
                    shareExportedFile(url: url)
                    triggerExportHaptic(success: true)
                } else {
                    bannerMessage = "Failed to export data."
                    withAnimation { showBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showBanner = false }
                    }
                    triggerExportHaptic(success: false)
                }
            } catch {
                bannerMessage = "Failed to export data."
                withAnimation { showBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showBanner = false }
                }
                triggerExportHaptic(success: false)
            }
        }
    }

    private func shareExportedFile(url: URL) {
        #if canImport(UIKit)
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            bannerMessage = "Unable to share file."
            withAnimation { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showBanner = false }
            }
            return
        }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(activityVC, animated: true, completion: nil)
        #endif
    }
}

#Preview {
    SettingsView()
} 
