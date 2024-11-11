//
//  Untitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/4/24.
//
// 현재는 locationManager가 정보가 업데이트만 되면 계속 호출되는데 이것은 리소스 낭비가 됨
// 추후에는 필요할때만 locationManager => True Wind update => ApparentWindUpdate => SailingAngleUpdate => SailingDataCollector
// 이순서대로 한번씩만 실행되게 하면 좀더 효율적으로 작동할것임.
//
//  Untitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/4/24.
//
// 현재는 locationManager가 정보가 업데이트만 되면 계속 호출되는데 이것은 리소스 낭비가 됨
// 추후에는 필요할때만 locationManager => True Wind update => ApparentWindUpdate => SailingAngleUpdate => SailingDataCollector
// 이순서대로 한번씩만 실행되게 하면 좀더 효율적으로 작동할것임

// DELEGATE method모두 없애고 Combine/Publisher로하기로 함
import SwiftUI
import CoreLocation
import Combine

enum LocationError: LocalizedError {
    case noLocations
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noLocations:
            return "No locations found for this route."
        case .queryFailed(let error):
            return "Failed to fetch locations: \(error.localizedDescription)"
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Singleton instance
    var locationManager = CLLocationManager()
    
    // PassthroughSubjects for location and heading updates
    let locationPublisher = PassthroughSubject<CLLocation, Never>()
    let headingPublisher = PassthroughSubject<CLHeading, Never>()
    let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    
    var cancellables: Set<AnyCancellable> = []
    
    @Published var speed: CLLocationSpeed = 0.0 // 속도 (m/s)
    @Published var course: CLLocationDirection = 0.0 // 이동 방향 (degrees)
    @Published var heading: CLHeading? // 나침반 헤딩 정보
    @Published var latitude: CLLocationDegrees = 0.0
    @Published var longitude: CLLocationDegrees = 0.0
    @Published var showAlert : Bool = false
    @Published var lastLocation: CLLocation?
    
    
    private var updateTimer: Timer?
    // 계산이나 회전을 위해서 아래 두 변수를 사용하기로 한다.  예를 들면 화면에 보여질때 보트스피드가 0인경우  direction값은 -1일테니까 이런경우  heading으로 값을 정한다.
    
    @Published var boatCourse : CLLocationDirection = 0.0
    @Published var boatSpeed :  CLLocationSpeed = 0.0 // 속도 (m/s)
    
    @Published var previousBoatCourse: CLLocationDirection = 0.0
    @Published var previousBoatSpeed :  CLLocationSpeed = 0.0 // 속도 (m/s)
    
    private var lastHeading : CLHeading?
    
    let distanceFilter = 1.0
    let headingFilter  = 1.0
    let locationUpdateTimeInterval = 3
    let boatSpeedBuffer = 0.3
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = distanceFilter
        locationManager.headingFilter = headingFilter
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
        
        authorizationStatusSubject
            .sink { [weak self] status in
                      self?.handleAuthorizationStatus(status)
                  }
                  .store(in: &cancellables)
        
    }
    
    deinit {
        
        stopUpdatingLocationAndHeading()
    }
    
    func handleAuthorizationStatus(_ status: CLAuthorizationStatus ) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            
            print("authorizedWhenInUse or authorizedAlways")
//            locationManager.startUpdatingLocation()
//            locationManager.startUpdatingHeading()
//            startLocationUpdateTimer()
          //Combine Publiser방식으로 전환
            startUpdatingLocationAndHeading()
            showAlert = false
            
        case .denied, .restricted:
            print("denied or restricted")
            showAlert = true
            
        case .notDetermined:
            print("Authorization not determined.")
            locationManager.requestWhenInUseAuthorization()
            showAlert = false
            
        @unknown default:
            showAlert = true
            
        }
    }
    
    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        print("locationManagerStatus \(status)")
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            authorizationStatusSubject.send(status)
        }
    }
    // GPS Info
