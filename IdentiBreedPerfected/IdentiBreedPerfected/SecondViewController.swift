//
//  SecondViewController.swift
//  IdentiBreedPerfected
//
//  Created by Nicholas Assaderaghi on 4/14/20.
//  Copyright © 2020 Liege LLC. All rights reserved.
//

import Foundation
import CoreML
import Vision
import UIKit
import Firebase
import AVKit

class SecondViewController: UIViewController, ResultsHandlerDelegate
{
    @IBOutlet weak var petImage: UIImageView!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var similarPets: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var breedInfo: UILabel!
    
    public var results = [String]()
    public var userSimilarPets = [(QueryDocumentSnapshot, Int)]()
    public var petImageData: UIImage!
    public var breedResults = [String]()
    var resultsHandler = ResultsHandler()
    var breedInfoDictionary: [String: String] = [:]
        
    override func viewDidLoad()
    {
        super.viewDidLoad()
        similarPets.delegate = self
        similarPets.dataSource = self
        similarPets.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        resultsHandler.results = breedResults
        resultsHandler.delegate = self
        resultsTable.delegate = resultsHandler
        resultsTable.dataSource = resultsHandler
        resultsTable.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        petImage.image = petImageData
        breedInfo.text = breedInfoDictionary[breedResults[0]]
        self.view.bringSubviewToFront(backButton)
    }
    @IBAction func backButton(_ sender: Any)
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    func selectBreed(_ breed: String)
    {
        breedInfo.text = breedInfoDictionary[breed]
    }
}
extension SecondViewController: UITableViewDataSource, UITableViewDelegate
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
        let urlString = userSimilarPets[indexPath.row].0.data()["Link"] as! String
        if let realData = try? Data(contentsOf: NSURL(string: urlString)! as URL)
        {
            if let image = UIImage(data: realData)
            {
                cell.imageView!.image = image
                cell.imageView!.contentMode = .scaleAspectFit
                var infoText = "Similarity: \(userSimilarPets[indexPath.row].1)\n"
                let probabilitiesInfo = userSimilarPets[indexPath.row].0.data()["Probabilities"] as! [Int]
                let breedsInfo = userSimilarPets[indexPath.row].0.data()["Breeds"] as! [String]
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
                cell.textLabel!.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                cell.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return userSimilarPets.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 150
    }
}
protocol ResultsHandlerDelegate: class
{
    func selectBreed(_ breed: String)
}
class ResultsHandler: UITableViewCell
{
    public var results = [String]()
    public var selectedBreed = ""
    weak var delegate: ResultsHandlerDelegate?
}
extension ResultsHandler: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (selectedBreed == "")
        {
            selectedBreed = results[0]
        }
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if (selectedBreed == "")
        {
            selectedBreed = results[0]
        }
        let cell = BreedCell()
        cell.textLabel!.text = results[indexPath.row]
        cell.textLabel!.numberOfLines = 1
        cell.textLabel!.textAlignment = .center
        cell.textLabel!.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        cell.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        selectedBreed = results[indexPath.row]
        delegate?.selectBreed(selectedBreed)
    }
}

