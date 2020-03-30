//
//  NetworkHelper.swift
//  Virtual-Tourist
//
//  Created by Rodion Konioshko on 29/03/2020.
//  Copyright © 2020 Rodion Konioshko. All rights reserved.
//

import Foundation
import UIKit
import CoreData
class NetworkHelper{
    static func fetchAndSavePhotos(_ photoVC:PhotoAlbumViewController,page:Int = 1){
        let authority = "https://api.flickr.com/"
        let path = "services/rest/"
        let method = "?method=flickr.photos.search"
        let apiKey = "&api_key=33f0ab319db6154843cbbd342ce72c6c"
        let lat = "&lat="
        let lon = "&lon="
        let pageNum = "&page="
        let jsonFormat = "&format=json&nojsoncallback=1"
        let urlString = "\(authority)\(path)\(method)\(apiKey)\(lat)\(photoVC.lat!)\(lon)\(photoVC.long!)\(pageNum)\(page)\(jsonFormat)"
        let request = URLRequest(url: URL(string:urlString)!)
        let session = URLSession.shared
        let viewContext = photoVC.viewContext
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                return
            }
            do{
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]{
                    let photosObj = json["photos"] as! [String:Any]
                    let pages = photosObj["pages"] as! Int
                    let photoArr = photosObj["photo"] as! [[String:Any]]
                    var photoUrls = [String]()
                    for photo in photoArr{
                        if let farm:Int = photo["farm"] as? Int,let server:String = photo["server"] as? String,let id:String = photo["id"] as? String,let secret:String = photo["secret"] as? String {
                            photoUrls.append("https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg")
                        }
                    }    
                    
                    if photoUrls.count == 0{
                        DispatchQueue.main.async{
                            photoVC.imagesCollectionView.isHidden = true
                        }
                    }
                        //set place holders
                    else if photoUrls.count > 0{
                        for j in 0...(photoUrls.count-1){
                            let photo = Photo(context: viewContext)
                            photo.imageUrl = photoUrls[j]
                            photo.dateInMs = Date().timeIntervalSince1970*1000
                            photo.lat = photoVC.lat!
                            photo.long = photoVC.long!
                            photo.page = Int32(page)
                            photo.pages = Int32(pages)
                            photoVC.photos.append(photo)
                        }
                        try? viewContext.save()
                        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
                        let sortDescriptor = NSSortDescriptor(key: "dateInMs", ascending: false)
                        fetchRequest.sortDescriptors = [sortDescriptor]
                        if let photos = try? viewContext.fetch(fetchRequest){
                            for photo in photos{
                                let request = URLRequest(url:URL(string:photo.imageUrl!)!)
                                let task =  URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
                                    if error != nil {
                                        return
                                    }
                                    DispatchQueue.main.async{
                                        photo.image = data!
                                        try? viewContext.save()
                                        photoVC.imagesCollectionView.reloadData()
                                    }
                                })
                                task.resume()
                            }
                        }

                    }
                }
            }
            catch{}
        }
        task.resume()
    }
}
