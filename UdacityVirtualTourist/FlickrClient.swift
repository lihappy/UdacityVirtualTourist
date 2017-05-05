//
//  FlickrClient.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/4/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit

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
    
    func searchByLatLon(_ latitude: Double, _ longitude: Double, _ sender: AnyObject) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
//        displayImageFromFlickrBySearch(methodParameters as [String:AnyObject])
        
//        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        
        let _ = self.taskForHttpRequest(request) { (result, error) in
            
            if (error != nil) {
                showSimpleErrorAlert(_message: (error?.localizedDescription)!, _sender: sender)
            }
            if ( result == nil) {
                showSimpleErrorAlert(_message: "No photos", _sender: sender)
            }
            
            let totalPages = result?[Constants.FlickrResponseKeys.Pages] as? Int
            if (totalPages == nil || totalPages! < 1) {
                return
            } else {
                let randomPage = Int(arc4random_uniform(UInt32(totalPages!))) + 1
                var methodParametersWithPageNumber = methodParameters
                methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = "\(randomPage)"
                
                let requestForRandomImages = URLRequest(url: self.flickrURLFromParameters(methodParametersWithPageNumber as [String : AnyObject]))
                let _ = self.taskForHttpRequest(requestForRandomImages, completionHandlerForPOST: { (randomResult, randomError) in
                    if (error != nil) {
                        showSimpleErrorAlert(_message: (error?.localizedDescription)!, _sender: sender)
                    }
                    if ( result == nil) {
                        showSimpleErrorAlert(_message: "No photos", _sender: sender)
                    }
                    
                    // Random select 50 of the photo array
                    
                    
                })
            }
           
            
        }
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
    
    
    
    
    
    
    
//    func startHttpTask(_ url: URL, method: String, parameters: NSDictionary, jsonBody: String, completionHandlerForPOST: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
//        
//        let request = NSMutableURLRequest(url: url)
//        request.httpMethod = method
//        for parameter in parameters {
//            request.addValue(parameter.value as! String, forHTTPHeaderField: parameter.key as! String)
//        }
//        request.httpBody = jsonBody.data(using: String.Encoding.utf8)
//        
//        return self.taskForHttpRequest(request, completionHandlerForPOST: completionHandlerForPOST)
//    }
    
    func taskForHttpRequest(_ request: URLRequest, completionHandlerForPOST: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForPOST(nil, NSError(domain: "taskForHttpRequest", code: 1, userInfo: userInfo))
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
            print(parsedResult)
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
            
            completionHandlerForPOST(photosDictionary as AnyObject?, nil)
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
