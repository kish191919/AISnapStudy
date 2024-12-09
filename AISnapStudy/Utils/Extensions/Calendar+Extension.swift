import Foundation

extension Calendar {
    
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
