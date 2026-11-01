//
//  DrawingCanvasView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/24/26.
//

import SwiftUI
import PencilKit
import UIKit

// CaseIterable protocol allows you can access all the enums cases
// Identifiable protocol provides a stable notion of identity to a class or value type
enum DrawingTool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case eraser = "Eraser"

    var id: String { rawValue }
}

// ObservableObject
final class DrawingCanvasController: ObservableObject {
    weak var canvasView: PKCanvasView?

    func undo() {
        canvasView?.undoManager?.undo()
    }

    func redo() {
        canvasView?.undoManager?.redo()
    }

    func clear() {
        canvasView?.drawing = PKDrawing()
    }
}

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    let selectedTool: DrawingTool
    let selectedColor: Color
    let strokeWidth: CGFloat
    let controller: DrawingCanvasController

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()

        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator

        controller.canvasView = canvas

        updateTool(for: canvas)

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }

        updateTool(for: canvas)
    }

    private func updateTool(for canvas: PKCanvasView) {
        switch selectedTool {
        case .pen:
            canvas.tool = PKInkingTool(
                .pen,
                color: UIColor(selectedColor),
                width: strokeWidth
            )

        case .eraser:
            canvas.tool = PKEraserTool(.vector)
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
