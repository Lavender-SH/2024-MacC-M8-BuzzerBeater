//
//  ContentView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/29/24.
//

import Foundation
import HealthKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationManager : LocationManager
    @EnvironmentObject private var windDetector : WindDetector
    @EnvironmentObject private var apparentWind :ApparentWind
    @EnvironmentObject private var sailAngleFind : SailAngleFind
    @EnvironmentObject private var sailingDataCollector : SailingDataCollector
    @EnvironmentObject private var bleDeviceManager: BleDeviceManager
    @EnvironmentObject var sharedWorkoutManager : WorkoutManager
    @State private var selection = 2

    private let totalTabs = 3 // 총 탭 수
    
    var body: some View {
        NavigationStack {
            TabView(selection:$selection) {
                SessionPage()
                    .environmentObject(LocationManager.shared)
                    .environmentObject(WindDetector.shared)
                    .environmentObject(ApparentWind.shared)
                    .environmentObject(SailAngleFind.shared)
                    .environmentObject(SailingDataCollector.shared)
                    .tabItem {
                        Image(systemName: "info.circle.fill")
                        //Text("Info")
                    }
                    .tag(1)
                
                CompassPage(selection:$selection)
                    .tabItem {
                        Image(systemName: "location.north.fill")
                        //Text("Compass")
                    }
                    .tag(2)
                MapPage(selection:$selection)
                    .tabItem {
                        Image(systemName: "map.fill")
                        //Text("Map")
                    }
                    .tag(3)
                
                //            InfoPage()
                //                .environmentObject(LocationManager.shared)
                //                .environmentObject(WindDetector.shared)
                //                .environmentObject(ApparentWind.shared)
                //                .environmentObject(SailAngleFind.shared)
                //                .environmentObject(SailingDataCollector.shared)
                //                .tabItem {
                //                    Image(systemName: "info.circle.fill")
                //                    Text("Info")
                //                }
                //                .tag(4)
              
//                 BleView()
//                     .environmentObject(BleDeviceManager.shared)
//                     .tag(4)
//             }
              
//            .navigationDestination(isPresented: $showWatchResultRecord) {
//                            if let latestWorkout = WorkoutManager.shared.workout {
//                                WatchResultRecord(workout: latestWorkout)
//                            } else {
//                                Text("No recent workout data available.")
//                                    .font(.headline)
//                                    .foregroundColor(.red)
//                            }
//            }

        }
    }
}
struct SessionPage: View {
    @EnvironmentObject  var locationManager : LocationManager
    @EnvironmentObject  var windDetector : WindDetector
    @EnvironmentObject  var apparentWind :ApparentWind
    @EnvironmentObject  var sailAngleFind : SailAngleFind
    @EnvironmentObject  var sailingDataCollector : SailingDataCollector

    //var sharedWorkoutManager = WorkoutManager.shared
    @EnvironmentObject var sharedWorkoutManager : WorkoutManager
    @State private var isSavingData = false
    @State var isShowingWorkoutList = false
    @State private var isSensorSetting = false
    @State var showingLastWorkoutSnapShot = false
    @State private var elapsedTime: TimeInterval = 0 // 스탑워치 시간
//@State private var timer: Timer? // 타이머 인스턴스
    @State private var isPaused = false // 일시정지 상태 변수
    @State private var isMap = false
    
    let sharedWorkoutManager = WorkoutManager.shared
    @State var workoutForView  : HKWorkout?
    
