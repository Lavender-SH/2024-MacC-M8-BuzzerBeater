//
//  ContentView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/29/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @StateObject var windDetector = WindDetector()
    @StateObject var apparentWind = ApparentWind()
    @StateObject var sailAngleFind = SailAngleFind()
    @StateObject var sailingDataCollector = SailingDataCollector()
    
        var body: some View {
               TabView {
                   VStack {
                       CompassPage()
                           .tabItem {
                               Image(systemName: "location.north.fill")
                               Text("Compass")
                           }
                           .ignoresSafeArea(.all)
                           .environmentObject(locationManager)
                           .environmentObject(windDetector)
                           .environmentObject(apparentWind)
                           .environmentObject(sailAngleFind)
                           .padding(.bottom, -20)

                       HStack {
                               VStack {
                                   Text("SOG")
                                       .foregroundColor(.orange)
                                       .font(.system(size: 10).bold())
                                       .multilineTextAlignment(.center)
                                   Text("\(locationManager.speed > 0 ? locationManager.speed : 0.0, specifier: "%.1f")")
                                       .foregroundColor(.orange)
                                       .font(.system(size: 17).bold())
                                       .multilineTextAlignment(.center)
                                   Text("m/s")
                                       .foregroundColor(.orange)
                                       .font(.system(size: 10).bold())
                                       .multilineTextAlignment(.center)
                               }
                               Spacer()

                               VStack {
                                   Text("TWS")
                                       .foregroundColor(.blue)
                                       .font(.system(size: 10).bold())
                                       .multilineTextAlignment(.center)
                                   Text("\(windDetector.speed ?? 0, specifier: "%.1f")")
                                       .foregroundColor(.blue)
                                       .font(.system(size: 17).bold())
                                       .multilineTextAlignment(.center)
                                   Text("m/s")
                                       .foregroundColor(.blue)
                                       .font(.system(size: 10).bold())
                                       .multilineTextAlignment(.center)
                               }
                           }
                           .padding([.leading, .trailing], 30)
                           .padding(.bottom, -20)
                       }

                   

                   MapPage()
                       .tabItem {
                           Image(systemName: "map.fill")
                           Text("Map")
                       }
                       .environmentObject(locationManager)
                       .environmentObject(windDetector)
                       .environmentObject(apparentWind)
                       .environmentObject(sailAngleFind)
                       .environmentObject(sailingDataCollector)
                   
                   InfoPage()
                       .tabItem {
                           Image(systemName: "info.circle.fill")
                           Text("Info")
                       }
                       .environmentObject(locationManager)
                       .environmentObject(windDetector)
                       .environmentObject(apparentWind)
                       .environmentObject(sailAngleFind)
               }
        }
}

struct CompassPage: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windDetector: WindDetector
    @EnvironmentObject var apparentWind: ApparentWind
    @EnvironmentObject var sailAngleFind: SailAngleFind

    var body: some View {
        GeometryReader { geometry in
            CompassView()
                .environmentObject(locationManager)
                .environmentObject(windDetector)
                .environmentObject(apparentWind)
                .environmentObject(sailAngleFind)
                .frame(width: geometry.size.width * 0.8 , height: geometry.size.width * 0.8)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .padding(5)
                .navigationTitle("Compass Page")
        }
    }
}
struct MapPage: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var sailingDataCollector: SailingDataCollector
    @State var minOfWidthAndHeight : Double = 0
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                // MapView를 중앙에 배치
                Spacer()
                MapView()
                    .environmentObject(locationManager)
                    .environmentObject(sailingDataCollector)
                    .frame(width: minOfWidthAndHeight * 0.9, height: minOfWidthAndHeight * 0.9) // 전체 크기로 설정
                    .navigationTitle("Map Page")
                // 적당한 패딩을 추가하여 가장자리에 여유 공간 추가
                Spacer()
            } .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear() {
                    minOfWidthAndHeight =  min(geometry.size.width, geometry.size.height)
                }
            
        }
    }
}


struct InfoPage: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windDetector: WindDetector
    @EnvironmentObject var apparentWind: ApparentWind
    
    var body: some View {
        VStack {
            if locationManager.speed >= 0 {
                Text("Boat Speed: \(locationManager.speed, specifier: "%.2f") m/s")
                    .font(.caption2)
            } else {
                Text("Boat doesn't move")
                    .font(.caption2)
            }

            if locationManager.course >= 0 {
                Text("Boat Course: \(locationManager.course, specifier: "%.2f")º")
                    .font(.caption2)
            } else {
                Text("Boat doesn't move")
                    .font(.caption2)
            }

            if let heading = locationManager.heading {
                Text("Boat Heading: m:\(heading.magneticHeading, specifier: "%.2f")º t:\(heading.trueHeading, specifier: "%.2f")º")
                    .font(.caption2)
            } else {
                Text("Getting Boat Heading...")
                    .font(.caption2)
            }

            if let location = locationManager.lastLocation {
                Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    .font(.caption2)
                Text("True Wind: \(windDetector.direction ?? 0)°, \(windDetector.speed ?? 0) m/s")
                    .font(.caption2)
                Text("Apparent Wind: \(apparentWind.direction ?? 0)°, \(apparentWind.speed ?? 0) m/s")
                    .font(.caption2)
            } else {
                Text("Getting Wind and Location Data...")
                    .font(.caption2)
            }
        }
        .navigationTitle("Info Page")
    }
}


#Preview {
    ContentView()
}

