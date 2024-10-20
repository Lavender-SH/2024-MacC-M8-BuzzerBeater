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
    @Environment(\.colorScheme) var colorScheme
    @State var windCorrectionDetent : Double  = 0
    @State var isCrownIdle = true
    
    var body: some View {
        GeometryReader { geometry in
            let r1 = geometry.size.width * 0.45
            let r2 = geometry.size.width * 0.50
            let r3 = geometry.size.width * 0.32
            let r4 = geometry.size.width * 0.38
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
                            .rotationEffect(Angle(degrees: Double(index) * 90), anchor: .center)
                            .position(x: cx, y: cy)
                            .offset(x: x, y: -y)
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(index == 0 ? Color.red : colorScheme == .dark ? Color.white : Color.black)
                        
                        
                        
                        
#endif
                        
#if os(watchOS)
                        Text(marks[index])
                            .rotationEffect(Angle(degrees: Double(index) * 90), anchor: .center)
                            .position(x: cx, y: cy)
                            .offset(x: x, y: -y)
                            .font(.system(size: 12))
                            .fontWeight(.bold)
                            .foregroundColor(index == 0 ? Color.red : colorScheme == .dark ? Color.white : Color.black)
                        
                        
                        
                        
#endif
                        
                    }.rotationEffect(Angle(degrees: (  -(locationManager.heading?.trueHeading ?? 0))), anchor: .init(x: cx / geometry.size.width , y: cy / geometry.size.width ))
                    
                    
                    // Wind direction draw
                    
                    
                    
                    
                    let sfSymbolName = "location.north.fill"
                    
                    //  WindDetector에서는 이미 보정된 값만 사용하고 여기서 보정된 값을 만들지는 않음.. 단지 디지탈크라운을 이용해서 WindDetector에 보정값만 변경함
                    
                    // 왜 let direction = windDetector.adjustedDirection 하면 안되는걸까요?
                    
                    let shared = WindDetector.shared
                    if let direction = shared.adjustedDirection, let speed = shared.speed {
                        
                        let angle = Angle(degrees: 90 - direction +   (locationManager.heading?.trueHeading ?? 0))  // 각도 계산
                        let x = r6 * cos(angle.radians) // x 좌표
                        let y = r6 * sin(angle.radians) // y 좌표
                        let finalRotation = direction  - (locationManager.heading?.trueHeading ?? 0)
                        
                        ZStack {
                            Image(systemName: sfSymbolName)
                                .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                .frame(width: 10, height: 10) // 크기 지정
                                .foregroundColor(.blue)
                            
                            Text("T")
                                .font(.system(size: 7).bold())
                                .foregroundColor(.black)
                                .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                .offset(y: 0)
                        }
                        .position(x:cx, y:cy)
                        .offset(x: x, y: -y)
                        
                    }
                    
                    if let direction = apparentWind.direction , let speed = apparentWind.speed {
                        
                        let angle = Angle(degrees: 90 - direction + (locationManager.heading?.trueHeading ?? 0)) // 각도 계산
                        let x = r6 * cos(angle.radians) // x 좌표
                        let y = r6 * sin(angle.radians) // y 좌표
                        let finalRotation = direction  - (locationManager.heading?.trueHeading ?? 0)
                        //180 은  symbol 180도 자체 회전..
                        ZStack {
                            Image(systemName: sfSymbolName)
                                .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                .frame(width: 10, height: 10) // 크기 지정
                                .foregroundColor(.red)
                            
                            Text("A")
                                .font(.system(size: 7).bold())
                                .foregroundColor(.black)
                                .rotationEffect(Angle(degrees: finalRotation + 180), anchor: .center)
                                .offset(y: 0)
                        }
                        .position(x:cx, y:cy)
                        .offset(x: x, y: -y)
                        // apparent wind direction draw // 근데 여기서 계산까지 해줘야 하나 아니면 다른데서??
                    }
                    
                    //                    Path { path in
                    //                        // Arc의 중심 (ZStack에서 중앙을 기준으로)
                    //                        let radius: CGFloat = r2 - 2
                    //
                    //                        // Arc 추가 (시작 각도와 끝 각도 설정)
                    //                        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
                    //
                    //                    }
                    //                    .stroke(Color.green, lineWidth: 4)
                    //
                    //                    Path { path in
                    //                        // Arc의 중심 (ZStack에서 중앙을 기준으로)
                    //                        let radius: CGFloat = r2 - 2
                    //                        // Arc 추가 (시작 각도와 끝 각도 설정)
                    //                        path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-180), clockwise: true)
                    //                    }
                    //                    .stroke(Color.red, lineWidth: 4)
                    
                    
                    Text(String(format: "%+d°", Int(windCorrectionDetent)))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(1)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(5)  // Rounded corners for the box
                        .position(x: cx, y: cy)
                        .offset(x: 33, y: 0)
                    
                    
                    
#if os(watchOS)
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


