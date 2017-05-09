//
//  FlickrClient.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/4/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit
import CoreData

class FlickrClient: NSObject {
    
    // Shared session
    var session = URLSession.shared
    
    // MARK: Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func searchByLocation(_ pin: Pin, _ context: NSManagedObjectContext) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(pin.latitude, pin.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        // Request total pages first
        let _ = self.taskForHttpRequest(request) { (result, error) in
            
            if (error != nil) {
                self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.fail, Constants.Notification.ErrorKey: (error?.localizedDescription)!])
                return
            }
            if ( result == nil) {
                self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.noPhotos])
                return
            }
            
            let totalPages = result?[Constants.FlickrResponseKeys.Pages] as? Int
            if (totalPages == nil || totalPages! < 1) {
                self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.noPhotos])
                return
            } else {
                let randomPage = Int(arc4random_uniform(UInt32(totalPages!))) + 1
                var methodParametersWithPageNumber = methodParameters
                methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = "\(randomPage)"
                
                // Then request images of a random page
                let requestForRandomImages = URLRequest(url: self.flickrURLFromParameters(methodParametersWithPageNumber as [String : AnyObject]))
                let _ = self.taskForHttpRequest(requestForRandomImages, completionHandler: { (randomResult, randomError) in
                    
                    guard (error == nil) else {
                        self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.fail, Constants.Notification.ErrorKey: (error?.localizedDescription)!])
                        return
                    }
                    guard (result != nil) else {
                        self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.noPhotos])
                        return
                    }
                    
                    // Random select n from the photo array
                    guard var photosArray = result![Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                        self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.noPhotos])
                        return
                    }
                    
                    if photosArray.count == 0 {
                        self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.noPhotos])
                        return
                    } else {
                        var selectedArray: [[String: AnyObject]]
                        if (photosArray.count <= Constants.Flickr.imageCount) {
                            selectedArray = photosArray
                        } else {
                            selectedArray = photosArray.shuffle().choose(Constants.Flickr.imageCount)
                        }
                        
                        for photoItem in selectedArray {
                            
                            print("\(photoItem)")

                            guard let photoId = photoItem[Constants.FlickrResponseKeys.Id] as? String else {
                                print("Invalid photoId")
                                continue
                            }
                            
                            guard let farmId = photoItem[Constants.FlickrResponseKeys.Farm] as? Int else {
                                print("Invalid farmId")
                                continue
                            }
                            
                            guard let serverId = photoItem[Constants.FlickrResponseKeys.Server] as? String else {
                                print("Invalid serverId")
                                continue
                            }
                            
                            guard let secret = photoItem[Constants.FlickrResponseKeys.Secret] as? String else {
                                print("Invalid secret")
                                continue
                            }
                            guard let mediaUrl = photoItem[Constants.FlickrResponseKeys.MediumURL] as? String else {
                                print("Invalid mediaUrl")
                                continue
                            }
                            
                            let photo = Photo(photoId: Int64(photoId)!,
                                                   farmId: Int64(farmId),
                                                 serverId: Int64(serverId)!,
                                                   secret: secret,
                                                      url: mediaUrl,
                                                  context: context)
                            photo.pin = pin
                        }
                        
                        (UIApplication.shared.delegate as! AppDelegate).stack.save()
                        
                        // Send notifications
                        self.sendNotification([Constants.Notification.GetPhotoStatusKey: GetPhotoStatus.succeed])
  
                    }
                    
                })
            }
           
            
        }
    }
    
    func sendNotification(_ userInfo: [AnyHashable : Any]) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.GetPhotosNotification),
                                      object: nil,
                                    userInfo: userInfo)
    }
    
    private func bboxString(_ latitude: Double, _ longitude: Double) -> String {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func taskForHttpRequest(_ request: URLRequest, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForHttpRequest", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                sendError("Could not parse the data as JSON: '\(data)'")
                return
            }

            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            completionHandler(photosDictionary as AnyObject?, nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

}

func showSimpleErrorAlert(_message: String, _sender: AnyObject) {
    DispatchQueue.main.async {
        let alertController = UIAlertController.init(title: "Error", message: _message, preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alertController.addAction(alertAction);
        _sender.present(alertController, animated: true, completion: nil);
    }
}

extension Array {
    /// Returns an array containing this sequence shuffled
    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }
    /// Shuffles this sequence in place
    @discardableResult
    mutating func shuffle() -> Array {
        indices.dropLast().forEach {
            guard case let index = Int(arc4random_uniform(UInt32(count - $0))) + $0, index != $0 else { return }
            swap(&self[$0], &self[index])
        }
        return self
    }
    var chooseOne: Element { return self[Int(arc4random_uniform(UInt32(count)))] }
    func choose(_ n: Int) -> Array { return Array(shuffled.prefix(n)) }
}
