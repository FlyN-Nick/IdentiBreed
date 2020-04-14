import CoreML
import Vision
import UIKit
import Firebase
import AVKit

class ViewController: UIViewController
{

  // MARK: - IBOutlets
  @IBOutlet weak var petImage: UIImageView!
  @IBOutlet weak var resultsText: UILabel!
  @IBOutlet weak var similarPetsView: UITableView!
    
  var badCount = 0
    
  var userSimilarPets = [(String, Int)]()
  
  // MARK: - View Did Load
  override func viewDidLoad()
  {
    super.viewDidLoad()
    similarPetsView.delegate = self
    similarPetsView.dataSource = self
    let db = Firestore.firestore()
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
                    var indexer = 0
                    var similarPets = [(String, Int)]()
                    print("made it")
                    print("# of documents: \(querySnapshot!.documents.count)")
                    for document in querySnapshot!.documents
                    {
                        let breeds = document.data()["Breeds"] as! [String]
                        let probabilities = document.data()["Probabilities"] as! [Int]
                        var similarityScore = 0
                        print("# of breeds: \(breeds.count)")
                        for breed in breeds
                        {
                            if (userBreeds.contains(breed))
                            {
                                print("userProbs.count: \(userProbabilities.count), userIndex: \(userBreeds.firstIndex(of: breed)!), probabilities.count: \(probabilities.count), indexer: \(indexer)")
                                if (userProbabilities[userBreeds.firstIndex(of: breed)!] > probabilities[indexer])
                                {
                                    similarityScore += (probabilities[indexer]/userProbabilities[userBreeds.firstIndex(of: breed)!])
                                }
                                else if (userProbabilities[userBreeds.firstIndex(of: breed)!] < probabilities[indexer])
                                {
                                    similarityScore += (userProbabilities[userBreeds.firstIndex(of: breed)!]/probabilities[indexer])
                                }
                                else
                                {
                                    similarityScore += 1
                                }
                            }
                        }
                        if similarityScore > 0
                        {
                            let temp = (document.data()["Link"] as! String, similarityScore)
                            similarPets.append(temp)
                        }
                        indexer += 1
                    }
                    let sortedSimilarPets = similarPets.sorted {
                        $0.1 > $1.1
                    }
                    self.userSimilarPets = sortedSimilarPets
                    print("SimilarPets: \(self.userSimilarPets)")
                    self.similarPetsView.reloadData()
                }
        }
    }
  // MARK: - Firebase Upload
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
            print("url: \(urlString), data: \(data)")
            dataReference.setData(data, completion: {(err) in
              if err != nil
              {
                return
              }
              else
              {
                print("Image and data successfully uploaded!")
                self.comparePet(userBreeds: breeds, userProbabilities: probabilities)
              }
            })
        }
    }
  }
  // MARK: - Classify Animal
  func classifyAnimal(image: UIImage, imageTwo: CIImage)
  {
    resultsText.text = "Analyzing your pet..."
    
    // Load the ML model through its generated class
    guard let model = try? VNCoreMLModel(for: DogsVsCats().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]
        if (results![0].identifier == "Cats")
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
      
      for res in results!
      {
        var breed = res.identifier as String
        breed = String(breed.dropFirst(10))
        breed = breed.replacingOccurrences(of: "_", with: " ")
        let probability = Int(res.confidence*100)
        if (probability > 0)
        {
            breeds.append(breed.capitalized)
            probabilities.append(probability)
            outputText += "\(breed.capitalized): \(probability)%\n"
        }
      }
      print("Breeds: \(breeds)")
      print("Probabilities \(probabilities)")
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
      }
    }
    
    // Run the classifier on global dispatch queue
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
      for res in results!
      {
        let probability = Int(res.confidence*100)
        if (probability > 0)
        {
            outputText += "\(res.identifier): \(Int(res.confidence * 100))%\n"
            breeds.append(res.identifier as String)
            probabilities.append(probability)
        }
      }
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
      }
    }
    
    // Run the classifier on global dispatch queue
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
// MARK: - Table View Code
extension ViewController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if (userSimilarPets.count == 0)
        {
            return PhotoCell()
        }
        else if (userSimilarPets.count <= indexPath.row)
        {
            return PhotoCell()
        }
        let cell = PhotoCell()
        let urlString = userSimilarPets[indexPath.row].0
        print("Here's the url string: \(urlString)")
        if let realData = try? Data(contentsOf: NSURL(string: urlString)! as URL)
        {
            if let image = UIImage(data: realData)
            {
                cell.setPhoto(image: image)
                /*DispatchQueue.main.async
                {
                    cell.setPhoto(image: image)
                }*/
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (userSimilarPets.count == 0)
        {
            return badCount
        }
        else
        {
            return userSimilarPets.count
        }
    }
}
