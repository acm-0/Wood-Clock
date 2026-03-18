//
//  MotorControlButton.swift
//  WoodClock
//
//  Created by Adam Malamy on 2/13/26.
//
import SwiftUI

struct MotorImageButton: View {
    
    var onShortPress: (Bool) -> Void
    var onLongPress: (Bool) -> Void
    var onRelease: () -> Void
    var direction: Bool
    var image: String
    var imagePressed: String
    
    @State private var isPressing = false
    @State private var longPressTriggered = false

    var body: some View {
        Image(isPressing ? imagePressed : image)
            .resizable()
            .frame(width: 100, height: 100)
            .scaleEffect(isPressing ? 1.2 : 1.0)
        // 1️⃣ Detect finger down + lift reliably
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            isPressing = true
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        if longPressTriggered { onRelease() }
                        longPressTriggered = false
                    }
            )
        // 2️⃣ Detect long press threshold
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        longPressTriggered = true
                        onLongPress(direction)
                    }
            )
        // 3️⃣ Detect short tap
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !longPressTriggered {
                            print("direction = \(direction)")
                            onShortPress(direction)
                        }
                    }
            )
    }
}
