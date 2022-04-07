//
//  ContentView.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var workoutViewModel = WorkoutViewModel()
    
    var body: some View {
        VStack {
            Text(workoutViewModel.heartRateLabelText)
                .fontWeight(.bold)
                .foregroundColor(workoutViewModel.trainingStatus == .started ? .red : .gray)
            
            Spacer()
            
            if workoutViewModel.trainingStatus == .stopped {
                Button(action: workoutViewModel.startWorkout) {
                    Label("Start workout", systemImage: "play.fill")
                        .foregroundColor(.green)
                }
            }
            
            if (workoutViewModel.trainingStatus == .started || workoutViewModel.trainingStatus == .paused) {
                Button(action: {
                    workoutViewModel.trainingStatus == .paused ? workoutViewModel.startWorkout() : workoutViewModel.pauseWorkout()
                }) {
                    if workoutViewModel.trainingStatus == .paused {
                        Label("Restart workout", systemImage: "arrow.counterclockwise")
                    } else {
                        Label("Pause workout", systemImage: "pause")
                    }
                }.foregroundColor(.orange)
                
                Button(action: workoutViewModel.stopWorkout) {
                    Label("Stop workout", systemImage: "stop.fill")
                        .foregroundColor(.red)
                }
            }
            
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
