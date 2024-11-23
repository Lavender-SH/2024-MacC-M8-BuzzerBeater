//
//  LastWorkoutSnapShot.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/21/24.
//

import SwiftUI
import HealthKit



struct LastWorkoutSnapShot: View {
  
    
 
    let workoutManager = WorkoutManager.shared
    
    var workout: HKWorkout?
    let healthStore =  HealthService.shared.healthStore
  
    @State var activeEnergyBurned: Double = 0
    @State var isDataLoaded : Bool = false
    
    
    @State var totalEnergyBurned: Double = 0
    @State var totalDistance: Double = 0
    @State var maxSpeed : Double = 0
    @State var duration : TimeInterval = 0
    @State var startDate: Date?
    @State var endDate: Date?
    @State var locationName: String = "Loading location..."
    
    init(workout: HKWorkout) {
        
        self.workout = workout
    }
    
    var body: some View {
        VStack(spacing: 13) { // 전체 줄 간격
            if isDataLoaded {
                // 날짜 표시
                Text(formattedDate(startDate))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                // 상자 그룹
                HStack(spacing: 8) {
                    // Time 상자
                    InfoBox(title: "Time", value: formattedDuration(duration), valueColor: .yellow)
                    // Distance 상자
                    InfoBox(title: "Distance", value: "\(formattedDistance(totalDistance))", valueColor: .cyan)
                }
                HStack(spacing: 8) {
                    // Calories 상자
                    InfoBox(title: "Calories", value: "\(formattedEnergyBurned(totalEnergyBurned))", valueColor: .cyan)
                    // Max Speed 상자
                    InfoBox(title: "Max Speed", value: "\(formattedMaxSpeed(self.maxSpeed)) m/s", valueColor: .cyan)
                }
                
                // 시작 및 종료 시간
                if let startDate = startDate, let endDate = endDate {
                    Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // 위치 정보
                HStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
//                    Text(locationName)
//                        .font(.system(size: 15, weight: .bold, design: .rounded))
//                        .foregroundColor(.secondary)
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
        .onAppear {
            DispatchQueue.main.async {
                guard let workout = workout else { return print("workout is nil in the LastWorkoutSnapShot view") }
                self.totalDistance = workout.metadata?["TotalDistance"] as? Double ?? 0.0
                self.duration = workout.metadata?["Duration"] as? Double ?? 0.0
                self.totalEnergyBurned = workout.metadata?["TotalEnergyBurned"] as? Double ?? 0.0
                self.maxSpeed = workout.metadata?["MaxSpeed"] as? Double ?? 0.0
                self.startDate = workout.startDate
                self.endDate = workout.endDate
                
                self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                    if let activeEnergyBurned = activeEnergyBurned {
                        self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                    }
                }
                self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                    if let totalEnergyBurned = totalEnergyBurned {
                        self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                    }
                }
                
                self.duration = workout.endDate.timeIntervalSince(workout.startDate)
                
                self.isDataLoaded = true
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
    
   func formattedTime(_ date: Date) -> String {
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
 

    func fetchLatestWorkout(completion: @escaping (HKWorkout?) -> Void) {
        let healthStore = HKHealthStore()
        
        // 워크아웃 타입 정의
        let workoutType = HKObjectType.workoutType()
        
        // 쿼리 설정: 워크아웃 시작 시간으로 내림차순 정렬
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let workoutQuery = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let error = error {
                print("Error fetching workouts: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // 가장 최근의 워크아웃을 반환
            if let latestWorkout = results?.first as? HKWorkout {
                completion(latestWorkout)
            } else {
                completion(nil)
            }
        }
        
        // 쿼리 실행
        healthStore.execute(workoutQuery)
    }

}


