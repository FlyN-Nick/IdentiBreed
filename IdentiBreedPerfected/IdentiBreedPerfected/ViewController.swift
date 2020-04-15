import CoreML
import Vision
import UIKit
import Firebase
import AVKit

class ViewController: UIViewController
{

  // MARK: - IBOutlets
  @IBOutlet weak var petImage: UIImageView!
  //@IBOutlet weak var resultsTable: UITableView!
  @IBOutlet weak var LoadingIndicator: UIActivityIndicatorView!
    
  var badCount = 0
  var userSimilarPets = [(QueryDocumentSnapshot, Int)]()
  var userLink = String()
  var results = [String]()
  var breedResults = [String]()
  
  // MARK: - View Did Load
  override func viewDidLoad()
  {
    super.viewDidLoad()
    let db = Firestore.firestore()
    petImage.startAnimating()
    LoadingIndicator.isOpaque = false
    LoadingIndicator.isHidden = true
    LoadingIndicator.stopAnimating()
    db.collection("imageInfos")
        .getDocuments() { (querySnapshot, err) in
            if let err = err
            {
                print("Error getting documents: \(err)")
            }
            else
            {
                self.badCount = querySnapshot!.documents.count
            }
    }
  }
}

extension ViewController
{
  // MARK: - Pick Image Button
  @IBAction func pickImage(_ sender: Any)
  {
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
    // MARK: - Pick Image Text Button
    @IBAction func pickImageText(_ sender: Any)
    {
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

extension ViewController
{
    // MARK: - Compare Pet Button
    func comparePet(userBreeds: [String], userProbabilities: [Int])
    {
        let db = Firestore.firestore()
        db.collection("imageInfos")
            .getDocuments() { (querySnapshot, err) in
                if let err = err
                {
                    print("Error getting documents: \(err)")
                }
                else
                {
                    print("Successfull firebase query!")
                    var similarPets = [(QueryDocumentSnapshot, Int)]()
                    for document in querySnapshot!.documents
                    {
                        let breeds = document.data()["Breeds"] as! [String]
                        let probabilities = document.data()["Probabilities"] as! [Int]
                        var similarityScore = 0
                        var indexer = 0
                        for breed in breeds
                        {
                            if (userBreeds.contains(breed))
                            {
                                let userIndex = userBreeds.firstIndex(of: breed)!
                                if (userProbabilities[userIndex] > probabilities[indexer])
                                {
                                    let score = (probabilities[indexer]/userProbabilities[userIndex])
                                    let gravity = (probabilities[indexer]+userProbabilities[userIndex])/2
                                    similarityScore += score*gravity
                                }
                                else if (userProbabilities[userBreeds.firstIndex(of: breed)!] < probabilities[indexer])
                                {
                                    let score = (userProbabilities[userIndex]/probabilities[indexer])
                                    let gravity = (probabilities[indexer]+userProbabilities[userIndex])/2
                                    similarityScore += score*gravity
                                }
                                else
                                {
                                    let score = 1
                                    let gravity = probabilities[indexer]
                                    similarityScore += score*gravity
                                }
                            }
                            indexer += 1
                        }
                        if (document.data()["Link"] as! String == self.userLink)
                        {
                            similarityScore = 0
                        }
                        if similarityScore > 0
                        {
                            let temp = (document, similarityScore)
                            similarPets.append(temp)
                        }
                    }
                    let sortedSimilarPets = similarPets.sorted {
                        $0.1 > $1.1
                    }
                    self.userSimilarPets = sortedSimilarPets
                    let storyboard = UIStoryboard(name: "Second", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as! SecondViewController
                    vc.petImageData = self.petImage.image
                    vc.userSimilarPets = self.userSimilarPets
                    vc.results = self.results
                    vc.breedResults = self.breedResults
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }
        }
    }
  // MARK: - Firebase Upload
  func uploadPetImage(_ image: UIImage, breeds: [String], probabilities: [Int])
  {
    print("Attempting to upload image")
    let uid = UUID().uuidString
    let imageRef = Storage.storage().reference().child("images/\(uid)")
    guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      imageRef.putData(imageData, metadata: metadata) { metaData, error in
          if error != nil
          {
              print("Error while uploading image: \(String(describing: error))")
              return
          }
          imageRef.downloadURL { (url, error) in
            if error != nil
            {
                print("Error while downloading image url: \(String(describing: error))")
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
            print("Url: \(urlString), data: \(data)")
            dataReference.setData(data, completion: {(err) in
              if err != nil
              {
                print("Error while uploading image data: \(String(describing: error))")
                return
              }
              else
              {
                print("Image and data successfully uploaded!")
                self.userLink = urlString
                self.comparePet(userBreeds: breeds, userProbabilities: probabilities)
              }
            })
        }
    }
  }
  // MARK: - Classify Animal
  func classifyAnimal(image: UIImage, imageTwo: CIImage)
  {
    LoadingIndicator.isHidden = false
    LoadingIndicator.isOpaque = true
    LoadingIndicator.startAnimating()
    guard let model = try? VNCoreMLModel(for: DogsVsCats().model) else {
      fatalError("Could not load Animal Classifier model...")
    }
    
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]
        print("Identifier: \(results![0].identifier), probability: \(results![0].confidence)")
        if (results![0].identifier == "cats")
        {
            self!.classifyCatType(image: imageTwo, uiimage: image)
        }
        else
        {
            self!.classifyDogBreed(image: imageTwo, uiimage: image)
        }
    }
    
    // Run the classifier on global dispatch queue
    let handler = VNImageRequestHandler(ciImage: imageTwo)
    DispatchQueue.global(qos: .userInteractive).async {
      do
      {
        try handler.perform([request])
      }
      catch
      {
        print(error)
      }
    }
  }
  // MARK: - Classify Dog
  func classifyDogBreed(image: CIImage, uiimage: UIImage)
  {
    guard let model = try? VNCoreMLModel(for: DogClassifier().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
      let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputTextArr = [String]()
      var probabilities = Array<Int>()
      var breeds = Array<String>()
      for res in results!
      {
        var breed = res.identifier as String
        breed = String(breed.dropFirst(10))
        breed = breed.replacingOccurrences(of: "_", with: " ")
        breed = breed.replacingOccurrences(of: "-", with: " ")
        let probability = Int(res.confidence*100)
        if (probability > 0)
        {
            breeds.append(breed.capitalized)
            probabilities.append(probability)
            outputTextArr.append("\(breed.capitalized): \(probability)%")
        }
      }
      print("Breeds: \(breeds)")
      print("Probabilities: \(probabilities)")
      self!.results = outputTextArr
      self!.breedResults = breeds
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
    }
    
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do
      {
        try handler.perform([request])
      }
      catch
      {
        print(error)
      }
    }
  }
  // MARK: - Classify Cat
  func classifyCatType(image: CIImage, uiimage: UIImage)
  {
    guard let model = try? VNCoreMLModel(for: CatClassifierFixed().model) else {
      fatalError("Could not load Cat Classifier model...")
    }
      let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputTextArr = [String]()
      var breeds = Array<String>()
      var probabilities = Array<Int>()
      for res in results!
      {
        let probability = Int(res.confidence*100)
        if (probability > 0)
        {
            breeds.append(res.identifier as String)
            probabilities.append(probability)
            outputTextArr.append("\(res.identifier): \(Int(res.confidence * 100))%")
        }
      }
      self!.results = outputTextArr
      self!.breedResults = breeds
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
    }
    
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async
    {
      do
      {
        try handler.perform([request])
      }
      catch
      {
        print(error)
      }
    }
  }
}

// MARK: - Image Picker
extension ViewController: UIImagePickerControllerDelegate
{

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
  {
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
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any]
{
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

