//
//  EmailView.swift
//  BuzzerBeater
//
//  Created by 이승현 on 11/23/24.
//

import SwiftUI
import MessageUI

struct EmailView: UIViewControllerRepresentable {
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: EmailView

        init(parent: EmailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = context.coordinator
        mailComposeVC.setToRecipients(["susie204@naver.com"])
        mailComposeVC.setSubject("WindTalker Feedback")
        mailComposeVC.setMessageBody("""
        Please write your questions or feedback below:
        
        
        
        
        -------------------
        Device Model: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        App Version: \(Utils.getAppVersion())
        -------------------
        """, isHTML: false)
        return mailComposeVC
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

// MARK: - Email Utils
final class Utils {
    static func getAppVersion() -> String {
        let fullVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        
        let regexPattern = #"^(\d+\.\d+\.\d+)"#
        if let regex = try? NSRegularExpression(pattern: regexPattern),
           let match = regex.firstMatch(in: fullVersion, options: [], range: NSRange(location: 0, length: fullVersion.utf16.count)),
           let range = Range(match.range(at: 1), in: fullVersion) {
            return String(fullVersion[range])
        }
        return fullVersion
    }
    
    static func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }
    
    static func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    static func getDeviceModelName() -> String {
        let device = UIDevice.current
        let modelName = device.name
        if modelName.isEmpty {
            return "알 수 없음"
        } else {
            return modelName
        }
    }
    
}
