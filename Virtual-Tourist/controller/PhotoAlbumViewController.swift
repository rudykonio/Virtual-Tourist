//
//  PhotoAlbumViewController.swift
//  Virtual-Tourist
//
//  Created by Rodion Konioshko on 28/03/2020.
//  Copyright © 2020 Rodion Konioshko. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
class PhotoAlbumViewController: UIViewController,MKMapViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,UICollectionViewDataSource {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imageCollectionViewFlowLayout: UICollectionViewFlowLayout!
    var lat:CLLocationDegrees?
    var long:CLLocationDegrees?
    var photos = [Photo]()
    let viewContext = (UIApplication.shared.delegate as! AppDelegate).dataController.viewContext
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
        let sortDescriptor = NSSortDescriptor(key: "dateInMs", ascending: false)
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "long = %d AND lat = %d", argumentArray: [long!,lat!])
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let photosFetched = try? viewContext.fetch(fetchRequest){
            if photosFetched.count == 0{
                NetworkHelper.fetchAndSavePhotos(self)
            }else{
                photos = photosFetched.reversed()
                imagesCollectionView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.backItem?.title = "OK"
    }
    
    func configureMap(){
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
        let distanceSpan:CLLocationDistance = 5000
        let region = MKCoordinateRegion(center: location, latitudinalMeters:distanceSpan , longitudinalMeters: distanceSpan)
        mapView.setRegion(region, animated: true)
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = location
        mapView.addAnnotation(pointAnnotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MapHelper.configureMapPins(mapView, viewFor: annotation)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.frame.width/3.0
        let yourHeight = (collectionView.frame.height-44)/3.0
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionCell
        if photos[indexPath.item].image != nil{
            cell.image.image = UIImage(data: photos[indexPath.item].image!)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at:indexPath,animated: false)
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imageUrl == %@", argumentArray: [photos[indexPath.row].imageUrl!])
        do{
            let objectToDeleteArr = try viewContext.fetch(fetchRequest)
            if objectToDeleteArr.count == 1{
                viewContext.delete(objectToDeleteArr[0] as NSManagedObject)
                do{
                    try viewContext.save()
                    photos.remove(at: indexPath.row)
                    imagesCollectionView.reloadData()
                }
            }
        }
        catch{}
    }
    
    
    @IBAction func newCollectionClick(_ sender: Any) {
        let pages = photos[0].pages
        let nextPage = photos[0].page+1
        if nextPage <= pages{
            //clear previous photos first
            let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
            if let photosToDelete = try? viewContext.fetch(fetchRequest){
                for photoToDelete in photosToDelete{
                    viewContext.delete(photoToDelete)
                }
                do{
                    try viewContext.save()
                    photos = [Photo]()
                    NetworkHelper.fetchAndSavePhotos(self,page:Int(nextPage))
                }
                catch{}
            }
        }
    }
}
