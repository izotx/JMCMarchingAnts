# JMCMarchingAnts
Example of adding marching ants selection to the edges of the images.

<h3>Usage:</h3>
1. Copy files:
copy the JMCMarchingAnts.swift file to your project
2. Create an instance of the JMCMarchingAnts class
    let marcher:JMCMarchingAnts = JMCMarchingAnts()
3. Add animated selection layer with a addAnts(image:UIIMage, imageView:UIImageView) method, where image is an image that will be processed, and the imageView is a view that selection layer will be displayed on. 
 marcher.addAnts(image, imageView: self.imageView)
class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    //Initialize the marching ants object
    let marcher:JMCMarchingAnts = JMCMarchingAnts()
    

    override func viewDidAppear(animated: Bool) {
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


