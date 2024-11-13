//
//  InfoIcon.swift
//  BuzzerBeater
//
//  Created by 이승현 on 11/13/24.
//

import SwiftUI

struct InfoIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let diameter = min(width, height)
            let center = CGPoint(x: width / 2, y: height / 2)
            
            ZStack {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: diameter, height: diameter)
                    .opacity(0.2)
                
                Image(systemName: "figure.sailing")
                    .resizable()
                    .frame(width: diameter / 2, height: diameter / 2)
                    .foregroundColor(.cyan)
            }
            .position(center)

        }
    }
}

#Preview {
    InfoIcon()
}
