//
//  ChatRoomServer.swift
//  ChictoPat
//
//  Created by Aaaaaaa a on 10/1/26.
//

import Foundation
import Network

@Observable
class ChatRoomServer {
    var isHosting = false
    var serverName: String = ""
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var history: [NetworkPacket] = []
    
    private let maximumHistoryCount = 200
    private let maximumPacketSize = 1_048_576 // 1 MiB
    
    var onRoomReady: ((NWEndpoint) -> Void)?
    
    private struct Participant {
        let id: UUID
        let name: String
    }

    // dictionary that maps each connection to the participant who joined through it
    private var participants: [ObjectIdentifier: Participant] = [:]
    
    func createRoom() {
        do {
            listener = try NWListener(using: .tcp)
        } catch {
            print("Failed to create listener: \(error)")
            return
        }
        
        listener?.service  = NWListener.Service(
            name: serverName,
            type: "_chictopat._tcp"
        )
        
        listener?.stateUpdateHandler = { [weak self] state in
            print("Listener state: \(state)")
            
            guard case .ready = state else {return}
            
            guard let port = self?.listener?.port else {
                print("Listender is ready, but no port available")
                return
            }
            
            let endpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: port)
            
            DispatchQueue.main.async {
                self?.onRoomReady?(endpoint)
            }
        }
        
        // new connection to server
        listener?.newConnectionHandler = { [weak self] connection in
            print("Someone connected!")
            
            // append connection to array
            self?.connections.append(connection)
            
            // set callback for connection object
            connection.stateUpdateHandler = { [weak self] state in
                print("Host connection state: \(state)")
                
                switch state {
                    case .ready:
                        print("Connection ready")
                    case .failed:
                        print("Connection failed")
                        self?.removeConnection(connection)
                    case .cancelled:
                        print("Client disconnected")
                        self?.removeConnection(connection)
                        
                    default:
                        break
                }
            }
            
            connection.start(queue: .main)
            self?.receive(on: connection)
        }
        
        listener?.start(queue: .main)
        
        isHosting = true
    }

    private func removeConnection(_ connection: NWConnection) {
        let key = ObjectIdentifier(connection)

        // Remove the participant, if they successfully joined.
        let participant = participants.removeValue(forKey: key)

        // Remove the network connection.
        connections.removeAll {
            $0 === connection
        }

        // Announce the departure only once.
        if let participant = participant {
            let packet = NetworkPacket(
                type: .leave,
                participantID: participant.id,
                participantName: participant.name,
                eventTimestamp: Date()
            )

            recordHistory(packet)
            broadcast(packet)
            print("\(participant.name) left the room")
        }

        print("Connected clients: \(connections.count)")
    }

    
    // dismantle server
    func destroyRoom() {
        guard isHosting else { return }

        let packet = NetworkPacket(type: .roomDestroyed)

        // Notify clients before cancelling their connections.
        broadcast(packet) { [weak self] in
            guard let self = self else { return }

            let activeConnections = self.connections

            // Clear participants first so cancellation doesn't announce
            // everyone as individually leaving the room.
            self.participants.removeAll()
            self.connections.removeAll()
            self.history.removeAll()

            self.listener?.cancel()
            self.listener = nil
            self.isHosting = false

            for connection in activeConnections {
                connection.cancel()
            }

            print("Room destroyed")
        }
        onRoomReady = nil
    }

    
    // get message from client
    private func receive(on connection: NWConnection) {
        receiveLength(on: connection)
    }
    
   
    // decode message length from first 4 bytes of messaage
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

    
    // use message length to decode message from client
    private func receiveMessage(
        on connection: NWConnection,
        length: Int
    ) {
        receiveExactly(
            on: connection,
            count: length
        ) { [weak self] data in

            guard let self = self, let data = data else {
                connection.cancel()
                return
            }
            

            do {
                let packet = try JSONDecoder().decode(
                    NetworkPacket.self,
                    from: data
                )

                switch packet.type {
                    case .join:
                        guard
                            let id = packet.participantID,
                            let name = packet.participantName,
                            !name.isEmpty
                        else {
                            print("Invalid join packet")
                            break
                        }
                        
                        // send message history on join
                        for historicalRecord in history {
                            send(historicalRecord, to: connection)
                        }

                        // create participant
                        let participant = Participant(id: id, name: name)
                        participants[ObjectIdentifier(connection)] = participant

                        print("\(name) joined the room")
                        
                        var eventPacket = packet
                        eventPacket.eventTimestamp = Date()
                        
                        // record join to history
                        recordHistory(eventPacket)

                        // announce to all clients
                        broadcast(eventPacket)

                    case .chat:
                        guard let message = packet.chatMessage else {
                            print("Chat packet has no message")
                            break
                        }

                         print("Received message from \(message.senderName):")
                        // print(message.text)

                        // record chat message to history
                        recordHistory(packet)
                        
                        // send to all clients
                        broadcast(packet)

                    case .leave:
                        print("Received leave packet")
                        connection.cancel()

                    case .roomDestroyed:
                        print("Received room-destroyed packet")
                        
                    case .drawing:
                        guard let data = packet.drawingData,
                              !data.isEmpty else { return }
                        recordHistory(packet)
                        broadcast(packet)
                    
                }
                
                self.receiveLength(on: connection)

            } catch {
                print("Failed to decode packet: \(error)")
            }

            
        }
    }
    
    private func send(
        _ packet: NetworkPacket,
        to connection: NWConnection
    ) {
        do {
            let data = try NetworkMessage.encode(packet)

            connection.send(
                content: data,
                contentContext: .defaultMessage,
                isComplete: true,
                completion: .contentProcessed { error in
                    if let error = error {
                        print("Send error: \(error)")
                    }
                }
            )
        } catch {
            print("Failed to encode packet: \(error)")
        }
    }

    
    // send message to all clients on server
    private func broadcast(_ packet: NetworkPacket, completion: (() -> Void)? = nil) {
        do {
            let data = try NetworkMessage.encode(packet)
            let activeConnections = connections
            
            guard !activeConnections.isEmpty else {
                completion?()
                return
            }
            
            // broadcast messages async across multiple threads
            let group = DispatchGroup()

            for connection in activeConnections {
                // group task has started
                group.enter()
                
                connection.send(
                    content: data,
                    contentContext: .defaultMessage,
                    isComplete: true,
                    completion: .contentProcessed { error in
                        if let error = error {
                            print("Broadcast error: \(error)")
                        }
                        
                        // group task has finished
                        group.leave()
                    }
                )
            }
            
            // wait for all threads to terminate
            group.notify(queue: .main) {
                completion?()
            }
        } catch {
            print("Failed to broadcast packet: \(error)")
            completion?()
        }
    }
    
    private func recordHistory(_ packet: NetworkPacket) {
        history.append(packet)

        if history.count > maximumHistoryCount {
            history.removeFirst(
                history.count - maximumHistoryCount
            )
        }
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

            // append newly read data to accumulated data
            if let data = data, !data.isEmpty {
                buffer.append(data)
            }

            // complete message has been read
            if buffer.count == count {
                completion(buffer)
                return
            }

            // the stream ended or stopped making progress too soon
            if isComplete || buffer.count == accumulated.count {
                connection.cancel()
                completion(nil)
                return
            }

            // continue reading the missing bytes
            self.receiveExactly(
                on: connection,
                count: count,
                accumulated: buffer,
                completion: completion
            )
        }
    }

    
}
