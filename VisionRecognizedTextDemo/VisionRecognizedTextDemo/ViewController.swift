//
//  ViewController.swift
//  VisionRecognizedTextDemo
//
//  Created by Ben Dodson on 10/06/2019.
//  Copyright © 2019 Ben Dodson. All rights reserved.
//

import UIKit
import Vision
import Photos

class ViewController: UIViewController {
    
    var image: UIImage?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var setLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en_GB"]
        return request
    }()
    
    func processImage() {
        nameLabel.text = ""
        setLabel.text = ""
        numberLabel.text = ""
        
        guard let image = image, let cgImage = image.cgImage else { return }
        
        let requests = [textDetectionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
    fileprivate func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            presentAlert(title: "Error", message: error.localizedDescription)
            return
        }
        guard let results = request?.results, results.count > 0 else {
            presentAlert(title: "Error", message: "No text was found.")
            return
        }

        var components = [CardComponent]()
        
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    let component = CardComponent()
                    component.x = observation.boundingBox.origin.x
                    component.y = observation.boundingBox.origin.y
                    component.text = text.string
                    components.append(component)
                }
            }
        }
        
        guard let firstComponent = components.first else { return }
        
        var nameComponent = firstComponent
        var numberComponent = firstComponent
        var setComponent = firstComponent
        for component in components {
            if component.x < nameComponent.x && component.y > nameComponent.y {
                nameComponent = component
            }
            
            if component.x < (numberComponent.x + 0.05) && component.y < numberComponent.y {
                numberComponent = setComponent
                setComponent = component
            }
        }
        
        DispatchQueue.main.async {
            self.nameLabel.text = nameComponent.text
            if numberComponent.text.count >= 3 {
                self.numberLabel.text = "\(numberComponent.text.prefix(3))"
            }
            if setComponent.text.count >= 3 {
                self.setLabel.text = "\(setComponent.text.prefix(3))"
            }
        }
    }
    
    fileprivate func presentAlert(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: Buttons

    @IBAction func choosePhoto(_ sender: Any) {
        presentPhotoPicker(type: .photoLibrary)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        presentPhotoPicker(type: .camera)
    }
    
    fileprivate func presentPhotoPicker(type: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.sourceType = type
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true, completion: nil)
        image = info[.originalImage] as? UIImage
        processImage()
    }
    
}
