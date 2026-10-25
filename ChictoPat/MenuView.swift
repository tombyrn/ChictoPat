//
//  MenuView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 9/28/26.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("ChictoPat")
                
        
                NavigationLink(destination: HostView()) {
                    Text("Create Room")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                NavigationLink(destination: ClientView()) {
                    Text("Join Room")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

            }
        }
    }
}
