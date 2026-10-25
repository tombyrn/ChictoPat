//
//  DrawingBubbleView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/24/26.
//

import Foundation
import SwiftUI
import PencilKit

struct DrawingBubbleView: View {
    let drawingData: Data

    private var drawingImage: UIImage? {
        do {
            let drawing = try PKDrawing(data: drawingData)

            print("Drawing decoded successfully")
            print("Stroke count: \(drawing.strokes.count)")
            print("Drawing bounds: \(drawing.bounds)")

            guard !drawing.strokes.isEmpty else {
                print("Drawing has no strokes")
                return nil
            }

            let bounds = drawing.bounds

            // Add padding around the drawing.
            let paddedBounds = bounds.insetBy(
                dx: -20,
                dy: -20
            )

            return drawing.image(
                from: paddedBounds,
                scale: 2.0
            )

        } catch {
            print("Failed to decode drawing: \(error)")
            print("Received data size: \(drawingData.count)")
            return nil
        }
    }

    var body: some View {
        Group {
            if let image = drawingImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 220)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            } else {
                Text("Unable to display drawing")
                    .foregroundStyle(.red)
            }
        }
    }
}
