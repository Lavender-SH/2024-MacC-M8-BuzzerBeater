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
    static let shared = SailAngleFind() // Singleton instance
    // sailAngle은 마스트를 중심으로 오른쪽이 플러스 왼쪽을 마이너스로 정의
    @Published  var sailAngle: Angle?
    @Published var sailingPoint : [SailingPoint]?

    
    let windDetector = WindDetector.shared
    let locationManager = LocationManager.shared
    let apparentWind = ApparentWind.shared
    var previousSpeed  : Double = 0
    var previousDirection : Double = 0
    var previousHeading : CLLocationDegrees = 0
    var previousCourse :CLLocationDegrees = 0
    var cancellables: Set<AnyCancellable> = []
 
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.startCollectingData()
        }
    }
    
    func startCollectingData() {
        
        
        Publishers.CombineLatest4( apparentWind.$speed, apparentWind.$direction , locationManager.$heading, locationManager.$course )
            .filter { [weak self] speed, direction, heading, course in
                // 이전 값과 비교하여 1도 이상 변했을 때만 필터 통과
                let speedChange = abs((speed ?? 0 - (self?.previousSpeed ?? 0))) > 0.1
                let directionChange = abs((direction ?? 0 - (self?.previousDirection ?? 0))) > 1
                
                // heading이 nil일 경우에 대한 안전한 처리
                let headingValue = heading?.trueHeading ?? 0.0
                
                let headingChange = abs(headingValue - (self?.previousHeading ?? 0.0)) > 1
                // course
                let courseValue = course
                let courseChange = abs(courseValue - (self?.previousCourse ?? 0.0
                                                     )) > 1
                
                self?.previousSpeed = speed ?? 0
                self?.previousDirection = direction ?? 0
                self?.previousHeading = headingValue
                self?.previousCourse = courseValue
                
                return speedChange || directionChange || headingChange || courseChange
            }
               .sink { [weak self] _, _, _ , _ in
                   DispatchQueue.main.async {
                       self?.calcSailAngle()
                   }
               }
               .store(in: &cancellables)
          
        
    }
    
    
    //0 <= Starboard 쪽 바람 각도 <= 180
    //- 180 <= Port 쪽 바람 각도<=0
    func calcSailAngle(){
        
        guard let trueWindDirection  = windDetector.adjustedDirection else {
            print("True wind Data is not available in calcSailAngle")
            return
        }
        let trueWindSpeed = windDetector.speed
        print("True windDetector is available  speed: \(trueWindSpeed) windDirection \(trueWindDirection)")
        
        let boatSpeed = locationManager.boatSpeed
        let boatDirection = locationManager.boatCourse
        
        print("calcSailAngle from boatSpeed: \(boatSpeed) boatDirection \(boatDirection)")
        
        // 이제 계산 하자
        
        guard let apparentWindDirection = apparentWind.direction ,
               let apparentWindSpeed = apparentWind.speed else {
            
            print("apparent wind direction is nil")
        return
        }
        print("Apparent windDetector is available  speed: \(apparentWindSpeed) apparent windDirection \(apparentWindDirection)")
        // Statboard : 0 < relativeWindDrection < = 180도
        // Port      : - 180 < relativeWindDiretion <=0 가정함.
        
        var relativeWindDirection = fmod( trueWindDirection - boatDirection , 360)
        var relativeApparentWindDirection  = fmod (apparentWindDirection  - boatDirection , 360)
        
        print("relative Wind Direction \(relativeWindDirection)")
        print("relative Apparent Wind Direction \(relativeApparentWindDirection)")
        
        // 왼쪽방향을 넘어서면 오른쪽 방향에서 계산
        if relativeWindDirection <  -180 {
            relativeWindDirection  += 360
        }
        
        if relativeWindDirection > 180 {
            relativeWindDirection -= 360
        }
        
        // 오른쪽 방향을 넘어가면 왼쪽 방향에서 계산
        
        // relativeApparentWind Direction도 위와 동일
        if relativeApparentWindDirection > 180 {
            relativeApparentWindDirection -= 360
        }
        // relativeApparentWind Direction도 조정
        
        if relativeApparentWindDirection <  -180 {
            relativeApparentWindDirection  += 360
        }
        // 오른쪽 방향을 넘어가면 왼쪽 방향에서 계산
        // 바람이 마이너스면 세일은 플러스
        // 바람이 플러스면 세일은 마이넛
        print("relativeWindDirection \(relativeWindDirection)")
        
        if relativeWindDirection > -40 && relativeWindDirection < 40 {
            
            print("no go zone")
            sailingPoint = [.noGoZone]
            sailAngle = Angle(degrees: 0)
            
            print("sailAngle between -40 and -40 r:\(relativeWindDirection) s: \(String(describing: sailAngle))  a: \(relativeApparentWindDirection)")
            
        } else if (relativeWindDirection < -40  && relativeWindDirection > -120) {
            print(".closehauled, .beamReach, .broadReach")
            sailingPoint = [.closehauled, .beamReach, .broadReach]
            sailAngle = min( Angle(degrees: -(relativeApparentWindDirection)), Angle(degrees: 90))
            print("sailAngle between -40 and -120 r:\(relativeWindDirection) s: \(String(describing: sailAngle))  a: \(relativeApparentWindDirection)")
            
            
        } else if (relativeWindDirection > 40  && relativeWindDirection < 120) {
            print(".closehauled, .beamReach, .broadReach")
            sailingPoint = [.closehauled, .beamReach, .broadReach]
            sailAngle = max(Angle(degrees: -(relativeApparentWindDirection)), Angle(degrees: -90))//check apparentWindDirection 90도 이하인지 체크
            print("sailAngle between 40 and 130 r:\(relativeWindDirection) s: \(String(describing: sailAngle)) a: \(relativeApparentWindDirection)")
        }
        else if relativeWindDirection > 120  {
            // 뒷바람 ..sailAngle은 90도
            print("downWind")
            sailingPoint = [.downwind]
            sailAngle = Angle(degrees: -90)
            print("downWind > 145 SailAngle r:\(relativeWindDirection)  s:\(String(describing: sailAngle)) a:\(relativeApparentWindDirection)")
        }
        else if relativeWindDirection < -120 {
            print("downWind")
            sailingPoint = [.downwind]
            sailAngle = Angle(degrees: 90)
            print("downWind < -120 SailAngle r:\(relativeWindDirection) s:\(String(describing: sailAngle)) a:\(relativeApparentWindDirection)")
        }
        
    }
}

