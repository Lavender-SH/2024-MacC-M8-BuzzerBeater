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
- 경북도지사, 포항시장, 포스텍 총장, 포스코 그룹에게 발표 <br>
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

- 1.애플워치에서 나침반을 구현한 방법</br>
- 2.실시간으로 바람의 방향을 나침반에 보여주는 기능</br>
- 3.바람의 방향에 맞게 최적의 돛의 각도를 가이딩하는 기능</br>
- 4.지도에서 항해 경로를 표시하는 기능</br>
- 5.애플워치와 아이폰의 데이터 연동</br>
- 6.요트에 하드웨어를 부착하여 블루투스로 실제 돛의 각도를 보여주는 기능</br>

</br>

### 1. 애플워치에서 나침반을 구현한 방법
WindTalker앱에서 나침반(Compass)은 사용자 경험을 극대화하기 위해 SwiftUI와 CoreLocation을 활용하여 구현되었습니다.</br>

 1. `CoreLocation`
 - CLLocationManager를 사용해 사용자의 실시간 위치와 방향 정보를 수집.</br>
 - trueHeading 값을 활용하여 현재 나침반 방향을 동적으로 업데이트.</br>
 2. `GeometryReader`
 - GeometryReader를 사용해 디스플레이 크기에 맞게 동적으로 크기를 조정.</br>
 - 화면 중심을 기준으로 나침반의 눈금을 계산하고, 각도를 기반으로 UI 요소를 배치.</br>
 3. UI 업데이트
 - UI 반영: @Published 속성을 사용하여 데이터를 UI와 자동으로 연동.</br>
 - 나침반 화살표, 주요 방향(N, E, S, W), 바람의 방향 등을 시각적으로 표시.</br>

    ###  나침반 원과 눈금 표시하는 코드
 ``` swift
ForEach(0..<72, id: \.self) { index in
    let degree = index * 5  // 5도 단위 눈금
    let isMainDirection = degree % 90 == 0 // 주요 방향 (N, E, S, W)
    let lineLength: CGFloat = isMainDirection ? 8 : 3 // 주요 방향은 길이를 길게

    Path { path in
        let angle = Angle.degrees(Double(degree))
        let startX = (r1 - lineLength) * cos(angle.radians)
        let startY = (r1 - lineLength) * sin(angle.radians)
        let endX = r2 * cos(angle.radians)
        let endY = r2 * sin(angle.radians)

        path.move(to: CGPoint(x: startX + cx, y: startY + cy))
        path.addLine(to: CGPoint(x: endX + cx, y: endY + cy))
    }
    .stroke(isMainDirection ? Color.white : Color.gray, lineWidth: isMainDirection ? 3 : 1)
}

 ```  
 </br>

### 나침반 부가 설명
    
- 코드에서 cos(코사인)과 sin(사인)을 사용한 부분은 원(circle) 위의 점의 위치를 계산하는 데 쓰였습니다. 이 원은 나침반처럼 중심에서 360도로 퍼져 있다고 생각하면 됩니다. 각도를 사용해 원의 특정 지점(점)을 계산하려는 것입니다.</br>
 ``` swift
let angle = Angle.degrees(Double(degree)) // 현재 각도
let x = r * cos(angle.radians) // x좌표 계산
let y = r * sin(angle.radians) // y좌표 계산
 ``` 
 </br>
 
 1. 원 위의 점을 찾는 과정
- 원의 중심을 (0, 0)이라고 하고, 반지름을 r이라고 가정합니다.
- 각도 angle에 따라 원 위의 특정 점 (x, y)를 계산합니다</br>
  x = r * cos(각도) // cos(각도)는 가로 방향(x축)의 비율</br>
  y = r * sin(각도) // sin(각도)는 세로 방향(y축)의 비율
 
 2. 시각적인 이해
 - 원의 중심에서 각도를 기준으로 cos은 오른쪽(가로축), sin은 위쪽(세로축)으로 점을 이동시킵니다.</br>
 - 각도가 커질수록 점의 위치가 시계 방향으로 움직입니다.</br>
 -x = r * cos(각도), y = r * sin(각도)로 계산하면, 항상 원 위의 점을 정확히 찾을 수 있습니다.</br>
 
 3. 실제 계산 예시

    반지름 r = 100 (나침반 원의 크기)</br>
    각도 angle = 90° (동쪽을 가리킴)</br>

    각도를 라디안으로 변환</br>
    angle.radians = 90° × (π / 180) = π/2</br>

    x = r * cos(π/2) = 100 * 0 = 0</br>
    y = r * sin(π/2) = 100 * 1 = 100</br>
    결과: (x, y) = (0, 100)</br>

    즉, 이 점은 동쪽(E) 방향에 해당하는 위치입니다.</br>
 
</br>

### 2. 실시간으로 바람의 방향을 나침반에 보여주는 기능
- WindTalker앱은 `WeatherKit`을 사용하여 현재 사용자가 위치한 지역의 실시간 바람 데이터를 제공합니다. 이를 통해 세일링 중인 사용자가 바람의 방향, 속도, 그리고 나침반 방향을 직관적으로 확인할 수 있습니다.</br>

1. `WeatherKit` 활용: Apple의 `WeatherKit`을 사용하여 정확하고 실시간 데이터를 가져옵니다.</br>
2. 데이터 구조화: 바람 데이터를 WindData라는 구조체에 저장하여 UI에서 쉽게 활용 가능.</br>
3. 오차 보정: windCorrectionDetent를 통해 센서 오차를 실시간으로 보정하며, 디지털 크라운을 통해 사용자가 직접 보정값을 조정할 수 있습니다.</br>

</br>

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

###  애플워치 디지털 크라운 활용 코드(바람의 방향 오차 보정 기능)
    
``` swift
.digitalCrownRotation(
    detent: $windCorrectionDetent,
    from: -30,
    through: 30,
    by: 5,
    onChange: { crownEvent in
        let crownOffset = crownEvent.offset
        windCorrectionDetent = max(min(crownOffset, 30), -30) // 보정값 -30°~+30°로 제한
        windDetector.windCorrectionDetent = windCorrectionDetent // WindDetector에 반영
        print("Crown Offset: \(crownOffset), Correction: \(windCorrectionDetent)")
    },
    onIdle: {
        isCrownIdle = true
    }
)


```

</details>
