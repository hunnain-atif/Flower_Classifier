//
//  ViewController.swift
//  Flower_Classifier
//
//  Created by Hunnain Atif on 2020-04-11.
//  Copyright © 2020 Hunnain Atif. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let coreImage = CIImage(image: userImage) else {
                fatalError("Unable to convert provided picture into CIImage")
            }
            
            detect(ciImage: coreImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(ciImage userImage: CIImage) {
        guard let coreModel = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Could not load FlowerClassifier coreML model")
        }
        
        let request = VNCoreMLRequest(model: coreModel) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Unable to return results as VNClassificationObservation")
            }
            
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestAPI(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: userImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestAPI(flowerName: String) {
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got info from wikipedia API")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let extract = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let imageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: imageURL))
                self.label.text = extract
            }
        }
    }
    
    
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil )
    }
    
    


}
