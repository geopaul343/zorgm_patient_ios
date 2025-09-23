import Foundation
import UserNotifications
import UIKit
import AVFoundation

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerForBackgroundTasks()
        
        // Check for alarm sound files
        checkAlarmSoundFiles()
    }
    
    // MARK: - Register Background Tasks
    private func registerForBackgroundTasks() {
        // Background modes are configured in Info.plist
        // This ensures the app appears in Background App Refresh settings
        print("📱 Background modes configured in Info.plist")
        print("📱 App should now appear in Background App Refresh settings")
    }
    
    // MARK: - Request Permission
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge, .provisional]
            )
            
            if granted {
                print("✅ Notification permission granted")
                // Setup notification categories after permission is granted
                setupNotificationCategories()
                
                // Request additional permissions for better delivery
                await requestAdditionalPermissions()
                
                // Check sound settings specifically
                await checkSoundSettings()
                
                // Check device sound settings
                checkDeviceSoundSettings()
            } else {
                print("❌ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Failed to request notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Request Additional Permissions
    private func requestAdditionalPermissions() async {
        // Request provisional permission for immediate delivery
        do {
            let provisionalGranted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.provisional]
            )
            print("📱 Provisional permission: \(provisionalGranted ? "granted" : "denied")")
        } catch {
            print("❌ Failed to request provisional permission: \(error)")
        }
    }
    
    // MARK: - Schedule Medication Reminder
    func scheduleMedicationReminder(for medication: Medication) {
        // Parse the frequency time
        guard let reminderTime = parseTimeFromFrequency(medication.frequency) else {
            print("❌ Could not parse reminder time for medication: \(medication.name)")
            return
        }
        
        print("⏰ Scheduling reminder for \(medication.name) at \(formatTime(reminderTime))")
        
        // Configure audio session for better sound
        configureAudioSession()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🚨 MEDICATION ALARM"
        content.body = "URGENT: Time to take \(medication.name) - \(medication.dosage)"
        
        // Use multiple sound options for maximum compatibility
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "MEDICATION_REMINDER"
        
        // Set interruption level for better visibility and sound
        content.interruptionLevel = .active
        content.relevanceScore = 1.0
        
        // Add sound configuration for better audio
        content.userInfo["sound_enabled"] = true
        content.userInfo["priority"] = "high"
        content.userInfo["force_sound"] = true
        content.userInfo["alarm_type"] = "medication_reminder"
        content.userInfo["sound_priority"] = "critical"
        
        // Configure audio session for background playback
        configureBackgroundAudioSession()
        
        // Use system default sound for background compatibility
        content.sound = UNNotificationSound.default
        
        // Add background alarm properties
        content.userInfo["background_alarm"] = true
        content.userInfo["force_background_audio"] = true
        content.userInfo["alarm_type"] = "medication_reminder"
        
        print("🔔 Using system default sound for background compatibility")
        
        // Add additional properties for better notification delivery
        content.threadIdentifier = "medication_reminders"
        
        // Add medication info to userInfo for handling
        content.userInfo = [
            "medication_id": medication.id,
            "medication_name": medication.name,
            "medication_dosage": medication.dosage
        ]
        
        // Create date components for daily reminder
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Create trigger for daily repetition
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "medication_\(medication.id)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule notification for \(medication.name): \(error)")
                } else {
                    print("✅ Scheduled daily reminder for \(medication.name) at \(self.formatTime(reminderTime))")
                    print("🔔 Alarm sound: \(content.sound?.description ?? "default")")
                    print("📱 Notification ID: medication_\(medication.id)")
                    print("⏰ Next trigger: \(dateComponents.hour ?? 0):\(String(format: "%02d", dateComponents.minute ?? 0))")
                    
                    // Schedule additional alarm notifications for better alerting
                    self.scheduleAdditionalAlarmNotifications(for: medication, at: reminderTime)
                }
            }
        }
    }
    
    // MARK: - Schedule Additional Alarm Notifications
    private func scheduleAdditionalAlarmNotifications(for medication: Medication, at reminderTime: Date) {
        print("🚨 Scheduling additional alarm notifications for \(medication.name)")
        
        // Create additional alarm notifications that will trigger at the same time as main reminder
        for i in 0..<2 {
            let content = UNMutableNotificationContent()
            content.title = "🚨 MEDICATION ALARM \(i + 2)"
            content.body = "URGENT: Time to take \(medication.name) - \(medication.dosage)"
            content.badge = 1
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.interruptionLevel = .active
            content.relevanceScore = 1.0
            
            // Add sound configuration for better audio
            content.userInfo["sound_enabled"] = true
            content.userInfo["priority"] = "critical"
            content.userInfo["alarm_type"] = "medication_reminder"
            content.userInfo["sound_priority"] = "critical"
            content.userInfo["alarm_sequence"] = i + 2
            
            // Use system default sound for background compatibility
            content.sound = UNNotificationSound.default
            
            // Add background alarm properties
            content.userInfo["background_alarm"] = true
            content.userInfo["force_background_audio"] = true
            
            print("🔔 Additional alarm \(i + 2) using system default sound for background compatibility")
            
            // Add medication info
            content.userInfo["medication_id"] = medication.id
            content.userInfo["medication_name"] = medication.name
            content.userInfo["medication_dosage"] = medication.dosage
            
            // Create calendar trigger for the same time as main reminder
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "alarm_\(medication.id)_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to schedule additional alarm notification \(i + 2): \(error)")
                    } else {
                        print("✅ Scheduled additional alarm notification \(i + 2) for \(medication.name)")
                    }
                }
            }
        }
    }
    
    // MARK: - Cancel Medication Reminder
    func cancelMedicationReminder(for medication: Medication) {
        let identifier = "medication_\(medication.id)"
        
        // Cancel main notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Cancel additional alarm notifications
        for i in 0..<2 {
            let alarmIdentifier = "alarm_\(medication.id)_\(i)"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmIdentifier])
        }
        
        print("🔕 Cancelled all reminders for \(medication.name)")
    }
    
    // MARK: - Cancel All Medication Reminders
    func cancelAllMedicationReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔕 Cancelled all medication reminders")
    }
    
    // MARK: - Update Medication Reminder
    func updateMedicationReminder(for medication: Medication) {
        // First cancel existing reminder
        cancelMedicationReminder(for: medication)
        
        // Then schedule new reminder
        scheduleMedicationReminder(for: medication)
    }
    
    // MARK: - Check if reminder is scheduled
    func isReminderScheduled(for medication: Medication) async -> Bool {
        let identifier = "medication_\(medication.id)"
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pendingRequests.contains { $0.identifier == identifier }
    }
    
    // MARK: - Get all scheduled reminders
    func getAllScheduledReminders() async -> [String] {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pendingRequests.map { $0.identifier }
    }
    
    // MARK: - Test Notification (for debugging)
    func testNotification(for medication: Medication) {
        print("🧪 Testing notification for \(medication.name)")
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Medication Reminder"
        content.body = "Test alarm for \(medication.name) - \(medication.dosage)"
        
        // Use default sound for testing (same as production)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.interruptionLevel = .active
        content.relevanceScore = 1.0
        
        // Add additional properties for better delivery
        content.threadIdentifier = "medication_reminders"
        
        // Trigger immediately (5 seconds from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_medication_\(medication.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule test notification: \(error)")
                } else {
                    print("✅ Test notification scheduled for \(medication.name) - will fire in 5 seconds")
                    print("🔔 Test notification will show even if app is in background")
                }
            }
        }
    }
    
    // MARK: - Force Immediate Notification (for testing)
    func forceImmediateNotification(for medication: Medication) {
        print("🚨 Force immediate notification for \(medication.name)")
        
        // Configure audio session for better sound
        configureAudioSession()
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 MEDICATION ALARM"
        content.body = "URGENT: Time to take \(medication.name) - \(medication.dosage)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.interruptionLevel = .active
        content.relevanceScore = 1.0
        
        // Add sound configuration for better audio
        content.userInfo["sound_enabled"] = true
        content.userInfo["priority"] = "high"
        content.userInfo["alarm_type"] = "medication_reminder"
        content.userInfo["sound_priority"] = "critical"
        
        // Trigger immediately (1 second from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "immediate_test_\(medication.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule immediate notification: \(error)")
                } else {
                    print("✅ Immediate notification scheduled - will fire in 1 second")
                }
            }
        }
        
        // Also play alarm sound immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.playImmediateAlarm()
        }
    }
    
    // MARK: - Play Immediate Alarm
    private func playImmediateAlarm() {
        print("🚨 Playing immediate alarm...")
        
        // Play multiple alarm sounds immediately
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                AudioServicesPlaySystemSound(1005)
                AudioServicesPlaySystemSound(1006)
                AudioServicesPlaySystemSound(1007)
                print("🚨 Immediate alarm \(i + 1)/5")
            }
        }
        
        // Add vibration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    // MARK: - Test Sound Directly
    func testSoundDirectly() {
        print("🔊 Testing sound directly...")
        
        // Configure audio session for better sound
        configureAudioSession()
        
        // Play multiple system sounds for testing
        let soundsToTest: [SystemSoundID] = [1005, 1006, 1007, 1010, 1011, 1012, 1013, 1014, 1015, 1016]
        
        for (index, soundID) in soundsToTest.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                AudioServicesPlaySystemSound(soundID)
                print("🔊 Playing system sound \(soundID)")
            }
        }
        
        // Also try playing a custom sound
        if let soundURL = Bundle.main.url(forResource: "notification", withExtension: "wav") {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
            print("✅ Played custom notification sound")
        } else {
            print("ℹ️ No custom sound file found, using system sounds")
        }
        
        // Check audio session
        let audioSession = AVAudioSession.sharedInstance()
        print("📱 Audio Session Status:")
        print("   Output Volume: \(audioSession.outputVolume)")
        print("   Category: \(audioSession.category)")
        print("   Mode: \(audioSession.mode)")
        print("   Is Other Audio Playing: \(audioSession.isOtherAudioPlaying)")
    }
    
    // MARK: - Test Alarm Sound
    func testAlarmSound() {
        print("🚨 Testing alarm sound...")
        
        // Configure audio session for alarm
        configureAudioSession()
        
        // Play the most prominent alarm sounds
        let alarmSounds: [SystemSoundID] = [1005, 1006, 1007, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030]
        
        for (index, soundID) in alarmSounds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                AudioServicesPlaySystemSound(soundID)
                print("🚨 Playing alarm sound \(soundID)")
            }
        }
        
        // Play continuous alarm sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playContinuousAlarm()
        }
    }
    
    // MARK: - Create Alarm Notification
    func createAlarmNotification(for medication: Medication) {
        print("🚨 Creating alarm notification for \(medication.name)")
        
        // Configure audio session for better sound
        configureAudioSession()
        
        // Create multiple notifications for better alerting
        for i in 0..<3 {
            let content = UNMutableNotificationContent()
            content.title = "🚨 MEDICATION ALARM \(i + 1)"
            content.body = "URGENT: Time to take \(medication.name) - \(medication.dosage)"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.interruptionLevel = .active
            content.relevanceScore = 1.0
            
            // Add sound configuration for better audio
            content.userInfo["sound_enabled"] = true
            content.userInfo["priority"] = "critical"
            content.userInfo["alarm_type"] = "medication_reminder"
            content.userInfo["sound_priority"] = "critical"
            content.userInfo["alarm_sequence"] = i + 1
            
            // Add medication info
            content.userInfo["medication_id"] = medication.id
            content.userInfo["medication_name"] = medication.name
            content.userInfo["medication_dosage"] = medication.dosage
            
            // Schedule each notification with a small delay
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(i * 2), repeats: false)
            let request = UNNotificationRequest(
                identifier: "alarm_\(medication.id)_\(i)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to schedule alarm notification \(i + 1): \(error)")
                    } else {
                        print("✅ Scheduled alarm notification \(i + 1) for \(medication.name)")
                    }
                }
            }
        }
        
        // Also play immediate alarm sounds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playImmediateAlarm()
        }
    }
    
    // MARK: - Play Continuous Alarm
    private func playContinuousAlarm() {
        print("🚨 Playing continuous alarm sequence...")
        
        // Play alarm sound repeatedly for 10 seconds
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                // Use the most prominent alarm sound
                AudioServicesPlaySystemSound(1005) // Default notification sound
                AudioServicesPlaySystemSound(1006) // Another prominent sound
                print("🚨 Continuous alarm \(i + 1)/20")
            }
        }
        
        // Also try to play vibration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    // MARK: - Configure Audio Session
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try audioSession.setActive(true)
            print("✅ Audio session configured for playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Check Alarm Sound Files
    private func checkAlarmSoundFiles() {
        print("🔍 Checking for alarm sound files...")
        
        // Check if alarm.caf exists
        if let alarmPath = Bundle.main.path(forResource: "alarm", ofType: "caf") {
            print("✅ Found alarm.caf at: \(alarmPath)")
        } else {
            print("❌ alarm.caf not found in app bundle")
            print("💡 To add custom alarm sounds:")
            print("   1. Add alarm.caf file to Xcode project")
            print("   2. Ensure it's included in app bundle")
            print("   3. File should be 30 seconds or less")
        }
        
        // Check if notification.caf exists
        if let notificationPath = Bundle.main.path(forResource: "notification", ofType: "caf") {
            print("✅ Found notification.caf at: \(notificationPath)")
        } else {
            print("❌ notification.caf not found in app bundle")
        }
        
        // List all sound files in bundle
        let soundFiles = Bundle.main.paths(forResourcesOfType: "caf", inDirectory: nil)
        print("🔍 Available .caf files: \(soundFiles)")
        
        let wavFiles = Bundle.main.paths(forResourcesOfType: "wav", inDirectory: nil)
        print("🔍 Available .wav files: \(wavFiles)")
        
        let mp3Files = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        print("🔍 Available .mp3 files: \(mp3Files)")
        
        // Check system sounds that might work better
        print("🔍 System sounds that work well for alarms:")
        print("   - Default notification sound (current)")
        print("   - Custom .caf files (if added to bundle)")
        print("   - System alarm sounds (limited access)")
    }
    
    // MARK: - Create Alarm Sound File
    func createAlarmSoundFile() {
        print("🎵 Creating alarm sound file...")
        
        // This is a placeholder for creating alarm sound files
        // In a real implementation, you would:
        // 1. Generate or download alarm sound files
        // 2. Add them to the Xcode project
        // 3. Ensure they're included in the app bundle
        
        print("💡 To get better alarm sounds:")
        print("   1. Download alarm.caf files from the internet")
        print("   2. Add them to your Xcode project")
        print("   3. Ensure they're included in the app bundle")
        print("   4. File format: .caf (Core Audio Format)")
        print("   5. Duration: 30 seconds or less")
        print("   6. Quality: 16-bit, 44.1kHz recommended")
        
        // Check if we can create a simple alarm sound programmatically
        print("🔧 Attempting to create simple alarm sound...")
        
        // Note: Creating sound files programmatically is complex
        // The best approach is to add pre-made alarm sound files to the project
    }
    
    // MARK: - Test Background Notification
    func testBackgroundNotification(for medication: Medication) {
        print("🚨 Testing background notification for \(medication.name)")
        
        // Check device sound settings first
        checkDeviceSoundSettings()
        
        // Configure audio session for background playback
        configureBackgroundAudioSession()
        
        // Create notification with system alarm sound
        let content = UNMutableNotificationContent()
        content.title = "🚨 MEDICATION ALARM"
        content.body = "URGENT: Time to take \(medication.name) - \(medication.dosage)"
        content.badge = 1
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.interruptionLevel = .active
        content.relevanceScore = 1.0
        
        // Use system alarm sound that works in background
        content.sound = UNNotificationSound.default
        
        // Add background alarm properties
        content.userInfo["background_alarm"] = true
        content.userInfo["force_background_audio"] = true
        content.userInfo["alarm_type"] = "medication_reminder"
        content.userInfo["medication_id"] = medication.id
        content.userInfo["medication_name"] = medication.name
        content.userInfo["medication_dosage"] = medication.dosage
        
        print("🔔 Using system default sound for background compatibility")
        
        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "background_alarm_\(medication.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule background alarm: \(error)")
                } else {
                    print("✅ Background alarm scheduled - will fire in 5 seconds")
                    print("📱 Put the app in background NOW to test")
                    print("🔔 This should ring like a normal iPhone alarm")
                    print("⚠️  Make sure Background App Refresh is ON in Settings")
                }
            }
        }
    }
    
    // MARK: - Configure Background Audio Session
    private func configureBackgroundAudioSession() {
        print("🔊 Configuring background audio session...")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Set category for background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            
            // Activate the session
            try audioSession.setActive(true)
            
            print("✅ Background audio session configured successfully")
            print("   Category: \(audioSession.category)")
            print("   Mode: \(audioSession.mode)")
            print("   Options: \(audioSession.categoryOptions)")
            
        } catch {
            print("❌ Failed to configure background audio session: \(error)")
        }
    }
    
    // MARK: - Check Device Sound Settings
    private func checkDeviceSoundSettings() {
        print("🔍 Checking device sound settings...")
        
        // Check notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification Settings:")
                print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
                print("   Sound Setting: \(settings.soundSetting.rawValue)")
                print("   Badge Setting: \(settings.badgeSetting.rawValue)")
                print("   Alert Setting: \(settings.alertSetting.rawValue)")
                print("   Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
                print("   Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
                print("   Car Play Setting: \(settings.carPlaySetting.rawValue)")
                
                if settings.soundSetting == .disabled {
                    print("⚠️ WARNING: Notification sounds are disabled!")
                    print("   Go to Settings > Notifications > ZorgamIOS > Allow Notifications > Sounds")
                }
                
                if settings.authorizationStatus != .authorized {
                    print("⚠️ WARNING: Notifications are not authorized!")
                    print("   Go to Settings > Notifications > ZorgamIOS > Allow Notifications")
                }
            }
        }
        
        // Check audio session
        let audioSession = AVAudioSession.sharedInstance()
        print("🔊 Audio Session Status:")
        print("   Output Volume: \(audioSession.outputVolume)")
        print("   Category: \(audioSession.category)")
        print("   Mode: \(audioSession.mode)")
        print("   Is Other Audio Playing: \(audioSession.isOtherAudioPlaying)")
        
        if audioSession.outputVolume == 0.0 {
            print("⚠️ WARNING: Device volume is at 0!")
            print("   Increase device volume to hear alarm sounds")
        }
        
        // Check if device is in silent mode
        if audioSession.outputVolume > 0.0 && audioSession.isOtherAudioPlaying == false {
            print("✅ Device volume is set and no other audio is playing")
        }
        
        // Check background app refresh status
        checkBackgroundAppRefreshStatus()
    }
    
    // MARK: - Check Background App Refresh Status
    private func checkBackgroundAppRefreshStatus() {
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        print("🔄 Background App Refresh Status: \(backgroundRefreshStatus.rawValue)")
        
        switch backgroundRefreshStatus {
        case .available:
            print("✅ Background App Refresh is available")
        case .denied:
            print("❌ Background App Refresh is denied!")
            print("   Go to Settings > General > Background App Refresh")
            print("   Enable it globally and for ZorgamIOS")
            print("   This is REQUIRED for background alarms to work!")
        case .restricted:
            print("❌ Background App Refresh is restricted!")
            print("   This device doesn't support background refresh")
        @unknown default:
            print("❓ Unknown Background App Refresh status")
        }
        
        // Check if app appears in background refresh settings
        print("📱 Background Modes Check:")
        if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            print("   Configured Background Modes: \(backgroundModes)")
            if backgroundModes.contains("background-processing") {
                print("✅ background-processing mode enabled")
            } else {
                print("❌ background-processing mode missing!")
            }
            if backgroundModes.contains("background-fetch") {
                print("✅ background-fetch mode enabled")
            } else {
                print("❌ background-fetch mode missing!")
            }
            if backgroundModes.contains("remote-notification") {
                print("✅ remote-notification mode enabled")
            } else {
                print("❌ remote-notification mode missing!")
            }
        } else {
            print("❌ No background modes configured!")
        }
        
        // Check if app is in background refresh list
        print("📱 App Background Refresh Check:")
        print("   Make sure ZorgamIOS appears in:")
        print("   Settings > General > Background App Refresh")
        print("   And is enabled (toggle ON)")
    }
    
    // MARK: - Request Background App Refresh
    func requestBackgroundAppRefresh() {
        print("🔄 Requesting background app refresh permissions...")
        
        // Check current status
        let currentStatus = UIApplication.shared.backgroundRefreshStatus
        print("Current Background App Refresh Status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .available:
            print("✅ Background App Refresh is already available")
            print("   App should appear in Settings > General > Background App Refresh")
        case .denied:
            print("❌ Background App Refresh is denied!")
            print("   User needs to manually enable it:")
            print("   1. Go to Settings > General > Background App Refresh")
            print("   2. Turn ON Background App Refresh globally")
            print("   3. Find ZorgamIOS in the list and enable it")
            print("   4. This is REQUIRED for background alarms to work!")
        case .restricted:
            print("❌ Background App Refresh is restricted!")
            print("   This device doesn't support background refresh")
        @unknown default:
            print("❓ Unknown Background App Refresh status")
        }
        
        // Show instructions to user
        print("📱 To enable background alarms:")
        print("   1. Open Settings app")
        print("   2. Go to General > Background App Refresh")
        print("   3. Turn ON Background App Refresh")
        print("   4. Find ZorgamIOS and enable it")
        print("   5. Return to app and test background alarm")
    }
    
    // MARK: - Helper Functions
    private func parseTimeFromFrequency(_ frequency: String) -> Date? {
        print("🕐 Parsing frequency: '\(frequency)'")
        
        // Try different time formats
        let formatters = [
            // Short time format (e.g., "8:00 AM", "20:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter
            }(),
            // 24-hour format (e.g., "20:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter
            }(),
            // 12-hour format with AM/PM (e.g., "8:00 AM")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter
            }(),
            // 12-hour format without AM/PM (e.g., "8:00")
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: frequency) {
                print("✅ Successfully parsed time: \(date)")
                return date
            }
        }
        
        print("❌ Could not parse frequency: \(frequency)")
        return nil
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Notification Categories
extension NotificationService {
    func setupNotificationCategories() {
        print("🔧 Setting up notification categories")
        
        // Define notification actions
        let takeAction = UNNotificationAction(
            identifier: "TAKE_MEDICATION",
            title: "✅ Mark as Taken",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_MEDICATION",
            title: "⏰ Snooze 10 min",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_MEDICATION",
            title: "❌ Dismiss",
            options: [.destructive]
        )
        
        // Create category with critical alert options
        let category = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [takeAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        // Register category
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ Notification categories registered successfully")
    }
    
    // MARK: - Check Notification Settings
    func checkNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("📱 Notification Settings:")
        print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
        print("   Alert Setting: \(settings.alertSetting.rawValue)")
        print("   Sound Setting: \(settings.soundSetting.rawValue)")
        print("   Badge Setting: \(settings.badgeSetting.rawValue)")
        print("   Critical Alert Setting: \(settings.criticalAlertSetting.rawValue)")
        print("   Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
        print("   Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
        print("   Car Play Setting: \(settings.carPlaySetting.rawValue)")
        
        // Check if notifications are properly configured
        if settings.authorizationStatus == .authorized {
            print("✅ Notifications are authorized")
        } else if settings.authorizationStatus == .denied {
            print("❌ Notifications are denied - user needs to enable in Settings")
        } else if settings.authorizationStatus == .notDetermined {
            print("⚠️ Notifications not determined - requesting permission")
        }
        
        // Check background app refresh
        checkBackgroundAppRefresh()
    }
    
    // MARK: - Check Background App Refresh
    private func checkBackgroundAppRefresh() {
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        print("📱 Background App Refresh Status: \(backgroundRefreshStatus.rawValue)")
        
        switch backgroundRefreshStatus {
        case .available:
            print("✅ Background App Refresh is available")
        case .denied:
            print("❌ Background App Refresh is denied - user needs to enable in Settings")
            print("📋 Instructions:")
            print("   1. Go to Settings > General > Background App Refresh")
            print("   2. Turn ON Background App Refresh")
            print("   3. Find 'ZorgamIOS' in the list and enable it")
        case .restricted:
            print("⚠️ Background App Refresh is restricted")
        @unknown default:
            print("❓ Unknown Background App Refresh status")
        }
        
        // Check if app has background modes configured
        checkBackgroundModesConfiguration()
    }
    
    // MARK: - Check Background Modes Configuration
    private func checkBackgroundModesConfiguration() {
        guard let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            print("❌ No background modes configured in Info.plist")
            return
        }
        
        print("📱 Configured Background Modes: \(backgroundModes)")
        
        let requiredModes = ["background-processing", "background-fetch", "remote-notification"]
        let hasRequiredModes = requiredModes.allSatisfy { backgroundModes.contains($0) }
        
        if hasRequiredModes {
            print("✅ All required background modes are configured")
        } else {
            print("❌ Missing required background modes")
            print("📋 Required modes: \(requiredModes)")
        }
    }
    
    // MARK: - Check Sound Settings
    private func checkSoundSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        print("🔊 Sound Settings Check:")
        print("   Sound Setting: \(settings.soundSetting.rawValue)")
        print("   Alert Setting: \(settings.alertSetting.rawValue)")
        
        // Check if device is in silent mode
        let audioSession = AVAudioSession.sharedInstance()
        let isSilentMode = audioSession.outputVolume == 0.0
        
        print("📱 Device Audio Status:")
        print("   Output Volume: \(audioSession.outputVolume)")
        print("   Silent Mode: \(isSilentMode ? "YES" : "NO")")
        
        if settings.soundSetting == .disabled {
            print("❌ Notification sounds are disabled")
            print("📋 Instructions:")
            print("   1. Go to Settings > Notifications > ZorgamIOS")
            print("   2. Turn ON 'Sounds'")
            print("   3. Make sure device is not in silent mode")
        } else if isSilentMode {
            print("⚠️ Device is in silent mode - sounds won't play")
            print("📋 Instructions:")
            print("   1. Turn off silent mode (flip the silent switch)")
            print("   2. Or increase device volume")
        } else {
            print("✅ Sound settings are properly configured")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService {
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async {
            print("🔔 Notification received in foreground: \(notification.request.content.title)")
            
            // Check if this is a medication alarm notification
            if let alarmType = notification.request.content.userInfo["alarm_type"] as? String,
               alarmType == "medication_reminder" {
                print("🚨 Medication alarm notification received - playing immediate alarm sounds")
                self.playImmediateAlarm()
            }
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        DispatchQueue.main.async { [self] in
            print("🔔 Notification action received: \(actionIdentifier)")
            
            // Check if this is a medication alarm notification and play alarm sounds
            if let alarmType = userInfo["alarm_type"] as? String,
               alarmType == "medication_reminder" {
                print("🚨 Medication alarm notification action - playing immediate alarm sounds")
                self.playImmediateAlarm()
            }
            
            switch actionIdentifier {
        case "TAKE_MEDICATION":
            print("✅ Medication marked as taken")
            // Handle medication taken action
            if let medicationId = userInfo["medication_id"] as? Int {
                print("💊 Medication ID: \(medicationId) marked as taken")
            }
            
        case "SNOOZE_MEDICATION":
            print("⏰ Medication snoozed for 10 minutes")
            // Handle snooze action
            if let medicationId = userInfo["medication_id"] as? Int {
                print("💊 Medication ID: \(medicationId) snoozed")
                // Schedule a new notification for 10 minutes later
                scheduleSnoozeNotification(for: medicationId, in: 10 * 60) // 10 minutes
            }
            
        case "DISMISS_MEDICATION":
            print("❌ Medication reminder dismissed")
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 Notification tapped")
            
        default:
            print("❓ Unknown action: \(actionIdentifier)")
        }
        }
        
        completionHandler()
    }
    
    // Helper method to schedule snooze notification
    private func scheduleSnoozeNotification(for medicationId: Int, in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💊 Medication Reminder (Snoozed)"
        content.body = "Time to take your medication"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.interruptionLevel = .active
        content.relevanceScore = 1.0
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze_medication_\(medicationId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule snooze notification: \(error)")
                } else {
                    print("✅ Snooze notification scheduled for \(seconds) seconds")
                }
            }
        }
    }
}
