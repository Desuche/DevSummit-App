//
//  GameObjectDetector.swift
//  Social Connect
//
//  Created by Vanessa Chan on 28/5/2025.
//

import Foundation
import CoreML
import Vision
import CoreImage

class GameObjectDetector2: ObservableObject {
    
    func detect(ciImage: CIImage) -> [Int] {
        guard let model = try? VNCoreMLModel(for: MyObjectDetector(configuration: MLModelConfiguration()).model) else {
            return []
        }
        
        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }
        
        var numerics = [Int]()
        
        for objectObservation in results {
            let topLabel = objectObservation.labels[0]
            numerics.append(topLabel.numeric())
            
        }
        
        // Return the numerics array for further use
        return numerics
    }
}

class GameObjectDetector: ObservableObject {
    
    func detect(ciImage: CIImage) -> [Int] {
        // Attempt to initialize the model and capture any errors
        do {
            let model = try VNCoreMLModel(for: MyObjectDetector(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model)
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try handler.perform([request])
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("No model results")
                return []
            }
            return [1234, 1234, 1234, 1122]
            
            
            
            var numerics = [Int]()
            for objectObservation in results {
                let topLabel = objectObservation.labels[0]
                numerics.append(topLabel.numeric())
            }
            
            return numerics
            
        } catch {
            // Print detailed error information
            print("Error initializing model or performing request: \(error.localizedDescription)")
            return []
        }
    }
}

extension VNClassificationObservation {
    func numeric() -> Int {
        let features = self.identifier.components(separatedBy: "_")
        
        let featureToInt: [String: Int] = [
            "one": 0,
            "two": 1,
            "three": 2,
            "red": 0,
            "green": 1,
            "purple": 2,
            "solid": 0,
            "striped": 1,
            "open": 2,
            "squiggle": 0,
            "diamond": 1,
            "oval": 2
        ]
        
        var x = 0
        var value = 0
        for feature in features {
            if let intValue = featureToInt[feature] {
                value += (intValue + 1) * power(10, x)
            }
            x += 1
        }
        
        return value
    }
    
    func power(_ base: Int, _ exponent: Int) -> Int {
        var result = 1
        for _ in 0..<exponent {
            result *= base
        }
        return result
    }
}
