//
//  CompassView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/29/24.
//
// 나중에 뷰별로 정리를 좀 합시다.세부적인 뷰들을 묶어서 별도로 관리해서 불러오는것으로 함.
import Foundation
import SwiftUI

/*  nonisolated public func digitalCrownRotation<V>(detent: Binding<V>, from minValue: V, through maxValue: V, by stride: V.Stride, sensitivity: DigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true, onChange: @escaping (DigitalCrownEvent) -> Void = { _ in }, onIdle: @escaping () -> Void = { }) -> some View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint
 */
struct CompassView: View {
    // View에서는  Sigleton 썼더니 화면이 업데이트가 안되서 다시 원복.
    @Binding var selection: Int
    @EnvironmentObject  var locationManager : LocationManager
    @EnvironmentObject  var windDetector : WindDetector
    @EnvironmentObject  var apparentWind :ApparentWind
    @EnvironmentObject  var sailAngleFind : SailAngleFind
    @EnvironmentObject  var sailAngleDetect : SailAngleDetect
    
    // View에서는  Sigleton 썼더니 화면이 업데이트가 안되서 다시 원복.
    @State var showAlert : Bool = false
    
    // 먼저 보여주는것이 되면 그 값을  Windetector의 파라메타로 전달하든지 해서 윈드의 방향을 보정해주는걸로 함.
    @Environment(\.colorScheme) var colorScheme
    @State var windCorrectionDetent : Double  = 0
    @State var isCrownIdle = true
    @State var showBoatView = false
    @State var countdown: Int? = nil
    
    let sharedWorkoutManager = WorkoutManager.shared
    
