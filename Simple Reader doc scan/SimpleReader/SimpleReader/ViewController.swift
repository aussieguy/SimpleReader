//
//  ViewController.swift
//  SimpleReader
//
//  Created by Glen Hobby on 9/10/20.
///Coding motto: To profoundly impact upon the people of this world.  Make a difference.  Lift up others so they can be better.
//  Version 1 - Builds 1 - 4. Initial project build to working prototype.
//              Build 5. - Tidied up code and removed live OCR (not accurate enough).
//              Build 6. - Added LaunchScreen.  Oh wow!  This app now has life.
//              Build 7. - Complete code rewrite (groan).  Now have multiple ViewControllers.
//              Build 8. - Added user settings view controller.
//              Build 9. - Improved accessibility of app.
//  Version 2 - Build 1. - Added automatic redirection to Settings to turn on camera permission.  Does Apple allow this auto redirection?
//              Build 2. - New build number as a new upload to Apple App Store.
//
//          ViewController - root controller and presents camera view.
//          TextViewController - manages text OCR, display of the text and speaking the text.
//          UserSettingsController - Change text size, speech rate, email feedback.
//                  ===============================================
//
//      Purpose of ViewController.swift - Function as root controller and present camera view.
//

import UIKit
import Vision               //Gives access to OCR capabilities.
import AVFoundation         //Gives access to speech synthesiser.

//Delegate is used to receive photo taken.
class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var stillImageOutput: AVCapturePhotoOutput!
    var synthesiser = AVSpeechSynthesizer()
    var recognitionLanguage:String = "eng-us" //www.andiamo.co.uk/resources/iso-language-codes/
    var OCRConfidenceScore:Float = 1.0            // Values are 0.0, 0.3, 0.5, 1.0
    var image: UIImage!
    var speechRate:Float = 0.4
    var defaults = UserDefaults.standard    //User saved settings, eg. font size, voice rate etc.
    var accessGranted = false           //Camera access permission flag.
    
    
    //This is a document scan, ie. take a photo of text and then OCR it.
    @IBAction func didTapButton(_ sender: Any) {
//Check if camera access has been enabled.
        if accessGranted {
//Check if user has enabled front screen audio - on by default.
            if defaults.bool(forKey: "Front screen audio") {
                speakText(wordsToBeSpoken: "Recognizing text.")
            }
            let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput.capturePhoto(with: photoSettings, delegate: self)      //Take photo
        }
    }
    
    //The delegate calls this method when photo has been taken and passes photo to it.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {return}
        let image = UIImage(data:imageData)
        
        // OCR requires cgImage format.
        guard let cgImage = image?.cgImage else { return }
        
        // Create a new image-request handler object with the image to be processed (in cgi format).
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: CGImagePropertyOrientation.right)
         
        // Create a new request object to recognize text in the image.
        let request = VNRecognizeTextRequest()
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["eng-us"]   //www.andiamo.co.uk/resources/iso-language-codes
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])       //Perform OCR.
        } catch { return }

