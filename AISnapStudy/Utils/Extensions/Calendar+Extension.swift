import Foundation

extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(40)
        
        var date = dateInterval.start
        
        while date <= dateInterval.end {
            dates.append(date)
            guard let nextDate = self.date(
                byAdding: .day,
                value: 1,
                to: date
            ) else { break }
            date = nextDate
        }
        
        return dates
    }
    
    func monthDateRange(for date: Date) -> (start: Date, end: Date) {
        let components = dateComponents([.year, .month], from: date)
        let startOfMonth = self.date(from: components)!
        
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        let endOfMonth = self.date(
            byAdding: nextMonthComponents,
            to: startOfMonth
        )!
        
        return (startOfMonth, endOfMonth)
    }
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func endOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(
            byAdding: DateComponents(month: 1),
            to: startOfMonth(for: date)
        ) else { return date }
        
        return self.date(
            byAdding: DateComponents(second: -1),
            to: startOfNextMonth
        ) ?? date
    }
}
