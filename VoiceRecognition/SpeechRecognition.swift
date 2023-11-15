//
//  SpeechRecognition.swift
//  BluetoothVoiceRecognition
//
//  Created by Aiden Seo on 10/20/23.
//

import UIKit
import Speech

class SpeechRecognition:NSObject, SFSpeechRecognizerDelegate{
    //MARK: properties
    static let shared = SpeechRecognition()
    
    //MARK: -
    let audioEngine = AVAudioEngine()
    let speechRecognizer : SFSpeechRecognizer? = SFSpeechRecognizer()
    var request = SFSpeechAudioBufferRecognitionRequest()
    var task : SFSpeechRecognitionTask!
    var isActive : Bool = false
    var isError : Bool = false
    
    //MARK: methods
    private override init(){
        super.init()
        self.requestForPermission()
    }
    
    //request for permission
    func requestForPermission(){
        //self.startButton.isEnabled = false
        SFSpeechRecognizer.requestAuthorization { authState in
            OperationQueue.main.addOperation{
                //when permission granted, start button enabled
                if authState == .authorized{
                    //self.startButton.isEnabled = true
                }
                else if authState == .denied{
                    self.isError = true
                    //self.alertView(message: "Denied permission")
                }
                else if authState == .notDetermined{
                    self.isError = true
                    //self.alertView(message: "There is no speech recognization")
                }
                else if authState == .restricted{
                    self.isError = true
                    //self.alertView(message: "The user has been restricted from using speech recognization")
                }
            }
        }
    }
    
    func prepareSpeechRecognization(){
        
        isActive = true
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
                
        //prepare audio
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch _{
            self.isError = true
            //alertView(message: "Error comes here for starting the audio listener = \(error.localizedDescription)")
        }
        
        guard let myRecognization = SFSpeechRecognizer() else{
            self.isError = true
            //self.alertView(message: "Recognization is not allowed on your local")
            return
        }
        
        if !myRecognization.isAvailable{
            self.isError = true
            //self.alertView(message: "Renognization not available. Try again.")
        }
        
    }
    
    func stopSpeechRecognization(){
        //for task
        task?.finish()
        task?.cancel()
        task = nil
        isActive = false
        isError = false
        
        //for audio
        request.endAudio()
        audioEngine.stop()
        
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

}

