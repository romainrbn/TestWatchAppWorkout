//
//  ContentView.swift
//  TestWatchAppWorkout
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Group {
            if viewModel.trainingInProgress {
                VStack {
                    Text("Training status: \(viewModel.trainingIsRunning ? "Running" : "Paused")")
                    
                    Spacer()
                    
                    Button {
                        viewModel.stopWorkout()
                    } label: {
                        Text("Stop Workout")
                    }
                    
                    Spacer()
                }.padding()
            } else {
                VStack {
                    Text("Training in progress: \(viewModel.trainingInProgress ? "true" : "false")...")
                }
            }
        }.onChange(of: viewModel.trainingInProgress) { newValue in
            if !newValue {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
