//
//  BoatView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/30/24.
//
//
// 여기서는 수학좌표계 사용하지 않고  frame 좌표계를 이용했음
// 햇갈리기 쉬운데 다시 직교좌표계로 하고 변환해줘야 하는가???
import Foundation
import SwiftUI

struct BoatView: View{
    @State private var sailAngle: Angle = .degrees(0)
    @EnvironmentObject private var sailAngleFind : SailAngleFind
    var body: some View {
        // 여기서는 수학좌표계 사용하지 않고  frame 좌표계를 이용했음..간단한 도형이라..
#if os(watchOS)
        let scaleFactor = 0.8
#else
        let scaleFactor = 1.0
#endif
        
        let lb1 = CGPoint(x:  0 * scaleFactor, y: -50 * scaleFactor)
        let lb2 = CGPoint(x : -20 * scaleFactor, y: -20 * scaleFactor)
        let lb3 = CGPoint(x:  -20 * scaleFactor, y:0 * scaleFactor)
        let lb4 = CGPoint(x : -20 * scaleFactor, y: 50 * scaleFactor)
        
        let rb1 = CGPoint(x: 0 * scaleFactor, y: -50 * scaleFactor)
        let rb2 = CGPoint(x : 20 * scaleFactor, y: -20 * scaleFactor)
        let rb3 = CGPoint(x:  20 * scaleFactor, y: 0 * scaleFactor)
        let rb4 = CGPoint(x : 20 * scaleFactor, y: 50 * scaleFactor)
        
        let mast = CGPoint(x: 0 * scaleFactor, y: -20 * scaleFactor)
        
        let sailLength  = 68.0 * scaleFactor
        

        ZStack {
            
            Path { path in
                path.move(to: lb1)
                path.addCurve(to: lb4, control1: lb2, control2: lb3)
                
            }
#if os(watchOS)
            .stroke(Color.white, lineWidth: 3)
#else
            .stroke(Color.black, lineWidth: 3)
#endif
            Path { path in
                path.move(to: rb1)
                path.addCurve(to: rb4, control1: rb2, control2: rb3)
                
            }
#if os(watchOS)
            .stroke(Color.white, lineWidth: 3)
#else
            .stroke(Color.black, lineWidth: 3)
#endif
            Path { path in
                let newlb4 = CGPoint(x: lb4.x - 2, y: lb4.y)
                let newrb4 = CGPoint(x: rb4.x + 2, y: rb4.y)
                
                path.move(to: newlb4)
                path.addLine(to: newrb4)
                
            }
#if os(watchOS)
            .stroke(Color.white, lineWidth: 4 * scaleFactor)
#else
            .stroke(Color.black, lineWidth: 4 * scaleFactor)
#endif
            
            // StarBoard 오른쪽 방향은 가운데를 중심으로 0 ~90
            // Port 왼쪽 방향 가운데를 중심으로  0~ -90
            
            Path { path in
                Task { @MainActor in
                    sailAngle = Angle(degrees: (sailAngleFind.sailAngle ?? 0))
                }
                    
                let lx  =  sailLength * sin(sailAngle.radians) + 0
                let ly =   sailLength * cos(sailAngle.radians) - 20
                
                let sailEnd = CGPoint(x: lx, y: ly)
                path.move(to: sailEnd)
                path.addLine(to: mast)
                print("Current sailAngle: \(sailAngleFind.sailAngle ?? 0)")
                
            }.stroke(Color.blue, lineWidth: 4)
              
        }
 }
}


struct BoatView_Previews: PreviewProvider {
    static var previews: some View {
        BoatView()
    }
}



