//
//  DrawingCanvasView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/24/26.
//

import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()

        canvas.backgroundColor = .white
        canvas.isOpaque = true

        canvas.drawingPolicy = .anyInput

        canvas.tool = PKInkingTool(
            .pen,
            color: .black,
            width: 5
        )

        canvas.delegate = context.coordinator

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(
            _ canvasView: PKCanvasView
        ) {
            parent.drawing = canvasView.drawing
        }
    }
}
