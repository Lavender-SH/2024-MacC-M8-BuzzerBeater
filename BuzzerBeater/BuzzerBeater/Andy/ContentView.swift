//
//  ContentView.swift
//  SailingIndicator
//
//  Created by Gi Woo Kim on 9/29/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationManager : LocationManager
    @EnvironmentObject private var windDetector : WindDetector
    @EnvironmentObject private var apparentWind :ApparentWind
    @EnvironmentObject private var sailAngleFind : SailAngleFind
    @EnvironmentObject private var sailingDataCollector : SailingDataCollector
    
    
    var body: some View {
        TabView {
            
            CompassPage()
                .tabItem {
                    Image(systemName: "location.north.fill")
                    Text("Compass")
                }
            MapPage()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
            
            InfoPage()
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("Info")
                }
            
        }
    }
}

struct CompassPage: View {
    
    var body: some View {
        GeometryReader { geometry in
            CompassView()
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .environmentObject(SailingDataCollector.shared)
                .frame(width: geometry.size.width * 0.8 , height: geometry.size.width * 0.8)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .padding(5)
                .navigationTitle("Compass Page")
        }
    }
}
struct MapPage: View {
    @State var minOfWidthAndHeight : Double = 0
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                // MapView를 중앙에 배치
                Spacer()
                MapView()
                    .environmentObject(LocationManager.shared)
                    .environmentObject(SailingDataCollector.shared)
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
    @EnvironmentObject  var locationManager : LocationManager
    @EnvironmentObject  var windDetector : WindDetector
    @EnvironmentObject  var apparentWind :ApparentWind
    @EnvironmentObject  var sailAngleFind : SailAngleFind
    
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
                    Text("LAT: \(location.coordinate.latitude, specifier: "%.2f")º")
                        .font(.caption2)
                    Text("LAT: \(location.coordinate.longitude, specifier: "%.2f")º")
                        .font(.caption2)
                    Text("TWD: \(windDetector.direction ?? 0 , specifier: "%.f")°")
                        .font(.caption2)
                    Text("TWS: \(windDetector.speed ?? 0 , specifier: "%.f") m/s")
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
            }
           
        }
        .padding(.top, 10)
        .navigationTitle("Info Page")
    }
}


#Preview {
    ContentView()
}

