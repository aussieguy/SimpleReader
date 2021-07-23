//
//  TextViewController.swift
//  SimpleReader
//
//  Created by Glen Hobby on 10/10/20.
//

import UIKit
import AVFoundation
import MessageUI            //Gives access to email

class TextViewController: UIViewController, MFMailComposeViewControllerDelegate {

    var speechRate:Float = 0.4                   // Values are 0.0 ... 1.0
    var result:String!                            //Result of OCR
    var synthesiser = AVSpeechSynthesizer()
    var speechLanguage:String = "en-US"       //https://appmakers.dev/bcp-47-language-codes-list/
    var defaults = UserDefaults.standard    //User saved settings, eg. font size, voice rate etc.


    @IBAction func stopButton() {
        if synthesiser.isSpeaking {
            synthesiser.pauseSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
        }
    }
    @IBAction func playButton() {
        if synthesiser.isPaused {
            synthesiser.continueSpeaking()
        }
    }
    
    @IBAction func rewindButton() {
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
        }
        //Start reading from start again.
        let utterance = AVSpeechUtterance(string: result)
        utterance.voice = AVSpeechSynthesisVoice(language: speechLanguage)

        synthesiser.speak(utterance)            //Speak the text!
    }
    
    @IBAction func upLoadButton() {
//Stop speaking whilst we send the email.
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
        }
        //Check if email capability exists
        if MFMailComposeViewController.canSendMail() {
            
            let mailVC = MFMailComposeViewController()
            
            mailVC.mailComposeDelegate = self
            mailVC.setToRecipients([])
            mailVC.setSubject("")
            mailVC.setMessageBody(result, isHTML: true) //We want to email the document scanned.
            
            present(mailVC, animated: true, completion: nil)
        }
    }
    //This will dismiss the Mail View Controller once email has been sent.
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)

    }
       
    @IBOutlet weak var textOutput:UITextView!           //Display OCRed text.
    
    func speakAndDisplayTheText() {
 
        // Cover situation if no text is detected.
        if result.isEmpty {
            result = "No text was detected."
        }
        
// Create an AVSpeechUtterance instance with the text to be spoken
        let utterance:AVSpeechUtterance = AVSpeechUtterance(string: result)
        utterance.rate = speechRate
        utterance.voice = AVSpeechSynthesisVoice(language: speechLanguage)

        //Check if synthesiser is currently speaking and stop it if it is otherwise multiple voices!
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)    // 0 = immediate. 1 = word.
        }
        
        synthesiser.speak(utterance)            //Speak the text!

//Retrieve the default font size as user may have changed this last time app was used.
        var newFontSize = defaults.integer(forKey: "Text size")
        if newFontSize == 0 {     //No user value saved.
            newFontSize = 16      //Our default font size.
        }
        
        let pointSize = CGFloat(newFontSize)

        //Set new font size and redisplay the text along and reread.
        textOutput.font = .systemFont(ofSize: pointSize)

        textOutput.text = result                  //Display the text!
        
    }

//Turn off reading of text if user swipes back or taps on back button in navigation bar.
    override func viewWillDisappear(_ animated: Bool) {
        //Check if synthesiser is currently speaking and stop it if it is otherwise multiple voices!
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: AVSpeechBoundary(rawValue: 0)!)    // 0 = immediate. 1 = word.
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//Retrieve the default speech rate as user may have changed this.
        let newSpeechRate = defaults.double(forKey: "Speech rate")

        if newSpeechRate != 0 {         //User has made changes to speechrate.
                   speechRate = Float(newSpeechRate)
               }
  
        speakAndDisplayTheText()
  
        
//Create navigation bar buttons which will be displayed on the next screen.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Document",
                                                                   style: .plain,
                                                                   target: nil,
                                                                   action: nil)
        
//Create navigation bar buttons for this screen.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(settings))
        
        //Define the gesture - screen tap to stop speaking.
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapTextView))
//Add the gesture to the screen.
        textOutput.addGestureRecognizer(tapGesture)

    }
    @objc func settings() {
//Go to UserSettingsViewController to manage user settings.
        let vc = storyboard?.instantiateViewController(identifier:"usersettings") as! UserSettingsViewController
        
        navigationController?.pushViewController(vc, animated:true)
    }
    
    @objc func tapTextView() {
        if synthesiser.isSpeaking {
            synthesiser.pauseSpeaking(at: AVSpeechBoundary(rawValue: 0)!)
        }
        return 
    }
}
