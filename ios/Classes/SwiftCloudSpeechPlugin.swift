import Flutter
import UIKit
import AVFoundation


@available(iOS 9.0, *)
public class SwiftCloudSpeechPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    let engine = AVAudioEngine()
    private var eventSink: FlutterEventSink?
    private var outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 8000, channels: 2, interleaved: true)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cloud_speech", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "audio", binaryMessenger: registrar.messenger())
        let instance = SwiftCloudSpeechPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
      }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
          switch call.method {
          case "initialize":
            let args = call.arguments as! [String: Any]
            switch args["commonFormat"] as! String{
            case "AVAudioCommonFormat.pcmFormatInt16":
                outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16,
                                                 sampleRate: args["sampleRate"] as! Double,
                                                 channels: args["channelCount"] as! UInt32,
                                                 interleaved: args["interleaved"] as! Bool
                )
            case "AVAudioCommonFormat.pcmFormatInt32":
                outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt32,
                                                 sampleRate: args["sampleRate"] as! Double,
                                                 channels: args["channelCount"] as! UInt32,
                                                 interleaved: args["interleaved"] as! Bool
                )
            default:
                result("iOS " + UIDevice.current.systemVersion)
            }
            result("iOS " + UIDevice.current.systemVersion)

          case "startAudioStream":

            result("iOS " + UIDevice.current.systemVersion)

          case "stopAudioStream":

            result("iOS " + UIDevice.current.systemVersion)

          default:
            result("iOS " + UIDevice.current.systemVersion)

          }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Switch for parsing commonFormat - Can abstract later
        let input = engine.inputNode
        let bus = 0
        let inputFormat = input.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)!

        input.installTap(onBus: bus, bufferSize: 512, format: inputFormat) { (buffer, time) -> Void in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }

            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.outputFormat!, frameCapacity: AVAudioFrameCount(self.outputFormat!.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)

            if (self.outputFormat?.commonFormat == AVAudioCommonFormat.pcmFormatInt16) {
                let values = UnsafeBufferPointer(start: convertedBuffer.int16ChannelData![0], count: Int(convertedBuffer.frameLength))
                let arr = Array(values)
                events(arr)
            }
            else{
                let values = UnsafeBufferPointer(start: convertedBuffer.int32ChannelData![0], count: Int(convertedBuffer.frameLength))
                let arr = Array(values)
                events(arr)
            }
        }

        try! engine.start()

        return nil

    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {

        engine.stop()

        return nil

    }
}
