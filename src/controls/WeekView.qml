import QtQuick
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property date selectedDate
    required property string viewTitle
    required property bool workWeek
    readonly property int dayCount: workWeek ? 5 : 7
    readonly property date weekStartDate: {
        const start = new Date(selectedDate)
        start.setDate(start.getDate() - ((start.getDay() + 6) % 7))
        return start
    }
    readonly property int selectedDayIndex: {
        for (let index = 0; index < dayCount; ++index) {
            const day = new Date(weekStartDate.getFullYear(), weekStartDate.getMonth(), weekStartDate.getDate() + index)
            if (Qt.formatDate(day, "yyyyMMdd") === Qt.formatDate(selectedDate, "yyyyMMdd"))
                return index
        }
        return -1
    }
    signal incidenceActivated(var incidence, var occurrence)
    signal eventContextRequested(var incidence, var occurrence, bool recurring, int collectionId, var anchor, real x, real y)
    signal dateContextRequested(date date, var anchor, real x, real y)
    signal timeSlotActivated(date date)
    signal dateActivated(date date)
    signal dateSelected(date date)

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Events for this week")
    }

    RowLayout
    {
        Layout.fillWidth: true
        Layout.leftMargin: Maui.Style.contentMargins
        Layout.rightMargin: Maui.Style.contentMargins
        spacing: Maui.Style.space.tiny - Maui.Style.space.tiny

        Item
        {
            Layout.preferredWidth: weekTimeline.gutterWidth
        }

        WeekdayTabBar
        {
            dayCount: control.dayCount
            startDate: control.weekStartDate
            activeDate: control.selectedDate
            showDateNumbers: true
            onDateSelected: function(date) { control.dateSelected(date) }
        }
    }

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: Maui.Style.space.tiny / 4

        DayTimeline
        {
            id: weekTimeline
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            startDate: control.weekStartDate
            dayCount: control.dayCount
            tableRules: true
            filter: MauiCalendar.Filter
            onIncidenceActivated: function(incidence, occurrence) { control.incidenceActivated(incidence, occurrence) }
            onEventContextRequested: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { control.eventContextRequested(incidence, occurrence, recurring, collectionId, anchor, x, y) }
            onTimeContextRequested: function(date, anchor, x, y) { control.dateContextRequested(date, anchor, x, y) }
            onTimeSlotActivated: function(date) { control.timeSlotActivated(date) }
            onDateActivated: function(date) { control.dateActivated(date) }
        }
    }
}
