//
//  MapHelper.swift
//  Virtual-Tourist
//
//  Created by Rodion Konioshko on 28/03/2020.
//  Copyright © 2020 Rodion Konioshko. All rights reserved.
//

import Foundation
import UIKit
import MapKit
class MapHelper{
    static func configureMapPins(_ mapView: MKMapView, viewFor annotation: MKAnnotation)-> MKAnnotationView?{
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .blue

        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}
