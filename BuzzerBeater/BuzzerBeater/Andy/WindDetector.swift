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
    var wind: Wind
    var timestamp: Date
}

class WindDetector : ObservableObject{
    static let shared = WindDetector()
    
//    @ObservedObject var locationManager = LocationManager()
 
    @Published var currentWind: WindData?
    @Published var timestamp :Date?
    @Published var direction: Double?
    @Published var speed: Double?
    @Published var gust: Measurement<UnitSpeed>?
    @Published var adjustedDirection : Double?
    
    
    @Published var windCorrectionDetent: Double = 0 {
        didSet {
        
            if let direction = self.direction {
                self.adjustedDirection = direction + self.windCorrectionDetent
                print("Updated windCorrectionDetent in the WindDetector:  \(windCorrectionDetent)")
            }
        }
    }

    let  locationManager = LocationManager.shared
    var timer: AnyCancellable?
    
    init() {
       
        startCollectingWind()
        
    }
    
    func startCollectingWind() {

        let shared = LocationManager.shared
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task {
                print("Fectching wind in the disptach")
                if let location =  shared.lastLocation {
                    await self.fetchCurrentWind(for: location)
                }
            }
        }
        
        timer =  Timer.publish(every: 60 * 10 , on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    print("Fectching wind in the timer")
                    if let location =  shared.lastLocation {
                        await self?.fetchCurrentWind(for: location)
                    }
                }
            }
        
    }
    
    func fetchCurrentWind(for location: CLLocation) async  {
        // WeatherService에도  Singleton 으로 인스턴스를 만드는  shared 변수가 있음.
        let weatherService =  WeatherService.shared
        let location = location
        print("fetchCurrentWind  in the WindDetector :\(weatherService) at \(location).\n")
        
        Task {
            do {
                //try! await weatherService.weather(for: syracuse)
                
                let weather = try await weatherService.weather(for: location)
            
                let currentWind = weather.currentWeather.wind
                let currentWindCompassDirection = weather.currentWeather.wind.compassDirection
                
                // @Published 는  UI와 관련이있으므로 main thread를 사용해서  update 해줘야 한다고 봄.
                DispatchQueue.main.async {
                    
                    self.currentWind?.timestamp = Date.now
                    self.currentWind?.wind = currentWind
                    self.timestamp = Date.now
                    // direction 을  winDetecor class에서 보정값을 더해서  Direction을 계산.
                    self.direction = currentWind.direction.value > 0 ? currentWind.direction.value : 0
                    self.adjustedDirection = currentWind.direction.value + self.windCorrectionDetent
                    self.speed = currentWind.speed.value > 0 ? currentWind.speed.value  : 0
                    print("timestamp : \(self.timestamp!)")
                    print("location lat: \(location.coordinate.latitude) long:\(location.coordinate.longitude)")
                    print("Current wind speed: \(currentWind.speed.value) m/s")
                    print("Current wind direction: \(String(describing: self.direction))°  adjusted: \(String(describing: self.adjustedDirection))°")
                }
                
                
            } catch {
                print("Failed to fetch weather: \(error) \n")
            }
        }
    }
    
}

