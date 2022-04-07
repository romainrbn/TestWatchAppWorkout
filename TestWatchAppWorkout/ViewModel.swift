//
//  ViewModel.swift
//  TestWatchAppWorkout
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import Foundation
import WatchConnectivity

class ViewModel: NSObject, WCSessionDelegate, ObservableObject {
    
    var session: WCSession
    
    @Published var heartRate: Double = 0
    @Published var trainingStatus: TrainingStatus = TrainingStatus.stopped
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func sendMessage(text: String) {
        self.session.sendMessage(["message": text], replyHandler: nil) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.trainingStatus = message["trainingStatus"] as? TrainingStatus ?? .started
            self.heartRate = message["heartRate"] as? Double ?? 0
        }
    }
}
