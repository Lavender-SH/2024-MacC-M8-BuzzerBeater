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

//HKWorkoutRoute와 중복되겠지만 일단 중복해서 저장하고 HKworkoutRoute의 기능을 파악해나가기로함

struct SailingData : Equatable, Identifiable{
    var id: UUID = UUID()
    var timeStamp: Date
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var boatSpeed: Double  // m/s
    var boatDirection: Double? // deg
    var boatHeading : Double?
    var latitude: Double //deg
    var longitude: Double //deg
}

class SailingDataCollector : ObservableObject {
    static let shared = SailingDataCollector()

    @Published var sailingDataArray: [SailingData] = []

    let locationManager = LocationManager.shared
    let windData = WindDetector.shared
    
    // EnvironmentObject를 사용하는것과 어떻게 다르지?? 항상 햇갈림
    // 모델 vs 모델 인경우  파라메터로 주입시키고 값을 가져다쓰는 방식을 써봄
    //보통 뷰모델일때 @ObservedObject나 @EnvironmentObject를 사용하니까 일단 피함
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        if CLLocationManager().authorizationStatus == .authorizedAlways || CLLocationManager().authorizationStatus == .authorizedWhenInUse  {
                    print("start collect data")
                    self.startCollectingData(locationManager: locationManager )
                } else {
                    print("not authorized to collect data")
                    locationManager.checkAuthorizationStatus()
                }
    }
    
    func startCollectingData(locationManager: LocationManager) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                  self.collectSailingData(locationManager: locationManager)
            
              }
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectSailingData(locationManager: locationManager)
            }
            .store(in: &cancellables)
    }
    func collectSailingData(locationManager: LocationManager) {
        let currentTime = Date()
        let windSpeed = windData.speed ?? 0
        let windDirection = windData.direction
        let boatSpeed =  locationManager.speed
        let boatDirection = locationManager.course
        let boatHeading = locationManager.heading?.trueHeading
        let latitude = locationManager.latitude
        let longitude = locationManager.longitude

        let sailingData = SailingData(id: UUID(),
                                      timeStamp: currentTime,
                                      windSpeed: windSpeed,
                                      windDirection: windDirection,
                                      boatSpeed: boatSpeed,
                                      boatDirection: boatDirection,
                                      boatHeading : boatHeading,
                                      latitude: latitude, longitude: longitude )
        DispatchQueue.main.async {
        
            self.sailingDataArray.append(sailingData)
            print(sailingData)
        }
     
    }
    
    
}
