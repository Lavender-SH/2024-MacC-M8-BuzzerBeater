//
//  Untitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/4/24.
//
// 현재는 locationManager가 정보가 업데이트만 되면 계속 호출되는데 이것은 리소스 낭비가 됨
// 추후에는 필요할때만 locationManager => True Wind update => ApparentWindUpdate => SailingAngleUpdate => SailingDataCollector
// 이순서대로 한번씩만 실행되게 하면 좀더 효율적으로 작동할것임.

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Singleton instance
    var locationManager = CLLocationManager()
    
    @Published var speed: CLLocationSpeed = 0.0 // 속도 (m/s)
    @Published var course: CLLocationDirection = 0.0 // 이동 방향 (degrees)
    @Published var heading: CLHeading? // 나침반 헤딩 정보
    @Published var latitude: CLLocationDegrees = 0.0
    @Published var longitude: CLLocationDegrees = 0.0
    @Published var showAlert : Bool = false
    @Published var  lastLocation: CLLocation?
    // 계산이나 회전을 위해서 아래 두 변수를 사용하기로 한다.  예를 들면 화면에 보여질때 보트스피드가 0인경우  direction값은 -1일테니까 이런경우  heading으로 값을 정한다.
    
    @Published var boatCourse : CLLocationDirection = 0.0
    @Published var boatSpeed :  CLLocationSpeed = 0.0 // 속도 (m/s)

    let distanceFilter = 0.5
    let headingFilter  = 1.0
    
        
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = distanceFilter
        locationManager.headingFilter = headingFilter
    
        // locationSericeEnable 체크는 필요없나???
        checkAuthorizationStatus()
       
    }
    
    func checkAuthorizationStatus() {
        switch locationManager.authorizationStatus  {
                
        case .authorizedWhenInUse , .authorizedAlways :
                print("authorizedWhenInUse or authorizedAlways ")
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
            
            case .denied, .restricted:
                print("denied or restricted")
            case .notDetermined:
                print("notDetermined. requestWhenInUseAuthorization")
                locationManager.requestWhenInUseAuthorization()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.checkAuthorizationStatus() // 권한 요청 후
                }
            default:
                return
            }
        }
// GPS Info
    
// 나중이라도  locationManager.speed == 0 이 되는 상황이 수시로 발생할수있다는 점을 염두에 두어야함
// 이런경우에 일정 시간 전짜기는 직전  direction이 유효한것으로 간주하고 일정기간 사용해야하며 그게 지난다면  locationManager.heading?.trueHeading 값으로 변경해서 사용해야함
// 현재는 센서로 부터 들어오는 값이 일관성이 있다고 가정함  즉 계속 유효한 데이터가 들어옴
// 추후에  CoreLocation에서 들어오는 정보가 맞지 않는다면 Noise Reduction을 해주어야함.
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
               // 음수인 경우 0으로 처리함
               // speed와  course는 CoreLocation에서 받는 정보지만 다시 boatSpeed와 boatCourse로 값을 산정함
                //boatCourse는 스피드가 0일때는 direction대신에 location.heading?.trueHeading정보를 사용했고 배의 속도가 0보다 클때는 가는 방향을 뱃머리가 가르킬수있도록 함
                
                self.speed = location.speed  > 0 ?  location.speed : 0
                self.course = location.course > 0 ? location.course : 0
              
                self.latitude = location.coordinate.latitude
                self.longitude  = location.coordinate.longitude
                self.lastLocation = location
                
               // sef.course 가 유효한 값인지 꼭 체크해볼 필요가있음
                if self.speed > 0.0 {
                    self.boatSpeed = self.speed
                    self.boatCourse = self.course
                } else {
                    self.boatSpeed = 0
                    self.boatCourse = self.heading?.trueHeading ?? 0
                }
                
                print("didUpdateLocations: speed: \(self.boatSpeed)m/s course: \(String(format: "%.2f", self.boatCourse))º")

            }
        }
    }
// Magnetic Info : 그래서 분리했음.
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    
        //주의 :  sef.course 가 유효한 값인지 꼭 체크해볼 필요가있음
        
        DispatchQueue.main.async {
            self.heading = newHeading
            if self.speed > 0  {
                self.boatSpeed = self.speed
                self.boatCourse = self.course
             
            } else {
                self.boatSpeed = 0
                self.boatCourse = self.heading?.trueHeading ?? 0
            
            }
            
            print("didUpdateHeading: speed: \(self.boatSpeed)m/s course: \(String(format: "%.2f", self.boatCourse))º")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

            switch manager.authorizationStatus {
            case .authorizedWhenInUse , .authorizedAlways:
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
                showAlert = false
            case .denied, .restricted:
               showAlert = true
                print("denied")
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                showAlert = false
            default:
                showAlert = false
                return
            }
        }
    
}

