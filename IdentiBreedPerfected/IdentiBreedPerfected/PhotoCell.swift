//
//  PhotoCell.swift
//  IdentiBreedPerfected
//
//  Created by Nicholas Assaderaghi on 4/13/20.
//  Copyright © 2020 Liege LLC. All rights reserved.
//

import UIKit
import Foundation

class PhotoCell: UITableViewCell
{
    @IBOutlet weak var petImage: UIImageView!
    func setPhoto(image: UIImage)
    {
        print(image)
        petImage.image = image
    }
}
