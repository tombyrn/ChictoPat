//
//  DrawingComposerView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/24/26.
//

import SwiftUI
import PencilKit

struct DrawingComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var drawing = PKDrawing()

    let onSend: (Data) -> Void

    var body: some View {
        NavigationStack {
            DrawingCanvasView(drawing: $drawing)
                .padding()
                .navigationTitle("New Drawing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Send") {
                            print("Sending drawing")
                            print("Stroke count: \(drawing.strokes.count)")

                            let data = drawing.dataRepresentation()

                            print("Drawing data size: \(data.count) bytes")

                            onSend(data)
                            dismiss()
                        }
                        .disabled(drawing.strokes.isEmpty)
                    }
                }
        }
    }
}
