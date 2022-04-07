//
//  ContentView.swift
//  TestWatchAppWorkout
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI



struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            
            Text("Training status: \(viewModel.trainingStatus.rawValue)")
            
            if viewModel.trainingStatus == TrainingStatus.started {
                Text("Heart Rate: \(Int(viewModel.heartRate)) bpm")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                Text("Heart Rate: - bpm")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            
            Spacer()
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
