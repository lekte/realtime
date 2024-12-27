import Foundation
import WebRTC
import AVFoundation

/// An SDK for interacting with the OpenAI Realtime API
public class OpenAIRealtimeAPI {
    private let baseUrl = "https://api.openai.com/v1/realtime"
    private let modelId: String
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?

    private let apiKey: String

    public init(modelId: String, apiKey: String) {
        self.modelId = modelId
        self.apiKey = apiKey
        setupAudioSession()
    }

    /// Initializes a WebRTC connection to the OpenAI Realtime API
    public func connect(completion: @escaping (Error?) -> Void) {
        let configuration = RTCConfiguration()
        configuration.iceServers = [] // Use default ICE servers

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        peerConnection = factory.peerConnection(with: configuration, constraints: constraints, delegate: self)

        // Add local audio track
        if let localAudioTrack = createAudioTrack(factory: factory) {
            self.audioTrack = localAudioTrack
            let stream = factory.mediaStream(withStreamId: "localStream")
            stream.addAudioTrack(localAudioTrack)
            peerConnection?.add(stream)
        }

        // Create data channel for events
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannel = peerConnection?.dataChannel(forLabel: "oai-events", configuration: dataChannelConfig)
        dataChannel?.delegate = self

        // Create offer
        peerConnection?.offer(for: constraints) { [weak self] offer, error in
            guard let self = self, let offer = offer else {
                completion(error)
                return
            }
            self.peerConnection?.setLocalDescription(offer) { error in
                guard error == nil else {
                    completion(error)
                    return
                }

                self.exchangeSDP(offer: offer.sdp, completion: completion)
            }
        }
    }

    /// Sends a text input event to the Realtime API
    public func sendTextInput(_ text: String) {
        let event: [String: Any] = [
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [["type": "input_text", "text": text]]
            ]
        ]
        sendEvent(event)
    }

    /// Sends a request to generate a response
    public func requestResponse(modalities: [String] = ["text", "audio"]) {
        let event: [String: Any] = [
            "type": "response.create",
            "response": ["modalities": modalities]
        ]
        sendEvent(event)
    }

    /// Cleans up the connection
    public func disconnect() {
        peerConnection?.close()
        peerConnection = nil
    }

    private func exchangeSDP(offer: String, completion: @escaping (Error?) -> Void) {
        var request = URLRequest(url: URL(string: "\(baseUrl)?model=\(modelId)")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                completion(error)
                return
            }

            if let sdp = String(data: data, encoding: .utf8) {
                let answer = RTCSessionDescription(type: .answer, sdp: sdp)
                self.peerConnection?.setRemoteDescription(answer, completionHandler: completion)
            } else {
                completion(NSError(domain: "OpenAIRealtimeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse SDP"]))
            }
        }.resume()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func createAudioTrack(factory: RTCPeerConnectionFactory) -> RTCAudioTrack? {
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        return factory.audioTrack(with: audioSource, trackId: "audio0")
    }

    public func sendEvent(_ event: [String: Any]) {
        guard let dataChannel = dataChannel else { return }
        if let jsonData = try? JSONSerialization.data(withJSONObject: event, options: []) {
            let buffer = RTCDataBuffer(data: jsonData, isBinary: false)
            dataChannel.sendData(buffer)
        }
    }
}

extension OpenAIRealtimeAPI: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let audioTrack = stream.audioTracks.first {
            print("Received remote audio track")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannel = dataChannel
        print("Data channel opened")
    }
}

extension OpenAIRealtimeAPI: RTCDataChannelDelegate {
    /// Updates the data channel delegate
    public func setDataChannelDelegate(_ delegate: RTCDataChannelDelegate) {
        self.dataChannel?.delegate = delegate
    }

    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state changed: \(dataChannel.readyState.rawValue)")
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if let message = String(data: buffer.data, encoding: .utf8) {
            print("Received message: \(message)")
        }
    }
}

