//
//  ContentView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 12/28/25.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    @State private var drawing = PKDrawing()
    
    @State private var chatRoom = ChatRoomServer()
    
    var body: some View {
        VStack {
            CanvasView(drawing: $drawing)
            .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
            .cornerRadius(8)
            .padding()
            .contentMargins(10)
            
            Button("Clear") {
                drawing = PKDrawing()
            }
            .padding()
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
