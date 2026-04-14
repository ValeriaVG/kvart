import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Status: String, Codable, Hashable {
            case running
            case paused
            case completed
        }

        var status: Status
        var startMs: UInt64
        var endMs: UInt64
        var secondsTotal: UInt32
        var secondsElapsed: UInt32
        var fractionAtPause: Double
    }

    var themeId: String
}