    var body: some View {
        ZStack{
            Color.black
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
              
            
            VStack{
                
                VStack{
                    GeometryReader { geometry in
                        let r1 = geometry.size.width * 0.45
                        let r2 = geometry.size.width * 0.50
                        let r3 = geometry.size.width * 0.32
                        let r4 = geometry.size.width * 0.38
                        let cx = geometry.size.width * 0.50
                        let cy = geometry.size.height * 0.50
                        
                        let center = CGPoint(x: cx, y: cy)
                        let r5 = geometry.size.width * 0.53
                        let r6 = geometry.size.width * 0.55
                                      
                        
                        VStack(alignment: .center){
                            ZStack {
                                // 나침반 원
                                // reflection이  y축 기준으로 발생하니까 수학좌표계로는  clockwise
                                // 스크린이나  frame좌표계에서는  counter clockwise.
                                
                                
                                ForEach(0..<72, id: \.self) { index in
                                    let degree = index * 5  // Multiply the index by 5 to get the degree (since 72 ticks = 360 degrees)
                                    let isMainDirection = degree % 90 == 0 // 90-degree intervals for main directions
                                    let isTickMark = degree % 30 == 0 // 30-degree intervals for larger tick marks
                                    let lineLength: CGFloat = isMainDirection ? 8 : isTickMark ? 3 : 3 // Adjust lengths for main directions, larger and smaller tick marks
                                    
                                    //                        let lineColor: Color = isMainDirection
                                    //                        ? (colorScheme == .dark ? .white : .black) // Black in light mode, white in dark mode
                                    //                        : isTickMark ? .gray : .gray
                                    let lineColor: Color = index == 54 // First tick mark at 0 degrees is always red
                                    ? .red
                                    : (isMainDirection ? (colorScheme == .dark ? .white : .black) : .gray)
                                    
                                    // Draw lines for each 5-degree interval
                                    Path { path in
                                        let angle = Angle.degrees(Double(degree))
                                        let startX = (r1 - lineLength) * cos(angle.radians)
                                        let startY = (r1 - lineLength) * sin(angle.radians)
                                        let endX = r2 * cos(angle.radians)
                                        let endY = r2 * sin(angle.radians)
                                        
                                        path.move(to: CGPoint(x: startX + cx, y: startY + cy)) // Move to start point
                                        path.addLine(to: CGPoint(x: endX + cx, y: endY + cy))  // Draw line to end point
                                    }
                                    .stroke(lineColor, lineWidth: isMainDirection ? 3 : 2) // Different thickness for main and secondary marks
                                }
                                
                                
                                
                                
                                // 글자 및 방향 표시
                                //                    let marks = ["N" , "30" , "60" , "E", "120", "150", "S", "210", "240", "W" ,"300", "330"]
                                let marks = ["N", "E", "S", "W"]
                                
                                ForEach(0..<marks.count, id: \.self) { index in
                                    let angle = Angle(degrees: 90 - Double(index) * 90) // 각도 계산
                                    let x = r3 * cos(angle.radians) // x 좌표
                                    let y = r3 * sin(angle.radians) // y 좌표
                                    
                                    let x_c = r4 * cos(angle.radians)
                                    let y_c = r4 * sin(angle.radians)
                                    Path { path in
                                        // Arc의 중심 (ZStack에서 중앙을 기준으로)
                                        let center = CGPoint(x: x_c, y: -y_c)
                                        let radius: CGFloat = 2
                                        
                                        // Arc 추가 (시작 각도와 끝 각도 설정)
                                        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                                        
                                    }
                                    .offset(x: cx, y: cy)
                                    .fill(index == 0 ? Color.red : colorScheme == .dark ? Color.white : Color.black)
                                    
#if !os(watchOS)  // watchOS가 아닐 때만 그려짐
                                    
                                    Text(marks[index])
                                    //       .rotationEffect(Angle(degrees: Double(index) * 90), anchor: .center)
                                        .position(x: cx, y: cy)
                                        .offset(x: x, y: -y)
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(index == 0 ? Color.red : colorScheme == .dark ? Color.white : Color.black)
                                    
                                    
                                    
                                    
#endif
                                    
#if os(watchOS)
                                    Text(marks[index])
                                    //       .rotationEffect(Angle(degrees: Double(index) * 90), anchor: .center)
                                        .position(x: cx, y: cy)
                                        .offset(x: x, y: -y)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(index == 0 ? Color.red : colorScheme == .dark ? Color.white : Color.black)
                                    
                                    
                                    
                                    
#endif
                                    
                                    // heading에서  course러 바꿔줘야 배가 가는 방향이 항상 시계의 상단
                                    // heading에서 원래 course 값으로 변경함.
                                }.rotationEffect(Angle(degrees:  -locationManager.boatCourse), anchor: .init(x: cx / geometry.size.width , y: cy / geometry.size.height ))
                                
                                
                                // Wind direction draw
                                
                                
                                
                                
                                let sfSymbolName = "location.north.fill"
                                let locationDirection =  locationManager.boatCourse
                                
                                //  WindDetector에서는 이미 보정된 값만 사용하고 여기서 보정된 값을 만들지는 않음.. 단지 디지탈크라운을 이용해서 WindDetector에 보정값만 변경함
                                
                                // 왜 let direction = windDetector.adjustedDirection 하면 안되는걸까요?
                                
                                
                                if let direction = windDetector.adjustedDirection {
                                    
                                    //   let angle = Angle(degrees: 90 - direction +   (locationManager.heading?.trueHeading ?? 0))  // 각도 계산
                                    let speed = windDetector.speed
                                    let angle = Angle(degrees: 90 - direction +   locationDirection)
                                    let x = r6 * cos(angle.radians) // x 좌표
                                    let y = r6 * sin(angle.radians) // y 좌표
                                    let finalRotation = direction  -  locationDirection
                                    
                                    ZStack {
                                        Image(systemName: sfSymbolName)
                                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                            .frame(width: 10, height: 10) // 크기 지정
                                            .foregroundColor(.cyan)
                                        
                                        Text("T")
                                            .font(.system(size: 7, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                            .offset(y: 0)
                                    }
                                    .position(x:cx, y:cy)
                                    .offset(x: x, y: -y)
                                    
                                }
                                
                                if let direction = apparentWind.direction , let speed = apparentWind.speed {
                                    
                                    //                        let angle = Angle(degrees: 90 - direction + (locationManager.heading?.trueHeading ?? 0)) // 각도 계산
                                    let angle = Angle(degrees: 90 - direction +    locationDirection)
                                    let x = r6 * cos(angle.radians) // x 좌표
                                    let y = r6 * sin(angle.radians) // y 좌표
                                    let finalRotation = direction  -    locationDirection
                                    //180 은  symbol 180도 자체 회전..
                                    ZStack {
                                        Image(systemName: sfSymbolName)
                                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                            .frame(width: 10, height: 10) // 크기 지정
                                            .foregroundColor(.white)
                                        
                                        Text("A")
                                            .font(.system(size: 7, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                            .offset(y: 0)
                                    }
                                    .position(x:cx, y:cy)
                                    .offset(x: x, y: -y)
                                    // apparent wind direction draw // 근데 여기서 계산까지 해줘야 하나 아니면 다른데서??
                                }
                                
                                
#if os(watchOS)
                                if showBoatView {
                                    Text(String(format: "%+d°", Int(windCorrectionDetent)))
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(1)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(5)  // Rounded corners for the box
                                        .position(x: cx, y: cy)
                                        .offset(x: 33, y: 0)
                                    
                                    
                                        .focusable()
                                        .digitalCrownRotation(
                                            detent: $windCorrectionDetent,
                                            from: -30,
                                            through: 30,
                                            by: 5,
                                            
                                            sensitivity: .medium,
                                            isHapticFeedbackEnabled :true
                                        )
                                    {
                                        crownEvent in
                                        isCrownIdle = false
                                        let crownOffset = crownEvent.offset
                                        
                                        windCorrectionDetent = crownOffset
                                        // 모델 클라스 WindDetector.shared.windCorrectionDetent 값을 변경함..다음번 윈도우 정보는 보정이 반영된값임.
                                        windDetector.windCorrectionDetent = windCorrectionDetent
                                        
                                        windCorrectionDetent = max(min(30, windCorrectionDetent), -30)
                                        print("crownOffset :\(crownOffset) ,  windCorrectionDetent:\(windCorrectionDetent)")
                                    } onIdle: {
                                        isCrownIdle = true
                                    }
                                }
#endif
                                
                                
#if !os(watchOS)
                                HStack(alignment: .center,spacing: 0) { // 수평 정렬 및 가운데 정렬
                                    // 현재 보정값을 표시하는 Text
                                    Text(String(format: "%+2d°", Int(windCorrectionDetent)))
                                        .font(.system(size: 20)) // 텍스트 크기 증가
                                        .foregroundColor(.black)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(5)
                                        .frame(width: 50, height:50) // 텍스트 박스의 너비를 고정
                                    
                                    VStack(spacing: 0) { // 버튼 간의 간격을 0으로 설정하여 붙여줌
                                        Button(action: {
                                            adjustWindCorrection(by: -5) // -5도 감소
                                        }) {
                                            Text("-")
                                                .font(.system(size: 30)) // 버튼 크기 증가
                                                .foregroundColor(.white)
                                                .frame(width: 50, height: 30) // 버튼 크기 지정
                                                .background(Color.red)
                                                .cornerRadius(5) // 직사각형 모양
                                        }
                                        
                                        Button(action: {
                                            adjustWindCorrection(by: 5) // +5도 증가
                                        }) {
                                            Text("+")
                                                .font(.system(size: 30)) // 버튼 크기 증가
                                                .foregroundColor(.white)
                                                .frame(width: 50, height: 30) // 버튼 크기 지정
                                                .background(Color.yellow)
                                                .cornerRadius(5) // 직사각형 모양
                                        }
                                    }
                                    .frame(height: 50) // 버튼 높이를 설정하여 텍스트 박스와 맞춤
                                    
                                }
                                .position(x: cx + 75, y: cy)
#endif
                                
                            }
                            .overlay {
                                if showBoatView {
                                    BoatView()
                                        .offset(x: cx, y: cy)
                                        .environmentObject(sailAngleFind)
                                        .environmentObject(sailAngleDetect)
                                    
                                    
                                    
                                    
                                    
                                } else {
                                    if countdown == nil {
                                        Button(action: startCountdown) {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.clear, lineWidth: 2)
                                                    .background(Circle().fill(Color.clear))
                                                
                                                VStack {
                                                    Image(systemName: "figure.sailing")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.cyan)
                                                    
                                                    Text("Start")
                                                        .font(.system(size: 17).bold())
                                                        .foregroundColor(.cyan)
                                                        .fontDesign(.rounded)
                                                }
                                                .padding(17)
                                                
                                            }
                                            .padding(18)
                                        }.allowsHitTesting(true)
                                        .position(x: cx, y: cy)
                                        .buttonStyle(.plain)
                                    }
                                    if let countdown = countdown {
                                        Text("\(countdown)")
                                            .font(.system(size: 60, weight: .bold))
                                            .fontDesign(.rounded)
                                            .foregroundColor(.cyan)
                                            .transition(.scale) // 애니메이션 효과
                                            .position(x: cx, y: cy)
                                    }
                                    
                                }
                                
                            }.allowsHitTesting(true)
                        }
                    }
                }.allowsHitTesting(true)
                
                
                HStack {
                    VStack {
                        Text("SOG")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("\(LocationManager.shared.speed > 0 ? LocationManager.shared.speed : 0.0, specifier: "%.1f")")
                            .foregroundColor(.yellow)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        //                    Text("m/s")
                        //                        .foregroundColor(.orange)
                        //                        .font(.system(size: 10).bold())
                        //                        .multilineTextAlignment(.center)
                    }
                    Spacer()
                    
                    VStack {
                        Text("TWS")
                            .foregroundColor(.cyan)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("\(WindDetector.shared.speed ?? 0, specifier: "%.1f")")
                            .foregroundColor(.cyan)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        //                    Text("m/s")
                        //                        .foregroundColor(.blue)
                        //                        .font(.system(size: 10).bold())
                        //                        .multilineTextAlignment(.center)
                    }
                }.allowsHitTesting(false)
                    .padding([.leading, .trailing], 5)
                    .padding(.bottom, -20)
                
                
                
                
                
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: .resetCompassView, object: nil, queue: .main) { _ in
                    resetToInitialState()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .resetCompassView, object: nil)
            }
        }
    }
    
    private func adjustWindCorrection(by amount: Double) {
        windCorrectionDetent += amount
        windCorrectionDetent = max(min(30, windCorrectionDetent), -30)
        // WindDetector 모델의 값을 변경
        windDetector.windCorrectionDetent = windCorrectionDetent
        print("windCorrectionDetent:\(windCorrectionDetent)")
        
    }
    
    private func startCountdown() {
        countdown = 3
        showBoatView = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(countdown ?? 3 )){
            sharedWorkoutManager.isSavingData = true
            sharedWorkoutManager.startStopwatch()
            sharedWorkoutManager.startToSaveHealthStore()
        //    sharedWorkoutManager.activateWaterLock()
        }
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let currentCount = countdown, currentCount > 1 {
                withAnimation {
                    countdown = currentCount - 1
                }
            } else {
                timer.invalidate()
                withAnimation {
                    countdown = nil
                    showBoatView = true
                }
                
            }
        }
    }
    
    func resetToInitialState() {
        countdown = nil
        showBoatView = false
    }
    
    
}





//struct CompassView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompassView().environmentObject(LocationManager())
//    }
//}


extension Notification.Name {
    static let resetCompassView = Notification.Name("resetCompassView")
}
