//
//  Untitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/5/24.
//
import Foundation
import SwiftUI
import Combine
import CoreLocation
import HealthKit

//HKWorkoutRoute와 중복되겠지만 일단 중복해서 저장하고 HKworkoutRoute의 기능을 파악해나가기로함

struct SailingDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date

    var latitude: Double //deg
    var longitude: Double //deg
  
    var boatSpeed: Double  // m/s
    var boatCourse: Double // deg
    var boatHeading : Double?
    
    var windSpeed: Double?  // m/s
    var windDirection: Double?  //deg
    var windCorrectionDetent : Double
       
}

class SailingDataCollector : ObservableObject {
    static let shared = SailingDataCollector()

    @Published var sailingDataPointsArray: [SailingDataPoint] = []

    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    
    var startDate :Date = Date()
    var endDate  : Date = Date()
    
    // EnvironmentObject를 사용하는것과 어떻게 다르지?? 항상 햇갈림
    // 모델 vs모델 인경우  파라메터로 주입시키고 값을 가져다쓰는 방식을 써봄
    //보통 뷰모델일때 @ObservedObject나 @EnvironmentObject를 사용하니까 일단 피함
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        if CLLocationManager().authorizationStatus == .authorizedAlways || CLLocationManager().authorizationStatus == .authorizedWhenInUse  {
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
          cancellables.removeAll() // 구독을 모두 취소하여 타이머 중지
      }
    
    func startCollectingData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                  self.collectSailingData()
            
              }
        
        let timerPublisher60 = Timer.publish(every: 60, on: .main,  in: .common)
        let timerPublisher01 = Timer.publish(every: 3, on:  .main, in :.common)
        
        timerPublisher60
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectSailingData()
            }
            .store(in: &cancellables)
        
    // 15이상 값이 바뀌면 저장함.
        
       timerPublisher01
            .autoconnect()
            .sink  { [weak self] _ in
                
                if self?.isHeadingChange(by: 15) == true {
                    print("isHeadingChange == true")
                    self?.collectSailingData()
                }
            }
            .store(in: &cancellables)
        
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
    
    
    func collectSailingData() {
        
        let currentTime = Date()
        let latitude = locationManager.latitude
        let longitude = locationManager.longitude
  
        let boatSpeed =  locationManager.boatSpeed
        
        //boatSpeed == 0 이면 locationManager에서  boatCourse = locationManager.heading?.trueHeading
        //boatSpeed > 0 이면  boatCourse = locationManager.course
        
        let boatCourse = locationManager.boatCourse
        let boatHeading = locationManager.heading?.trueHeading   // 값이 존재하지 않으면  nil
        
        let windSpeed = windDetector.speed
        let windDirection = windDetector.direction
        let windCorrectionDetent = windDetector.windCorrectionDetent
      
        let sailingDataPoint = SailingDataPoint(id: UUID(),
                                                timeStamp: currentTime,
                                                latitude: latitude,
                                                longitude: longitude,
                                                boatSpeed: boatSpeed,
                                                boatCourse: boatCourse,
                                                boatHeading: boatHeading,
                                                windSpeed: windSpeed,
                                                windDirection: windDirection,
                                                windCorrectionDetent: windCorrectionDetent
         )
        
        self.sailingDataPointsArray.append(sailingDataPoint)
        print("SailingDataPointsArray count:\(self.sailingDataPointsArray.count) data: \(String(describing: self.sailingDataPointsArray.last))")
        
        
    }
    
    
}

