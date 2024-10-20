//
//  CompassView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/29/24.
//

import Foundation
import SwiftUI

/*  nonisolated public func digitalCrownRotation<V>(detent: Binding<V>, from minValue: V, through maxValue: V, by stride: V.Stride, sensitivity: DigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true, onChange: @escaping (DigitalCrownEvent) -> Void = { _ in }, onIdle: @escaping () -> Void = { }) -> some View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint
*/
struct CompassView: View {
    // View에서는  Sigleton 썼더니 화면이 업데이트가 안되서 다시 원복.
    @State var showAlert : Bool = false
    @EnvironmentObject private var locationManager : LocationManager
    @EnvironmentObject private var windDetector : WindDetector
    
    @EnvironmentObject var apparentWind :ApparentWind
    @EnvironmentObject private var sailAngleFind : SailAngleFind
// 먼저 보여주는것이 되면 그 값을  Windetector의 파라메타로 전달하든지 해서 윈드의 방향을 보정해주는걸로 함.
    
    @State var windCorrectionDetent : Double  = 0
    @State var isCrownIdle = true
    
    var body: some View {
        GeometryReader { geometry in
            let r1 = geometry.size.width * 0.45
            let r2 = geometry.size.width * 0.50
            let r3 = geometry.size.width * 0.36
            let r4 = geometry.size.width * 0.40
            let cx = geometry.size.width * 0.50
            let cy = geometry.size.width * 0.50
            
            let center = CGPoint(x: cx, y: cy)
            let r5 = geometry.size.width * 0.53
            let r6 = geometry.size.width * 0.55
            
            VStack(alignment: .center){
                ZStack {
                    // 나침반 원
                    // reflection이  y축 기준으로 발생하니까 수학좌표계로는  clockwise
                    // 스크린이나  frame좌표계에서는  counter clockwise.
                    
                    ForEach(0..<360, id: \.self) { degree in
                        let isMainDirection = degree % 30 == 0 // 30도마다 큰 눈금
                        let lineLength: CGFloat = isMainDirection ? 10 : 2 // 큰 눈금과 작은 눈금의 길이
#if !os(watchOS)
                        let lineColor: Color = isMainDirection ? .black : .orange // 큰 눈금은 검은색, 작은 눈금은 회색
#endif
                        
#if os(watchOS)
                        let lineColor: Color = isMainDirection ? .white : .orange
#endif
                        // 선을 그린다
                        // 직교 수학 좌표계
                        Path { path in
                            // 직교 수학 좌표계
                            let angle = Angle.degrees(Double(degree))
                            let startX = (r1 - lineLength) * cos(angle.radians) // 시작점
                            let startY = (r1 - lineLength) * sin(angle.radians) // 시작점
                            let endX = r2 * cos(angle.radians) // 끝점
                            let endY = r2 * sin(angle.radians) // 끝점
                            
                            let startX1 = startX
                            let endX1 = endX
                            let startY1 = -startY
                            let endY1 = -endY
                            
                            path.move(to: CGPoint(x: startX1, y: startY1))
                            path.addLine(to: CGPoint(x: endX1, y: endY1))
                        }   .offset(x: cx, y: cy)
                            .stroke(lineColor, lineWidth: 2)
                        
                        
                    }
                    
                    
                    // 글자 및 방향 표시
                    let marks = ["N" , "30" , "60" , "E", "120", "150", "S", "210", "240", "W" ,"300", "330"]
                    
                    ForEach(0..<marks.count, id: \.self) { index in
                        let angle = Angle(degrees: 90 - Double(index) * 30) // 각도 계산
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
                        .fill(Color.red)
                        
#if !os(watchOS)  // watchOS가 아닐 때만 그려짐
                        if index % 3 != 0 {
                            Text(marks[index])
                                .rotationEffect(Angle(degrees: Double(index) * 30), anchor: .center)
                                .position(x: cx, y: cy)
                                .offset(x: x, y: -y)
                                .font(.system(size: 12))
                        } else {
                            Text(marks[index])
                                .rotationEffect(Angle(degrees: Double(index) * 30), anchor: .center)
                                .position(x: cx, y: cy)
                                .offset(x: x, y: -y)
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundColor( index == 0 ? Color.red : Color.black)
                        }
                        
                        
                        
#endif
                        
#if os(watchOS)
                        Text(marks[0])
                            .rotationEffect(Angle(degrees: Double(0) * 30), anchor: .center)
                            .position(x: cx, y: cy)
                            .offset(x: 0, y: -r3)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        
                        
                        
                        
#endif
                        
                    }.rotationEffect(Angle(degrees: (  -(locationManager.heading?.trueHeading ?? 0))), anchor: .init(x: cx / geometry.size.width , y: cy / geometry.size.width ))
                    // Wind direction draw
                    
                    
                    
                    
                    let sfSymbolName = "location.north.fill"
  
                    //  WindDetector에서는 이미 보정된 값만 사용하고 여기서 보정된 값을 만들지는 않음.. 단지 디지탈크라운을 이용해서 WindDetector에 보정값만 변경함
                    
                    // 왜 let direction = windDetector.adjustedDirection 하면 안되는걸까요?
                    
                    let shared = WindDetector.shared
                    if let direction = shared.adjustedDirection, let speed = shared.speed {
                        
                        let angle = Angle(degrees: 90 - direction +   (locationManager.heading?.trueHeading ?? 0))  // 각도 계산
                        let x = r5 * cos(angle.radians) // x 좌표
                        let y = r5 * sin(angle.radians) // y 좌표
                        let finalRotation = direction  - (locationManager.heading?.trueHeading ?? 0)
                        
                        Image(systemName: sfSymbolName)
                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                            .frame(width: 10, height: 10) // 크기 지정
                            .foregroundColor(.blue)
                            .position(x:cx, y:cy)
                            .offset(x: x, y: -y)
                      
                    }
                  
                    if let direction = apparentWind.direction , let speed = apparentWind.speed {

                        let angle = Angle(degrees: 90 - direction + (locationManager.heading?.trueHeading ?? 0)) // 각도 계산
                        let x = r6 * cos(angle.radians) // x 좌표
                        let y = r6 * sin(angle.radians) // y 좌표
                        let finalRotation = direction  - (locationManager.heading?.trueHeading ?? 0)
                        //180 은  symbol 180도 자체 회전..
                        Image(systemName: sfSymbolName)
                            .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                            .frame(width: 10, height: 10) // 크기 지정
                            .foregroundColor(.red)
                            .position(x:cx, y:cy)
                            .offset(x: x, y: -y)
                        // apparent wind direction draw // 근데 여기서 계산까지 해줘야 하나 아니면 다른데서??
                    }
                    
                    Path { path in
                        // Arc의 중심 (ZStack에서 중앙을 기준으로)
                        let radius: CGFloat = r2 - 2
                        
                        // Arc 추가 (시작 각도와 끝 각도 설정)
                        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
                        
                    }
                    .stroke(Color.green, lineWidth: 4)
                    
                    Path { path in
                        // Arc의 중심 (ZStack에서 중앙을 기준으로)
                        let radius: CGFloat = r2 - 2
                        // Arc 추가 (시작 각도와 끝 각도 설정)
                        path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-180), clockwise: true)
                    }
                    .stroke(Color.red, lineWidth: 4)


                    Text(String(format: "%+d", Int(windCorrectionDetent)))
                        .position(x: cx, y: cy)
                        .offset(x: 40, y: 0)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
               
                    
                    #if os(watchOS)
                        .focusable()
                        .digitalCrownRotation(
                            detent: $windCorrectionDetent,
                            from: -30,
                            through: 30,
                            by: 1,
                            sensitivity: .low
                        )
                        {
                            crownEvent in
                            isCrownIdle = false
                            let crownOffset = crownEvent.offset
                         
                            windCorrectionDetent = crownOffset
                            // 모델 클라스 WindDetector.shared.windCorrectionDetent 값을 변경함..다음번 윈도우 정보는 보정이 반영된값임.
                            WindDetector.shared.windCorrectionDetent = windCorrectionDetent
                        
                            windCorrectionDetent = max(min(30, windCorrectionDetent), -30)
                            print("crownOffset :\(crownOffset) ,  windCorrectionDetent:\(windCorrectionDetent)")
                        } onIdle: {
                            isCrownIdle = true
                        }
                    #endif


                }
                .overlay{
                    BoatView().offset(x: cx, y: cy)
                        .environmentObject(sailAngleFind)
                    
                  
                }
            }

        }
    }
}





struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView().environmentObject(LocationManager())
    }
}


