# JMCMarchingAnts
Example of adding marching ants selection to the edges of the images.
![](https://raw.githubusercontent.com/izotx/JMCMarchingAnts/master/marchingAnts.gif)

<h3>Usage:</h3>
1. Copy files:
copy the JMCMarchingAnts.swift file to your project
2. Create an instance of the JMCMarchingAnts class
```   
 let marcher:JMCMarchingAnts = JMCMarchingAnts()
``` 
3. Add animated selection layer with a addAnts(image:UIIMage, imageView:UIImageView) method, where image is an image that will be processed, and the imageView is a view that selection layer will be displayed on. 
```
 marcher.addAnts(image, imageView: self.imageView)
```
4. Enjoy yur marching ants! 


```Swift 
class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    //Initialize the marching ants object
    let marcher:JMCMarchingAnts = JMCMarchingAnts()
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let image = imageView.image{
            //if image exists add the selection layer to the image view
            marcher.addAnts(image, imageView: self.imageView)
        }
    }
}
```
<h3>License</h3>
GNU General Public License V3
