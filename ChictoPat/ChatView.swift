//
//  ChatView.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/15/26.
//

import SwiftUI

struct ChatView: View {
    @State private var roomBrowser: ChatRoomClient
    @State private var draft = ""
    @State private var showingDrawingComposer = false
    
    private var hostServer: ChatRoomServer? = nil

    init(roomBrowser: ChatRoomClient, server: ChatRoomServer? = nil) {
        _roomBrowser = State(initialValue: roomBrowser)
        hostServer = server
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // chat messages
                        ForEach(roomBrowser.messages) { message in
                            HStack {
                                if message.senderID == roomBrowser.clientID {
                                    Spacer()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.senderName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if let drawingData = message.drawingData {
                                        DrawingBubbleView(drawingData: drawingData)
                                    } else {
                                        Text(message.text)
                                            .padding(10)
                                            .background(
                                                message.senderID == roomBrowser.clientID
                                                    ? Color.blue.opacity(0.2)
                                                    : Color.gray.opacity(0.2)
                                            )
                                            .clipShape(
                                                RoundedRectangle(cornerRadius: 12)
                                            )
                                    }

                                    Text(message.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                if message.senderID != roomBrowser.clientID {
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }

                    }
                    .padding()
                }
                .onChange(of: roomBrowser.messages.count) { _, _ in
                    guard let lastMessage = roomBrowser.messages.last else {
                        return
                    }

                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leave") {
                        roomBrowser.disconnect()
                        if roomBrowser.isHost {
                            hostServer?.destroyRoom()
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                
                TextField("Message...", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit(sendMessage)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button {
                    showingDrawingComposer = true
                } label: {
                    Image(systemName: "pencil.tip.crop.circle").font(.title2)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("PictoChat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDrawingComposer) {
            DrawingComposerView(onSend: { drawingData in
                roomBrowser.sendDrawing(drawingData)
            })
        }
    }

    private func sendMessage() {
        let text = draft
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        roomBrowser.sendText(text)
        draft = ""
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isOwnMessage: Bool

    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer(minLength: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(message.text)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                isOwnMessage
                    ? Color.blue.opacity(0.15)
                    : Color.gray.opacity(0.15)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if !isOwnMessage {
                Spacer(minLength: 50)
            }
        }
    }
}
