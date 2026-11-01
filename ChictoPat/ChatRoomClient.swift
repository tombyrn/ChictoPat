//
//  ChatRoomClient.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/4/26.
//

import Foundation
import Network

@Observable
class ChatRoomClient {
    let clientID = UUID()
    
    var rooms: [NWBrowser.Result] = []
    var isConnected = false
    var isHost = false
    
    var messages: [ChatMessage] = []
    var senderName = ""
    
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let maximumPacketSize = 1_048_576 // 1 MiB
    
    
    func startBrowsing() {
        browser = NWBrowser(
            for: .bonjour(
                type: "_chictopat._tcp",
                domain: nil
            ),
            using: .tcp
        )
        
        browser?.stateUpdateHandler = { state in
            print("Browser state: \(state)")
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            self?.rooms = Array(results)
            
            print("Found \(results.count) room(s)")
            
            for result in results {
                print("Room found: \(result.endpoint)")
            }
        }
        
        browser?.start(queue: .main)
    }
    
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
    }
    
    func connect(to room: NWBrowser.Result) {
        connect(to: room.endpoint)
    }
    
    func connect(to endpoint: NWEndpoint) {
        print("Connecting to \(endpoint)")
        
        guard connection == nil else {
            print("Already connected or disconnecting")
            return
        }
        
        messages.removeAll()
        isConnected = false
        
        let connection = NWConnection(
            to: endpoint,
            using: .tcp
        )
        
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            print("Connection state \(state)")
            
            switch state {
            case .ready:
                DispatchQueue.main.async {
                    self?.isConnected = true
                }

                let joinPacket = NetworkPacket(
                    type: .join,
                    participantID: self?.clientID,
                    participantName: self?.senderName,
                    eventTimestamp: Date()
                )

                self?.send(joinPacket)
                self?.receiveLength(on: connection)
            case .failed, .cancelled:
                DispatchQueue.main.async {
                    if self?.connection === connection {
                        self?.connection = nil
                        self?.isConnected = false
                    }
                }
                print("Connection failed/cancelled")
            default:
                break
            }
            
        }
        connection.start(queue: .main)
        
    }

    func disconnect() {
        guard let connection = connection else {
            isConnected = false
            return
        }

        let packet = NetworkPacket(
            type: .leave,
            participantID: clientID,
            participantName: senderName,
            eventTimestamp: Date()
        )

        do {
            let data = try NetworkMessage.encode(packet)

            connection.send(
                content: data,
                contentContext: .defaultMessage,
                isComplete: true,
                completion: .contentProcessed { [weak self] error in
                    if let error = error {
                        print("Failed to send leave packet: \(error)")
                    }

                    // Cancel even if sending the leave packet fails.
                    connection.cancel()

                    DispatchQueue.main.async {
                        self?.connection = nil
                        self?.isConnected = false
                    }
                }
            )
        } catch {
            print("Failed to encode leave packet: \(error)")
            connection.cancel()
            self.connection = nil
            isConnected = false
        }
    }

    
    private func send(_ packet: NetworkPacket) {
        do {
            let data = try NetworkMessage.encode(packet)

            connection?.send(
                content: data,
                contentContext: .defaultMessage,
                isComplete: true,
                completion: .contentProcessed { error in
                    if let error = error {
                        print("Failed to send packet: \(error)")
                    }
                }
            )
        } catch {
            print("Failed to encode packet: \(error)")
        }
    }
    
    private func receive(on connection: NWConnection) {
        receiveLength(on: connection)
    }
   
    private func receiveLength(on connection: NWConnection) {
        receiveExactly(on: connection, count: 4) {
            [weak self] data in

            guard let self = self,
                  let data = data,
                  data.count == 4 else {
                connection.cancel()
                return
            }

            let bytes = [UInt8](data)

            let byte0 = UInt32(bytes[0])
            let byte1 = UInt32(bytes[1])
            let byte2 = UInt32(bytes[2])
            let byte3 = UInt32(bytes[3])

            let part0 = byte0 << 24
            let part1 = byte1 << 16
            let part2 = byte2 << 8

            let length = part0 | part1 | part2 | byte3

            print("Incoming message size: \(length) bytes")

            let maxSize = UInt32(self.maximumPacketSize)

            guard length > 0, length <= maxSize else {
                print("Invalid packet size: \(length)")
                connection.cancel()
                return
            }

            self.receiveMessage(
                on: connection,
                length: Int(length)
            )
        }
    }

    
    // use message length to decode message from server
    private func receiveMessage(
        on connection: NWConnection,
        length: Int
    ) {
        receiveExactly(on:connection, count: length) { [weak self] data in
            
            guard let self = self, let data = data else {
                connection.cancel()
                return
            }
            
            
            do {
                let packet = try JSONDecoder().decode(
                    NetworkPacket.self,
                    from: data
                )

                // print("Received from host: \(message.text)")

                // append message on the main thread
                DispatchQueue.main.async {
                    switch packet.type {
                        case .chat:
                            guard let message = packet.chatMessage else {
                                return
                            }

                            // avoid duplicates when the server echoes our message.
                            if !self.messages.contains(where: {
                                $0.id == message.id
                            }) {
                                self.messages.append(message)
                            }
                        case .drawing:
                            guard let drawingData = packet.drawingData,
                                  let senderID = packet.participantID,
                                  let senderName = packet.participantName else {
                                return
                            }
                            print("Received drawing \(drawingData.count)bytes")
                        
                            let message = ChatMessage(
                                id: UUID(),
                                senderID: senderID,
                                senderName: senderName,
                                text: "",
                                timestamp: packet.eventTimestamp ?? Date(),
                                drawingData: drawingData
                            )
                            
                        DispatchQueue.main.async {
                            self.messages.append(message)
                        }

                        case .join:
                            guard
                                let id = packet.participantID,
                                let name = packet.participantName
                            else {
                                return
                            }

                            // don't announce our own join back to ourselves.
                            guard id != self.clientID else { return }

                            let systemMessage = ChatMessage(
                                id: UUID(),
                                senderID: id,
                                senderName: "System",
                                text: "\(name) joined the room",
                                timestamp: packet.eventTimestamp ?? Date()
                            )

                            self.messages.append(systemMessage)

                        case .leave:
                            guard
                                let id = packet.participantID,
                                let name = packet.participantName
                            else {
                                return
                            }

                            let systemMessage = ChatMessage(
                                id: UUID(),
                                senderID: id,
                                senderName: "System",
                                text: "\(name) left the room",
                                timestamp: packet.eventTimestamp ?? Date()
                            )

                            self.messages.append(systemMessage)
                            break

                        case .roomDestroyed:
                            // The host has intentionally closed the room.
                            self.connection?.cancel()
                            self.connection = nil
                            self.isConnected = false
                            self.messages.removeAll()
                            break
                    }
                }
                
                // continue listening for messages from server
                self.receiveLength(on: connection)

            } catch {
                print("Failed to decode message: \(error)")
                connection.cancel()
            }
        }
    }
    
    // entry point for ui to send message to server
    func sendText(_ text: String) {
        let trimmedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedText.isEmpty else { return }

        let message = ChatMessage(
            id: UUID(),
            senderID: clientID,
            senderName: senderName,
            text: trimmedText,
            timestamp: Date()
        )

        // show the message immediately on this device.
        messages.append(message)

        let packet = NetworkPacket(
            type: .chat,
            chatMessage: message
        )

        send(packet)
    }
   
    private func receiveExactly(
        on connection: NWConnection,
        count: Int,
        accumulated: Data = Data(),
        completion: @escaping (Data?) -> Void
    ) {
        guard count >= 0 else {
            completion(nil)
            return
        }

        if accumulated.count == count {
            completion(accumulated)
            return
        }

        let remaining = count - accumulated.count

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: remaining
        ) { [weak self] data, _, isComplete, error in

            guard let self = self else {
                completion(nil)
                return
            }

            if let error = error {
                print("Receive error: \(error)")
                connection.cancel()
                completion(nil)
                return
            }

            var buffer = accumulated

            if let data = data, !data.isEmpty {
                buffer.append(data)
            }

            // We have the complete requested byte sequence.
            if buffer.count == count {
                completion(buffer)
                return
            }

            // The stream ended or stopped making progress too soon.
            if isComplete || buffer.count == accumulated.count {
                connection.cancel()
                completion(nil)
                return
            }

            // Continue reading the bytes still missing.
            self.receiveExactly(
                on: connection,
                count: count,
                accumulated: buffer,
                completion: completion
            )
        }
    }
    
    func sendDrawing(_ data: Data) {
        guard isConnected else { return }

        let packet = NetworkPacket(
            type: .drawing,
            participantID: clientID,
            participantName: senderName,
            eventTimestamp: Date(),
            drawingData: data
        )

        send(packet)
    }

}
