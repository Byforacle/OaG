import Foundation

extension Date {
    var relativeFormatted: String {
        let now = Date.now
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else if interval < 86400 * 2 {
            return "昨天"
        } else if interval < 86400 * 7 {
            let days = Int(interval / 86400)
            return "\(days)天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: self)
        }
    }
}
