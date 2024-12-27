# OpenAI Realtime API Swift SDK

This SDK provides an interface to interact with the OpenAI Realtime API using WebRTC. It supports real-time audio-to-audio interactions, text prompts, transcription retrieval, and more.

## Features
- **Audio-to-Audio Interaction**: Enables real-time voice-to-voice communication with the model.
- **Text Prompts**: Allows sending text inputs for responses.
- **Transcription**: Access transcription of audio inputs.
- **Custom Models**: Connect to specific models like `gpt-4o-mini-realtime-preview-2024-12-17`.

## Installation

### Prerequisites
- Swift 5.0 or later
- Xcode 13 or later
- CocoaPods or Swift Package Manager (for WebRTC library)

### Using CocoaPods
1. Add the following to your `Podfile`:
   ```ruby
   pod 'WebRTC'
   ```
2. Run `pod install`.

### Using Swift Package Manager
1. Add the WebRTC library to your project dependencies:
   ```swift
   .package(url: "https://github.com/webrtc-sdk/ios.git", from: "1.0.0")
   ```

## Initialization
To initialize the SDK, you need:
1. An ephemeral API token from OpenAI.
2. The ID of the model you want to use (e.g., `gpt-4o-mini-realtime-preview-2024-12-17`).

### Example
```swift
import OpenAIRealtimeAPI

let api = OpenAIRealtimeAPI(
    modelId: "gpt-4o-mini-realtime-preview-2024-12-17",
    ephemeralToken: "YOUR_EPHEMERAL_TOKEN"
)
```

## Connecting to the API
To establish a connection:

### Example
```swift
api.connect { error in
    if let error = error {
        print("Failed to connect: \(error.localizedDescription)")
    } else {
        print("Connected successfully!")
    }
}
```

## Audio-to-Audio Interaction
This feature captures live audio input from the microphone, sends it to the model, and plays back the model’s audio response.

### Example
```swift
api.connect { error in
    if let error = error {
        print("Connection error: \(error.localizedDescription)")
        return
    }

    // Start audio-to-audio interaction
    api.requestResponse(modalities: ["audio"]) // Ensure the session is configured for audio
}
```

## Retrieving Transcriptions
The SDK allows you to access transcriptions of audio inputs in real time.

### Example
```swift
api.connect { error in
    if let error = error {
        print("Connection error: \(error.localizedDescription)")
        return
    }

    // Handle transcription in the data channel delegate
    api.dataChannel?.delegate = MyDataChannelDelegate() // Implement your delegate
}

// Example delegate implementation
class MyDataChannelDelegate: RTCDataChannelDelegate {
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if let message = String(data: buffer.data, encoding: .utf8) {
            print("Received transcription: \(message)")
        }
    }

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state changed: \(dataChannel.readyState.rawValue)")
    }
}
```

## Sending Text Prompts
Send text inputs to the model and retrieve responses.

### Example
```swift
api.connect { error in
    if let error = error {
        print("Connection error: \(error.localizedDescription)")
        return
    }

    // Send a text prompt
    api.sendTextInput("What is the capital of France?")

    // Request a text response
    api.requestResponse(modalities: ["text"])
}
```

## Using a Specific Model
You can specify the model ID during initialization.

### Example
```swift
let api = OpenAIRealtimeAPI(
    modelId: "gpt-4o-mini-realtime-preview-2024-12-17",
    ephemeralToken: "YOUR_EPHEMERAL_TOKEN"
)
```

## Error Handling
All API methods provide error handling.

### Example
```swift
api.connect { error in
    if let error = error {
        print("Error: \(error.localizedDescription)")
    } else {
        print("Connection successful")
    }
}
```

## Cleanup
Always clean up resources when the connection is no longer needed.

### Example
```swift
api.disconnect()
print("Disconnected")
```

## Advanced Features

### Configure Audio Session
To handle audio input/output settings:
```swift
api.setupAudioSession()
```

### Custom Event Sending
To send custom events:
```swift
let event: [String: Any] = [
    "type": "session.update",
    "session": [
        "instructions": "Provide responses in a cheerful tone."
    ]
]
api.sendEvent(event)
```

### Listening for Custom Events
Implement a delegate to handle specific events:
```swift
class CustomEventHandler: RTCDataChannelDelegate {
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if let message = String(data: buffer.data, encoding: .utf8) {
            print("Custom event received: \(message)")
        }
    }

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state: \(dataChannel.readyState.rawValue)")
    }
}
```

## Troubleshooting
- **Connection Issues**: Ensure the ephemeral token is valid and has not expired.
- **Audio Issues**: Verify microphone permissions and audio session configuration.
- **Event Handling**: Check data channel state and ensure it is open before sending events.

## Contributing
Feel free to submit issues or contribute to the SDK by creating pull requests.

## License
This SDK is available under the MIT License. See the LICENSE file for more details.
