//
//  WindDetector.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/6/24.
//
import CoreLocation
import Combine
import Foundation
import SwiftUI
import WeatherKit


struct WindData  {
 
    var timestamp: Date
    var direction: Double?
    var adjustedDirection: Double?
    var speed : Double
    var wind: Wind
}

class WindDetector : ObservableObject{
    static let shared = WindDetector()
    
//    @ObservedObject var locationManager = LocationManager()
    @Published var lastWind: WindData?
    @Published var timestamp :Date?
    @Published var direction: Double?
    @Published var speed: Double?
    @Published var gust: Measurement<UnitSpeed>?
    @Published var adjustedDirection : Double?
    
    let windPublisher = PassthroughSubject<WindData, Never>()
    @Published var windCorrectionDetent: Double = 0 {
        didSet {
            if let direction = self.direction {
                self.adjustedDirection = direction + self.windCorrectionDetent
                print("Updated windCorrectionDetent in the WindDetector:  \(windCorrectionDetent)")
            }
        }
    }

    let locationManager = LocationManager.shared
    let windUpdateTimeInterval: TimeInterval = 60 * 30  // 30 minutes in second
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        startCollectingWind()
    }
    
    deinit {
        cancellables.removeAll()  // This ensures all subscriptions are canceled.
        print("WindDetector deinitialized, subscriptions canceled.")
    }
    
    func startCollectingWind() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task {
                print("Fectching wind in the disptach")
                if let location =  self.locationManager.lastLocation {
                    if let windData =  await self.fetchCurrentWind(for: location) {
                        self.windPublisher.send(windData)
                    } else {
                        print("Failed to fetch wind data")
                    }
                } else {
                    print("lastLocation is nil")
                }
            }
        }
     Timer.publish(every: self.windUpdateTimeInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    print("Fectching wind in the timer")
                    if let location =  self?.locationManager.lastLocation {
                        if let windData =  await self?.fetchCurrentWind(for: location) {
                            self?.windPublisher.send(windData)
                        } else {
                            print("Failed to fetch wind data")
                        }
                    }
                }
            }.store(in:&cancellables)
    }
    func fetchCurrentWind(for location: CLLocation) async  -> WindData? {
        // WeatherService에도  Singleton 으로 인스턴스를 만드는  shared 변수가 있음.
        let weatherService =  WeatherService.shared
        let location = location
        print("fetchCurrentWind  in the WindDetector :\(weatherService) at \(String(describing: location)).\n")
        
        do {
            //try! await weatherService.weather(for: syracuse)
            
            let weather = try await weatherService.weather(for: location)
            
            let currentWind = weather.currentWeather.wind
            let currentWindCompassDirection = weather.currentWeather.wind.compassDirection
            // 필요한 WindData를 생성합니다.
            let windData = WindData(
                timestamp: Date.now,
                direction: currentWind.direction.value > 0 ? currentWind.direction.value : 0,
                adjustedDirection: currentWind.direction.value + self.windCorrectionDetent,
                speed : currentWind.speed.value > 0 ? currentWind.speed.value  : 0,
                wind : currentWind
            )
            // @Published 는  UI와 관련이있으므로 main thread를 사용해서  update 해줘야 한다고 봄.
            DispatchQueue.main.async {
                self.lastWind?.wind = currentWind
                self.lastWind?.timestamp = Date.now
                self.lastWind?.direction = currentWind.direction.value > 0 ? currentWind.direction.value : 0
                self.lastWind?.adjustedDirection = currentWind.direction.value + self.windCorrectionDetent
                self.lastWind?.speed = currentWind.speed.value > 0 ? currentWind.speed.value  : 0
                
                self.timestamp = Date.now
                
                self.direction = currentWind.direction.value > 0 ? currentWind.direction.value : nil
                
                if self.direction != nil {
                    self.adjustedDirection = currentWind.direction.value + self.windCorrectionDetent
                }
                else {
                    self.adjustedDirection = nil                }
                
                self.speed = currentWind.speed.value > 0 ? currentWind.speed.value  : 0
                print("timestamp : \(self.timestamp!)")
                print("location lat: \(location.coordinate.latitude) long:\(location.coordinate.longitude)")
                print("Current wind speed: \(currentWind.speed.value) m/s")
                print("Current wind direction: \(String(describing: self.direction))°  adjusted: \(String(describing: self.adjustedDirection))°")
            }
            return windData
            
        } catch {
            print("Failed to fetch weather: \(error) \n")
            return nil
        }
    }
}

