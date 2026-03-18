//
//  BatteryBarView.swift
//  WoodClock
//
//  Created by Adam Malamy on 2/9/26.
//

import SwiftUI

struct BatteryBarView: View {
    var rawLevel: Float        // Voltage read from clock (3.5 would be low, 4.4 would be full)
    private var normalizedLevel: Float {
        return min(1.0,max(0.0,(rawLevel - 3.5) / (4.4 - 3.5)))
    } // 0.0 to 1.0

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 200, height: 20)

            // Fill
            RoundedRectangle(cornerRadius: 4)
                .fill(levelColor)
                .frame(width: 196 * CGFloat(normalizedLevel), height: 16)
                .padding(2)
                .animation(.easeOut(duration: 0.3), value: normalizedLevel)
        }
    }

    private var levelColor: Color {
        switch normalizedLevel {
        case 0.0..<0.2: return .red
        case 0.2..<0.5: return .orange
        default: return .green
        }
    }
}
