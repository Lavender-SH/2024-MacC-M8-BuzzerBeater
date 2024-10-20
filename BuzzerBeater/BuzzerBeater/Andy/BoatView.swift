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
import Combine

struct BoatView: View{
    @State private var sailAngle: Angle = .degrees(0)
    @State private var newSailAngle : Angle = .degrees(0)
    @State private var previousSailAngle: Angle = .degrees(0)
    @State private var diffAngle : Angle = .degrees(0)
    @State private var duration : TimeInterval = 0
    @State private var currentSailAngle : Angle = .degrees(0)
    @State private var angleStep : Angle = .degrees(1)
    @EnvironmentObject private var sailAngleFind : SailAngleFind
    
    @State private var cancellable: AnyCancellable? = nil
    
    var body: some View {
        // 여기서는 수학좌표계 사용하지 않고  frame 좌표계를 이용했음..간단한 도형이라..
#if os(watchOS)
        let scaleFactor = 0.8
#else
        let scaleFactor = 1.0
#endif
        
        let lb1 = CGPoint(x:  0 * scaleFactor, y: -50 * scaleFactor)
        let lb2 = CGPoint(x : -22 * scaleFactor, y: -30 * scaleFactor)
        let lb3 = CGPoint(x:  -20 * scaleFactor, y:25 * scaleFactor)
        let lb4 = CGPoint(x : -18 * scaleFactor, y: 48 * scaleFactor)
        
        let rb1 = CGPoint(x: 0 * scaleFactor, y: -50 * scaleFactor)
        let rb2 = CGPoint(x : 22 * scaleFactor, y: -30 * scaleFactor)
        let rb3 = CGPoint(x:  20 * scaleFactor, y: 25 * scaleFactor)
        let rb4 = CGPoint(x : 18 * scaleFactor, y: 48 * scaleFactor)
        
        let mast = CGPoint(x: 0 * scaleFactor, y: -20 * scaleFactor)
        
        let sailLength  = 70 * scaleFactor
        

        ZStack {
            
            Path { path in
                path.move(to: lb1)
                path.addCurve(to: lb4, control1: lb2, control2: lb3)
                
                
                path.addLine(to: rb4)
                
                
                path.addCurve(to: rb1, control1: rb3, control2: rb2)
                
                path.closeSubpath()
                
    
                
            }
#if os(watchOS)
  //          .stroke(Color.white, lineWidth: 3)
            .fill(.gray)
            .opacity(0.5)
#else
            .stroke(Color.black, lineWidth: 3)
#endif
  
            let lx =  sailLength * sin(sailAngle.radians) + 0
            let ly =  sailLength * cos(sailAngle.radians) - 20
            
            Path { path in
                let lb1 = mast
                let lb2 = CGPoint(x : lx / 4 , y:  mast.y + ly / 4)
                let lb3 = CGPoint(x:  lx / 2 , y:  mast.y + ly / 2)
                let lb4 = CGPoint(x : lx, y:  ly)
                let sailEnd = CGPoint(x: lx, y: ly)
//                path.move(to: sailEnd)
//                path.addLine(to: mast)
                path.move(to: lb1)
                path.addCurve(to: lb4, control1: lb2, control2: lb3)
                
                    
            }.stroke(Color.orange, lineWidth: 4)
          //   .animation(.spring, value: ly)   // 무슨 효과가 있다는건지..
              
        } .onAppear {
            updateSailAngle()
        }
        .onChange(of: sailAngleFind.sailAngle?.degrees ) { newValue , oldValue in
            if let newValue = newValue, let oldValue = oldValue {
                if abs( newValue - oldValue ) > 1 {
                    updateSailAngle()
                    
                    
                }
            }
        }
 }
    private func updateSailAngle() {
        
        guard let newSailAngle = sailAngleFind.sailAngle else { return }
        self.newSailAngle = newSailAngle
        print("newSailing Angle : \(newSailAngle.degrees)")
        
        self.previousSailAngle = Angle(degrees: self.sailAngle.degrees)
        print("previousSailingAngle : \(previousSailAngle.degrees)")
        
        self.diffAngle = Angle(degrees: newSailAngle.degrees - self.previousSailAngle.degrees)
        print("diffAngle updated to: \(diffAngle.degrees)")
        
        self.angleStep = Angle(degrees: self.diffAngle.degrees > 0 ? 3 : -3 )
        currentSailAngle = self.previousSailAngle
        
        // self.sailAngle = self.newSailAngle  vs startTimer() 둘중 하나만 사용
        // self.sailAngle = self.newSailAngle
        startTimer()
        print("newSailAngle in the updateSailAngle: \(self.sailAngle.degrees)")
        
        
        
        
     }
    
    
    private func startTimer() {
        cancellable = Timer.publish(every: 0.01, on: .main, in: .common)
               .autoconnect()
               .sink { _ in
                 
                   if self.angleStep.degrees >= 0 {
                       if self.currentSailAngle.degrees < self.newSailAngle.degrees  {
                           if (self.currentSailAngle.degrees  + self.angleStep.degrees <= self.newSailAngle.degrees) {
                               self.currentSailAngle = Angle(degrees: self.currentSailAngle.degrees + self.angleStep.degrees)
                           }
                           else {
                               self.currentSailAngle = self.newSailAngle
                           }
                           
                           self.sailAngle = self.currentSailAngle
                       } else {
                           stopTimer() // 조건 만족 시 타이머 취소
                       }
                   }
                   else {
                       if self.currentSailAngle.degrees > self.newSailAngle.degrees  {
                           if (self.currentSailAngle.degrees  + self.angleStep.degrees >= self.newSailAngle.degrees) {
                               self.currentSailAngle = Angle(degrees: self.currentSailAngle.degrees + self.angleStep.degrees)
                           }
                           else {
                               self.currentSailAngle = self.newSailAngle
                           }
                           
                           self.sailAngle = self.currentSailAngle
                       } else {
                           stopTimer() // 조건 만족 시 타이머 취소
                       }
                       
                   }
                   
               }
    }
    
       // 타이머 중지
       private func stopTimer() {
           cancellable?.cancel()
           print("Timer cancelled")
       }
}


struct BoatView_Previews: PreviewProvider {
    static var previews: some View {
        BoatView()
    }
}




