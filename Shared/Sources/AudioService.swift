import AVFoundation

public class AudioService {
    public static let shared = AudioService()
    private var player: AVPlayer?

    private init() {}

    public func play(word: String, type: Int) {
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://dict.youdao.com/dictvoice?audio=\(encoded)&type=\(type)")
        else { return }
        player?.pause()
        player = AVPlayer(url: url)
        player?.play()
    }
}
