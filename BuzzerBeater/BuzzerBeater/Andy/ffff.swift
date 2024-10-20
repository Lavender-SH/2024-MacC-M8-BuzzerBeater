//import SwiftUI
//import MapKit
//
//struct dd: View {
//    @State var degree = 0.0
//    @State var compass = 0.0
//    @State var windOffset = 0.0
//    var body: some View {
//        NavigationStack {
//            TabView {
//                GeometryReader { geometry in
//                    let diameter = min(geometry.size.width, geometry.size.height)
//                    var center = CGPoint(
//                        x: geometry.size.width / 2,
//                        y: geometry.size.height / 2
//                    )
//                    ZStack {
//                        VStack {
//                            HStack {
//                                Text("00:00:00")
//                                    .foregroundColor(.yellow)
//                                Spacer()
//                            }
//                            Spacer()
//                            HStack {
//                            Button("add") {
////                                    degree += 10
//                                compass -= 10
////                                    windOffset += 10
//                            }
////                                VStack {
////                                    Text("20")
////                                        .font(.title2)
////                                        .fontDesign(.rounded)
////                                        .foregroundColor(.mint)
////                                    Text("kn")
////                                }
//                                Spacer()
//                                VStack {
//                                    Text("27")
//                                        .font(.title3)
//                                    Text("m/s")
//                                }
////                                Button("dec") {
//////                                    degree -= 10
//////                                    compass += 10
////                                    windOffset -= 10
////                                }
//                            }
//                        }
//                        .frame(
//                            width: geometry.size.width,
//                            height: geometry.size.height
//                        )
//                        
//                        Circle()
//                            .stroke(.gray, lineWidth: 1)
//                        
//                        
//                        ForEach(0...72, id: \.self) { index in
//                            Rectangle()
//                                .frame(width: 1, height: diameter * 0.05)
//                                .foregroundColor(.white)
//                                .offset(x: 0, y: diameter * 0.34)
//                                .rotationEffect(.degrees(Double(index) * 6))
//                        }
//                        
//                        Image("Yacht")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: diameter * 0.45)
//                        
//                        ZStack {
//                            let dir = ["N", "E", "S", "W"]
//                            ForEach(0..<dir.count, id: \.self) { index in
//                                let dirString = dir[index]
//                                Text(dirString)
//                                    .font(.system(size: 12))
//                                    .foregroundColor(dirString != "N" ? .white : .red)
//                                    .offset(x: 0, y: -diameter * 0.28)
//                                    .rotationEffect(
//                                            Angle(degrees: Double(index) * 90)
//                                        )
//                                
//                            }
//                            ForEach(0..<8, id: \.self) { index in
//                                if index * 45 % 90 != 0 {
//                                    Rectangle()
//                                        .frame(width: 1, height: 10)
//                                    .offset(x: 0, y: -diameter * 0.28)
//                                    .rotationEffect(
//                                        Angle(degrees: Double(index) * 45)
//                                    )
//                                }
//                            }
//                        }.rotationEffect(Angle(degrees: compass))
//                        
//                        
//                        Image(systemName: "arrowtriangle.down.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 10)
//                            .offset(x: 0, y: -diameter * 0.4)
//                            .foregroundColor(.red)
//                        
//                        Image(systemName: "location.north.fill")
//                            .rotationEffect(Angle(degrees: 180))
//                            .offset(x: 0, y: -diameter * 0.43)
//                            .foregroundColor(.orange)
//                            .rotationEffect(Angle(degrees: 40))
//                            .rotationEffect(Angle(degrees: windOffset))
//                        
//                        Image(systemName: "location.north.fill")
//                            .rotationEffect(Angle(degrees: 180))
//                            .offset(x: 0, y: -diameter * 0.45)
//                            .foregroundColor(.mint)
//                            .rotationEffect(Angle(degrees: 30))
//                            .rotationEffect(Angle(degrees: windOffset))
//                        
//                        Rectangle()
//                            .frame(width: 3, height: diameter * 0.274)
//                            .foregroundColor(.red)
//                            .offset(x: 0, y: -diameter * 0.135)
//                            .rotationEffect(Angle(degrees: degree))
//                            .position(x: center.x, y: center.y - diameter * 0.1)
//                        
//                        Circle()
//                            .frame(width: 3, height: 3)
//                            .position(x: center.x, y: center.y - diameter * 0.1)
//                            .foregroundColor(.red)
//                    }
//                }
//                .padding(
//                    EdgeInsets(
//                        top: 13,
//                        leading: 15,
//                        bottom: 13,
//                        trailing: 15
//                    )
//                )
//                .ignoresSafeArea(.all)
//                
//                Map()
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
