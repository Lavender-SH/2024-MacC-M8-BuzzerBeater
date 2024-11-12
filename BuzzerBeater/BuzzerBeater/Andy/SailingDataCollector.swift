//
//  Untitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/5/24.
//
import Combine
import CoreLocation
import Foundation
import HealthKit
import SwiftUI


//HKWorkoutRoute와 중복되겠지만 일단 중복해서 저장하고 HKworkoutRoute의 기능을 파악해나가기로함

struct SailingDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date
    
    var latitude: Double //deg
    var longitude: Double //deg
    
    var boatSpeed: Double  // m/s
    var boatCourse: Double // deg
    var boatHeading : Double?
    
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var windAdjustedDirecton: Double?
    
}

class SailingDataCollector : ObservableObject {
    static let shared = SailingDataCollector()
    
    @Published var sailingDataPointsArray: [SailingDataPoint] = []
    
    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    
    var startDate :Date?
    var endDate  : Date?
    
    // EnvironmentObject를 사용하는것과 어떻게 다르지?? 항상 햇갈림
    // 모델 vs모델 인경우  파라메터로 주입시키고 값을 가져다쓰는 방식을 써봄
    //보통 뷰모델일때 @ObservedObject나 @EnvironmentObject를 사용하니까 일단 피함
    var cancellables: Set<AnyCancellable> = []
    
    private var lastLocation: CLLocation?
    private var lastHeading: CLHeading?
    
    private let locationChangeThreshold: CLLocationDistance = 10.0 // 10 meters
    private let headingChangeThreshold: CLLocationDegrees = 15.0   // 15 degrees
    
    
    init() {
        if locationManager.locationManager.authorizationStatus == .authorizedAlways || locationManager.locationManager.authorizationStatus == .authorizedWhenInUse  {
            print("start collect data")
            self.startCollectingData()
        } else {
            print("not authorized to collect data")
            locationManager.checkAuthorizationStatus()
        }
    }
    
    
    deinit {
        stopTimers() // 클래스가 소멸될 때 모든 타이머 종료
    }
    // heading이 15도 이상 바뀌었을때도 고려해서 넣어주자.
    func stopTimers() {
        
        endDate = Date()
        cancellables.removeAll() // 구독을 모두 취소하여 타이머 중지
        // 어딘가 저장하는 루틴을 여기다 만들까?? 만약에 헬쓰킷을 안쓴다면.. 
        
        
    }
    
    func startCollectingData() {
        self.startDate = Date()
        Publishers.CombineLatest3(LocationManager.shared.locationPublisher, LocationManager.shared.headingPublisher, WindDetector.shared.windPublisher)
            .sink { [weak self] newLocation, newHeading, newWind in
                DispatchQueue.main.async {
                    self?.handleLocationAndHeadingUpdate(newLocation: newLocation, newHeading: newHeading, newWind: newWind)
                    
                }
            }
            .store(in: &cancellables)
        
    }
    private func handleLocationAndHeadingUpdate(newLocation: CLLocation, newHeading: CLHeading, newWind: WindData) {
        // 위치 변화량 검사
        if let lastLocation = lastLocation {
            let distance = newLocation.distance(from: lastLocation)
            if distance < locationChangeThreshold {
                return // 위치 변화가 충분하지 않으면 업데이트하지 않음
            }
        }
        
        // 헤딩 변화량 검사
        if let lastHeading = lastHeading {
            let angleDifference = abs(newHeading.trueHeading - lastHeading.trueHeading)
            if angleDifference < headingChangeThreshold {
                return // 헤딩 변화가 충분하지 않으면 업데이트하지 않음
            }
        }
        
        // 조건에 만족하는 경우에만 updateData 호출
        updateData(location: newLocation, heading: newHeading, wind: newWind)
        
        // 마지막 위치와 헤딩 업데이트
        lastLocation = newLocation
        lastHeading = newHeading
    }
    
    func updateData(location: CLLocation, heading: CLHeading, wind: WindData) {
        //  클라스에 제대로 데이타가 들어가있다고 가정
        
        print("Received updated location and heading in SailingDataCollector")
        let currentTime = Date()
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        let boatSpeed =  location.speed
        
        //boatSpeed == 0 이면 locationManager에서  boatCourse = locationManager.heading?.trueHeading
        //boatSpeed > 0 이면  boatCourse = locationManager.course
        
        let boatCourse = location.course
        let boatHeading = heading.trueHeading  // 값이 존재하지 않으면  nil
        
        let windSpeed = wind.speed
        let windDirection = wind.direction
        let windAdjustedDirection = wind.adjustedDirection
        
        let sailingDataPoint = SailingDataPoint(id: UUID(),
                                                timeStamp: currentTime,
                                                latitude: latitude,
                                                longitude: longitude,
                                                boatSpeed: boatSpeed,
                                                boatCourse: boatCourse,
                                                boatHeading: boatHeading,
                                                windSpeed: windSpeed,
                                                windDirection: windDirection,
                                                windAdjustedDirecton: windAdjustedDirection
        )
        
        self.sailingDataPointsArray.append(sailingDataPoint)
        print("SailingDataPointsArray count:\(self.sailingDataPointsArray.count) data: \(String(describing: self.sailingDataPointsArray.last))")
        
    }
    
    
    func isHeadingChange(by: Double) -> Bool {
        
        if locationManager.boatSpeed > 0.3 {
            let currentAngle = Int(locationManager.boatCourse)
            let previousAngle = Int(locationManager.previousBoatCourse)
            let difference =  locationManager.boatCourse  - locationManager.previousBoatCourse
            print("difference Angle current: \(currentAngle) prev: \(previousAngle)")
            
            if  difference > by {
                return true
            }
        } else {
            print("boat Speed is 0")
            return false
        }
        
        
        return false
        
    }
    
}

