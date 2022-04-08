//
//  ViewModel.swift
//  TestWatchAppWorkout
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import Foundation
import HealthKit
import WatchConnectivity

class ViewModel: NSObject, ObservableObject {
    
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let _ = selectedWorkout else {
                return
            }
            
            startWorkout()
        }
    }
    
    var session: WCSession
    
    // the training is not stopped
    @Published var trainingInProgress = false
    
    // the training is not paused
    @Published var trainingIsRunning = false
    
    override init() {
        let defaultSesssion = WCSession.default
        self.session = defaultSesssion
        super.init()
        self.session.delegate = self
        session.activate()
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(workoutDidPause), name: .workoutDidPause, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(workoutDidStart), name: .workoutDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(workoutDidResume), name: .workoutDidResume, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(workoutDidStop), name: .workoutDidStop, object: nil)
    }
    
    func startWorkout() { // Passer le type de workout ici
        self.session.sendMessage([String.trainingIsRunning: true]) { replies in
//            if let reply = replies["watchStatus"] as? String, reply == "workoutDidStart" {
//                DispatchQueue.main.async {
//                    self.trainingInProgress = true
//                    self.trainingIsRunning = true
//                }
//            } else {
//                print("Workout could not start...")
//            }
            DispatchQueue.main.async {
                self.trainingInProgress = true
                self.trainingIsRunning = true
            }
        } errorHandler: { error in
            print(error.localizedDescription)
            return
        }
    }
    
    func stopWorkout() {
        self.session.sendMessage([String.trainingIsRunning: false]) { replies in
            print(replies)
        } errorHandler: { error in
            print("ERROR on stop Workout: \(error.localizedDescription)")
            return
        }
        
        trainingInProgress = false
        trainingInProgress = false
    }
}

// MARK: - Workout Status
extension ViewModel {
    @objc
    func workoutDidPause() {
        debugPrint("iOS: workout did Pause")
        self.trainingIsRunning = false
    }
    
    @objc
    func workoutDidStart() {
        debugPrint("iOS: workout did Start")
        self.trainingIsRunning = true
    }
    
    @objc
    func workoutDidResume() {
        debugPrint("iOS: workout did Resume")
        self.trainingIsRunning = true
    }
    
    @objc
    func workoutDidStop() {
        self.trainingIsRunning = false
        self.trainingInProgress = false
    }
}

extension ViewModel: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCActivation Complete for iPhone!")
    }
    
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
    
    private func sendNotification(with name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
