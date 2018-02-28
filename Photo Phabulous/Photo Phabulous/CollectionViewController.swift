//
//  CollectionViewController.swift
//  Photo Phabulous
//
//  Created by Alexi Chryssanthou on 2/23/18.
//  Copyright © 2018 Alexi Chryssanthou. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController {
    
    var images: DataFeed?
    let urlPrefix: String = "https://stachesandglasses.appspot.com/"
    let resultsSuffix: String = "user/alexichryss/json/"
    var imageSuffix: String?
    var selectedImage: UIImage? {
        willSet(image) {
            self.view.backgroundColor = UIColor(patternImage: image!)
        }
    }
    
    let imagePickerController = UIImagePickerController()
    
    @IBAction func tapCameraButton(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Source", message: "Would you like to use the Camera or access your Photos Library?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { action in
                self.imagePickerController.allowsEditing = true
                self.imagePickerController.delegate = self
            self.present(self.imagePickerController, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Camera", style: .cancel, handler: { action in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.imagePickerController.sourceType = .camera;
                    self.imagePickerController.allowsEditing = false
                    self.present(self.imagePickerController, animated: true, completion: nil)
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let _ = screenSize.height
        
        // Attribution: https://stackoverflow.com/questions/28325277/how-to-set-cell-spacing-and-uicollectionview-uicollectionviewflowlayout-size-r
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        collectionView!.collectionViewLayout = layout
        
        // Do any additional setup after loading the view.
        fetchPhotos()
    }
    
    func fetchPhotos() {
        IJProgressView.shared.showProgressView(view)
        let urlString = urlPrefix + resultsSuffix
        do {
            _ = try NetworkManager.sharedInstance.getData(urlString, view: self) { (dataFeed) in
                self.images = dataFeed
                self.images?.urlPrefix = self.urlPrefix
                //if var dataFeed = self.images {
                for i in 0..<self.images!.results.count {
                    print("IMAGE: \(i) in \(String(describing: self.images?.results.count))")
                        do{
                            _ = try NetworkManager.sharedInstance.getPhoto(from: (self.images?.results[i]!)!, withPrefix: self.urlPrefix)
                            self.images?.results[i]!.missing = false
                            
                        } catch NetworkManager.NetworkError.badImage(let message){
                            print("problem getting image: \(message)")
                            self.images?.results[i]!.missing = true
                        } catch {
                            print("something else went wrong getting image")
                            self.images?.results[i]!.missing = true
                        }
                    }
                DispatchQueue.main.async {
                    // Anything in here is execute on the main thread
                    // You should reload your table here.
                    self.collectionView!.reloadData()
                    IJProgressView.shared.hideProgressView()
                }
            }
            
        } catch NetworkManager.NetworkError.badURL {
            print("Couldn't form URL")
        } catch {
            print("something else went wrong when fetching data")
        }
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataFeed = self.images {
            var count = 0
            
            dataFeed.results.forEach { imageData in
                if let imageData = imageData {
                    if imageData.missing == false { count += 1}
                }
            }
            
            return count
        } else {return 0}
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        if let dataFeed = images {
            if let imageData = dataFeed.results[indexPath.row] {
                do{
                    let image = try NetworkManager.sharedInstance.getPhoto(from: imageData, withPrefix: urlPrefix)
                    let imageView = UIImageView(frame: cell.contentView.bounds)
                    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = image
                    cell.contentMode = .scaleAspectFit
                    cell.contentView.addSubview(imageView)
                    cell.setNeedsLayout()
                    
                    return cell
                } catch NetworkManager.NetworkError.badImage(let message){
                    print("problem getting image: \(message)")
                } catch {
                    print("something else went wrong getting image")
                }
            }
        }

        return cell
    }
    
    // Attribution: https://stackoverflow.com/questions/42312136/how-to-send-collection-view-cell-text-via-segue
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "ShowDetail", sender: indexPath)
        
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowDetail") {

            if let vc = segue.destination as? UINavigationController {
                if let tc = vc.topViewController as? ImageDetailViewController {
                    if let dataFeed = images {
                        let selectedIndexPath = sender as? NSIndexPath
                        if let imageData = dataFeed.results[(selectedIndexPath?.row)!] {
                            do{
                                let image = try NetworkManager.sharedInstance.getPhoto(from: imageData, withPrefix: urlPrefix)
                                let imageView = UIImageView(frame: tc.view.bounds)
                                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                                imageView.contentMode = .scaleAspectFit
                                imageView.image = image
                                tc.imageShown = image
                                tc.view.addSubview(imageView)
                                print("TESTTTTT DONNNNEEE")
                            } catch NetworkManager.NetworkError.badImage(let message){
                                print("problem getting image: \(message)")
                            } catch {
                                print("something else went wrong getting image")
                            }
                        }
                    }
                }
            }
        }
    }
    
// end of VC
}

extension CollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImage = possibleImage
        } else {
            return
        }
        
        if let image = selectedImage {
            NetworkManager.sharedInstance.uploadRequest(user: "alexichryss", image: image, caption: NSUserName() as NSString)
        }
        
        dismiss(animated: true, completion: {
            self.fetchPhotos()
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
                IJProgressView.shared.hideProgressView()
            }
        })
    }
    
    func imagePickerControllerDidFinishPicking(_ picker: UIImagePickerController,didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: {
            self.fetchPhotos()
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
                IJProgressView.shared.hideProgressView()
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
