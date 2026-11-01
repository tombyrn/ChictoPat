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
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .black
    @State private var strokeWidth: Double = 5

    @State private var showingClearConfirmation = false

    @StateObject private var canvasController =
        DrawingCanvasController()

    var onSend: (Data) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                
                // drawing tools
                HStack(spacing: 16) {
                    // select eraser or pen
                    Picker("Tool", selection: $selectedTool) {
                        ForEach(DrawingTool.allCases) { tool in
                            Text(tool.rawValue)
                                .tag(tool)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 190)

                    if selectedTool == .pen {
                        ColorPicker(
                            "Color",
                            selection: $selectedColor,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .accessibilityLabel("Pen color")
                    }

                    Spacer(minLength: 0)
                }

                // stroke width
                if selectedTool == .pen {
                    HStack {
                        Image(systemName: "circle")
                            .font(.system(size: 10))

                        Slider(
                            value: $strokeWidth,
                            in: 1...20,
                            step: 1
                        )

                        Image(systemName: "circle.fill")
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 4)
                }

                // undo, redo, and clear
                HStack {
                    Button {
                        canvasController.undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }

                    Button {
                        canvasController.redo()
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }

                    Spacer()

                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)

                // Canvas
                DrawingCanvasView(
                    drawing: $drawing,
                    selectedTool: selectedTool,
                    selectedColor: selectedColor,
                    strokeWidth: strokeWidth,
                    controller: canvasController
                )
                .background(Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                }
            }
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
                        onSend(drawing.dataRepresentation())
                        dismiss()
                    }
                    .disabled(drawing.strokes.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Clear the entire drawing?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Drawing", role: .destructive) {
                    canvasController.clear()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all strokes from the canvas.")
            }
        }
    }
}

