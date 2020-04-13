import CoreML
import Vision
import UIKit
import Firebase
import AVKit

class MainViewController: UIViewController
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
    print("YEET")
    //petImage.translatesAutoresizingMaskIntoConstraints = false;
    /*let captureSession = AVCaptureSession()
    guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
    guard let input =  try? AVCaptureDeviceInput(device: captureDevice) else { return }
    captureSession.addInput(input)
    captureSession.startRunning()
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    view.layer.addSublayer(previewLayer)
    previewLayer.frame = view.frame*/
  }
}

// MARK: - IBActions
extension MainViewController {
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
}

// MARK: - Methods
extension MainViewController {
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
    guard let model = try? VNCoreMLModel(for: CatClassifierFixed().model) else {
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
extension MainViewController: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

    dismiss(animated: true)

    guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
      fatalError("Could not properly upload image...")
    }
    petImage.image = image
    guard let ciImage = CIImage(image: image) else {
      fatalError("Could not convert UIImage to CIImage...")
    }
    classifyAnimal(image: petImage.image!, imageTwo: ciImage)
  }
}

// MARK: - UINavigationControllerDelegate
extension MainViewController: UINavigationControllerDelegate {
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
