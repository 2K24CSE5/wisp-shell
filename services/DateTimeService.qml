pragma Singleton
import QtQuick

QtObject {
    id: service

    // Live display strings
    property string currentTime: ""
    property string currentDay: ""
    property string currentMonthDate: ""
    property string fullDateText: ""
    property string timezoneName: ""

    // Calendar state
    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth() // 0-11
    property int todayDate: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    property int viewYear: currentYear
    property int viewMonth: currentMonth
    property string viewMonthName: ""
    property var calendarDays: []

    function updateTime(): void {
        const now = new Date();
        service.currentTime = Qt.formatTime(now, "hh:mm A");
        service.currentDay = Qt.formatDate(now, "ddd").toUpperCase();
        service.currentMonthDate = Qt.formatDate(now, "d MMM");
        service.fullDateText = Qt.formatDate(now, "dddd, MMMM d, yyyy");

        const realDay = now.getDate();
        const realMonth = now.getMonth();
        const realYear = now.getFullYear();

        if (realDay !== service.todayDate || realMonth !== service.todayMonth || realYear !== service.todayYear) {
            service.todayDate = realDay;
            service.todayMonth = realMonth;
            service.todayYear = realYear;
            service.currentYear = realYear;
            service.currentMonth = realMonth;
            generateCalendar();
        }
    }

    function generateCalendar(): void {
        const d = new Date(service.viewYear, service.viewMonth, 1);
        service.viewMonthName = Qt.formatDate(d, "MMMM yyyy");

        // Sunday = 0, Monday = 1 ... Saturday = 6
        const firstDayIndex = d.getDay();
        const daysInMonth = new Date(service.viewYear, service.viewMonth + 1, 0).getDate();
        const daysInPrevMonth = new Date(service.viewYear, service.viewMonth, 0).getDate();

        const grid = [];

        // Trailing days from previous month
        for (let i = firstDayIndex - 1; i >= 0; i--) {
            grid.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            });
        }

        // Days in current active view month
        for (let day = 1; day <= daysInMonth; day++) {
            const isToday = (day === service.todayDate && service.viewMonth === service.todayMonth && service.viewYear === service.todayYear);
            grid.push({
                day: day,
                isCurrentMonth: true,
                isToday: isToday
            });
        }

        // Leading days for next month to complete the row
        const totalSlots = Math.ceil(grid.length / 7) * 7;
        const remaining = totalSlots - grid.length;
        for (let next = 1; next <= remaining; next++) {
            grid.push({
                day: next,
                isCurrentMonth: false,
                isToday: false
            });
        }

        service.calendarDays = grid;
    }

    function prevMonth(): void {
        if (service.viewMonth === 0) {
            service.viewMonth = 11;
            service.viewYear--;
        } else {
            service.viewMonth--;
        }
        generateCalendar();
    }

    function nextMonth(): void {
        if (service.viewMonth === 11) {
            service.viewMonth = 0;
            service.viewYear++;
        } else {
            service.viewMonth++;
        }
        generateCalendar();
    }

    function resetToToday(): void {
        service.viewYear = service.todayYear;
        service.viewMonth = service.todayMonth;
        generateCalendar();
    }

    property Timer ticker: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.updateTime()
    }

    Component.onCompleted: {
        service.updateTime();
        service.generateCalendar();
    }
}
