//
//  ViewController.swift
//  JMCMarchingAnts
//
//  Created by Janusz Chudzynski on 10/5/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

/**
This file is part of JMCMarchingAnts.

JMCMarchingAnts is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

JMCMarchingAnts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with JMCMarchingAnts.  If not, see <http://www.gnu.org/licenses/>.
*/

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    //Initialize the marching ants object
    let marcher:JMCMarchingAnts = JMCMarchingAnts()
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let image = imageView.image{
            //if image exists add it to the image view
            marcher.addAnts(image, imageView: self.imageView)
            
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

