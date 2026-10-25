//
//  ClientView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/1/26.
//

import SwiftUI
import Network

struct ClientView: View {
    @State private var roomBrowser = ChatRoomClient()
    @State private var displayName = ""
    @State private var hasEnteredName = false

    var body: some View {
        NavigationStack {
            Group {
                if !hasEnteredName {
                    nameEntryView
                } else if roomBrowser.isConnected {
                    ChatView(roomBrowser: roomBrowser)
                } else {
                    roomListView
                }
            }
            .navigationTitle("PictoChat")
        }
        .onAppear {
            roomBrowser.startBrowsing()
        }
        .onDisappear {
            roomBrowser.stopBrowsing()
        }
    }

    private var nameEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 64))

            Text("What's your name?")
                .font(.title2.bold())

            TextField("Display name", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal)

            Button("Continue") {
                let name = displayName
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !name.isEmpty else {
                    return
                }

                roomBrowser.senderName = name
                hasEnteredName = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(displayName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty)
        }
        .padding()
    }
    
    private func name(for endpoint: NWEndpoint) -> String {
        if case let .service(name, _, _, _) = endpoint {
            return name
        }
        return "Unknown Room"
    }

    private var roomListView: some View {
        VStack {
            Text("Joining as \(roomBrowser.senderName)")
                .foregroundStyle(.secondary)

            if roomBrowser.rooms.isEmpty {
                ContentUnavailableView(
                    "No Rooms Found",
                    systemImage: "antenna.radiowaves.left.and.right",
                    description: Text("Ask someone to create a room.")
                )
            } else {
                List(roomBrowser.rooms, id: \.hashValue) { room in
                    Button {
                        roomBrowser.connect(to: room)
                    } label: {
                        Label(name(for: room.endpoint), systemImage: "person.3.fill")
                    }
                }
            }
        }
    }
}
