//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Rodion Konioshko on 27/03/2020.
//  Copyright © 2020 Rodion Konioshko. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import CoreData
class MapViewController: UIViewController,MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var pinAnnotations = [Pin]()
    let photoAlbumSegue = "photoAlbumSegue"
    var selectedLat:Double?
    var selectedLong:Double?
    let viewContext = (UIApplication.shared.delegate as! AppDelegate).dataController.viewContext
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        if let annotationsFetched = try? viewContext.fetch(fetchRequest){
            pinAnnotations = annotationsFetched
            for pinAnnotation in pinAnnotations{
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pinAnnotation.lat, longitude: pinAnnotation.long)
                mapView.addAnnotation(pointAnnotation)
            }
        }
        
        configureMapGesutreListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MapHelper.configureMapPins(mapView, viewFor: annotation)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let url = URL(string: (view.annotation?.subtitle!)!){
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @objc func mapClickAction(longPressRecognizer:UILongPressGestureRecognizer){
        let touchPoint = longPressRecognizer.location(in: mapView)
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        //prvent duplication
        for i in pinAnnotations{
            if(i.lat == pointAnnotation.coordinate.latitude && i.long == pointAnnotation.coordinate.longitude){
                return
            }
        }
        let pin = Pin(context: viewContext)
        pin.lat = pointAnnotation.coordinate.latitude
        pin.long = pointAnnotation.coordinate.longitude
        do{
            try viewContext.save()
            pinAnnotations.append(pin)
            mapView.addAnnotation(pointAnnotation)
        }catch{
            return
        }
    }
    
    func configureMapGesutreListener(){
        let longPressRecognizer = UILongPressGestureRecognizer()
        longPressRecognizer.addTarget(self,action: #selector(mapClickAction(longPressRecognizer:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation{
            selectedLat = annotation.coordinate.latitude
            selectedLong = annotation.coordinate.longitude
            performSegue(withIdentifier: photoAlbumSegue, sender: self)
            mapView.deselectAnnotation(view as? MKAnnotation, animated: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier =  segue.identifier{
            if identifier == photoAlbumSegue {
                let photoAlbumVC = (segue.destination as! PhotoAlbumViewController)
                photoAlbumVC.lat = selectedLat
                photoAlbumVC.long = selectedLong
            }
        }
    }
}

