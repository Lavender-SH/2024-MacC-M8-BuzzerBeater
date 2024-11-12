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
 
    var timestamp: Date?
    var direction: Double?
    var adjustedDirection: Double?
    var compassDirection: Wind.CompassDirection?
    var speed : Double
    var wind: Wind?
}

class WindDetector : ObservableObject{
    static let shared = WindDetector()
    let locationManager = LocationManager.shared

    @Published var lastWind: WindData?
    @Published var timestamp :Date?
    @Published var direction: Double?
    @Published var adjustedDirection : Double?
    @Published var compassDirection: Wind.CompassDirection?
    @Published var speed: Double = 0
    //    @Published var gust: Measurement<UnitSpeed>?
    let windPublisher = PassthroughSubject<WindData, Never>()
    @Published var windCorrectionDetent: Double = 0 {
        didSet {
            if let direction = self.direction {
                self.adjustedDirection = direction + self.windCorrectionDetent
                print("Updated windCorrectionDetent in the WindDetector:  \(windCorrectionDetent)")
            }
        }
    }

    let windUpdateTimeInterval: TimeInterval = 60 * 30 //30 minutes in second
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        print("windDetector initialized")
        startCollectingWind()
    }
    
    deinit {
        cancellables.removeAll()  // This ensures all subscriptions are canceled.
        print("WindDetector deinitialized, subscriptions canceled.")
    }
    
    func startCollectingWind() {
        //location 감지되는 시간이 지나고 나서 윈드를 감지해야해서.
        
        //처음은 바로 가져오고 그 다음부터는 타이머에서 가져옴
       
        DispatchQueue.main.asyncAfter(deadline: .now() +  1) { [weak self] in
            guard let self = self else {
                print("self is nil in the windDetector")
                return }
            Task {
                while self.locationManager.lastLocation == nil {
                    print("Waiting for lastLocation to be available...")
                    do {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초마다 체크
                    } catch {
                        print("error in waiting for lastLocation: \(error)")
                    }
                }
                
                print("Fectching wind in the disptach")
                
                if let location =  self.locationManager.lastLocation {
                    if let windData =  await self.fetchCurrentWind(for: location) {
                        print("publish the windData in the windDetector")
                        self.windPublisher.send(windData)
                    } else {
                        print("Failed to fetch wind data")
                    }
                } else {
                    print("lastLocation is nil in the windDetector. Wind data will not be published.")
                }
            }
        }
        
     Timer.publish(every: self.windUpdateTimeInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    print("Fectching wind in the timer")
                    if let location =  self.locationManager.lastLocation {
                        if let windData =  await self.fetchCurrentWind(for: location) {
                            print("publish the windData in the windDetector")
                            self.windPublisher.send(windData)
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
           
            // @Published 는  UI와 관련이있으므로 main thread를 사용해서  update 해줘야 한다고 봄.
            // View관련 변수 업데이
            DispatchQueue.main.async {
                self.timestamp = Date.now
                self.direction = currentWind.direction.value > 0 ? currentWind.direction.value : nil
                if self.direction != nil {
                    self.adjustedDirection = currentWind.direction.value + self.windCorrectionDetent
                }
                else {
                    self.adjustedDirection = nil
                }
                self.compassDirection = currentWindCompassDirection
                self.speed = currentWind.speed.value > 0 ? currentWind.speed.value  : 0
                
                print("timestamp : \(String(describing: self.timestamp))")
                print("location lat: \(location.coordinate.latitude) long:\(location.coordinate.longitude)")
                print("Current wind speed: \(currentWind.speed.value) m/s")
                print("Current wind direction: \(String(describing: self.direction))°  adjusted: \(String(describing: self.adjustedDirection))°")
                
                self.lastWind?.wind = currentWind
                self.lastWind?.timestamp = self.timestamp
                self.lastWind?.direction = self.direction
                self.lastWind?.adjustedDirection = self.adjustedDirection
                self.lastWind?.compassDirection = self.compassDirection
                self.lastWind?.speed = self.speed
            }
            return self.lastWind
            
        } catch {
            print("Failed to fetch weather: \(error) \n")
            return nil
        }
    }
}

