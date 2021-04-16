
# DeepLook SDK
[![Platform](https://img.shields.io/cocoapods/p/LookKit.svg?style=flat)](https://github.com/LA-Labs/LookKit_Pod)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/LookKit.svg)](https://img.shields.io/cocoapods/v/LookKit.svg)
[![Pod License](http://img.shields.io/cocoapods/l/LookKit.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

When dealing with user data privacy should be your first concern. 
DeepLook is a very lightweight framework aim to make using Computer Vision as simple as possible for iOS and macOS developers. It is a hybrid framework wrapping state-of-the-art models: VGG-Face2, Google FaceNet, and Apple Vision. DeepLook contains no external dependency and was written in 100% pure Swift and run locally on the end user device.

It uses 2 main concepts. First, We create IAP (Image Analyzing Pipeline) and then We process multiple IAPs over a batch of photos keeping low memory footprints.

It has 4 main API's:
1. [```DeepLook```](#DeepLook) - For fast simple analyzing actions over single photo.
1. [```Recognition```](#Recognition) - For face Recognition/Identification/Grouping.
2. [```Detector```](#Detector) - For using many available image deep looking operations over batch of photos.
3.  ```ImageProcessor``` - For Image Processing like align, crop, and rotate faces.

## Features 🚀

 - [x] Faces Location, Landmarks, Quality, and much more in only one line.
 - [x] No internet connection needed. All running locally.
 - [x] Face Verification and grouping over user gallery.
 - [x] 100% pure Swift. No external dependency like openCV, Dlib, etc.
 - [x] Chainable Request for faster performance.
 - [x] Image processing, Crop and align faces for creating a faces database.
 - [x] Fully integrated to work with user photo library out of the box.
 - [x] Supported both iDevices and macOS.

## Requirements

- iOS 13.0+
- Swift 5.3+
- Xcode 12.0+

# Install
## SPM:
```swift 
dependencies: [
  .package(
      url:  "https://github.com/LA-Labs/DeepLook.git",
      .branch("master")
  )
]
```
## Cocoapod:
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate DeepLook into your Xcode project using CocoaPods, specify it in your Podfile:
```ruby
pod 'DeepLook' 
```
## Import
```swift 
import DeepLook
```
# Usage
## Basic Usege

### ```DeepLook```

```DeepLook``` provide the most simple API for computer vision analysis. Unlike other API in this package ```DeepLook``` is not using a background thread. It is your responsibility to call it from any background thread you like, like ```DispatchQueue.global().async``` to not block the ```main``` thread. 

### Find faces in pictures - [```Demo```](https://github.com/LA-Labs/LookKit_Demo/blob/main/LookKit_Demo/Deeplook%20Demo/Face_location.swift)
![Screenshot](https://github.com/LA-Labs/LookKit_Demo/blob/main/face_locations_demo.png)

Find all the faces that appear in a picture:
```swift
// load image
let image = UIImage(named: "your_image_name")!

// find face locations
let faceLocations = DeepLook.faceLocation(image) // Normalized rect. [CGRect]
```
```faceLocation(image)``` return an array of normalized vision bounding box. to convert it to ```CGRect``` in UIKit coordinate system you can use apple func ```VNImageRectForNormalizedRect```.

To crop face chips out of the image. - [```Demo```](https://github.com/LA-Labs/LookKit_Demo/blob/main/LookKit_Demo/Deeplook%20Demo/Crop_faces.swift)
```swift
// get list of face chips images.
let corppedFaces = DeepLook.cropFaces(image,
                                      locations: faceLocations)
```


### Find facial features in pictures. - [```Demo```](https://github.com/LA-Labs/LookKit_Demo/blob/main/LookKit_Demo/Deeplook%20Demo/Faces_landmarks.swift)


Get the locations and outlines of each person's eyes, nose, mouth and chin.

```swift
// load image
let image = UIImage(named: "your_image_name")!

// get facial landmarks for each face in the image.
let faceLandmarks = DeepLook.faceLandmarks(image) // [VNFaceLandmarkRegion2D]
```

To extract facial landmarks normalized points.
```swift
let faceLandmarksPoints = faceLandmarks.map({ $0.normalizedPoints })
```

To convert it to UIKit coordinate system.
```swift

// get image size
let imageSize =  CGSize(width: image.cgImage!.width, height: image.cgImage!.height)

// convert to UIKit coordinate system.
let points = faceLandmarks.map({ (landmarks) -> [CGPoint] in
    landmarks.pointsInImage(imageSize: imageSize)
    .map({ (point) -> CGPoint in
        CGPoint(x: point.x, y: imageSize.height - point.y)
    })
})
```

[Facial landmakes image](https://i.stack.imgur.com/JkJd9.jpg)

If you already have the normlized face locations you can use them for faster result.
```swift
let faceLandmarks = DeepLook.faceLandmarks(image, knownFaceLocations: faceLocations)
```


### Identify faces in pictures

Recognize who appears in each photo.
![Screenshot](https://github.com/LA-Labs/LookKit_Demo/blob/main/face_recognition_demo.png)

```swift
// load 2 images to compare.
let known_image = UIImage(named: "angelina.jpg")
let unknown_image = UIImage(named: "unknown.jpg")

// encode faces in both images.
let angelina_encoding = DeepLook.faceEncodings(known_image)[0] // array of encoding faces.
let unknown_encoding = DeepLook.faceEncodings(unknown_image)[0] // array of encoding faces.

// return result for each faces in the source image.
// treshold default is set to 0.6.
let result = DeepLook.compareFaces([angelina_encoding], faceToCompare: unknown_encoding) // [Bool]
```

if you want to have more control on the result you can call ```faceDistance``` and mange the distance by yourself.

```swift
// get array of double represent the l2 norm euclidean distance.
let results = DeepLook.faceDistance([angelina_encoding], faceToCompare: unknown_encoding) // [Double]
```



### Find facial attribute in picture [```Demo```](https://github.com/LA-Labs/LookKit_Demo/blob/main/LookKit_Demo/Deeplook%20Demo/Face_emotion.swift)
![Screenshot](https://github.com/LA-Labs/LookKit_Demo/blob/main/emotion_demo.png)


```swift
// return list of faces emotions `[Face.FaceEmotion]`.
let emotions = DeepLook.faceEmotion(image)
```


## Advance Usege
### ```Recognition```

A modern face recognition pipeline consists of 4 common stages: detect, align, represent and verify. LookKit handles all these common stages in the background. You can just call its verification, find or cluster function in its interface with a single line of code.

## Face Verification
Verification function offers to verify face pairs as same person or different persons. 
treshold can be adjusted.

```swift
let sourceImage = UIImage(named: "my_image_file")!
let targetImage = UIImage(named: "unknow_image_file")!

Recognition.verify(sourceImage: sourceImage,
                   targetImages: targetImage,
                   similarityThreshold: 0.75) { (result) in
      switch result {
         case .success(let result): 
          // result contain list of all faces that's has match on the target image.
          // each Match has:
            // sourceFace: Face // source cropped and align face
            // targetFace: Face // target cropped and align face
            // distance: Double // distance between faces
            // threshold: Double // maximum threshold
         case .failure(let error):
             print(error)
         }
}
```
Sometime we want to work with more then one target image. then we can pass an array of ```UIImage```.
```swift

// Traget images
let targetImages = [UIImage(named: "image1.jpg"), 
                    UIImage(named: "image2.jpg"), 
                    UIImage(named: "image3.jpg")]
```
and then just call with the image list

```swift
let sourceImage = UIImage(named: "my_image_file")!

Recognition.verify(sourceImage: sourceImage,
                   targetImages: targetImages,
                   similarityThreshold: 0.75) { (result) in ...
                   
```
But this is not recommand for large amount of photos due to high memory allocation. insted use *Face Identification*

### Face Identification

Face identification requires to apply face verification several times. Lookit offers an out-of-the-box find function to handle this action for you.
We start with fatching user photos using ```AssetFetchingOptions```.
```swift
// source image must contian at least one face. 
let sourceImage = UIImage(named: "my_image_file")!

// We fetch the last 100 photos from the user gallery to find relevant faces.
let fetchAssetOptions = AssetFetchingOptions(sortDescriptors: nil,
                                             assetCollection: .allPhotos,
                                             fetchLimit: 100)
                                                                     
```
For better control over the process you can create ```ProcessConfiguration```. it has many options for fine tuning the result of the face recognition.

```swift
// Process Configuration
let cofig = ProcessConfiguration()

// encoder model
cofig.faceEncoderModel = .facenet

// linear regresion alignment algorithm
cofig.landmarksAlignmentAlgorithm = .pointsSphereFace5

// face chip padding
cofig.faceChipPadding = 0.0
     
```
Then, We can start finding all faces matched to the source faces. using ``find``
```swift
Recognition.find(sourceImage: face1,
                 galleyFetchOptions: fetchAssetOptions,
                 similarityThreshold: 0.75,
                 processConfiguration: cofig) { (result) in
                 switch result {
                    case .success(let result):
                    // result contain list of all faces that's has match on the target image.
                    // each Match has:
                    // sourceFace: Face // source cropped and align face
                    // targetFace: Face // target cropped and align face
                    // distance: Double // distance between faces
                    // threshold: Double // maximum threshold
                    case .failure(let error):
                        print(error)
              }
}


```

### Face Grouping

Like every photo app we want to cluster all faces from the user gallery to groups of faces. it can be achieved in less then 5 lines of code.

```swift
// Create photo fetech options.
let options = AssetFetchingOptions()
        
// Create cluster options.
let clusterOptions = ClusterOptions()

// Start clustering
Recognition.cluster(fetchOptions: options,
                    clusterOptions: clusterOptions) { (result) in
     // Result contian groups of faces
     // [[Face]]
     switch result {
        case .success(let faces):
           print(faces)
        case .failure(_):
           break
     }
}
```

### ```Detector```

### Create Action
Firstly, DeepLook provides useful initializers to create face location request with ```Actions```. 
```swift 
// Create face location request (Action)
let faceLocation = Actions.faceLocation
````

### Face Location
Call ```Detector``` with the Action request and the source image.
```swift 
Detector.analyze(faceLocation, 
                 sourceImage: UIImage(named: "image1.jpg")) { (result) in
        switch result {
            case .success(let result):
              // The result type is ProcessOutput
              // Containt normilized face recatangle location
              // result[0].boundingBoxes
            case .failure(let error):
              print(error)
        }
}
```

### Chain Requests
### Create a pipeline process
If we want to request more then one action on the image we can chain actions.
The photo will go through the actions pipeline and the result will contain all the requsted data. 

Available Actions:
- Face location - find all faces location.
- Face landmarks - find face landmark for each face.
- Face quality - 0...1 quality scroe for each face.
- Face emotion - emotion anlize for each face.
- Face encoding - conver face to vector representation.
- Object location - find object location (100 classes)
- Object detection - find object (1000 classes)

To make it more efficiant we use each action output as other action input.
For example if we already have faces location we can pass this boxes to the landmark detecor and make much more faster. 

```swift
// Create face location request (Action)
let faceLocation = Actions.faceLocation
        
// Create Object Detection request (Action).
// Sky, flower, water etc.
let objectDetection = Actions.objectDetecting

// Combine 2 requests to one pipeline.
// Every photo will go through the pipeline. both actions will be processed
let pipelineProcess = faceLocation --> objectDetecting

// Start detecting
Detector.detect(pipelineProcess, 
                sourceImage: UIImage(named: "image1.jpg")) { (result) in
// You can path it as a function 
// Detector.detect(faceLocation --> objectDetecting, with: options) { (result) in
           switch result {
              case .success(let result):
                  // The result type is ProcessOutput
                  // Containt normilized face recatangle location and object detected.
                  // result[0].boundingBoxes
                  // result[0].tags
              case .failure(let error):
                print(error)
          }
}
```


### Fetch options
Sometime we want to work with more then one source image. 
We can pass a list of images:
```swift

// User photos
let images = [UIImage(named: "image1.jpg"), 
              UIImage(named: "image2.jpg"), 
              UIImage(named: "image3.jpg")]

// Start detecting
Detector.detect(faceLocation, 
                sourceImages: images) { (result) in
```
But this is not recommand for large amount of photos due to high memory allocation.
DeepLook provice usful fetch options to work with user photo gallery and let you focus on your user experience.
It's start with creation of asset fetching options using ```AssetFetchingOptions```
```swift 
// Create default fetch options
let options = AssetFetchingOptions()
```

We can custom ```AssetFetchingOptions``` with 3 properties:
- sortDescriptors: Ascending\Descending.
- assetCollection: Photos source.
- fetchLimit: Limit the amount of photos we are fetching.
```swift
let options = AssetFetchingOptions(sortDescriptors: [NSSortDescriptor]?,
                                   assetCollection: AssetCollection,
                                   fetchLimit: Int)
```

### Asset Collections
```swift
public enum AssetCollection {
    case allPhotos
    case albumName(_ name: String)
    case assetCollection(_ collection: PHAssetCollection)
    case identifiers(_ ids: [String])
}
```


# Demo Project 
Just plug and play.
Make sure you have enough photos with faces before running the project on iDevice/Simulator.

[```Demo```](https://github.com/LA-Labs/DeepLook_Demo) 

# Contributing
We don't have any contributing guidelines at the moment, but feel free to submit pull requests & file issues within GitHub!

# Buy me a beer 🍺

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate?hosted_button_id=KTQZY5A3FJPSL)

# License
DeepLook is released under the MIT license. [See License](https://github.com/LA-Labs/DeepLook/blob/main/LICENSE) for details.
