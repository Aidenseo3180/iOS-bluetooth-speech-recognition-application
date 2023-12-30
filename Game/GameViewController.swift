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
    
    @IBOutlet weak var winLabel: UILabel!
    @IBOutlet weak var returnButton: UIButton!
    
    @IBOutlet weak var fromPositionLabel: UILabel!
    @IBOutlet weak var fromPositionXLabel: UILabel!
    @IBOutlet weak var fromPositionYLabel: UILabel!

    @IBOutlet weak var toPositionLabel: UILabel!
    @IBOutlet weak var toPositionXLabel: UILabel!
    @IBOutlet weak var toPositionYLabel: UILabel!
    
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
        
        //transmit a signal to the game to let it know when the game starts
        serial.gameDelegate = self
        serial.writeOutgoingValue(data: "Z")
        
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
            //serial.gameDelegate = self
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let dateString = formatter.string(from: date)
            print("start:\(dateString)")
            
            serial.writeOutgoingValue(data: "\(findCorrespondingPosition(response: from_x.text!))")
            serial.writeOutgoingValue(data: "\(from_y.text!)")
            serial.writeOutgoingValue(data: "\(findCorrespondingPosition(response: to_x.text!))")
            serial.writeOutgoingValue(data: "\(to_y.text!)")
            
            print("[Sent] - \(findCorrespondingPosition(response: from_x.text!)) \(from_y.text!) \(findCorrespondingPosition(response: to_x.text!)) \(to_y.text!)")
                        
            //TODO: turn off and turn on the speech recognition while the loading happens!
            
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
                lastString = String(message[indexTo...]).lowercased()
            }
            
            //print(lastString)
            //if position is said, positionFlag = true and prepare to take in x y positions as an input
            if lastString == "position" || lastString == "physician" || lastString == "positions"{
                positionFlag = true
                cnt = 0
                self.from_y.backgroundColor = .systemGray5
                self.to_x.backgroundColor = .systemGray5
                self.to_y.backgroundColor = .systemGray5
                
                self.from_x.backgroundColor = .systemOrange
            }
            else if lastString == "finish"{
                if self.submitButton.isEnabled == true{
                    self.submitButton.sendActions(for: .touchUpInside)
                }
            }
            else if lastString == "reset" || lastString == "resets" || lastString == "clear"{
                positionFlag = false
                cnt = 0
                self.from_x.text = ""
                self.from_y.text = ""
                self.to_x.text = ""
                self.to_y.text = ""
                
                //change background color as well
                self.from_x.backgroundColor = .systemGray5
                self.from_y.backgroundColor = .systemGray5
                self.to_x.backgroundColor = .systemGray5
                self.to_y.backgroundColor = .systemGray5
            }
            //give up
            else if lastString == "up"{
                if self.giveUpButton.isEnabled == true{
                    self.giveUpButton.sendActions(for: .touchUpInside)
                }
            }
            else if lastString == "return"{
                if self.returnButton.isEnabled == true{
                    self.returnButton.sendActions(for: .touchUpInside)
                }
            }
            //if we know that we're going to take positions from now on
            else if positionFlag == true{
                var pos = ""
                if cnt == 1 || cnt == 3{
                    pos = self.convertToNumber(text: lastString)
                }
                else if cnt == 0 || cnt == 2{
                    pos = self.findCorrespondingLetter(text: lastString)
                }
                
                //if not valid input is given, go back
                if pos != ""{
                    if cnt == 0{
                        self.from_x.text = pos
                        self.from_x.backgroundColor = .systemGray5
                        self.from_y.backgroundColor = .systemOrange
                        cnt += 1
                    }
                    else if cnt == 1{
                        self.from_y.text = pos
                        self.from_y.backgroundColor = .systemGray5
                        self.to_x.backgroundColor = .systemOrange
                        cnt += 1
                    }
                    else if cnt == 2{
                        self.to_x.text = pos
                        self.to_x.backgroundColor = .systemGray5
                        self.to_y.backgroundColor = .systemOrange
                        cnt += 1
                    }
                    else if cnt == 3{
                        self.to_y.text = pos
                        self.to_y.backgroundColor = .systemGray5
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
    func convertToNumber(text : String) -> String{
        let inputText = text.lowercased()
        var val = ""
        if inputText == "one" || inputText == "1"{
            val = "1"
        }
        else if inputText == "two" || inputText == "2"{
            val = "2"
        }
        else if inputText == "three" || inputText == "3"{
            val = "3"
        }
        else if inputText == "four" || inputText == "4"{
            val = "4"
        }
        else if inputText == "five" || inputText == "5"{
            val = "5"
        }
        else if inputText == "six" || inputText == "6"{
            val = "6"
        }
        else if inputText == "seven" || inputText == "7"{
            val = "7"
        }
        else if inputText == "eight" || inputText == "8"{
            val = "8"
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
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateString = formatter.string(from: date)
        print("end:\(dateString)")
        
        //Take actions based on what microcontroller returns
        //0:invalid 1:valid 2:player1 wins 3:player2 wins 4:p1 start 5:p2 start
        switch (response){
            case "0":
                //clear position, but stay in same player
                clearPositionInputTextBox()
                print("invalid")
            case "1":
                currentPlayer = (currentPlayer == 1 ? 2 : 1)
                currentPlayerLabel.text = "Player \(currentPlayer)'s turn"
                clearPositionInputTextBox()
                print("valid")
            case "2":
                hideGameLabelWhenWin()
                winLabel.text = "Player 1 wins!"
            case "3":
                hideGameLabelWhenWin()
                winLabel.text = "Player 2 wins!"
            case "4":
                currentPlayer = 1
                currentPlayerLabel.text = "Player 1's turn"
                print("p1 turn")
            case "5":
                currentPlayer = 2
                currentPlayerLabel.text = "Player 2's turn"
                print("p2 turn")
            default:
                print("invalid flag received from microcontroller")
        }
        
    }
    
    func keyboardHiding(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(keyboardRemove))
        self.view.addGestureRecognizer(tap)
    }
        
    @objc func keyboardRemove(){
        view.endEditing(true)
    }
    
    @IBAction func giveUpPressed(_ sender: UIButton) {
        //enable return button and display who won the game
        self.returnButton.isEnabled = true
        let playerWon = self.currentPlayer == 1 ? 2 : 1
        self.winLabel.text = "Player \(playerWon) won!"
        
        self.giveUpButton.isEnabled = false
        self.submitButton.isEnabled = false
        
        hideGameLabelWhenWin()
        
        //let the microcontroller know that the player has given up
        serial.writeOutgoingValue(data: "X")
    }
    
    func clearPositionInputTextBox(){
        //clean the position texts
        self.from_x.text = ""
        self.from_y.text = ""
        self.to_x.text = ""
        self.to_y.text = ""
    }
    
    func findCorrespondingPosition(response : String) -> Int{
        var position = 0
        
        switch (response){
        case "A":
            position = 0
        case "B":
            position = 1
        case "C":
            position = 2
        case "D":
            position = 3
        case "E":
            position = 4
        case "F":
            position = 5
        case "G":
            position = 6
        case "H":
            position = 7
        default:
            position = 9
        }
        
        return position
    }
    
    func findCorrespondingLetter(text : String) -> String{
        var res = text
        switch (text){
        case "eight","a","A":
            res = "A"
        case "be","b","B":
            res = "B"
        case "c", "see":
            res = "C"
        case "d":
            res = "D"
        case "e":
            res = "E"
        case "f":
            res = "F"
        case "g":
            res = "G"
        case "h":
            res = "H"
        default:
            res = ""
        }
        
        return res
    }
    
    @IBAction func returnHomeAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func hideGameLabelWhenWin(){
        currentPlayerLabel.isHidden = true
        
        fromPositionLabel.isHidden = true
        fromPositionXLabel.isHidden = true
        fromPositionYLabel.isHidden = true
        
        toPositionLabel.isHidden = true
        toPositionXLabel.isHidden = true
        toPositionYLabel.isHidden = true
        
        from_x.isHidden = true
        from_y.isHidden = true
        to_x.isHidden = true
        to_y.isHidden = true
        
    }
}

