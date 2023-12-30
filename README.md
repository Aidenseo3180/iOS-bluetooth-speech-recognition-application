# iOS-bluetooth-speech-recognition-application
[![Latest release](https://img.shields.io/github/release/Aidenseo3180/iOS-bluetooth-speech-recognition-application.svg)](https://github.com/Aidenseo3180/iOS-bluetooth-speech-recognition-application/releases/latest)  

A mobile application that allows an iOS device to connect to [Adafruit Bluefruit LE SPI Friend](https://www.adafruit.com/product/2633) by default, and control everything through a speech recognition feature.  
The configuration of the application can be changed from CBUUID.swift file to connect to other Bluetooth devices.  
It is implemented to control LED Checkers hardware that is specifically designed for ECE1896 Senior Design Project.  

## How to Use
Before the user starts the LED Checkers game, it needs to connect to the Bluetooth device first.
The speech recognition can be either turned on/off in the beginning of the game. Once the game is started, this cannot be turned on/off again until it ends.
The application listens to certain keywords to mimic the speech recognition functionality once the game is started. The available keywords from the game tab are listed below:
* Position - allows the user to give from-to positions of the piece that he wants to move in x-y order. The x corresponds to A - H, and the y corresponds to 1 - 8. 
* Give up - end the game immediately and the other player wins the game
* Finish - finish the turn and send the positions to the microcontroller through BLE chip.
* Clear - clear all the input boxes

## Note
Xcode, Mac, and the iOS device must be upgraded to the latest version.  
Since the application requires a microphone to use speech recognition, running a simulation from Xcode leads to a crash. However, running from an iOS device works normally.
In order for the application to use both the Bluetooth and the microphone, permission is required.

## Learn about Swift BLE
[BLE tutorial](https://learn.adafruit.com/build-a-bluetooth-app-using-swift-5?view=all)  
[BLE in depth (Translation needed)](https://staktree.github.io/ios/iOS-Bluetooth-01-about-CoreBluetooth/)  
[Website about Adafruit Bluefruit SPI Friend](https://learn.adafruit.com/introducing-the-adafruit-bluefruit-spi-breakout/uart-service)  

## Credits
[Steph Layton](https://www.linkedin.com/in/stephen-layton-031994272/) - Bare metal programming of microcontroller  
[Caileigh Wettasinghe](https://www.linkedin.com/in/caileigh-wettasinghe/) - Hardware  
