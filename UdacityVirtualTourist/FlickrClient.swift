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
    
    func startHttpTask(_ url: URL, method: String, parameters: NSDictionary, jsonBody: String, completionHandlerForPOST: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        for parameter in parameters {
            request.addValue(parameter.value as! String, forHTTPHeaderField: parameter.key as! String)
        }
        request.httpBody = jsonBody.data(using: String.Encoding.utf8)
        
        return self.taskForHttpRequest(request, completionHandlerForPOST: completionHandlerForPOST)
    }
    
    func taskForHttpRequest(_ request: NSMutableURLRequest, completionHandlerForPOST: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForPOST(nil, NSError(domain: "taskForHttpRequest", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            if (error != nil) {
                sendError("There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            /* GUARD: Was there any data returned? */
            if (data == nil) {
                sendError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
            } catch {
                NSLog("Could not parse the data as JSON: '\(newData)'")
                sendError("Could not parse the data")
                return
            }
            
            completionHandlerForPOST(parsedResult as AnyObject?, nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }

}
