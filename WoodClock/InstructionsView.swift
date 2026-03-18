//
//  InstructionsView.swift
//  WoodClock
//
//  Created by Adam Malamy on 2/9/26.
//


//
//  InstructionsView.swift
//  button_demo
//
//  Created by Adam Malamy on 2/3/26.
//
import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.8, green: 0.6, blue: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Instructions")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack(spacing: 5) {
                    Text(
                        "• Move the toggle switch on the back of Ugears Clock to the Down position (bluetooth enabled)"
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                HStack(spacing: 5) {
                    Text(
                        "• Wait about 20 seconds and use the Connect button on the app to establish a bluetooth connection."
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                HStack(spacing: 5) {
                    Text(
                        "• Adjust the time as necessary.  Be sure to end with a forward adjustment to eliminate the play in the gears"
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                HStack(spacing: 5) {
                    Text(
                        "• Move the toggle switch on the back of the Ugears Clock to the Up position (bluetooth disabled).  Do this before disconnecting from bluetooth"
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                HStack(spacing: 5) {
                    Text(
                        "• Use the Disconnect button in the app to disconnect bluetooth.  The clock should start keeping time.  It will not start until bluetooth is disconnected, with the toogle switch in the Up posiion."
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                HStack(spacing: 5) {
                    Text(
                        "• If the battery level is low, plug into power adapter (not into a PC, will not connect) and charge for a while"
                    )
                    .font(.system(size: 20))
                    .frame(width: 350)
                }
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .foregroundColor(Color.black)
                        .frame(width: 200)
                        .font(.system(size: 30))
                }
                .background(Color.yellow)
                .cornerRadius(50)

            }
            .padding()
            .navigationTitle("Instructions")
        }
    }
}
#Preview {
    InstructionsView()
}
