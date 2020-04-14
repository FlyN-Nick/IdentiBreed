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
  var userSimilarPets = [(QueryDocumentSnapshot, Int)]()
  var userLink = String()
  
  // MARK: - View Did Load
  override func viewDidLoad()
  {
    super.viewDidLoad()
    similarPetsView.delegate = self
    similarPetsView.dataSource = self
    self.resultsText.textAlignment = .center
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
                    self.similarPetsView.reloadData()
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
    resultsText.text = "Analyzing your pet..."
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

      var outputText = ""
      var probabilities = Array<Int>()
      var breeds = Array<String>()
      var indexer = 0
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
            if (indexer == 4)
            {
                outputText += "\(breed.capitalized): \(probability)%"
                indexer += 1
            }
            else if (indexer < 5)
            {
                outputText += "\(breed.capitalized): \(probability)%\n"
                indexer += 1
            }
        }
      }
      print("Breeds: \(breeds)")
      print("Probabilities: \(probabilities)")
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
        self?.resultsText.textAlignment = .left
      }
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

      var outputText = ""
      var breeds = Array<String>()
      var probabilities = Array<Int>()
      var counter = 0
      for res in results!
      {
        let probability = Int(res.confidence*100)
        if (probability > 0)
        {
            breeds.append(res.identifier as String)
            probabilities.append(probability)
            if (counter == 4)
            {
                outputText += "\(res.identifier): \(Int(res.confidence * 100))%"
                counter += 1
            }
            else if (counter < 5)
            {
                outputText += "\(res.identifier): \(Int(res.confidence * 100))%\n"
                counter += 1
            }
        }
      }
      self!.uploadPetImage(uiimage, breeds: breeds, probabilities: probabilities)
      DispatchQueue.main.async { [weak self] in
        self?.resultsText.text! = outputText
        self?.resultsText.textAlignment = .left
      }
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
        /*if (indexPath.row == 0)
        {
            let cell = PhotoCell()
            cell.textLabel!.text = "Similar Pets"
            return PhotoCell()
        }
        else */if (userSimilarPets.count == 0)
        {
            return PhotoCell()
        }
        else if (userSimilarPets.count <= indexPath.row)
        {
            return PhotoCell()
        }
        let cell = PhotoCell()
        let urlString = userSimilarPets[indexPath.row/*-1*/].0.data()["Link"] as! String
        if let realData = try? Data(contentsOf: NSURL(string: urlString)! as URL)
        {
            if let image = UIImage(data: realData)
            {
                cell.imageView!.image = image
                cell.imageView!.contentMode = .scaleAspectFit
                var infoText = "Similarity: \(userSimilarPets[indexPath.row/*-1*/].1)\n"
                let probabilitiesInfo = userSimilarPets[indexPath.row/*-1*/].0.data()["Probabilities"] as! [Int]
                let breedsInfo = userSimilarPets[indexPath.row/*-1*/].0.data()["Breeds"] as! [String]
                var counter = 0
                for probability in probabilitiesInfo
                {
                    if (counter == 4)
                    {
                        infoText += "\(breedsInfo[counter]): \(probability)%"
                        counter += 1
                    }
                    else if (counter < 5)
                    {
                        infoText += "\(breedsInfo[counter]): \(probability)%\n"
                        counter += 1
                    }
                }
                cell.textLabel!.text = infoText
                cell.textLabel!.textAlignment = .left
                cell.textLabel!.font = UIFont.preferredFont(forTextStyle: .body)
                cell.textLabel!.numberOfLines = 6
                cell.textLabel!.font = cell.textLabel!.font.withSize(13)
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
            return (userSimilarPets.count/*+1*/)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 150
    }
}