//    private func startLocationUpdateTimer() {
//        updateTimer = Timer.scheduledTimer(withTimeInterval: locationUpdateTimeInterval, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            self.locationManager.requestLocation()
//            if let location = self.locationManager.location {
//                self.updateLocation(location)
//                self.locationPublisher.send(location)
//            }
//        }
//    }
//
    private func startLocationUpdateTimer() {
      Timer.publish(every: TimeInterval(locationUpdateTimeInterval), on: .main, in: .common)
            .autoconnect() // Timer가 자동으로 시작하도록 설정
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.locationManager.requestLocation()
                if let location = self.locationManager.location {
                    self.updateLocation(location)
                    self.locationPublisher.send(location)
                }
            } .store(in: &cancellables)
    }
    private func updateLocation(_ location: CLLocation) {
        
        DispatchQueue.main.async {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.speed = max(location.speed, 0)
            self.course = max(location.course, 0)
            self.lastLocation = location
            self.previousBoatCourse  = self.boatCourse
            self.previousBoatSpeed = self.boatSpeed
            
            self.boatSpeed = self.speed
            // 약간의 버퍼를 주자
            self.boatCourse = self.boatSpeed > self.boatSpeedBuffer ? self.course : self.heading?.trueHeading ?? 0
            print("didUpdateLocations: lat: \(String(format: "%.4f", self.latitude)) lon: \(String(format: "%.4f", self.longitude))  speed:\(self.boatSpeed)m/s course:\(String(format: "%f", self.boatCourse))º")
            
        }
    }
    
    private func updateHeading(_ heading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = heading
            self.lastHeading = heading
            self.boatCourse = self.boatSpeed > self.boatSpeedBuffer ? self.course : heading.trueHeading
            
            print("didUpdateHeading: speed: \(self.boatSpeed)m/s course: \(String(format: "%.f", self.boatCourse))º")
        }
    }
    // 나중이라도  locationManager.speed == 0 이 되는 상황이 수시로 발생할수있다는 점을 염두에 두어야함
    // 이런경우에 일정 시간 전짜기는 직전  direction이 유효한것으로 간주하고 일정기간 사용해야하며 그게 지난다면  locationManager.heading?.trueHeading 값으로 변경해서 사용해야함
    // 현재는 센서로 부터 들어오는 값이 일관성이 있다고 가정함  즉 계속 유효한 데이터가 들어옴
    // 추후에  CoreLocation에서 들어오는 정보가 맞지 않는다면 Noise Reduction을 해주어야함.
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            self.lastLocation = newLocation
            locationPublisher.send(newLocation)
        }
        return
    }
    // Magnetic Info : 그래서 분리했음.
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
      //  주의 :  sef.course 가 유효한 값인지 꼭 체크해볼 필요가있음
       
        headingPublisher.send(newHeading)

        return
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed with error: \(error.localizedDescription)")
        let clError = error as? CLError
               switch clError?.code {
               case .denied:
                   // 위치 서비스가 거부된 경우
                   showAlert(message: "위치 서비스가 비활성화되었습니다. 설정에서 활성화해주세요.")
               case .locationUnknown:
                   // 위치를 찾을 수 없는 경우
                   showAlert(message: "현재 위치를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.")
               case .network:
                   // 네트워크 문제로 인한 경우
                   showAlert(message: "네트워크 연결을 확인해주세요.")
               default:
                   // 기타 오류
                   showAlert(message: "위치 업데이트에 실패했습니다. 다시 시도해주세요.")
               }
    }
    private func showAlert(message: String) {
            // 사용자에게 경고 메시지 표시
          
            print(message) // 대체로는 사용자에게 알림을 띄우는 방법을 사용
        }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
       
        let status = manager.authorizationStatus
        authorizationStatusSubject.send(status)
        
    }
   
    // 나중 콤바인은 정리 !!!
    func startUpdatingLocationAndHeading() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        startLocationUpdateTimer()
        
        locationPublisher
            .compactMap { $0 }
            .filter { [weak self] newLocation in
                print("filtered location\(newLocation)")
                guard let lastLocation = self?.lastLocation else {
                    self?.lastLocation = newLocation
                    return true // 첫 번째 위치는 항상 퍼블리시
                }
                print("filtered location\(newLocation)")
                let distance = newLocation.distance(from: lastLocation)
                if distance >= self?.distanceFilter  ?? 3 {
                    // 10m 이상 차이날 때만 업데이트
                    return true
                } else {
                    return false
                }
            }
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)
        
        headingPublisher
            .compactMap { $0 }
            .filter { [weak self] newHeading in
                guard let lastHeading = self?.lastHeading else {
                    self?.lastHeading = newHeading
                    return true // 첫 번째 값은 항상 퍼블리시
                }
                let angleDifference = abs(newHeading.trueHeading - lastHeading.trueHeading)
                if angleDifference >= self?.headingFilter ?? 1 {
                    self?.lastHeading = newHeading // 차이가 15도 이상일 때만 업데이트
                    return true
                } else {
                    return false
                }
            }
            .sink { [weak self] heading in
                self?.updateHeading(heading)
                if let lastLocation = self?.lastLocation {
                    self?.updateLocation(lastLocation)
                }
            }
            .store(in: &cancellables)
        
       
        
    }
    
    func stopUpdatingLocationAndHeading() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        if updateTimer != nil {
            updateTimer?.invalidate()
        }
        cancellables.removeAll()
    }
}


