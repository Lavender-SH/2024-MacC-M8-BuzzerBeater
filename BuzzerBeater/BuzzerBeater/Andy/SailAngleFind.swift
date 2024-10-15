//
//  SailAngle.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/7/24.
//

import SwiftUI
import Combine
import CoreLocation

enum SailingPoint {
    case closehauled     // 바람을 맞고 항해하는 자세 45도
    case broadReach      // 바람과 거의 옆으로 항해하는 자세 110-140
    case beamReach       // 바람을 옆으로 받아 항해하는 자세 70-110
    case downwind        // 바람을 뒤에서 받으며 항해하는 자세 // 145-180
    case noGoZone        // 못가는 구간 -45~45
    
}

class SailAngleFind: ObservableObject {
    
    // sailAngle은 마스트를 중심으로 오른쪽이 플러스 왼쪽을 마이너스로 정의
    
    @Published  var sailAngle: Double?
    @Published var sailingPoint : [SailingPoint]?
//    @ObservedObject var  apparentWind = ApparentWind()
    
    let apparentWind = ApparentWind.shared
    
    var previousSpeed  : Double = 0
    var previousDirection : Double = 0
    var previousHeading : CLLocationDegrees = 0
    var cancellables: Set<AnyCancellable> = []
    static let shared = SailAngleFind() // Singleton instance
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.startCollectingData()
        }
    }
    
    func startCollectingData() {
        
        
        Publishers.CombineLatest3( apparentWind.$speed, apparentWind.$direction , apparentWind.windData.locationManager.$heading)
            .filter { [weak self] speed, direction, heading in
                // 이전 값과 비교하여 1도 이상 변했을 때만 필터 통과
                let speedChange = abs((speed ?? 0 - (self?.previousSpeed ?? 0))) > 1
                let directionChange = abs((direction ?? 0 - (self?.previousDirection ?? 0))) > 1
                
                // heading이 nil일 경우에 대한 안전한 처리
                let headingValue = heading?.trueHeading ?? 0.0
                let headingChange = abs(headingValue - (self?.previousHeading ?? 0.0)) > 1
                
                self?.previousSpeed = speed ?? 0
                self?.previousDirection = direction ?? 0
                self?.previousHeading = headingValue
                
                return speedChange || directionChange || headingChange
            }
               .sink { [weak self] _, _, _ in
                   self?.calcSailAngle()
               }
               .store(in: &cancellables)
          
        
    }
    
    
    //0 <= Starboard 쪽 바람 각도 <= 180
    //- 180 <= Port 쪽 바람 각도<=0
    func calcSailAngle(){
        
        guard let trueWindSpeed = apparentWind.windData.speed,
              let trueWindDirection  = apparentWind.windData.direction else {
            print("True wind Data is not available in calcSailAngle")
            return
        }
        print("True windData is available  speed: \(trueWindSpeed) windDirection \(trueWindDirection)")
        let boatSpeed =  apparentWind.windData.locationManager.speed
        guard let boatHeading = apparentWind.windData.locationManager.heading?.trueHeading else { return }
        print("calcSailAngle from boatSpeed: \(boatSpeed) boatDirection \(boatHeading)")
        
        // 이제 계산 하자
        
        guard let apparentWindDirection = apparentWind.direction ,
               let apparentWindSpeed = apparentWind.speed else {
            print("apparent wind direction is nil")
        return
        }
        print("Apparent windData is available  speed: \(apparentWindSpeed) windDirection \(apparentWindDirection)")
        // Statboard : 0 < relativeWindDrection < = 180도
        // Port      : - 180 < relativeWindDiretion <=0 가정함.
        
        var relativeWindDirection =  trueWindDirection - boatHeading
        var relativeApparentWindDirection  = apparentWindDirection  - boatHeading
        
        // 왼쪽방향을 넘어서면 오른쪽 방향에서 계싼
        if relativeWindDirection <  -180 {
            relativeWindDirection  += 360
        }
        // 오른쪽 방향을 넘어가면 왼쪽 방향에서 계산
        
        
        if relativeWindDirection > 180 {
            relativeWindDirection -= 360
        }
    
        
        // 바람이 마이너스면 세일은 플러스
        // 바람이 플러스면 세일은 마이넛
        print("relativeWindDirection \(relativeWindDirection)")
        
        
        if relativeWindDirection > -40 && relativeWindDirection < 40 {
            
            print("no go zone")
            sailingPoint = [.noGoZone]
            sailAngle = 0
            
            print("sailAngle between -40 and -40 r:\(relativeWindDirection) s: \(String(describing: sailAngle))  a: \(relativeApparentWindDirection)")
            
        } else if (relativeWindDirection < -40  && relativeWindDirection > -120) {
            print(".closehauled, .beamReach, .broadReach")
            sailingPoint = [.closehauled, .beamReach, .broadReach]
            sailAngle =  -(relativeApparentWindDirection)
            print("sailAngle between -40 and -120 r:\(relativeWindDirection) s: \(String(describing: sailAngle))  a: \(relativeApparentWindDirection)")
            
            
        } else if (relativeWindDirection > 40  && relativeWindDirection < 120) {
            print(".closehauled, .beamReach, .broadReach")
            sailingPoint = [.closehauled, .beamReach, .broadReach]
            sailAngle = -(relativeApparentWindDirection) //check apparentWindDirection 90도 이하인지 체크
            print("sailAngle between 40 and 130 r:\(relativeWindDirection) s: \(String(describing: sailAngle)) a: \(relativeApparentWindDirection)")
        }
        else if relativeWindDirection > 120  {
            // 뒷바람 ..sailAngle은 90도
            print("downWind")
            sailingPoint = [.downwind]
            sailAngle = -90
            print("downWind > 145 SailAngle r:\(relativeWindDirection)  s:\(String(describing: sailAngle)) a:\(relativeApparentWindDirection)")
        }
        else if relativeWindDirection < -120 {
            print("downWind")
            sailingPoint = [.downwind]
            sailAngle = 90
            print("downWind < -120 SailAngle r:\(relativeWindDirection) s:\(String(describing: sailAngle)) a:\(relativeApparentWindDirection)")
        }
        
    }
}
