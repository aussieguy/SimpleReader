//
//  UserSettingsViewController.swift
//  SimpleReader
//
//  Created by Glen Hobby on 13/10/20.
//
// Used to manage user settings in the app.
//

import UIKit
import AVFoundation
import MessageUI            //Gives access to email

class UserSettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {

    var defaults = UserDefaults.standard    //User saved settings, eg. font size, voice rate etc.

// Speech rate
    @IBOutlet weak var speechRateSlider:UISlider!
    @IBAction func speechRateSliderBar() {
//We need to make the speech rate slider talk as we slide it.
//Compare what we are about to save with what is already saved.
        let savedSpeechRate = defaults.double(forKey: "Speech rate")
//Only do comparison if user has made changes.
        if savedSpeechRate != 0 {
            if speechRateSlider.value > Float(savedSpeechRate) {
                speakRateChange(rate:"Faster")
            }
            if speechRateSlider.value < Float(savedSpeechRate) {
                speakRateChange(rate:"Slower")
            }
        }
        
        //Save setting
        defaults.set(speechRateSlider.value, forKey: "Speech rate")
        
    }

    func speakRateChange(rate:String) {
        let speechLanguage:String = "en-US"       //https://appmakers.dev/bcp-47-language-codes-list/
        let synthesiser = AVSpeechSynthesizer()

        let utterance:AVSpeechUtterance = AVSpeechUtterance(string: rate)
        utterance.rate = speechRateSlider.value
        utterance.voice = AVSpeechSynthesisVoice(language: speechLanguage)

        synthesiser.speak(utterance)            //Speak the text!

    }

// Text size
    @IBOutlet weak var textSizeLabel:UILabel!
    @IBOutlet weak var textSizeSlider:UISlider!
    @IBAction func textSizeSliderBar() {
        //Show the label text changing in size as the user slides the slider thumbnail.
        textSizeLabel.font = textSizeLabel.font.withSize(CGFloat(textSizeSlider.value))

        //Save setting
        defaults.set(textSizeSlider.value, forKey: "Text size")
    }
    
// Help button - go to help section on web site.
    @IBAction func helpButton() {
        if let url = URL(string: "https://www.simplereader.thecolourblue.com.au/#faq") {
            UIApplication.shared.open(url)
        }
    }
    
// Developer website
    @IBAction func logoButton() {
        if let url = URL(string: "https://www.simplereader.thecolourblue.com.au") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func developerWebsite() {
        
        if let url = URL(string: "https://www.simplereader.thecolourblue.com.au") {
            UIApplication.shared.open(url)
        }
    }
    
// Feedback - send email to developer.
    @IBOutlet weak var emailButton:UIButton!
    @IBAction func feedbackButton() {        
        sendEmail()
    }
    
    @IBAction func sendEmailImage() {
        sendEmail()
    }
    
    func sendEmail() {
        //Check if email capability exists
        if MFMailComposeViewController.canSendMail() {
            
            let mailVC = MFMailComposeViewController()
            
            mailVC.mailComposeDelegate = self
            mailVC.setToRecipients(["gemvalidate1@gmail.com"])
            mailVC.setSubject("")
            mailVC.setMessageBody("", isHTML: true)
            
            present(mailVC, animated: true, completion: nil)
        } else {
            emailButton.setTitle("Email unavailable", for: .normal)
        }

    }
//This will dismiss the Mail View Controller once email has been sent.
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
//Front screen audio switch
    @IBOutlet weak var audioSwitch:UISwitch!
    @IBAction func turnOffFrontScreenAudio() {
        //Save audio button setting
        defaults.setValue(audioSwitch.isOn, forKey: "Front screen audio")
    }
    
//Show version number
    @IBOutlet weak var versionNumber:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//Retrieve the default font size as user may have changed this last time app was used.
        var newFontSize = defaults.integer(forKey: "Text size")
        if newFontSize == 0 {       //No default setting saved by user.
            newFontSize = 16        //Default font size.
        }

//Retrieve slider position and label text size as per settings.
        textSizeSlider.value = Float(newFontSize)
        textSizeLabel.font = textSizeLabel.font.withSize(CGFloat(textSizeSlider.value))

//Retrieve the default speech rate.
        var newSpeechRate = defaults.double(forKey: "Speech rate")
        if newSpeechRate == 0 {      //User did not change setting
            newSpeechRate = 0.4     //Default speech rate.
        }
//Retrieve speech rate slider position
        speechRateSlider.value = Float(newSpeechRate)
        
//Retrieve and show version and build numbers
                let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                let build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
                let name:String = Bundle.main.infoDictionary!["CFBundleName"] as! String
                
                versionNumber?.text = "\(name)   \(version) . \(build)"

//Retrieve and show the position of the front screen audio button.
        let audioButton = defaults.bool(forKey: "Front screen audio")
        audioSwitch.setOn(audioButton, animated: true)
        
//Create navigation bar buttons which will be displayed on the next screen (Help screen).
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Settings",
                                                           style: .plain,
                                                           target: self,
                                                           action: nil)

        
    }
    


}
