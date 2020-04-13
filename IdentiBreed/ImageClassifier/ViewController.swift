import CoreML
import Vision
import UIKit
import Firebase
import FirebaseFirestore

class ViewController: UIViewController
{

  // MARK: - IBOutlets
  @IBOutlet weak var petImage: UIImageView!
  @IBOutlet weak var resultsText: UILabel!
  let comparable = false
  var userBreeds: Array<String>?
  var userProbabilities: Array<Int>?
  
  // MARK: - View Life Cycle
  override func viewDidLoad()
  {
    super.viewDidLoad()
    petImage.translatesAutoresizingMaskIntoConstraints = false;
    petImage.setGIFImage(name: "dna-rna-chromosomes-double-helix-rotating-animated-gif-16.gif")
  }
}

// MARK: - IBActions
extension ViewController {
  @IBAction func comparePet(_ sender: Any) {
    guard userBreeds != nil else { return }
    let db = Firestore.firestore()
    db.collection("imageInfos")
    .getDocuments() { (querySnapshot, err) in
      if let err = err
      {
          print("Error getting documents: \(err)")
      }
      else
      {
        var indexer = 0
        var similarPets = [(QueryDocumentSnapshot, Int)]()
        for document in querySnapshot!.documents
        {
          let breeds = document.data()["Breeds"] as! [String]
          let probabilities = document.data()["Probabilities"] as! [Int]
          var similarityScore = 0
          for breed in breeds
          {
            if (self.userBreeds!.contains(breed))
            {
              if (self.userProbabilities![indexer] > probabilities[indexer])
              {
                similarityScore += (probabilities[indexer]/self.userProbabilities![indexer])
              }
              else if (self.userProbabilities![indexer] < probabilities[indexer])
              {
                similarityScore += (self.userProbabilities![indexer]/probabilities[indexer])
              }
              else
              {
                similarityScore += 1
              }
            }
          }
          if similarityScore > 0
          {
            let temp = (document, similarityScore)
            similarPets.append(temp)
          }
          indexer += 1
        }
      }
    }
  }
  @IBAction func pickImage(_ sender: Any) {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    let actionSheet = UIAlertController(title: "Upload photo from:", message: "", preferredStyle: .actionSheet)
    actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else
        {
            print("The camera is unavailable, so you must be simulating an iPhone.")
        }
    }))
    actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }))
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(actionSheet, animated: true)
  }
  @IBAction func pickImageButton(_ sender: Any) {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    let actionSheet = UIAlertController(title: "Upload photo from:", message: "", preferredStyle: .actionSheet)
    actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else
        {
            print("The camera is unavailable, so you must be simulating an iPhone.")
        }
    }))
    actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }))
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(actionSheet, animated: true)
  }
}

// MARK: - Methods
extension ViewController {
  func uploadPetImage(_ image: UIImage, breeds: [String], probabilities: [Int])
  {
      let uid = UUID().uuidString
      let imageRef = Storage.storage().reference().child("images/\(uid)")
      
    guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      imageRef.putData(imageData, metadata: metadata) { metaData, error in
          if error != nil
          {
              return
          }
          imageRef.downloadURL { (url, error) in
            if error != nil
            {
                return
            }
            guard let url = url else {
                return
            }
            let dataReference = Firestore.firestore().collection("imageInfos").document()
            let urlString = url.absoluteString
            let data = [
              "Breeds": breeds,
              "Probabilities": probabilities,
              "Link": urlString
              ] as [String : Any]
            dataReference.setData(data, completion: {(err) in
              if err != nil {
                return
              }
            })
        }
    }
  }
  func classifyAnimal(image: UIImage, imageTwo: CIImage) {
    resultsText.text = "Analyzing your pet..."
    let model = DogsVsCats();
    guard let prediction = try? model.prediction(image: image.cgImage! as! CVPixelBuffer) else {fatalError("Unexpected runtime error...")}
    if (prediction.classLabel == "Cats")
    {
      classifyCatType(image: imageTwo, uiimage: image)
    }
    else
    {
      classifyDogBreed(image: imageTwo, uiimage: image)
    }
  }
  func classifyDogBreed(image: CIImage, uiimage: UIImage)
  {
    // Load the ML model through its generated class
    guard let model = try? VNCoreMLModel(for: DogClassifier().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputText = ""
      var probabilities = Array<Int>()
      var breeds = Array<String>()
      
      for res in results!{
        var breed = res.identifier as String
        breed = String(breed.dropFirst(10))
        breed = breed.replacingOccurrences(of: "_", with: " ")
        let probability = Int(res.confidence*100)
        outputText += "\(breed.capitalized): \(probability)%\n"
        breeds.append(breed.capitalized)
        probabilities.append(probability)
      }
      self!.userBreeds = breeds
      self!.userProbabilities = probabilities
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
      }
    }
    
    // Run the classifier on global dispatch queue
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        print(error)
      }
    }
  }
  func classifyCatType(image: CIImage, uiimage: UIImage)
  {
    // Load the ML model through its generated class
    guard let model = try? VNCoreMLModel(for: CatClassifier().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputText = ""
      var breeds = Array<String>()
      var probabilities = Array<Int>()
      for res in results!{
        outputText += "\(res.identifier): \(Int(res.confidence * 100))%\n"
        breeds.append(res.identifier as String)
        probabilities.append(Int(res.confidence*100))
      }
      self!.userBreeds = breeds
      self!.userProbabilities = probabilities
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
      }
    }
    
    // Run the classifier on global dispatch queue
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        print(error)
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

    dismiss(animated: true)

    guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
      fatalError("Could not properly upload image...")
    }
    petImage.stopAnimating()
    petImage.image = image
    guard let ciImage = CIImage(image: image) else {
      fatalError("Could not convert UIImage to CIImage...")
    }
    classifyAnimal(image: petImage.image!, imageTwo: ciImage)
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}






extension UIImageView {
    func setGIFImage(name: String, repeatCount: Int = 0 ) {
        DispatchQueue.global().async {
            if let gif = UIImage.makeGIFFromCollection(name: name, repeatCount: repeatCount) {
                DispatchQueue.main.async {
                    self.setImage(withGIF: gif)
                    self.startAnimating()
                }
            }
        }
    }

    private func setImage(withGIF gif: GIF) {
        animationImages = gif.images
        animationDuration = gif.durationInSec
        animationRepeatCount = gif.repeatCount
    }
}

extension UIImage {
    class func makeGIFFromCollection(name: String, repeatCount: Int = 0) -> GIF? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            print("Cannot find a path from the file \"\(name)\"")
            return nil
        }

        let url = URL(fileURLWithPath: path)
        let data = try? Data(contentsOf: url)
        guard let d = data else {
            print("Cannot turn image named \"\(name)\" into data")
            return nil
        }

        return makeGIFFromData(data: d, repeatCount: repeatCount)
    }

    class func makeGIFFromData(data: Data, repeatCount: Int = 0) -> GIF? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Source for the image does not exist")
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                                source: source)
                duration += delaySeconds
            }
        }

        return GIF(images: images, durationInSec: duration, repeatCount: repeatCount)
    }

    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.0

        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }

        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)

        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as? Double ?? 0

        return delay
    }
}

class GIF: NSObject {
    let images: [UIImage]
    let durationInSec: TimeInterval
    let repeatCount: Int

    init(images: [UIImage], durationInSec: TimeInterval, repeatCount: Int = 0) {
        self.images = images
        self.durationInSec = durationInSec
        self.repeatCount = repeatCount
    }
}
