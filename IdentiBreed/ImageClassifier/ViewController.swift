import CoreML
import Vision
import UIKit

class ViewController: UIViewController
{

  // MARK: - IBOutlets
  @IBOutlet weak var petImage: UIImageView!
  @IBOutlet weak var resultsText: UILabel!

  // MARK: - View Life Cycle
  override func viewDidLoad()
  {
    super.viewDidLoad()
  }
}

// MARK: - IBActions
extension ViewController {
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
extension ViewController {
  func classifyAnimal(image: UIImage) -> String {
    resultsText.text = "Analyzing your pet..."
    let model = DogsVsCats();
    guard let prediction = try? model.prediction(image: image.cgImage! as! CVPixelBuffer) else {fatalError("Unexpected runtime error...")}
    return prediction.classLabel
  }
  func classifyDogBreed(image: CIImage)
  {
    // Load the ML model through its generated class
    guard let model = try? VNCoreMLModel(for: DogClassifier().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputText = ""
      
      for res in results!{
        outputText += "\(res.identifier): \(Int(res.confidence * 100))%\n"
      }
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
  func classifyCatType(image: CIImage)
  {
    // Load the ML model through its generated class
    guard let model = try? VNCoreMLModel(for: DogClassifier().model) else {
      fatalError("Could not load Dog Classifier model...")
    }
    
    // Create a Vision request with completion handler
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      let results = request.results as? [VNClassificationObservation]

      var outputText = ""
      
      for res in results!{
        outputText += "\(res.identifier): \(Int(res.confidence * 100))%\n"
      }
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

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    dismiss(animated: true)

    guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
      fatalError("Could not properly upload image...")
    }

    petImage.image = image
    guard let ciImage = CIImage(image: image) else {
      fatalError("Could not convert UIImage to CIImage...")
    }
    classifyDogBreed(image: ciImage)
    /*let animal = classifyAnimal(image: scene.image!)
    if(animal == "Cats")
    {
      classifyCatType(image: ciImage)
    }
    else
    {
      classifyDogBreed(image: ciImage)
    }*/
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}
