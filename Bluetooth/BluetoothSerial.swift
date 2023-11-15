//
//  BluetoothSerial.swift
//  bluetoothVoiceRecognition
//
//  Created by Aiden Seo on 10/7/23.
//

import UIKit
import CoreBluetooth

//global serial handler (global serial handler)
var serial : BluetoothSerial!

//MARK: delegates
//for communication between serial and view while connecting bluetooth
protocol BluetoothSerialDelegate: AnyObject{
    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?)
    func serialDidConnectPeripheral(peripheral : CBPeripheral)
}

protocol GameSerialDelegate{
    func UpdateResultText(response: String) -> Void
}

//set a few methods in protocol as OPTIONAL
//so these methods don't need to be implemented
extension BluetoothSerialDelegate{
    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?) {}
    func serialDidConnectPeripheral(peripheral : CBPeripheral) {}
}

class BluetoothSerial : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    //MARK: - variables
    var delegate : BluetoothSerialDelegate?
    
    //search nearby devices and connect
    var centralManager : CBCentralManager!
    
    //nearby bluetooth device that we're connecting to. Temporary variable that stores device in case something fails
    var pendingPeripheral : CBPeripheral?
    
    //successfully connected nearby bluetooth device. When communicating, use this object
    var connectedPeripheral : CBPeripheral?
    
    //save characteristic for tx and rx
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    
    var gameDelegate : GameSerialDelegate?
        
    //MARK: - methods
    //call when initializing serial
    //since serial cannot be nil, must init before use
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //search nearby devices that can be connected using serviceUUID
    func startScan(){
        //if central device not poweredOn, stop scan
        guard centralManager.state == .poweredOn else {return}
        
        //search connectable devices using servicex UUID
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    
    //stop device scan
    func stopScan(){
        centralManager.stopScan()
    }
    
    //connect to the device given as parameter
    func connectToPeripheral(_ peripheral : CBPeripheral){
        //in case connection fails, save the device that is getting connected to
        pendingPeripheral = peripheral
        
        centralManager.connect(peripheral, options: nil)
    }
    
    //used to check the BLE state of device
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        pendingPeripheral = nil
        connectedPeripheral = nil
        
        //check state of central device (phone)
        switch central.state {
            case .poweredOff:
                print("Is Powered Off.")
            case .poweredOn:
                print("Is Powered On.")
            case .unsupported:
                print("Is Unsupported.")
            case .unauthorized:
                print("Is Unauthorized.")
            case .unknown:
                print("Unknown")
            case .resetting:
                print("Resetting")
            @unknown default:
                print("Error")
        }
    }
    
    //MARK: - Search
    //gets called whenever a device gets searched
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //display the device to table view
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
    }
    
    //MARK: - Connect
    //gets called when a nearby device gets connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil             //no longer pending bc connection is ensured
        connectedPeripheral = peripheral    //set to connected
        
        peripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    //gets called when successfully searches for service of peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")

        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
    }
    
    //gets called when successfully searches the characteristic of the service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        //if service doesn't exist, return
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in service.characteristics!{
            //if RX found - subscribe to update to its value calling setNotifyValue
            //this is how it receive data from the peripheral
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx){

                //subscribe so that we know when we receive data from device
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)

                rxCharacteristic = characteristic
                
                //TODO: code when connected to nearby device
                delegate?.serialDidConnectPeripheral(peripheral: peripheral)
            }
            
            //if TX found - save a reference so that we can write values to it later
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
            }
        }
    }
    
    //when writeType is withResponse, when bluetooth device sends a response, this gets called
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //TODO: when bluetooth device with writeType of withResponse sends response, write code to handle it
        //print("gets called")
    }
    
    //gets called when the device receives the data from the peripheral
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // check if the data exists
        let data = characteristic.value
        guard data != nil else { return }
        
        print("-----[RECEIVED]-----")
        print("In byte form: \(data!)")
        // convert the data to a string, write to the screen (for a testing purpose)
        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            print("In string form: \(str)")
            gameDelegate?.UpdateResultText(response: str);
        } else {
            return
        }
    }
    
    //MARK: - Write to peripheral
    func writeOutgoingValue(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let bluefruitPeripheral = connectedPeripheral {
            
            if let txCharacteristic = txCharacteristic {
                
                bluefruitPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
}


