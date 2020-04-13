//
//  PhotoCell.swift
//  IdentiBreedPerfected
//
//  Created by Nicholas Assaderaghi on 4/13/20.
//  Copyright © 2020 Liege LLC. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UITableViewCell {
    @IBOutlet weak var imageView: UIImageView!
    func setPhoto(image: UIImage)
    {
        imageView.image = image
    }
}
