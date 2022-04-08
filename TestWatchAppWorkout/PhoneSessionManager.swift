//
//  WatchConnectivity.swift
//  TestWatchAppWorkout
//
//  Created by Romain Rabouan on 08/04/2022.
//

import WatchConnectivity

class PhoneSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()
    
    private override init() {
        super.init()
        
        startSession()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    private var validSession: WCSession? {
        if let session = session, session.isWatchAppInstalled && session.isPaired && session.isReachable {
            return session
        }
        
        return nil
    }
    
    func startSession() {
        validSession?.delegate = self
        validSession?.activate()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Update UI
        DispatchQueue.main.async {
            
        }
        
    }
    
    func transferUserInfo(userInfo: [String: Any]) -> WCSessionUserInfoTransfer? {
        return validSession?.transferUserInfo(userInfo)
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        // confirm that the user info did in fact transfer
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        // Receive user info
        DispatchQueue.main.async {
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession Activated!")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
}

extension PhoneSessionManager {
    
    // MARK: - Send
    func sendMessage(message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendMessageData(data: Data, replyHandler: ((Data) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // MARK: - Receive
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("DidReceiveMessage")
        
        DispatchQueue.main.async { [weak self] in
            
            var replyValues = Dictionary<String, Any>()
            
            guard let self = self else { return }
            
            // Handle iOS Message
            if let togglePause = message[String.togglePause] as? Bool {
                if togglePause {
                    self.sendNotification(with: .workoutDidPause)
                    replyValues["phoneStatus"] = "workoutDidPause"
                } else {
                    self.sendNotification(with: .workoutDidResume)
                    replyValues["phoneStatus"] = "workoutDidResume"
                }
            }
            
            if let trainingStatus = message[String.trainingIsRunning] as? Bool {
                if trainingStatus {
                    self.sendNotification(with: .workoutDidStart)
                    replyValues["phoneStatus"] = "workoutDidStart"
                } else {
                    self.sendNotification(with: .workoutDidStop)
                    replyValues["phoneStatus"] = "workoutDidStop"
                }
            }
            
            replyHandler(replyValues)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        DispatchQueue.main.async {
        }
    }
    
    private func sendNotification(with name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
