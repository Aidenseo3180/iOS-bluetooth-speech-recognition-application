//
//  GameViewController.swift
//  NavigationViewController
//
//  Created by Aiden Seo on 10/5/23.
//

import UIKit
import Speech

class GameViewController: UIViewController, SFSpeechRecognizerDelegate, GameSerialDelegate {
    
    //MARK: Outlet Properties
    @IBOutlet weak var from_x: UITextField!
    @IBOutlet weak var to_x: UITextField!
    @IBOutlet weak var from_y: UITextField!
    @IBOutlet weak var to_y: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var currentPlayerLabel: UILabel!
    @IBOutlet weak var giveUpButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    var currentPlayer = 1
    let synthesizer = AVSpeechSynthesizer()
    var receivedMessage = String()
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //If the player has been using speech recognition from the previous view
        if SpeechRecognition.shared.isActive == true{
            //cancel speech recognition and restart for current view
            SpeechRecognition.shared.stopSpeechRecognization()
            speechRecognitionStart()
        }
        
        //TODO: transmit a signal to the game to let it know when the game starts
        
        
        //call to setup the observer that will monitor the user tapping outside of keyboard
        keyboardHiding()
    }

    @IBAction func passToBluetooth(_ sender: UIButton) {
                
        //if any of the x y boxes are empty, then show wawrning sign
        //Don't check for invalid moves because microcontroller will handle that
        if (from_x.text == "" || from_y.text == "" || to_x.text == "" || to_y.text == ""){
            
            let invalidPositionAlert = UIAlertController(title: "Warning", message: "Please provide a valid from & to positions", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "OK", style: .default, handler: nil)
            invalidPositionAlert.addAction(confirm)
            present(invalidPositionAlert, animated: true, completion: {return})
        }
        else{
            //for delegate
            serial.gameDelegate = self
            
            serial.writeOutgoingValue(data: "\(from_x.text!) \(from_y.text!) \(to_x.text!) \(to_y.text!)")
            
            print("[Sent] - \(from_x.text!) \(from_y.text!) \(to_x.text!) \(to_y.text!)")
            
            //TODO: show loading until the device receives confirmation from the microcontroller
            
            
            //switch user
            currentPlayer = (currentPlayer == 1 ? 2 : 1)
            currentPlayerLabel.text = "Player \(currentPlayer)'s turn"
            
            //TODO: turn off and turn on the speech recognition while the loading happens!
            
            
            //clean the position texts
            self.from_x.text = ""
            self.from_y.text = ""
            self.to_x.text = ""
            self.to_y.text = ""
        }
    }
    
    func speechRecognitionStart(){
        SpeechRecognition.shared.request = SFSpeechAudioBufferRecognitionRequest()
        SpeechRecognition.shared.prepareSpeechRecognization()
        if (SpeechRecognition.shared.isError == true){
            self.alertView(message: "Something is wrong during the preparation. Check the setting")
        }
        
        var positionFlag = false
        var cnt = 0
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
                        
            //if position is said, positionFlag = true and prepare to take in x y positions as an input
            if lastString == "position" || lastString == "Position" || lastString == "physician" || lastString == "Physician"{
                positionFlag = true
            }
            else if lastString == "hear" || lastString == "listening"{
                self.readTextWithVoice(text: "Yes I can hear you")
            }
            else if lastString == "finish"{
                self.submitButton.sendActions(for: .touchUpInside)
                //self.submitButton.isEnabled = false
            }
            else if lastString == "reset" || lastString == "resets" || lastString == "clear"{
                positionFlag = false
                cnt = 0
                self.from_x.text = ""
                self.from_y.text = ""
                self.to_x.text = ""
                self.to_y.text = ""
            }
            //give up
            else if lastString == "up"{
                self.giveUpButton.sendActions(for: .touchUpInside)
            }
            //if we know that we're going to take positions from now on
            else if positionFlag == true{
                let pos = self.convertToNumber(text: lastString)
                //if non-int is given, go back
                if pos == 0{
                    positionFlag = false
                    cnt = 0
                }
                else{
                    if cnt == 0{
                        self.from_x.text = String(pos)
                        cnt += 1
                    }
                    else if cnt == 1{
                        self.from_y.text = String(pos)
                        cnt += 1
                    }
                    else if cnt == 2{
                        self.to_x.text = String(pos)
                        cnt += 1
                    }
                    else if cnt == 3{
                        self.to_y.text = String(pos)
                        cnt += 1
                    }
                    //if cnt == 4, then reset
                    else{
                        cnt = 0
                        positionFlag = false
                    }
                }
            }
            
        })
    }
    
    //Since speech recognition interprets numbers as a text, manually calculate
    func convertToNumber(text : String) -> Int{
        var val = 0
        if text == "one" || text == "1"{
            val = 1
        }
        else if text == "two" || text == "2"{
            val = 2
        }
        else if text == "three" || text == "3"{
            val = 3
        }
        else if text == "four" || text == "4"{
            val = 4
        }
        else if text == "five" || text == "5"{
            val = 5
        }
        else if text == "six" || text == "6"{
            val = 6
        }
        
        return val
    }
    
    func alertView(message : String){
        let controller = UIAlertController.init(title: "Error occurred...!", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            controller.dismiss(animated: true, completion: nil)
        }))
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func readTextWithVoice(text : String){
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
        utterance.rate = 0.55
        
        synthesizer.speak(utterance)
    }
    
    func UpdateResultText(response : String) -> Void{
        self.resultLabel.text = response
    }
    
    func keyboardHiding(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(keyboardRemove))
        self.view.addGestureRecognizer(tap)
    }
        
    @objc func keyboardRemove(){
        view.endEditing(true)
    }
    
    @IBAction func giveUpPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

