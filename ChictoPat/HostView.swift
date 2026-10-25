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
                ChatView(roomBrowser: chatClient)
            }
            // todo get rid of this
            else if chatRoom.isHosting {
                ProgressView("Starting your chat room…")
                Text("Hosting as \(displayName)")
                    .foregroundStyle(.secondary)
                
                
                Button("Destroy Room", role: .destructive) {
                    chatRoom.destroyRoom()
                }
            }
            // user enters name for server
            else if chatRoom.serverName.isEmpty {
                Text("Host a PictoChat Room")
                    .font(.title2.bold())

                TextField("Your room name", text: $serverName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Button("Create Room") {
                    let name = serverName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !name.isEmpty else { return }

                    serverName = name
                    chatRoom.serverName = name
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    serverName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
            // user enters a display name
            else {
                Text("Host a PictoChat Room")
                    .font(.title2.bold())

                TextField("Your display name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Button("Create Room") {
                    let name = displayName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !name.isEmpty else { return }

                    displayName = name
                    chatClient.senderName = name

                    chatRoom.onRoomReady = { endpoint in
                        chatClient.connect(to: endpoint)
                    }

                    chatRoom.createRoom()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    displayName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
        .padding()
    }
}
