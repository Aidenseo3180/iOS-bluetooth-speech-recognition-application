//
//  StartViewController.swift
//  NavigationViewController
//
//  Created by Aiden Seo on 10/5/23.
//

import UIKit
import AVFoundation

class StartViewController: UIViewController, BluetoothSerialDelegate, SendBLEStateDelegate {
    
    //MARK: properties
    @IBOutlet weak var BLEStatus: UILabel!
    @IBOutlet weak var SRSwitch: UISwitch!
    @IBOutlet weak var SRStatus: UILabel!
    @IBOutlet weak var GameStartButton: UIButton!
    
    let synthesizer = AVSpeechSynthesizer()
    
    //MARK: methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize Bluetooth serial from BluetoothSerial.swift file
        serial = BluetoothSerial.init()
        
        //disable button until the bluetooth is connected
        GameStartButton.isEnabled = false
    }
    
    func speechRecognitionStart(){
        //reassign to avoid re-used error
        SpeechRecognition.shared.prepareSpeechRecognization()
        if (SpeechRecognition.shared.isError == true){
            self.alertView(message: "Something is wrong during the preparation. Check the setting")
        }
        
        SpeechRecognition.shared.task = SpeechRecognition.shared.speechRecognizer?.recognitionTask(with: SpeechRecognition.shared.request, resultHandler: { (response, error) in
            guard let response = response else {
                if error != nil{
                    
                    //This gets called a lot but doesn't affect performance
                    //self.alertView(message: error.debugDescription)
                }else{
                    self.alertView(message: "Problem in giving the response")
                }
                return
            }
            
            //MARK: speech recognition actions
            let message = response.bestTranscription.formattedString
            
            var lastString : String = ""
            for segment in response.bestTranscription.segments{
                let indexTo = message.index(message.startIndex, offsetBy: segment.substringRange.location)
                lastString = String(message[indexTo...])
            }
            
            //check if game can hear you
            if lastString == "hear" || lastString == "listening"{
                self.readTextWithVoice(text: "Yes I can hear you")
            }
            //scan for device
            else if lastString == "scan" || lastString == "Scan"{
                
            }
            //start the game
            else if lastString == "start" && self.GameStartButton.isEnabled == true{
                self.GameStartButton.sendActions(for: .touchUpInside)
                //self.GameStartButton.isEnabled = false
            }
            
        })
    }
    
    @IBAction func speechSwitchChange(_ sender: UISwitch) {
        if SRSwitch.isOn{
            SRStatus.text = "On"
            SRStatus.textColor = .systemGreen
            speechRecognitionStart()
        }
        else{
            SRStatus.text = "Off"
            SRStatus.textColor = .systemGray2
            
            SpeechRecognition.shared.stopSpeechRecognization()
        }
    }
    
    //made a method for alert view due to its high occurence in the code
    func alertView(message : String){
        let controller = UIAlertController.init(title: "Error occurred...!", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            controller.dismiss(animated: true, completion: nil)
        }))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    //ai reads the text for you
    func readTextWithVoice(text : String){
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
        utterance.rate = 0.55
        
        synthesizer.speak(utterance)
    }
    
    //update bluetooth status text from a BluetoothScanView
    func updateBluetoothTextStatus(response: String) -> Void{
        self.BLEStatus.text = "\(response) Connected"
        self.BLEStatus.textColor = .systemGreen
        
        //enable the start button
        self.GameStartButton.isEnabled = true
    }
    
    @IBAction func scanForBluetooth(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "BluetoothScanViewController") as? BluetoothScanViewController else { return }
        vc.bleStateDelegate = self
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func gameStartAction(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "GameViewController") as? GameViewController else { return }
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

