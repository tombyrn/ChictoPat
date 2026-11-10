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
                Image(systemName: "globe")
                    .font(.system(size: 64))
                    .padding(10)
                
                Text("ChictoPat").font(.system(size:32)).bold()
                    
        
                NavigationLink(destination: HostView()) {
                    Text("Create Room")
                        .buttonStyle(.borderedProminent)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                NavigationLink(destination: ClientView()) {
                    Text("Join Room")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

            }
        }
    }
}
