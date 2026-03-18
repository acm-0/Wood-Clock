//
//  BluetoothManager.swift
//  WoodClock
//
//  Created by Adam Malamy on 2/9/26.
//

import Combine
import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate,
    CBPeripheralDelegate
{
    @Published var isConnected = false
    @Published var batteryLevel: Float32 = 0

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var peripheral: CBPeripheral?
    private var clkForwardCharacteristic: CBCharacteristic?
    private var clkBackwardCharacteristic: CBCharacteristic?
    private var batLevelCharacteristic: CBCharacteristic?
    private var resetCharacteristic: CBCharacteristic?

    // 🔧 Replace with your peripheral UUID
    private let targetUUID = UUID(uuidString: "807a35e5-60a1-4f95-8b68-9f8175d8e400")!
    private let targetServiceUUID = CBUUID(string: "807a35e5-60a1-4f95-8b68-9f8175d8e400")
    private let clkForwardUUID = CBUUID(string: "807a35e7-60a1-4f95-8b68-9f8175d8e400")
    private let clkBackwardUUID = CBUUID(string: "807a35e8-60a1-4f95-8b68-9f8175d8e400")
    private let resetUUID = CBUUID(string: "807a35e9-60a1-4f95-8b68-9f8175d8e400")
    private let batLevelUUID = CBUUID(string: "807a35ea-60a1-4f95-8b68-9f8175d8e400")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func scan() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not ready")
            return
        }
        print("Scanning")
        centralManager.scanForPeripherals(withServices: [targetServiceUUID])
    }

    func connect() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not ready")
            return
        }

        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [
            targetUUID
        ])
        print(peripherals)
        if let peripheral = peripherals.first {
            targetPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            print("Connecting to \(peripheral.name ?? "Unknown")")
        } else {
            print("Peripheral not found")
        }
    }

    func disconnect() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not ready")
            return
        }
        guard self.isConnected == true else {
            print("No Bluetooth connection to disconnect")
            return
        }
        
        centralManager.cancelPeripheralConnection(peripheral!)
    }
    
    func clkAdjust(direction : Bool) {
        guard
            let peripheral = peripheral,
            let fwdCharacteristic = clkForwardCharacteristic,
            let bwdCharacteristic = clkBackwardCharacteristic
        else {
            print("Peripheral or characteristic not ready")
            return
        }

        let characteristic = direction ? fwdCharacteristic : bwdCharacteristic
        peripheral.writeValue(Data([0x00]),
                              for: characteristic,
                              type: .withoutResponse)
    }
    
    func clkReset () {
        guard
            let peripheral = peripheral,
            let characteristic = resetCharacteristic
        else {
            print("Peripheral or characteristic not ready")
            return
        }
        
        peripheral.writeValue(Data([0x00]),
                              for: characteristic,
                              type: .withResponse)
    }
}

extension BluetoothManager {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Bluetooth state:", central.state.rawValue)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {

        print("Found peripheral: \(peripheral.name ?? "Unnamed")")

        self.peripheral = peripheral  // ⚠️ must retain
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        print("✅ Connected to peripheral")
        peripheral.delegate = self  // Set the delegate
        peripheral.discoverServices( /*[targetServiceUUID]*/nil)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        guard
            let service = peripheral.services?
                .first(where: { $0.uuid == targetServiceUUID })
        else { return }

        peripheral.discoverCharacteristics(
            /*[targetCharacteristicUUID]*/nil,
            for: service
        )
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("Characteristic found: \(characteristic.uuid)")
            if characteristic.uuid == clkForwardUUID {print("A"); clkForwardCharacteristic = characteristic}
            else if characteristic.uuid == clkBackwardUUID {clkBackwardCharacteristic = characteristic}
            else if characteristic.uuid == resetUUID {resetCharacteristic = characteristic}
            else if characteristic.uuid == batLevelUUID {
                batLevelCharacteristic = characteristic
                if batLevelCharacteristic!.properties.contains(.notify) {
                    print("Found notify characteristic")
                    
                    // Enable notifications
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            else {print("Found no match for \(characteristic.uuid)")}
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {

        if let error = error {
            print("Notify error: \(error.localizedDescription)")
            return
        }

        print("Notification state updated: \(characteristic.isNotifying)")
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        if let error = error {
            print("Update error: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else { return }
        
        let floatValue = data.withUnsafeBytes { buffer in
            buffer.load(as: Float32.self)
        }
        batteryLevel = floatValue
        
//        let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
//        print("Raw bytes (hex): \(hexString)")
        
        print("batteryLevel = \(batteryLevel)")
        // Convert to something meaningful
//        handleIncomingData(data)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        print(
            "❌ Failed to connect:",
            error?.localizedDescription ?? "Unknown error"
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        print("🔌 Disconnected")
    }
}
