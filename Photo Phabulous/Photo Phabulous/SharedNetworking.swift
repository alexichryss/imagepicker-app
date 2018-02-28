//
//  SharedNetworking.swift
//  Photo Phabulous
//
//  Created by Alexi Chryssanthou on 2/22/18.
//  Copyright © 2018 Alexi Chryssanthou. All rights reserved.
//

import Foundation
import SystemConfiguration
import UIKit

class NetworkManager {
    
    // Mark: - Properties
    static let sharedInstance = NetworkManager()
    let cache = NSCache<NSString, UIImage>()
    
    // This prevents others from using the default '()' initializer for this class.
    private init() {}
    
    enum NetworkError: Error {
        case badConnection
        case badURL
        case badURLRequest
        case badImage(message: String)
    }
    
    // Mark: - Methods
    func checkNetwork() throws {
        let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com")
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        let isReachable: Bool = flags.contains(.reachable)
        if !isReachable { throw NetworkError.badConnection }
    }
    
    func getData(_ url: String, view: UICollectionViewController, completion:@escaping (DataFeed?) -> Void) throws {
        //IJProgressView.shared.showProgressView(view.view)
        // Throw error if network is unreachable
        do
        {
            _ = try checkNetwork()
            print("Connection is up. Good to go!")
        } catch NetworkError.badConnection {
            print("No Internet Detected")
        } catch {
            print("Unexpected Error has occurred")
        }
        
        // Transform the `url` parameter argument to a `URL`
        guard let url = NSURL(string: url) else {
            throw NetworkError.badURL
        }
        
        // Create a url session and data task
        let session = URLSession.shared
        let task = session.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
            
            // Print out the response (for debugging purpose)
            if let response = response {
                print("Response: \(response)") }
            
            // Ensure there were no errors returned from the request
            guard error == nil else {
                self.showAlert(title:"Error: URLRequest", message:"The URL Session Request failed.")
                return
            }
            
            // Ensure there is data and unwrap it
            guard let data = data else {
                self.showAlert(title:"Error: No Data", message:"The data returned nil")
                return
            }
            
            // print size of data and save data feed to documents, then convert to JSON
            print("Raw data: \(data)")
            
            let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let jsonFeed: Json = Json(feed: data)
            NSKeyedArchiver.archiveRootObject(jsonFeed, toFile: docs.appending("/jsonFeed.plist"))
            print(docs)

            // Serialize the raw data into our custom structs
            do {
                // Covert JSON to `News`
                let decoder = JSONDecoder()
                let results = try decoder.decode(DataFeed.self, from: data)
                
                // Call the completion block closure and pass the News as argument to the completion block.
                completion(results)
            } catch {
                self.showAlert(title:"Error: JSON", message:"There was a problem serializing/decoding JSON")
                print("Error serializing/decoding JSON: \(error)")
            }
        })
        
        // Tasks start off in suspended state, we need to kick it off
        task.resume()
    }
    
    func getPhoto(from: ImageData, withPrefix: String) throws -> UIImage {
        

        guard let key = from.image_url else { throw NetworkError.badImage(message: "couldn't make image_url key") }
        
        let imageURL = withPrefix + key
        print("get: \(key)")
    
        // Try to retrieve the data from the cache
        var data = self.cache.object(forKey: key as NSString)
    
        if data != nil {
            return data!
        }
    
        // if not, recreate the data
    
        // make url string into url
        guard let url = NSURL(string: imageURL) else {
            throw NetworkError.badImage(message: "Unable to create NSURL from string")
        }
        // get the image data and turn into image
        guard let imageData = try? Data(contentsOf: url as URL) else { throw NetworkError.badImage(message: "couldn't get image")}
    
        guard let image: UIImage = UIImage(data: imageData) else { throw NetworkError.badImage(message: "couldn't make image") }
    
        data = image
        
        // Store it in the cache for next time
        self.cache.setObject(data!, forKey: key as NSString)
        // Return the data to whoever called for it
        return data!

    }
    
    func uploadRequest(user: NSString, image: UIImage, caption: NSString) {
        
        let boundary = generateBoundaryString()
        let imageJPEGData = UIImageJPEGRepresentation(image,0.1)
        
        guard let imageData = imageJPEGData else {return}
        
        // Create the URL, the user should be unique
        let url = NSURL(string: "https://stachesandglasses.appspot.com/post/\(user)/")
        
        // Create the request
        let request = NSMutableURLRequest(url: url! as URL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Set the type of the data being sent
        let mimetype = "image/jpeg"
        // This is not necessary
        let fileName = "test.png"
        
        // Create data for the body
        let body = NSMutableData()
        body.append("\r\n--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        
        // Caption data (this is optional)
        body.append("Content-Disposition:form-data; name=\"caption\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("CaptionText\r\n".data(using: String.Encoding.utf8)!)
        
        // Image data
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        
        // Trailing boundary
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        // Set the body in the request
        request.httpBody = body as Data
        
        // Create a data task
        let session = URLSession.shared
        _ = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            // Need more robust errory handling here
            // 200 response is successful post
            print(response!)
            print(error as Any)
            
            // The data returned is the update JSON list of all the images
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString as Any)
            }.resume()
        
    }
    
    /// A unique string that signifies breaks in the posted data
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        let topvc = UIApplication.shared.keyWindow?.rootViewController

        topvc?.present(alert, animated: true)
    }
}
