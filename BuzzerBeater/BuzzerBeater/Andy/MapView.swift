//
//  Uitled.swift
//  SailingIndicator
//
//  Created by Giwoo Kim on 10/5/24.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: View {
    @EnvironmentObject var vm: SailingDataCollector
  
//    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742), 
//        span: MKCoordinateSpan(latitudeDelta: mapShowingDegree, longitudeDelta: mapShowingDegree)
//    ))
//    
    @State private var coordinates: [CLLocationCoordinate2D] = []
    
    @State private var position: MapCameraPosition = .automatic
    
    @EnvironmentObject var locationManager : LocationManager
        
    let mapShowingDegree = 0.05
    
    var body: some View {
        VStack(alignment: .center) {
            //        Map(position: $cameraPosition, interactionModes: [.all]){
            //                    .stroke(Color.blue, lineWidth: 2)
            //
            //            }
            Map(position: $position, interactionModes: [.all] ){
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.blue, lineWidth: 2)
                
            }
            
            .onAppear {
                //                position = .userLocation(followsHeading: true, fallback: MapCameraPosition.region(MKCoordinateRegion(
                //                            center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742),
                //                            span: MKCoordinateSpan(latitudeDelta: mapShowingDegree, longitudeDelta: mapShowingDegree)
                //                        )))
                //              updateCameraPosition(with: locationManager.lastLocation)  //<= 이것도 .automatic과 중복됨
                
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
            .onChange(of : vm.sailingDataArray) {newValue, oldValue in
                if newValue != oldValue {
                    //                    let location = CLLocation(latitude: vm.sailingDataArray.last?.latitude ?? 36.01737499212958, longitude:vm.sailingDataArray.last?.longitude ?? 129.32226514081427 )
                    //                    updateCameraPosition(with : location)
                    
                    updateCoordinates() //좌표 업데이트
                    print("vm.sailingdata array changed : \(coordinates.count)")
                }
            }
            .mapControls{
                MapUserLocationButton()
                MapCompass()
#if !os(watchOS)
                MapScaleView()
#endif
                
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
        if !vm.sailingDataArray.isEmpty {
            coordinates.removeAll()
            coordinates = vm.sailingDataArray.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            print("MapView coordinagtes transferred : \(coordinates)")
        } else{
            
            coordinates.removeAll()
            coordinates.append(CLLocationCoordinate2D(latitude: locationManager.lastLocation?.coordinate.latitude ?? 36.017470189362115 , longitude:locationManager.lastLocation?.coordinate.longitude ?? 129.32224097538742))
        }
    }
}
