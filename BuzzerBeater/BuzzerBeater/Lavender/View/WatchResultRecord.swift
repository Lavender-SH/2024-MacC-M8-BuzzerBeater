//
//  WatchResultRecord.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 11/19/24.
//
// injected a viewmodel and change the view structure by andy 11/22

import SwiftUI
import HealthKit
import CoreLocation
import MapKit

struct WatchResultRecord: View {
//    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapPathViewModel : MapPathViewModel
    
    
    @State private var isMapModalPresented = false
    let workoutManager = WorkoutManager.shared
    
    var workout: HKWorkout?
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    
    @State private var region: MKCoordinateRegion?

    @State var isDataLoaded : Bool = false
    @State var locationName: String = "Loading location..."
    
    init(workout: HKWorkout?) {
        self.workout = workout
        
    }
    
    var body: some View {
        VStack(spacing: 13) { // 전체 줄 간격
            if isDataLoaded {
                // 날짜 표시
                Text(formattedDate(mapPathViewModel.workout?.startDate))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                // 상자 그룹
                HStack(spacing: 8) {
                    // Time 상자
                    InfoBox(title: "Time", value: formattedDuration(mapPathViewModel.duration), valueColor: .yellow)
                    // Distance 상자
                    InfoBox(title: "Distance", value: "\(formattedDistance(mapPathViewModel.totalDistance))", valueColor: .cyan)
                }
                HStack(spacing: 8) {
                    // Calories 상자
                    InfoBox(title: "Calories", value: "\(formattedEnergyBurned(mapPathViewModel.totalEnergyBurned))", valueColor: .cyan)
                    // Max Speed 상자
                    InfoBox(title: "Max Speed", value: "\(formattedMaxSpeed(mapPathViewModel.maxSpeed)) m/s", valueColor: .cyan)
                }
                
                // 시작 및 종료 시
                if let startDate = mapPathViewModel.workout?.startDate, let endDate = mapPathViewModel.workout?.endDate {
                    Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // 위치 정보
                HStack(spacing: 2) {
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(locationName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .onAppear{
                            let coordinate = CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742)
                            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            fetchLocationName(for: mapPathViewModel.routePoints.first ?? location )
                        }
                }
            } else {
                // 데이터 로딩 중 표시
                ProgressView("Loading Data...")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task{
            if mapPathViewModel.workout != self.workout {
                print("mapPathViewModel will load data in the WatchResultRecord \n workout: \(String(describing: self.workout))    \n mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
                if let workout = self.workout {
                    await  mapPathViewModel.loadWorkoutData(workout: workout)
                    self.mapPathViewModel.workout = self.workout //중복이지만 다시 작성
                    print("mapPathViewModel after loadWorkoutData in the WatchResultRecord \(mapPathViewModel.workout) \(mapPathViewModel.isDataLoaded)")
                    isDataLoaded = true
                }
                else {
                    print("self.workout in the WatchResultRecord is nil")
                    isDataLoaded = true
                }
            } else {
                isDataLoaded = true
                print("mapPathViewModel will not load data  in the WatchResultRecord \n workout: \(String(describing: self.workout)) \n    mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
            }
       
        }
    }

    
    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formattedDistance(_ distance: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let distance = distance else { return "0.00 km" }
        
        // 미터 단위로 값을 가져온 후, 1000으로 나누어 킬로미터로 변환
        let kilometer = distance / 1000
        
        print("kilo: \(kilometer)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%.2f km", kilometer)
    }
    
    func formattedEnergyBurned(_ calories: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let calories = calories else { return "0.00 Kcal" }
        let caloriesInt = Int( calories )
        print("Kcal \(caloriesInt)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%d Kcal", caloriesInt)
    }
    
    func formattedMaxSpeed(_ speed: CLLocationSpeed) -> String {
        return String(format: "%.1f", speed)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd (EEE)"
        return formatter.string(from: date)
    }
    
    func fetchLocationName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "en_US")) { placemarks, error in
            if let placemark = placemarks?.first, let city = placemark.locality {
                self.locationName = city
            } else {
                self.locationName = "Unknown Location"
            }
        }
    }
}

struct WatchResultRecord_Previews: PreviewProvider {
    static var previews: some View {
        WatchResultRecord(
            workout: createDummyWorkout()
        )
    }
    
    static func createDummyWorkout() -> HKWorkout {
        // 더미 HKWorkout 객체 생성
        return HKWorkout(
            activityType: .sailing,
            start: Date(),
            end: Date().addingTimeInterval(3600),
            workoutEvents: nil,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 500),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 10000),
            metadata: [
                "TotalDistance": 10000.0,
                "TotalEnergyBurned": 500.0
            ]
        )
    }
}


struct InfoBox: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.darkGray).opacity(0.3))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        )
    }
}
