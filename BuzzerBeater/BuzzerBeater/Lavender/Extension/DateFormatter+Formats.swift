import Foundation

extension DateFormatter {
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter
    }()
    
    static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }()
    // "10월 24일 (목)" 형식의 DateFormatter
    static let koreanMonthDayWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 형식 설정
        formatter.dateFormat = "M월 d일 (E)"           // 월, 일, 요일 표시 형식
        return formatter
    }()
    
    static let amPmTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.amSymbol = "Am"
        formatter.pmSymbol = "Pm"
        return formatter
    }()
    
}
