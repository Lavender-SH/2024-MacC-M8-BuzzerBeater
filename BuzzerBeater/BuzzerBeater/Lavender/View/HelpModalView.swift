//
//  HelpPage.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 11/22/24.
//

import SwiftUI

struct HelpModalView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8) // Semi-transparent background
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Title
                Text("Help")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 1
                        Text("1. Wind Direction Indicators")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Blue T Arrow: True Wind (actual wind)")
                            Text("• White A Arrow: Apparent Wind (felt wind)")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 2
                        Text("2. Zero Point Adjustment")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Use the Apple Watch Crown to adjust the True Wind direction (blue arrow).")
                            Text("• Rotate the Crown to fine-tune the True Wind angle in 5-degree steps. The Apparent Wind (white arrow) will automatically recalculate and display based on the adjusted True Wind direction.")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 3
                        Text("3. Measurement Units")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• TWS: True Wind Speed")
                            Text("• SOG: Speed Over Ground")
                            Text("• Speed is displayed in m/s.")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 4
                        Text("4. Optimal Sail Angle Guide")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• The yellow bar on the compass shows the optimal sail angle for your yacht.")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 5
                        Text("5. Water Lock Release")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• If Water Lock is enabled, press and hold the Crown button to release it.")
                            Text("• Once released, the screen will recognize touch input again.")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 6
                        Text("6. Map Record Colors")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Yellow: Sections where the yacht was sailing at low speed")
                            Text("• Green: Sections where the yacht was sailing at moderate speed")
                            Text("• Red: Sections where the yacht was sailing at high speed")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)

                        // Section 7
                        Text("7. Sensor Connection and \n    Sail Angle Adjustment")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .padding(.leading, 10)
                            
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• In the Control Center on your Apple Watch, tap the blue Bluetooth icon at the top to connect sensors.")
                            Text("• After connection, the current sail position will appear as a shadow of the yellow bar on the screen.")
                            Text("• Align your current sail position with the optimal angle to maximize your yacht's speed!")
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.leading, 20)
                    }
                }
                .padding(.bottom, 10)
            }
       //     .frame(width: main.bounds.width * 0.95, height: main.bounds.height * 0.95)
            .background(Color.black.opacity(0.1))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}



