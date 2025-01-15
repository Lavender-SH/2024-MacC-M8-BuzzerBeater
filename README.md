# Wind Talker - 세계 최초 센서 기반 요트 세일링앱

<img src="https://github.com/user-attachments/assets/f198009e-20cd-4694-83ad-4fda62541344" width="20%">

- [News Article - Apple Developer Academy @ POSTECH 공식 뉴스 기사](https://developeracademy.postech.ac.kr/news/%ED%8F%AC%ED%95%AD%EC%97%90-%EC%84%B8%EC%9A%B4-'%EC%95%A0%ED%94%8C-%EA%B0%9C%EB%B0%9C%EC%9E%90-%EC%82%AC%EA%B4%80%ED%95%99%EA%B5%90'%E2%80%A655%EC%82%B4-%EC%A6%9D%EA%B6%8C%EB%A7%A8%EB%8F%84-%EA%BF%88-%EC%AB%92%EC%95%84%EC%99%94%EB%8B%A4)</br>

- [실제 Apple 홍보에 쓰인 유튜브 영상 링크](https://www.youtube.com/watch?v=GKnI3lnFm9E&t=348s)</br>

- [Apple Developer Academy @ POSTECH 유튜버 방문 영상 9분 40초](https://www.youtube.com/watch?v=GKnI3lnFm9E&t=348s)</br>

- [Wind Talker - 세계 최초 센서 기반 요트 세일링앱 앱스토어 링크](https://apps.apple.com/kr/app/windtalker/id6738647452?platform=iphone)</br>

- [Wind Talker앱을 만들면서 참고했던 자료들](https://mahogany-numeric-6b8.notion.site/MACRO-CHALLENGE-115b508d1941802e84b3c1d45047355e#125b508d19418068a1fcdec7c71a478b)</br>

- [요트에 하드웨어를 부착하여 블루투스로 연동했던 센서 구매 링크](https://ko.aliexpress.com/item/1005006313311459.html?spm=a2g0o.productlist.main.1.3908chMychMydv&algo_pvid=6f78082b-8c93-495b-bbdd-3d7921bdd109&algo_exp_id=6f78082b-8c93-495b-bbdd-3d7921bdd109-0&pdp_npi=4%40dis%21KRW%2120568%2120500%21%21%2114.50%2114.45%21%402102f0cc17307854810794112ed37d%2112000036722462657%21sea%21KR%211934967517%21X&curPageLogUid=3I2hxbiPn2nG&utparam-url=scene%3Asearch%7Cquery_from%3A)</br>

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
- 4.애플워치와 아이폰의 데이터 연동</br>
- 5.지도에서 항해 경로를 표시하는 기능</br>
- 6.요트에 하드웨어를 부착하여 블루투스로 현재 나의 돛의 각도를 보여주는 기능</br>

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

    ###  나침반 원과 눈금을 표시하는 코드
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

### 1-1. 나침반 부가 설명
    
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
</br>

###  2-2. 주행풍에 따른 하얀색 화살표 (Apparent Wind) 계산 방식
 - 주행풍은 실제 바람(True Wind)과 보트가 움직이면서 생기는 상대적인 바람이 결합된 결과입니다. 예를 들어, 바람이 정면에서 불고 있지만 보트가 빠르게 이동하면 느껴지는 바람의 방향과 세기가 달라지게 됩니다. 이 주행풍은 세일링에서 매우 중요한 요소입니다.</br>

 1. 실제 바람의 성분 분리 (True Wind Components)</br>
    - x축: 바람이 가로 방향으로 얼마나 영향을 주는지 계산</br>
      wind X = windSpeed × cos(windDirection)</br>
    - Y축: 바람이 세로 방향으로 얼마나 영향을 주는지 계산</br>
      wind Y = windSpeed × sin(windDirection)</br>

 2. 보트의 이동 성분 분리 (Boat Motion Components)</br>
    - x축: 보트가 가로 방향으로 얼마나 움직이는지 계산</br>
      boat X = boatSpeed × cos(boatCourse)</br>
    - Y축: 보트가 세로 방향으로 얼마나 움직이는지 계산</br>
      boat Y = boatSpeed × sin(boatCourse)</br>
      
 3. 주행풍 계산 (Apparent Wind Calculation)</br>
    - x축 주행풍: 실제 바람(x)와 보트 이동(x)을 더한다.</br>
      apparentWind X = wind X + boat X</br>
    - Y축 주행풍: 실제 바람(y)와 보트 이동(y)을 더한다.</br>
      apparentWind Y = wind Y + boat Y</br>
      
 4. 주행풍 크기와 방향 구하기</br>
    - 크기: 피타고라스 정리를 사용해 주행풍의 속도를 구함.</br>
      Apparent Wind Speed = √((True Wind X + Boat X)² + (True Wind Y + Boat Y)²)

    - 방향: 주행풍의 각도를 atan2 함수로 계산.</br>
      direction = atan2(apparentWind X, apparentWind Y)</br>

###  하얀색 화살표 (Apparent Wind) 계산 코드
``` swift
func calcApparentWind() {
    // True Wind와 Boat의 속도 및 방향 데이터
    let windSpeed = windDetector.speed
    let windDirection = windDetector.adjustedDirection ?? 0
    let boatSpeed = locationManager.boatSpeed == 0 ? windSpeed * 0.5 : locationManager.boatSpeed
    let boatCourse = locationManager.boatCourse

    // True Wind와 Boat의 X, Y 성분 계산
    let windX = windSpeed * cos(Angle(degrees: 90 - windDirection).radians)
    let windY = windSpeed * sin(Angle(degrees: 90 - windDirection).radians)
    let boatX = boatSpeed * cos(Angle(degrees: 90 - boatCourse).radians)
    let boatY = boatSpeed * sin(Angle(degrees: 90 - boatCourse).radians)

    // Apparent Wind (주행풍) 성분
    let apparentWindX = windX + boatX
    let apparentWindY = windY + boatY

    // 주행풍 속도 및 방향 계산
    speed = sqrt(pow(apparentWindX, 2) + pow(apparentWindY, 2))
    direction = speed != 0 ? calculateThetaY(x: apparentWindX, y: apparentWindY) : windDirection
}

func calculateThetaY(x: Double, y: Double) -> Double {
    let theta = atan2(x, y) * (180 / .pi) // y축 기준 각도 계산
    return theta < 0 ? theta + 360 : theta // 음수 각도를 양수로 변환
}


```
</br>

### 3. 바람의 방향에 맞게 최적의 돛의 각도를 가이딩하는 기능

 - 돛의 각도는 바람의 방향(True Wind Direction)과 보트의 진행 방향(Boat Direction)을 기준으로 계산됩니다. 최적의 돛 각도를 설정하면 효율적인 항해가 가능합니다. 이를 위해 상대 바람(Apparent Wind Direction) 방향과 돛의 위치를 계산하는 방법이 구현되었습니다.</br>
 
 
 1. 돛의 각도 계산을 위한 필수 데이터</br>
    - True Wind Direction: 실제 바람의 방향</br>
    - Apparent Wind Direction: 보트의 움직임으로 인한 주행풍 방향</br>
    - Boat Direction: 보트의 진행 방향</br>
    
 2. 상대 바람 방향 계산</br>
    - Relative Wind Direction은 True Wind, Apparent Wind와 Boat Direction의 차이로 계산됩니다.</br>
    - 계산 후 방향은 -180° ~ 180° 범위로 조정됩니다.</br>

``` swift
var relativeWindDirection = fmod(trueWindDirection - boatDirection, 360)
var relativeApparentWindDirection  = fmod (apparentWindDirection  - boatDirection , 360)

if relativeWindDirection > 180 { relativeWindDirection -= 360 }
if relativeWindDirection < -180 { relativeWindDirection += 360 }

if relativeApparentWindDirection > 180 { relativeApparentWindDirection -= 360 }
if relativeApparentWindDirection < -180 { relativeApparentWindDirection += 360 }


-----------------------------------------------------------------------------------------
 1. 왜 trueWindDirection - boatDirection을 계산하는가?
    relativeWindDirection은 보트 기준에서의 바람 방향을 의미합니다. 이를 구하기 위해서는
    1.바람의 방향(trueWindDirection)에서
    2.보트가 진행하는 방향(boatDirection)을 빼서
    3.보트 입장에서 상대적으로 바람이 어느 쪽에서 불어오는지를 계산해야 합니다.
    
    - 예시
    trueWindDirection = 90° (동쪽에서 바람이 옴)
    boatDirection = 30° (보트가 북동쪽으로 진행 중)
    relativeWindDirection = 90° - 30° = 60°
    즉, 보트 기준으로 동쪽에서 60° 시계 방향으로 바람이 불어옴을 나타냅니다.
    
 2. 왜 360으로 나눠서 나머지를 구하는가?
    360으로 나눠 나머지를 구하는 이유는 각도를 항상 0° ~ 360° 범위로 유지하기 위해서입니다.

 3. 왜 추가로 음수 각도를 보정하는가?
     나머지 연산(fmod) 결과가 음수일 수 있기 때문에, 음수를 양수로 변환해 0° ~ 360° 사이로 맞춥니다.

```

 3. 돛의 각도 결정</br>
    - 상대 바람 방향에 따라 돛 각도와 항해 포인트(Sailing Point)를 설정.</br>

``` swift
enum SailingPoint {
    case noGoZone        // 못가는 구간 (-40° ~ 40°)
    case closehauled     // 바람을 맞고 항해하는 자세 (40° ~ 70° 또는 -40° ~ -70°)
    case beamReach       // 바람을 옆에서 받아 항해하는 자세 (70° ~ 120° 또는 -70° ~ -120°)
    case broadReach      // 바람을 사선 뒤쪽에서 받아 항해하는 자세 (120° ~ 160° 또는 -120° ~ -160°)
    case downwind        // 바람을 뒤에서 받으며 항해하는 자세 (160° ~ -160°)
}



if relativeWindDirection > -40 && relativeWindDirection < 40 {
    sailingPoint = [.noGoZone]
    sailAngle = Angle(degrees: 0)
    
} else if relativeWindDirection < -40 && relativeWindDirection > -120 {
    sailingPoint = [.closehauled, .beamReach, .broadReach]
    sailAngle = min(Angle(degrees: -relativeApparentWindDirection), Angle(degrees: 90))
    
} else if relativeWindDirection > 40 && relativeWindDirection < 120 {
    sailingPoint = [.closehauled, .beamReach, .broadReach]
    sailAngle = max(Angle(degrees: -relativeApparentWindDirection), Angle(degrees: -90))
    
} else if relativeWindDirection > 120 || relativeWindDirection < -120 {
    sailingPoint = [.downwind]
    sailAngle = Angle(degrees: relativeWindDirection > 0 ? -90 : 90)
}

``` 
</br>

### 3-1. `Combine` 프레임워크 활용

 - Combine 프레임워크를 사용하여 바람 속도, 방향, 보트의 진행 방향(heading), 코스(course)를 실시간으로 수집.</br>
 - 이전 데이터와 비교하여 중요한 변화(예: 1° 이상의 각도 변화)가 발생하면 calcSailAngle() 함수를 호출해 돛의 각도를 재계산.</br>
 - 실시간 데이터 스트림을 기반으로, 돛의 각도를 동적으로 업데이트.</br>
    
``` swift
func startCollectingData() {
    Publishers.CombineLatest4(
        apparentWind.$speed,
        apparentWind.$direction,
        locationManager.$heading,
        locationManager.$course
    )
    .filter { [weak self] speed, direction, heading, course in
        let speedChange = abs((speed ?? 0) - (self?.previousSpeed ?? 0)) > 0.1
        let directionChange = abs((direction ?? 0) - (self?.previousDirection ?? 0)) > 1
        let headingChange = abs((heading?.trueHeading ?? 0) - (self?.previousHeading ?? 0)) > 1
        let courseChange = abs((course ?? 0) - (self?.previousCourse ?? 0)) > 1

        self?.previousSpeed = speed ?? 0
        self?.previousDirection = direction ?? 0
        self?.previousHeading = heading?.trueHeading ?? 0
        self?.previousCourse = course ?? 0

        return speedChange || directionChange || headingChange || courseChange
    }
    .sink { [weak self] _, _, _, _ in
        DispatchQueue.main.async {
            self?.calcSailAngle()
        }
    }
    .store(in: &cancellables)
}

```
</br>

### 4. 애플워치와 아이폰의 데이터 연동
 - HealthKit을 사용하여 Apple Watch와 iPhone을 연동. 운동 데이터 기록 및 관리 시스템을 구축</br>
 
 ### 4-1. HealthKit 주요 구성 요소
 
 1. HKHealthStore</br>
  - HealthKit 데이터와 상호작용하는 중앙 허브 역할</br>
  - HealthKit 데이터베이스와 연결되어 데이터를 읽거나 쓰는 데 사용</br>
  - 앱에서 HKHealthStore 인스턴스를 생성하여 사용하며, 권한 요청 및 데이터 쿼리 실행에 활용</br>
  
```swift
let healthStore = HKHealthStore()
```
</br> 

 2. HKObjectType</br>
  - HealthKit에서 관리하는 데이터 유형 </br>
    HKQuantityType: 숫자 데이터 (예: 심박수, 이동 거리)</br>
    HKCategoryType: 카테고리 데이터 (예: 수면 상태)</br>
    
```swift
let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
```    
 </br>
 
 3. HKSampleType</br>
  - HealthKit 데이터베이스에서 쿼리할 수 있는 데이터의 샘플 유형</br>
  - HKObjectType의 하위 클래스이며, 데이터 항목을 구체적으로 정의</br>
  
```swift
let stepCountType = HKSampleType.quantityType(forIdentifier: .stepCount)!
``` 

 4. HKWorkout</br>
  - 운동 세션을 나타내는 객체</br>
  - 운동 유형(HKWorkoutActivityType), 운동 시간, 거리, 소모 칼로리 등과 같은 정보를 포함</br>
  - 운동 데이터를 기록하고 분석하는 데 사용</br>
  
```swift
let workout = HKWorkout(activityType: .running,
                        start: Date(),
                        end: Date(),
                        duration: 3600,
                        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 500),
                        totalDistance: HKQuantity(unit: .meter(), doubleValue: 5000),
                        metadata: nil)

```

 5. HKWorkoutBuilder</br>
 - 운동 세션 데이터를 실시간으로 기록하는 데 사용되는 객체</br>
 - 운동 세션 종료 후 데이터를 HealthKit에 저장</br>
 
```swift
let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore,
                                      configuration: workoutConfiguration,
                                      device: .local())

```

 6. HKWorkoutRoute</br>
  - 사용자가 이동한 GPS 경로를 저장하는 객체</br>
  - 위치 데이터(CLLocation)를 기반으로 경로를 구성</br>
  
```swift
let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore,
                                      configuration: workoutConfiguration,
                                      device: .local())

```
 </br>
 
  ### 4-2. HealthKit 데이터 흐름
 
  1. 권한 요청</br>
   - 사용자에게 데이터 읽기/쓰기 권한을 요청</br>
   - 사용자가 승인하지 않으면 HealthKit 데이터에 접근할 수 없음</br>
   
```swift
let sampleTypes: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
    healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes) { success, error in
    if success {
        print("Authorization granted.")
    } else {
        print("Authorization failed.")
    }
}

```

 2. 데이터 쓰기</br>
   - 앱에서 수집한 데이터를 HealthKit에 저장</br>
    
```swift
let heartRateQuantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: 80)
let heartRateSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                                       quantity: heartRateQuantity,
                                       start: Date(),
                                       end: Date())
healthStore.save(heartRateSample) { success, error in
    if success {
        print("Heart rate saved successfully.")
    }
}

```
 3. 데이터 읽기</br>
  - HealthKit 데이터베이스에서 특정 데이터를 쿼리</br>
  
```swift
let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 10, sortDescriptors: nil) { query, results, error in
    if let samples = results as? [HKQuantitySample] {
        for sample in samples {
            print("Heart rate: \(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())))")
        }
    }
}
healthStore.execute(query)

```
 4. 운동 세션 관리</br>
   - 운동 시작: HKWorkoutBuilder로 운동 데이터 기록</br>
   - 경로 추가: HKWorkoutRouteBuilder를 사용해 위치 데이터 추가</br>
   - 운동 종류 후 데이터 저장</br>
    
</br>
 
### 4-3. HKMetadata와 커스텀 데이터 관리

    - HKMetadata: HealthKit 데이터 항목에 추가 정보를 저장하기 위한 딕셔너리</br>
    - 메타데이터를 통해 커스텀 데이터를 HealthKit 데이터에 포함하여 저장</br>
    
```swift
let metadata: [String: Any] = [
    HKMetadataKeySyncIdentifier: "uniqueWorkoutID",
    HKMetadataKeySyncVersion: 1,
    "AppIdentifier": "com.example.myapp"
]

let windSpeedMetadata: [String: Any] = [
    "WindSpeed": 5.5,
    "WindDirection": 120
]

```

### 5. 지도에 항해 경로를 표시하는 기능

 - HealthKit 데이터를 활용하여 항해 기록 및 경로를 지도에 표시</br>
 - 사용자가 항해한 경로와 속도를 HealthKit에서 가져와 시각적으로 표시.</br>
 - 경로는 속도에 따라 색상이 다르게 표시되어 항해 데이터를 직관적으로 분석.</br>
 - HKWorkout과 HKWorkoutRoute를 생성 및 저장하여 운동 데이터와 경로를 효과적으로 관리.</br>
 - 경로 데이터는 지도에 표시되며, 속도, 에너지 소모량, 거리 등의 추가 데이터를 제공.</br>
 
 ``` swift

 func getRouteFrom(workout: HKWorkout, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
    let routePredicate = HKQuery.predicateForObjects(from: workout)
    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: routePredicate, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, error in
        guard let route = samples?.first as? HKWorkoutRoute else {
            completion(false, error)
            return
        }
        let locationQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
            if let locations = locations {
                self.routePoints.append(contentsOf: locations)
                if done {
                    self.routePoints.sort { $0.timestamp < $1.timestamp }
                    self.getMetric()
                    completion(true, nil)
                }
            }
        }
        self.healthStore.execute(locationQuery)
    }
    healthStore.execute(routeQuery)
}

-----------------------------------------------------------------------------------------
    1. HKWorkoutRouteQuery: 운동 경로 데이터를 가져오는 쿼리로, 사용자가 기록한 위치 데이터를 반환
    2. 데이터를 시간 순으로 정렬한 뒤 routePoints 배열에 저장하여 지도에 표시
       (CLLocation 객체를 저장하는 배열. 사용자 항해 경로의 위치 데이터(위도, 경도 등)가 포함)

```
</br>

- MapPolyline을 활용해 경로 데이터를 지도에 시각적으로 표시하며, 속도에 따라 색상이 달라지도록 구현</br>
    
```swift   
Map {
    ForEach(0..<mapPathViewModel.segments.count, id: \.self) { index in
        let segment = mapPathViewModel.segments[index]
        MapPolyline(coordinates: [segment.start, segment.end])
            .stroke(segment.color, lineWidth: 6)
    }
}

func calculateColor(for velocity: Double, minVelocity: Double, maxVelocity: Double) -> Color {
    let progress = CGFloat((velocity - minVelocity) / (maxVelocity - minVelocity))
    switch progress {
    case ..<0.7: return .yellow
    case 0.7..<0.85: return .green
    case 0.85...: return .red
    default: return .blue
    }
}

```
</br>

### 6. 요트에 하드웨어를 부착하여 블루투스로 현재 나의 돛의 각도를 보여주는 기능
 - Witmotion 센서를 요트의 실제 돛에 부착하여 돛의 각도를 실시간으로 측정하고 Apple Watch에서 데이터를 시각화
 - Witmotion에서 제공한 iOS 전용 SDK를 본사에 문의해서 샘플 코드를 받음
 - SDK를 Apple Watch 환경에 맞게 수정 및 최적화
 - BLE(Bluetooth Low Energy)를 활용하여 센서와 실시간 통신
 - 3축 데이터 X, Y, Z 각 축의 회전 각도를 실시간으로 읽어와서 돛의 실제 각도를 표현
    X: 세일의 좌우 기울기</br>
    Y: 세일의 앞뒤 기울기</br>
    Z: 세일이 수직으로 기울어진 정도</br>

```swift
class BleDeviceManager: ObservableObject {
    let bluetoothManager = WitBluetoothManager.shared
    
    @Published var deviceList: [Bwt901ble] = []
    @Published var angles = SIMD3<Double>(0, 0, 0)
    
    func scanDevices() {
        bluetoothManager.startScan()
    }
    
    func openDevice(device: Bwt901ble) {
        try? device.openDevice()
        device.registerListenKeyUpdateObserver(obj: self)
    }
    
    func onRecord(_ bwt901ble: Bwt901ble) {
        self.angles = getDeviceAngleData(bwt901ble)
    }
    
    func getDeviceAngleData(_ device: Bwt901ble) -> SIMD3<Double> {
        return SIMD3<Double>(
            x: Double(device.getDeviceData(WitSensorKey.AngleX) ?? "") ?? 0.0,
            y: Double(device.getDeviceData(WitSensorKey.AngleY) ?? "") ?? 0.0,
            z: Double(device.getDeviceData(WitSensorKey.AngleZ) ?? "") ?? 0.0
        )
    }
}
```

</details>
