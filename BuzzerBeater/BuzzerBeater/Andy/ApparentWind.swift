//
//  ApparentWindViewModel.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/7/24.
//


import Combine
import Foundation
import SwiftUI


class ApparentWind : ObservableObject {
    static let shared =  ApparentWind()
    
    @Published  var direction: Double? = nil
    @Published  var speed:  Double? = nil
 
    let windDetector = WindDetector.shared
    let locationManager = LocationManager.shared
    
    var cancellables: Set<AnyCancellable> = []
    
    init()
    {
        startCollectingData()
        
    }
    func startCollectingData() {

        
        Publishers.CombineLatest4(windDetector.$speed, windDetector.$adjustedDirection, locationManager.$heading, locationManager.$lastLocation)
            .throttle(for: .milliseconds(500), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ , _ , _ ,_ in
                self?.calcApparentWind()
                       }
                       .store(in: &cancellables)
        
        
    }
    
    func calcApparentWind(){
        
        guard let windSpeed = windDetector.speed,
              let windDirection  = windDetector.adjustedDirection  else {
            print("wind Data is not available in calcApparentWind")
            return
        }
    
       
 // boatCourse 와 boatSpeed는 locationManager에서 계산한 값만을 사용하고  locationManager에서만 업데이트 한다.
        // boatSpeed == 0 일때 바람의 속도의 50%로 보트가 진행한다고 가정하고 보트가 속도가 있을때는 실제 속도로 계산한다.
        let boatCourse = locationManager.boatCourse
        let boatSpeed = locationManager.boatSpeed == 0 ?  windSpeed * 0.5 : locationManager.boatSpeed
        print("calcApparentWind from trueWind: \(windSpeed) windDirection \(windDirection)")
        print("calcApparentWind from boatSpeed:  \(boatSpeed) boatCourse : \(boatCourse)")
        
        var windX : Double {
            let angle = Angle(degrees: 90 - windDirection)
            
            return  windSpeed  * cos( angle.radians )
        }
        
        var windY : Double {
            let angle = Angle(degrees: 90 - windDirection)
            return  windSpeed  * sin(angle.radians)
        }
        
        var boatX : Double {
            let angle = Angle(degrees: 90 - boatCourse)
            return boatSpeed * cos(angle.radians)
        }
        
        var boatY : Double {
            let angle = Angle(degrees: 90 - boatCourse)
            return boatSpeed * sin(angle.radians)
        }
        
        var apparentWindX : Double  {
            return  windX + boatX
        }
        
        var apparentWindY : Double  {
            return  windY + boatY
        }
        
        speed = sqrt(pow(apparentWindX,2) + pow(apparentWindY,2) )
        
        if speed != 0 {
            direction =  calculateThetaY(x: apparentWindX, y: apparentWindY)   // caclcuateTheta from Y axis   atan(x over  y) 임
        } else
        {
            direction = windDirection
              
        }
// for debugging use
//        print("atan(1,  1) \( atan2( 1, 1) * (180 / Double.pi) )")
//        print("atan(1, -1) \( atan2( 1, -1) * (180 / Double.pi) )")
//        print("atan(-1, -1) \( atan2( -1, -1) * (180 / Double.pi) )")
//        print("atan(-1, 1) \( atan2( -1, 1) * (180 / Double.pi) )")
       
        print("windx \(windX) windy \(windY)")
        print("apparent wind speed \(speed!)")
        print("apparent wind direction dir: \(direction!)  spd:\(speed!) ax: \(apparentWindX) ay: \(apparentWindY)")
    }
    func calculateThetaY(x: Double, y: Double) -> Double {
        let theta = atan2(x, y) * (180 / .pi) // y축에 대한 각도 계산
        return theta < 0 ? theta + 360 : theta // 음수 각도를 양수로 변환
    }

}