    var body: some View {
        VStack(alignment: .center) {
            Button(action: {
                isSensorSetting.toggle()
                
            }) {
                Image(systemName: "sensor.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18) // 아이콘 크기 설정
                    .foregroundColor(Color.white) // 아이콘 색상
                    .padding(0) // 아이콘 패딩
            }
            .buttonStyle(CustomButtonStyle(
                backgroundColor: .blue,
                foregroundColor: .blue
            ))
            
            .sheet(isPresented: $isSensorSetting) {
                BleView()
            }
            .padding([.leading], -85)
            .padding(.top, 10)
            //.disabled(sharedWorkoutManager.isSavingData)
            
            Text(sharedWorkoutManager.formattedElapsedTime)
                .foregroundColor(.yellow)
                .font(.system(size: 32))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .padding(.top, -7)
            
   //         StopWatchView()

            HStack {
                Button(action: {
                    sharedWorkoutManager.activateWaterLock()
                    
                    
                }) {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // 아이콘 크기 설정
                        .foregroundColor(WKInterfaceDevice.current().isWaterLockEnabled ? Color.white : Color(hex: "#02F5EA")) // 아이콘 색상
                        .padding(10) // 아이콘 패딩
                }
                .buttonStyle(CustomButtonStyle(
                    backgroundColor: WKInterfaceDevice.current().isWaterLockEnabled ? Color.black : Color(hex: "#01312E"),
                    foregroundColor: .white
                ))
                .disabled( WKInterfaceDevice.current().isWaterLockEnabled)
                
                
                Button(action: {
                    isShowingWorkoutList.toggle()
                    isMap = true
                }) {
                    Image(systemName: "chart.bar.xaxis") //chart.bar.xaxis
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30) // 아이콘 크기 설정
                        .foregroundColor(Color(hex: "4D98E3")) // 아이콘 색상
                        .padding(10) // 아이콘 패딩
                }
                .buttonStyle(CustomButtonStyle(
                    backgroundColor: Color(hex: "#374B73"),
                    foregroundColor: .white
                ))
                
                .sheet(isPresented: $isShowingWorkoutList) {
                    WorkoutListView(isMap: $isMap).disabled( WKInterfaceDevice.current().isWaterLockEnabled)
                }
                .disabled(sharedWorkoutManager.isSavingData)
            }
            
            HStack {
                
                Button(action: {
                    sharedWorkoutManager.isSavingData = false
                    sharedWorkoutManager.stopStopwatch()
                    
                    Task{
                        
                        // endTosaveHealthData aync 로 수정
                        // 최소한으로 수정했고 추후 다시 정리해야함.
                        await  sharedWorkoutManager.endToSaveHealthData()
                        // 2초의 여유를 안줘도 될듯한데 일단 버퍼로써 2초를 추가로 제공
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            
                            
                            if  let  workoutForView = sharedWorkoutManager.workout {
                                self.workoutForView = workoutForView
                                print("workoutForView: in contentView \(String(describing: self.workoutForView))")
                                sharedWorkoutManager.fetchLatestWorkout() { workout in
                                    print("sharedWorkoutManager.fetchLatestWorkout  \(workout)")
                                    self.workoutForView = workout
                                }
                                
                                showingLastWorkoutSnapShot.toggle()
                                
                            }
                            
                        }
                        //CompassView.countdown = nil
                        
                        NotificationCenter.default.post(name: .resetCompassView, object: nil)
                        
                        isMap = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                    
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(sharedWorkoutManager.isSavingData ? Color(hex: "#FF3B2E") : Color.white) // 아이콘 색상 설정
                        .padding(10)
                }
                .disabled(!sharedWorkoutManager.isSavingData)
                .buttonStyle(CustomButtonStyle(
                    backgroundColor: sharedWorkoutManager.isSavingData ? Color(hex: "#330D0A") : Color.black,
                    foregroundColor: .white
                ))
                .sheet(isPresented: $showingLastWorkoutSnapShot) {
                    if let workout = self.workoutForView {
                        NavigationView {
                            LastWorkoutSnapShot(workout: workout)
                               
                        }
                    }
                }
                // Pause/Resume 버튼
                Button(action: {
                    isPaused.toggle()
                    if isPaused {
                        sharedWorkoutManager.pauseStopwatch() // 일시정지 기능
                        sharedWorkoutManager.pauseSavingHealthData()
                    } else {
                        sharedWorkoutManager.resumeStopwatch() // 다시 시작 기능
                        sharedWorkoutManager.resumeSavingHealthData()
                    }
                }) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill") // 상태에 따라 아이콘 변경
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(sharedWorkoutManager.isSavingData ? Color(hex: "#FFD700") : Color.white) // 아이콘 색상 설정
                        .padding(10)
                }
                .buttonStyle(CustomButtonStyle(
                    backgroundColor: sharedWorkoutManager.isSavingData ? Color(hex: "#332E06") : Color.black,
                    foregroundColor: .white
                ))
                .disabled(!sharedWorkoutManager.isSavingData) // isSavingData가 false일 때 비활성화
            }
        }
        .padding(.top, 10)
        .ignoresSafeArea(.all)
        //.navigationTitle("Info")
        
    }
}


//struct StopWatchView: View {
//    let workoutManager = WorkoutManager.shared
//    @State var currentTime = Date()
//    @State var elapsedTime: TimeInterval = 0
//    var body: some View{
//        VStack{
//            
//            Text("\(formattedElapsedTime)")
//                            .font(.largeTitle)
//                            .padding()
//        }.onReceive(Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()) {
//            timer in
//            if workoutManager.stopWatchEnabled {
//                self.currentTime = timer
//                self.elapsedTime = self.currentTime.timeIntervalSince(self.workoutManager.startDate ?? Date())
//            } else {
//                self.currentTime = Date()
//                self.elapsedTime = 0
//            }
//        }
//      
//    }
//    
//    
//    private var formattedElapsedTime: String {
//            let formatter = DateComponentsFormatter()
//            formatter.unitsStyle = .positional // HH:mm:ss 형식
//            formatter.allowedUnits = [.hour, .minute, .second] // 시, 분, 초 포함
//            formatter.zeroFormattingBehavior = .pad // 00:00:00 형식 유지
//            return formatter.string(from: elapsedTime) ?? "00:00:00"
//        }
//}

