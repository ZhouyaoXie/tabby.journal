import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsModel = SettingsModel()
    @State private var notificationPermissionDenied = false
    @State private var showBanner = false
    @State private var bannerMessage = ""
    
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
                            Toggle("", isOn: $settingsModel.isIntentionReminderOn)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.6)))
                                .frame(width: 60)
                                .disabled(notificationPermissionDenied)
                            DatePicker("", selection: $settingsModel.intentionReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .disabled(!settingsModel.isIntentionReminderOn || notificationPermissionDenied)
                                .frame(width: 110)
                                .background(Color.gray.opacity(settingsModel.isIntentionReminderOn ? 0.1 : 0.2))
                                .cornerRadius(8)
                                .foregroundColor(settingsModel.isIntentionReminderOn ? Color.blue : Color.gray)
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
                            Toggle("", isOn: $settingsModel.isReflectionReminderOn)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.6)))
                                .frame(width: 60)
                                .disabled(notificationPermissionDenied)
                            DatePicker("", selection: $settingsModel.reflectionReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .disabled(!settingsModel.isReflectionReminderOn || notificationPermissionDenied)
                                .frame(width: 110)
                                .background(Color.gray.opacity(settingsModel.isReflectionReminderOn ? 0.1 : 0.2))
                                .cornerRadius(8)
                                .foregroundColor(settingsModel.isReflectionReminderOn ? Color.blue : Color.gray)
                        }
                    }
                    .padding(16)
                    .background(Color("CardBackground").opacity(0.85))
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 12)
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
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                    }
                    Spacer()
                }
            )
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
}

#Preview {
    SettingsView()
} 
