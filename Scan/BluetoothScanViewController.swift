//
//  BluetoothScanViewController.swift
//  BluetoothVoiceRecognition
//
//  Created by Aiden Seo on 11/7/23.
//

import UIKit
import CoreBluetooth

protocol SendBLEStateDelegate{
    func updateBluetoothTextStatus(response: String) -> Void
}

class BluetoothScanViewController: UITableViewController, BluetoothSerialDelegate {
    
    //list of searched peripherals
    var peripheralList : [(peripheral : CBPeripheral, RSSI : Float)] = []
    
    var bleStateDelegate : SendBLEStateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //reset list whenever scan button is pressed
        peripheralList = []
        
        //set serial's delegate to ScanViewController
        //When delegate methods are called from serial, methods within this class gets called
        serial.delegate = self
        //when view is loaded, start searching
        serial.startScan()
    }
    
    //MARK: - table view datasource
    //decide how many cells to show. Show by the number of all peripheral count
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    //decide how to represent each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        //display peripheral name in screen
        cell.textLabel?.text = peripheralList[indexPath.row].peripheral.name
        
        //TODO: if peripheral is already connected, mark it green or something?
        //BUT it doesn't display any seen devices so do i need to do this?
        
        return cell
    }
    
    //MARK: - table view delegates
    //when cell is pressed
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //effect when table cell is selected
        tableView.deselectRow(at: indexPath, animated: true)
        
        //connect to selected peripheral. Stop the search, find clicked peripheral from peripheralList
        serial.stopScan()
        let selectedPeripheral = peripheralList[indexPath.row].peripheral
        //request to connect to this peripheral using BluetoothSerial's connectToPeripheral
        serial.connectToPeripheral(selectedPeripheral)
        
        //update ble state(the label) in StartView using delegate
        bleStateDelegate?.updateBluetoothTextStatus(response: selectedPeripheral.name ?? "Unnamed Device")
    }
    
    //MARK: delegate methods that get called from BluetoothSerial
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        
        //if already saved, return
        for existing in peripheralList{
            if existing.peripheral.identifier == peripheral.identifier{
                return
            }
        }
        
        //sort by RSSI signal strength
        let fRSSI = RSSI?.floatValue ?? 0.0
        peripheralList.append((peripheral : peripheral, RSSI : fRSSI))
        
        //call tableview again to update searched devices
        tableView.reloadData()
    }

    //called from BluetoothSerial's delegate when connected to a device
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {
        
        //make controller for alert
        let connectSuccessAlert = UIAlertController(title: "Bluetooth Connection Configured", message: "Successfully Connected with \(peripheral.name ?? "Unnamed Device")", preferredStyle: .actionSheet)
        
        //Put button on alert. When clicked, dismiss the view
        let confirm = UIAlertAction(title: "Confirm", style: .default, handler: {_ in self.navigationController?.popViewController(animated: true)})
        connectSuccessAlert.addAction(confirm)
        serial.delegate = nil
        present(connectSuccessAlert, animated: true, completion: nil)
    }
}
