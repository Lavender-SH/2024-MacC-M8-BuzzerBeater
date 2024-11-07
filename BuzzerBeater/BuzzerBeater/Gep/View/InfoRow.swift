import Foundation
import SwiftUI

struct InfoRow: View {
    let workoutData: DummyWorkoutData
    
    var body: some View {
        HStack(spacing: 15) {
            InfoIcon()
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading) {
                Text("Dinghy Yacht")
                    .font(.headline)
                Text("\( Int(workoutData.totalDistance / 1000) ) km")
                    .font(.title3)
                    .foregroundColor(.cyan)
                HStack {
                    Spacer()
                    Text(
                        DateFormatter
                            .yearMonthDay.string(from: workoutData.startDate)
                    )
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    InfoRow(
        workoutData: Dummy.sampleDummyWorkoutData[0]
    )
    
}