/// Process results from OCR action.  The request object returns an array of VNRecognizedTextObservation objects.  Each observation provides the recognized text string along with a confidence score that indicates the recognition accuracy.
        
        let observations = request.results as? [VNRecognizedTextObservation]
        let recognizedStrings = observations?.compactMap            // compactMap returns a non empty array
        {
            observation in return observation.topCandidates(1).first?.string  // Return the the top VNRecognizedText instance.
        }
        
        let joinedArray = recognizedStrings!.joined(separator: " ")     //Convert array to string.
        
        var x = 0
        while synthesiser.isSpeaking {
            x += 1              //Just loop here until finished speaking.
        }

        //Go to next TextViewController to read and display the text.
        let vc = storyboard?.instantiateViewController(identifier:"text") as! TextViewController

        //Pass data to TextViewController
        vc.result = joinedArray
        
        navigationController?.pushViewController(vc, animated:true)
    }

    @IBOutlet weak var cameraView: UIView!
    
    func speakText(wordsToBeSpoken:String) {        // Add speech output
        
        let speechLanguage:String = "en-US"       //https://appmakers.dev/bcp-47-language-codes-list/

// Create an AVSpeechUtterance instance with the text to be spoken
        let utterance:AVSpeechUtterance = AVSpeechUtterance(string: wordsToBeSpoken)
        utterance.rate = speechRate
        utterance.voice = AVSpeechSynthesisVoice(language: speechLanguage)

        //Check if synthesiser is currently speaking and stop it if it is otherwise multiple voices!
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)    // 0 = immediate. 1 = word.
        }

        synthesiser.speak(utterance)            //Speak the text!

    }
    
    func enableCamera() {
        var captureSession: AVCaptureSession!
        var videoPreviewLayer: AVCaptureVideoPreviewLayer!  //Core animation layer displays live video
        
        // Set up the input device.
        guard let cameraDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        do {
            // Set up the input session.
            let inputSession = try AVCaptureDeviceInput(device: cameraDevice)
            
            // Create the capture session which links input session and device with output device.
            captureSession = AVCaptureSession()
            captureSession.beginConfiguration()
            
            // Connect the input session to the session controller.
            captureSession.addInput(inputSession)
            
            // Set up the output device.
            stillImageOutput = AVCapturePhotoOutput()   //A capture output for still images.
            
            // Connect the session controller to the output device.
            captureSession.addOutput(stillImageOutput)

            //Establish camera resolution settings.
            if captureSession.canSetSessionPreset(.hd4K3840x2160) {     //Higher the better for OCR.
                captureSession.sessionPreset = .hd4K3840x2160
            }
            else {
                if captureSession.canSetSessionPreset(.hd1920x1080) {
                    captureSession.sessionPreset = .hd1920x1080     //My iPad Pro supports this.
                }
                else {
                    captureSession.sessionPreset = .high
                }
            }
            
            captureSession.commitConfiguration()        //Save settings.
            captureSession.startRunning()               //Turn on session.
            
        } catch { return }
        
        //Configure live preview
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) //Video layer.
        videoPreviewLayer.videoGravity = .resizeAspect      //Preserve aspect ratio
        videoPreviewLayer.connection?.videoOrientation = .portrait  //Display vertically.
        videoPreviewLayer.frame = view.layer.bounds
        cameraView.layer.addSublayer(videoPreviewLayer)    //Core layer for displaying video.
        videoPreviewLayer.frame = cameraView.bounds  //Size the preview layer to fit the preview view.

    }

    override func viewDidLoad() {
        super.viewDidLoad()
// Check if this is the very first time the app is being run, ie. it has just been installed and then run for the first time.  If this is the case, then don't check for camera access permission.  This is done anyway as part of the first time run.
        var appHasBeenRun = defaults.bool(forKey: "AppRunStatus")
        if appHasBeenRun {          //This is not the first time the app has been run.
            checkForCameraAccessPermission()
        } else {
            appHasBeenRun = true
            defaults.setValue(appHasBeenRun, forKey: "AppRunStatus")
            accessGranted = true
        }

//Create navigation bar buttons which will be displayed on the next screen.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Camera view",
                                                           style: .plain,
                                                           target: nil,
                                                           action: nil) 
        self.title = "Tap on camera to scan document"
        
        //Retrieve the default speech rate as user may have changed this.
        let newSpeechRate = defaults.double(forKey: "Speech rate")
        
        if newSpeechRate != 0 {         //User has made changes to speechrate.
            speechRate = Float(newSpeechRate)
        }
//Check for camera access permission.
        if accessGranted {
//Check if user has enabled front screen audio - on by default.
            if defaults.bool(forKey: "Front screen audio") {
                speakText(wordsToBeSpoken: "Tap in center of screen to scan document.")
            }
        }

        enableCamera()
        
    }
    func checkForCameraAccessPermission() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            accessGranted = true
            return
        } else {
            showPermissionsAlert()
        }
    }
    
    func showPermissionsAlert() {
        
        let alertController = UIAlertController(title: "Camera Permission is Off",
                                                message: "Please grant permission for this app to use your camera.",
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { (alertAction) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
}
