import Foundation
import SwiftUI
import Charts
import MapKit

struct InfoDetail: View {
    let workoutData: DummyWorkoutData
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var coordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // 샌프란시스코
        CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
        CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
        CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4197),
        CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4198),
        CLLocationCoordinate2D(latitude: 37.7754, longitude: -122.4199),
        CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4200)
    ]
    
    var velocities: [CLLocationSpeed] = [
        5.0,
        5.2,
        5.5,
        5.7,
        5.9,
        6.1,
        6.3
    ]
    
    @State var position: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            List {
                HStack(spacing:16) {
                    InfoIcon()
                        .frame(width: 120)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dinghy Yacht")
                            .font(.title2)
                        Text("\(DateFormatter.amPmTime.string(from: workoutData.startDate)) - \(DateFormatter.amPmTime.string(from: workoutData.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Label("Pohang City", systemImage: "location.fill")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(height: 120)
                .listRowBackground(Color.clear)
                
                Section(header:
                    HStack {
                        Text("Navigation Detail")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                ) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sailing time")
                                Spacer()
                            }
                            Text(workoutData.duration.formattedTime)
                                .font(.title)
                                .foregroundColor(.yellow)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sailing Distance")
                                Spacer()
                            }
                            Text("13 Km")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Calories")
                                Spacer()
                            }
                            Text("564 KCAL")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Highest speed")
                                Spacer()
                            }
                            Text("27.3 m/s")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                    }
                    .padding()
                }
                    Section(
                        header:
                            HStack {
                                Text("speed of a yacht")
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                    ) {
                        Chart {
                            ForEach(velocities.indices, id: \.self) { index in
                                LineMark(
                                    x: .value("Index", index),
                                    y: .value("Velocity", velocities[index])
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 160)
                    }
                    
                    Section(
                        header:
                            HStack {
                                Text("speed of a yacht")
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                    ) {
                        Map(position: $position, interactionModes: [.all] ){
                            if coordinates.count >= 2 {
                                ForEach(0..<coordinates.count - 1, id: \.self) { index in
                                    let start = coordinates[index]
                                    let end = coordinates[index + 1]
                                    
                                    let velocity = velocities[index]
                                    let maxVelocity = velocities.max() ?? 10.0
                                    let minVelocity = velocities.min() ?? 0.0
                                    let color = calculateColor(for: velocity, minVelocity: minVelocity, maxVelocity: maxVelocity)
                                    
                                    MapPolyline(coordinates: [start, end])
                                        .stroke(color, lineWidth: 5)
                                }
                            }
                            
                             MapPolyline(coordinates: coordinates)
                                 .stroke(Color.cyan, lineWidth: 1)
                            
                        }
                        .mapControls{
                            MapUserLocationButton()
                            MapCompass()
            #if !os(watchOS)
                            MapScaleView()
            #endif
                        }
                        .frame(height: 200)
                    }
            }            .navigationTitle(
                DateFormatter.koreanMonthDayWeekday.string(from: workoutData.startDate)
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
    
    func calculateColor(for velocity: Double, minVelocity: Double, maxVelocity: Double) -> Color {
        if maxVelocity <= minVelocity {
            return Color.green
        }
        let progress = CGFloat((velocity - minVelocity) / (maxVelocity - minVelocity))
        
        if progress < 0.7 {
            return Color.yellow
        }
        else if progress  >= 0.7 && progress < 0.85 {
            return Color.green
        }
        
        else if progress >= 0.85 {
            return Color.red
        }
        else {
            return Color.blue
        }
    }
}

#Preview {
    InfoDetail(
        workoutData: Dummy.sampleDummyWorkoutData[0],
        coordinates: [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // 샌프란시스코
            CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
            CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4197),
            CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4198),
            CLLocationCoordinate2D(latitude: 37.7754, longitude: -122.4199),
            CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4200)
        ],
        velocities: [
            5.0,
            5.2,
            5.5,
            5.7,
            5.9,
            6.1,
            6.3
        ]
    )
}
