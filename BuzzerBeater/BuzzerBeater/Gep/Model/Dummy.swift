import Foundation

// HealthKit의 HKWorkout을 대체할 더미 구조체

class Dummy {
    static let sampleDummyWorkoutData: [DummyWorkoutData] = [
        DummyWorkoutData(
            id: UUID(),
            workout: DummyHKWorkout(
                activityType: "Running",
                startDate: Date().addingTimeInterval(-3600),  // 1시간 전
                endDate: Date(),                              // 현재 시간
                totalEnergyBurned: 500.0,                     // 500 kcal 소모
                totalDistance: 5000.0                         // 5 km 이동
            ),
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            duration: 3600,                                   // 1시간
            totalEnergyBurned: 500.0,
            totalDistance: 5000.0
        ),
        DummyWorkoutData(
            id: UUID(),
            workout: DummyHKWorkout(
                activityType: "Cycling",
                startDate: Date().addingTimeInterval(-5400),  // 1시간 30분 전
                endDate: Date().addingTimeInterval(-1800),    // 30분 전
                totalEnergyBurned: 600.0,                     // 600 kcal 소모
                totalDistance: 12000.0                        // 12 km 이동
            ),
            startDate: Date().addingTimeInterval(-5400),
            endDate: Date().addingTimeInterval(-1800),
            duration: 3600,                                   // 1시간
            totalEnergyBurned: 600.0,
            totalDistance: 12000.0
        ),
        DummyWorkoutData(
            id: UUID(),
            workout: DummyHKWorkout(
                activityType: "Swimming",
                startDate: Date().addingTimeInterval(-7200),  // 2시간 전
                endDate: Date().addingTimeInterval(-6600),    // 1시간 50분 전
                totalEnergyBurned: 400.0,                     // 400 kcal 소모
                totalDistance: 800.0                          // 0.8 km 이동
            ),
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-6600),
            duration: 600,                                    // 10분
            totalEnergyBurned: 400.0,
            totalDistance: 800.0
        )
    ]
}

struct DummyHKWorkout {
    let activityType: String       // 운동 유형 (예: 러닝, 사이클링 등)
    let startDate: Date            // 운동 시작 시간
    let endDate: Date              // 운동 종료 시간
    let totalEnergyBurned: Double   // 소모 칼로리 (kcal)
    let totalDistance: Double       // 이동 거리 (미터 단위)
}

// WorkoutData와 유사한 더미 구조체
struct DummyWorkoutData: Identifiable {
    let id: UUID                   // 고유 식별자
    let workout: DummyHKWorkout     // DummyHKWorkout 객체
    let startDate: Date             // 운동 시작 시간
    let endDate: Date               // 운동 종료 시간
    let duration: TimeInterval      // 운동 시간 (초 단위)
    let totalEnergyBurned: Double   // 총 소모 칼로리 (kcal)
    let totalDistance: Double       // 총 이동 거리 (미터 단위)
}

