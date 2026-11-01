//
//  HostView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/1/26.
//

import SwiftUI
import Network

struct HostView: View {
    @State private var chatRoom = ChatRoomServer()
    @State private var chatClient = ChatRoomClient()

    @State private var serverName = ""
    @State private var displayName = ""

    var body: some View {
        VStack(spacing: 20) {
            // host has started server and is now entering the chat
            if chatClient.isConnected {
                
                ChatView(roomBrowser: chatClient, server: chatRoom)
            }
            // host creates the server
            else {
                Text("Host a PictoChat Room")
                    .font(.title2.bold())

                TextField("Your room name", text: $serverName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                
                TextField("Your display name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Button("Create Room") {
                    serverName = serverName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    
                    displayName = displayName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !serverName.isEmpty else { return }
                    guard !displayName.isEmpty else { return }

                    chatRoom.serverName = serverName
                    
                    chatClient.senderName = displayName
                    chatClient.isHost = true

                    chatRoom.onRoomReady = { endpoint in
                        chatClient.connect(to: endpoint)
                    }

                    chatRoom.createRoom()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    serverName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
        .padding()
    }
}
