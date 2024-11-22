//
//  Uitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/5/24.
//
//SailingDataCollector는 보여주기 전용으로 데이타를 모은다면.. WorkoutManager는 저장용으로 데이타를 모음.
import CoreLocation
import MapKit
import SwiftUI
#if os(watchOS)
struct MapView: View {
    @Binding var selection: Int
    @EnvironmentObject var locationManager : LocationManager
    @EnvironmentObject var sailingDataCollector: SailingDataCollector
    @Environment(\.presentationMode) var presentationMode
    //    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
    //        center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742),
    //        span: MKCoordinateSpan(latitudeDelta: mapShowingDegree, longitudeDelta: mapShowingDegree)
    //    ))
    //
    @State private var coordinates: [CLLocationCoordinate2D] = []
    @State private var navigateToCompass: Bool = false
    @State private var position: MapCameraPosition = .automatic
    @State private var navigateTo: AnyView?
    
    @State private var startDragPosition: CGPoint? = nil
    @State private var pressedPosition: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    
    //
    //    let locationManager = LocationManager.shared
    //    let windDetector = WindDetector.shared
    //    let apparentWind = ApparentWind.shared
    //    let sailAngleFind = SailAngleFind.shared
    
    //   let sailingDataCollector = SailingDataCollector.shared
    let mapShowingDegree = 0.1
    
    
    var body: some View {
        
        ZStack {
            //        Map(position: $cameraPosition, interactionModes: [.all]){
            //                    .stroke(Color.blue, lineWidth: 2)
            //
            //            }
            Map(position: $position, interactionModes: [.all]) {
                if !coordinates.isEmpty {
                    MapPolyline(coordinates: coordinates)
                        .stroke(Color.blue, lineWidth: 2)
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                position = .userLocation(followsHeading: true, fallback: MapCameraPosition.region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude),
                    span: MKCoordinateSpan(latitudeDelta: mapShowingDegree, longitudeDelta: mapShowingDegree)
                )))
                updateCameraPosition(with: locationManager.lastLocation)  //<= 이것도 .automatic과 중복됨
                
                updateCoordinates() // 초기 좌표 업데이트
            }
            //            .onChange(of: locationManager.lastLocation) { newValue, oldValue in
            //                // 1분단위로 SailingData를 저장하는데 locationManager를 사용할 필요가 있는가?
            //                if newValue != oldValue {
            //                    updateCameraPosition(with : newValue) // 카메라 위치 업데이트
            //                    updateCoordinates() //좌표 업데이트
            //                }
            //                print("sailing data array changed : \(coordinates.count)")
            //            }
            .onChange(of : sailingDataCollector.sailingDataPointsArray) { newValue, oldValue in
                if newValue != oldValue {
                    //                    let location = CLLocation(latitude: sailingDataCollector.sailingDataArray.last?.latitude ?? 36.01737499212958, longitude:sailingDataCollector.sailingDataArray.last?.longitude ?? 129.32226514081427 )
                    //                    updateCameraPosition(with : location)
                    
                    updateCoordinates() //좌표 업데이트
                    print("sailingDataCollector.sailingdata array changed : \(coordinates.count)")
                }
            }
            .mapControls{
                
                MapUserLocationButton()
                MapCompass()
#if !os(watchOS)
                MapScaleView()
#endif
            }
            
            GeometryReader { geometry in
                
                ZStack {
                    Rectangle()
                    //.fill(Color.clear)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 55, height: 80)
                        .zIndex(1)
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.white)
                }
                .allowsHitTesting(true)
                .position(x: geometry.size.width * 0.13, y: geometry.size.height * 0.5)
                .gesture(
                    LongPressGesture(minimumDuration: 0.01, maximumDistance: 3)
                        .onEnded { value in
                            selection = 2
                        }
                )
                
                
                ZStack {
                    Rectangle()
                    //.fill(Color.clear)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 55, height: 80)
                        .zIndex(1)
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.white)
                }
                .allowsHitTesting(true)
                .position(x: geometry.size.width * 0.87, y: geometry.size.height * 0.5)
                .gesture(
                    LongPressGesture(minimumDuration: 0.01, maximumDistance: 3)
                        .onEnded { value in
                            selection = 4
                        }
                )
            }
        }
    }
    // updateCameraPosition 이 필요가 없음 왜냐면  case .automatic = position  이니까.
    private func updateCameraPosition(with location : CLLocation? = nil) {
        
        if case .automatic = position {
            return
        }
        else {
            position = .userLocation(followsHeading: true, fallback: MapCameraPosition.region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742),
                span: MKCoordinateSpan(latitudeDelta: mapShowingDegree, longitudeDelta: mapShowingDegree)
            )))
            
        }
        
        print("cameraposition updated : \(position)")
    }
    
    private func updateCoordinates() {
        if !sailingDataCollector.sailingDataPointsArray.isEmpty {
            coordinates.removeAll()
            coordinates = sailingDataCollector.sailingDataPointsArray.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            print("MapView coordinagtes transferred : \(coordinates)")
        } else{
            
            coordinates.removeAll()
            coordinates.append(CLLocationCoordinate2D(latitude: locationManager.lastLocation?.coordinate.latitude ?? 36.017470189362115 , longitude:locationManager.lastLocation?.coordinate.longitude ?? 129.32224097538742))
        }
    }
}

#endif
