# Wind Talker - 세계 최초 센서 기반 요트 세일링앱

<img src="https://github.com/user-attachments/assets/f198009e-20cd-4694-83ad-4fda62541344" width="20%">

- [News Article - Apple Developer Academy @ POSTECH 공식 뉴스 기사](https://developeracademy.postech.ac.kr/news/%ED%8F%AC%ED%95%AD%EC%97%90-%EC%84%B8%EC%9A%B4-'%EC%95%A0%ED%94%8C-%EA%B0%9C%EB%B0%9C%EC%9E%90-%EC%82%AC%EA%B4%80%ED%95%99%EA%B5%90'%E2%80%A655%EC%82%B4-%EC%A6%9D%EA%B6%8C%EB%A7%A8%EB%8F%84-%EA%BF%88-%EC%AB%92%EC%95%84%EC%99%94%EB%8B%A4)</br>

- [실제 Apple 홍보에 쓰인 유튜브 영상 링크](https://www.youtube.com/watch?v=GKnI3lnFm9E&t=348s)</br>

- [Apple Developer Academy @ POSTECH 유튜버 방문 영상 9분 40초](https://www.youtube.com/watch?v=GKnI3lnFm9E&t=348s)</br>

- [Wind Talker - 세계 최초 센서 기반 요트 세일링앱 앱스토어 링크](https://apps.apple.com/kr/app/windtalker/id6738647452?platform=iphone)</br>



## 프로젝트 소개
### 앱 설명
- WindTalker는 세일링 요트를 즐기는 사용자들을 위해 설계된 앱으로, 현재 바람의 방향과 의 각도를 제공하여 최적의 세일링을 지원합니다. 사용자는 바람과 돛 정보를 기반으로 세일링을 즐기고, 항해 후에는 항해 기록 및 회고 정보를 통해 경험을 돌아볼 수 있습니다.</br>

<p>
<img src="https://github.com/user-attachments/assets/576984b0-0824-4acc-8a05-b98dc322d078" width="19%">
<img src="https://github.com/user-attachments/assets/d505674d-f3fa-4d1f-95a0-6b71957ed7e5" width="19%">
<img src="https://github.com/user-attachments/assets/9f9f58d2-d6ed-4057-b73a-acbdbc632671" width="19%">
<img src="https://github.com/user-attachments/assets/f00327a1-83a5-4c69-b375-ee4fd4766492" width="19%">
<img src="https://github.com/user-attachments/assets/d312209b-31a0-4eab-baea-a49f437f31cc" width="19%">
</p>

</br>

### 성과
- Apple Developer Academy @ POSTECH 최종 PR 홍보팀 선정

- 애플 상부 및 고위 관계자들에게 프로젝트 발표<br>
- 글로벌 혁신성과 사회적 영향력을 입증<br>

### 프로젝트 기간
- 2024.09.01 ~ 2024.12.05 (3개월) - Apple Developer Academy @ POSTECH (MACRO Challenge)</br>

### 프로젝트 참여 인원
- iOS Developer 3명, Design 1명, PM 1명

</br>

## 기술 스택
- **Framework**
`SwiftUI`, `UIKit`, `WatchKit`, `HealthKit`, `CoreBluetooth`, `MapKit`, `WorkoutKit`, `WeatherKit`, `CoreLocation`, `Combine`, `Charts`, `simd`

- **Design Pattern**
`MVVM`

</br>

## 핵심 기능과 코드 설명

- 실시간 바람의 방향을 보여주는 기능

</br>

### 실시간 바람의 방향을 보여주는 기능
- WindTalker앱은 WeatherKit을 사용하여 현재 사용자가 위치한 지역의 실시간 바람 데이터를 제공합니다. 이를 통해 세일링 중인 사용자가 바람의 방향, 속도, 그리고 나침반 방향을 직관적으로 확인할 수 있습니다.</br>

1. WeatherKit 활용: Apple의 WeatherKit을 사용하여 정확하고 실시간 데이터를 가져옵니다.</br>
2. 데이터 구조화: 바람 데이터를 WindData라는 구조체에 저장하여 UI에서 쉽게 활용 가능.</br>
3. 오차 보정: windCorrectionDetent를 통해 센서 오차를 실시간으로 보정하며, 디지털 크라운을 통해 사용자가 직접 보정값을 조정할 수 있습니다.</br>
4. UI 반영: @Published 속성을 사용하여 데이터를 UI와 자동으로 연동.</br>

### 바람 데이터 처리코드
``` swift
func fetchCurrentWind(for location: CLLocation) async -> WindData? {

    let weatherService = WeatherService.shared
    
    do {
        let weather = try await weatherService.weather(for: location)
        let currentWind = weather.currentWeather.wind
        let currentWindCompassDirection = weather.currentWeather.wind.compassDirection
        
        DispatchQueue.main.async {
            self.timestamp = Date.now
            self.direction = currentWind.direction.value > 0 ? currentWind.direction.value : nil
            self.adjustedDirection = self.direction.map { $0 + self.windCorrectionDetent }
            self.compassDirection = currentWindCompassDirection
            self.speed = max(0, currentWind.speed.value)
            print("Current wind speed: \(self.speed) m/s")
            print("Current wind direction: \(String(describing: self.direction))°")
        }
        
        return WindData(
            timestamp: Date.now,
            direction: self.direction,
            adjustedDirection: self.adjustedDirection,
            compassDirection: self.compassDirection,
            speed: self.speed,
            wind: currentWind
        )
    } catch {
        print("Failed to fetch weather: \(error)")
        return nil
    }
}

```

</br>

### 디지털 크라운 활용 코드(애플워치 바람의 방향 오차 보정 기능)
``` swift
crownEvent in
    isCrownIdle = false
    let crownOffset = crownEvent.offset

    // 디지털 크라운의 오프셋을 바람 보정값에 반영
    windCorrectionDetent = crownOffset

    // WindDetector 모델의 보정값 업데이트
    windDetector.windCorrectionDetent = windCorrectionDetent

    // 보정값의 범위를 -30° ~ +30°로 제한
    windCorrectionDetent = max(min(30, windCorrectionDetent), -30)
    print("crownOffset: \(crownOffset), windCorrectionDetent: \(windCorrectionDetent)")
} onIdle: {
    isCrownIdle = true
}

```

</details>
