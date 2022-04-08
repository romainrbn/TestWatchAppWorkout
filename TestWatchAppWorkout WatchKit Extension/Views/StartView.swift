//
//  ContentView.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI
import HealthKit

struct StartView: View {
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var workoutTypes: [HKWorkoutActivityType] = [
        .coreTraining,
        .yoga
    ]
    
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Image("bimLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                    .padding(
                        EdgeInsets(top: 15, leading: 10, bottom: 10, trailing: 10)
                    )
                
                Text("Please start a workout from your iPhone.")
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                
                VStack(spacing: 7) {
                    ForEach(workoutTypes) { workoutType in
                        NavigationLink(
                            workoutType.name,
                            destination: SessionPagingView(),
                            tag: workoutType,
                            selection: $workoutManager.selectedWorkout
                        )
                    }
                }.padding(
                    EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
                )
                
            }
        }
        .navigationTitle("bim ⚡️")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}



struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView().environmentObject(WorkoutManager())
    }
}