struct CompassPage: View {
    @Binding var selection: Int
    var body: some View {
        GeometryReader { geometry in
            CompassView(selection: $selection)
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .environmentObject(SailingDataCollector.shared)
                .padding(5)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                //.navigationTitle("Compass")
        }
    }
}
struct MapPage: View {
    @State var minOfWidthAndHeight : Double = 0
    @Binding var selection: Int
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                // MapView를 중앙에 배치
                Spacer()
                MapView(selection: $selection)
                    .environmentObject(LocationManager.shared)
                    .environmentObject(SailingDataCollector.shared)
                    .frame(width: minOfWidthAndHeight * 1, height: minOfWidthAndHeight * 1) // 전체 크기로 설정
                    //.navigationTitle("Map")
                // 적당한 패딩을 추가하여 가장자리에 여유 공간 추가
                Spacer()
            } .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear() {
                    minOfWidthAndHeight =  min(geometry.size.width, geometry.size.height)
                }
            
        }
        .ignoresSafeArea(.all)
    }
}


struct InfoPage: View {
    @EnvironmentObject  var locationManager : LocationManager
    @EnvironmentObject  var windDetector : WindDetector
    @EnvironmentObject  var apparentWind :ApparentWind
    @EnvironmentObject  var sailAngleFind : SailAngleFind
    @EnvironmentObject  var sailingDataCollector : SailingDataCollector
    
    @State  private var isSavingData = false
    @State var isShowingWorkoutList = false

    let sharedWorkoutManager  = WorkoutManager.shared

    var body: some View {
        ScrollView{
           
            VStack(alignment: .leading) {
                if locationManager.speed >= 0 {
                    Text("Boat Speed: \(locationManager.boatSpeed, specifier: "%.2f") m/s")
                        .font(.caption2)
                    Text("Boat Direction: \(locationManager.boatCourse, specifier: "%.f")º")
                        .font(.caption2)
                } else {
                    Text("Boat doesn't move")
                        .font(.caption2)
                }
                
                if locationManager.course >= 0 {
                    Text("Boat Course: \(locationManager.boatCourse, specifier: "%.f")º")
                        .font(.caption2)
                } else {
                    Text("Boat doesn't move")
                        .font(.caption2)
                }
                
                if let heading = locationManager.heading {
                    Text("Mag Heading: \(heading.magneticHeading, specifier: "%.f")º")
                        .font(.caption2)
                    Text("True Heading: \(heading.trueHeading, specifier: "%.f")º")
                        .font(.caption2)
                } else {
                    Text("Getting Boat Heading...")
                        .font(.caption2)
                }
                
                if let location = locationManager.lastLocation {
                    Text("LAT: \(location.coordinate.latitude, specifier: "%.4f")º")
                        .font(.caption2)
                    Text("LAT: \(location.coordinate.longitude, specifier: "%.4f")º")
                        .font(.caption2)
                    Text("TWD: \(windDetector.direction ?? 0 , specifier: "%.f")°")
                        .font(.caption2)
                    Text("TWS: \(windDetector.speed , specifier: "%.f") m/s")
                        .font(.caption2)
                    Text("AWD: \(apparentWind.direction ?? 0 , specifier: "%.f")°")
                        .font(.caption2)
                    Text ("AWS: \(apparentWind.speed ?? 0 , specifier: "%.f") m/s")
                        .font(.caption2)
                } else {
                    Text("Getting Wind and Location Data...")
                        .font(.caption2)
                }
                
                if let sailAngle = sailAngleFind.sailAngle {
                    Text("Sail Angle: \(sailAngle.degrees, specifier: "%.f")º")
                        .font(.caption2)
                }
                
                Button("시작") {
                    isSavingData = true
                    sharedWorkoutManager.startToSaveHealthStore()
                }
                .padding()
                .background(isSavingData ? Color.gray : Color.blue) // 비활성화 시 회색으로 변경
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isSavingData) // isSavingData가 true일 때 버튼 비활성화
                
                Button("종료") {
                    isSavingData = false
                    Task {
                        await  sharedWorkoutManager.endToSaveHealthData()
                    }
                  
                }.padding()
                    .background(isSavingData ? Color.yellow : Color.gray) // 비활성화 시 회색으로 변경
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!isSavingData) // isSavingData가 true일 때 버튼 비활성화
                    
                
                Button("가져오기") {
                    isShowingWorkoutList.toggle()
                
              }
                .padding()
                .background(Color.red ) // 활성화 시 빨간색, 비활성화 시 회색으로 변경
                .foregroundColor(.white)
                .cornerRadius(10)
                
                .sheet(isPresented: $isShowingWorkoutList) {
                  //WorkoutListView()
                }
                
            }
            
        }
        .padding(.top, 10)
        //.navigationTitle("Info")
    }
    

}

struct CustomButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
            .shadow(radius: 2)
            .opacity(configuration.isPressed ? 0.8 : 1) // 누를 때만 살짝 투명해지도록
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 6: // RGB (24-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1.0; g = 1.0; b = 1.0 // Default to white if invalid hex
        }
        
        self.init(red: r, green: g, blue: b)
    }
} //버튼 hex 코드 지정



#Preview {
    ContentView()
}
