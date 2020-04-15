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

class SecondViewController: UIViewController
{
    @IBOutlet weak var petImage: UIImageView!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var breedInfo: UILabel!
    @IBOutlet weak var similarPets: UITableView!
    
    public var results = [String]()
    public var userSimilarPets = [(QueryDocumentSnapshot, Int)]()
    public var petImageData: UIImage!
    var resultsHandler = ResultsHandler()
    var breedLinkDictionary: [String: String] = [:]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        similarPets.delegate = self
        similarPets.dataSource = self
        resultsTable.delegate = resultsHandler
        resultsTable.dataSource = resultsHandler
        petImage.image = petImageData
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
class ResultsHandler: UITableViewCell
{
    public var results = [String]()
}
extension ResultsHandler: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = BreedCell()
        cell.textLabel!.text = results[indexPath.row]
        cell.textLabel!.numberOfLines = 1
        cell.textLabel!.textAlignment = .center
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //let selectedBreed = results[indexPath.row]
        //breedInfo.text = breedLinkDictionary[selectedBreed]
    }
}

