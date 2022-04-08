//
//  PhoneStartView.swift
//  TestWatchAppWorkout
//
//  Created by Romain Rabouan on 08/04/2022.
//

import SwiftUI
import HealthKit

struct PhoneStartView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    
    var workoutTypes: [HKWorkoutActivityType] = [
        .coreTraining,
        .yoga
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                ForEach(workoutTypes) { workoutType in
                    NavigationLink(
                        workoutType.name,
                        tag: workoutType,
                        selection: $viewModel.selectedWorkout)
                    {
                        ContentView()
                    }
                }
            }
            
        }
    }
}

struct PhoneStartView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneStartView().environmentObject(ViewModel())
    }
}
