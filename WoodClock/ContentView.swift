//
//  ContentView.swift
//  button_demo
//
//  Created by Adam Malamy on 2/2/26.
//

import SwiftUI

struct ImageSwapButtonStyle: ButtonStyle {
    let normalImage: String
    let pressedImage: String
    let width: CGFloat
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        Image(configuration.isPressed ? pressedImage : normalImage)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
}

struct ContentView: View {
    @State var connect: Bool = false
    @State private var showInstructions = false
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var repeatTask: Task<Void, Never>?
    @State private var isHolding = false
    @State private var isPressing = false
    @State private var longPressTriggered = false

    let ADJUSTFORWARD: Bool = true
    let ADJUSTBACKWARD: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.15, green: 0.25, blue: 0.6)
                    //            Color(red: 0.95, green: 0.95, blue: 0.96)

                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack {

                        Image("bluetooth-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)

                        Button {
                            if bluetoothManager.isConnected
                            {
                                bluetoothManager.clkReset()
                                Task {try await Task.sleep(for: .seconds(1))
                                bluetoothManager.disconnect()}
                            } else {
                                bluetoothManager.scan()
                                bluetoothManager.connect()
                            }
                        } label: {
                            Text(
                                bluetoothManager.isConnected
                                    ? "Disconnect" : "Connect"
                            )
                            .foregroundColor(.black)
                            .font(.system(size: 22))
                            .padding()
                            .frame(width: 150, height: 40)
                            .background(
                                bluetoothManager.isConnected
                                    ? Color.yellow : Color.yellow
                            )
                            .cornerRadius(10)
                        }

                        Text(
                            bluetoothManager.isConnected
                                ? "Connected" : "Disconnected"
                        )
                        .font(.system(size: 25))
                        .foregroundColor(
                            bluetoothManager.isConnected ? .green : .red
                        )

                    }
                    .padding(20)
                    Image("woodclocksquare")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)

                    Text("Adjust Time")
                        .font(.system(size: 30))
                        .foregroundColor(.white)

                    HStack(spacing: 20) {

                        MotorImageButton(
                            onShortPress: bluetoothManager.clkAdjust,
                            onLongPress: startMotor,
                            onRelease: stopMotor,
                            direction: ADJUSTBACKWARD,
                            image: String("timebackward"),
                            imagePressed: String("timebackwardpressed")
                        )

                        MotorImageButton(
                            onShortPress: bluetoothManager.clkAdjust,
                            onLongPress: startMotor,
                            onRelease: stopMotor,
                            direction: ADJUSTFORWARD,
                            image: String("timeforward"),
                            imagePressed: String("timeforwardpressed")
                        )
                    }
                    .padding()

                    Text("Battery Level")
                        .font(.system(size: 30))
                        .foregroundColor(.white)

                    BatteryBarView(rawLevel: bluetoothManager.batteryLevel)

//                    Button("Drain Battery 😈") {
//                        batteryLevel = max(0, batteryLevel - 0.1)
//                        if batteryLevel == 0.0 { batteryLevel = 1.0 }
//                    }

                    Button {
                        showInstructions = true
                    } label: {
                        Text("Instructions")
                            .frame(width: 250, height: 40)
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                    }
                    .background(.yellow)
                    .cornerRadius(50)
                    .navigationDestination(isPresented: $showInstructions) {
                        InstructionsView()
                    }
                }
            }
            //           .navigationTitle("Home")
        }
    }

    private func startMotor(direction: Bool) {
        guard repeatTask == nil else { return }

        isHolding = true

        repeatTask = Task {
            while !Task.isCancelled && isHolding {
                bluetoothManager.clkAdjust(direction: direction)
                try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
            }
        }
    }

    private func stopMotor() {
        isHolding = false
        repeatTask?.cancel()
        repeatTask = nil

        print("Motor stopped")
    }
}
#Preview {
    ContentView()
}
