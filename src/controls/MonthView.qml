import QtQuick
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property date selectedDate
    required property string viewTitle
    signal dateClicked(date date)
    signal dateDoubleClicked(date date)
    signal incidenceClicked(var incidence, var occurrence)
    signal moreEventsClicked(date date)
    signal eventContextRequested(var incidence, var occurrence, bool recurring, int collectionId, var anchor, real x, real y)
    signal dateContextRequested(date date, var anchor, real x, real y)

    spacing: Maui.Style.space.big

    readonly property date weekdayStartDate: {
        const date = new Date()
        const firstDay = Qt.locale().firstDayOfWeek % 7
        date.setDate(date.getDate() - ((date.getDay() - firstDay + 7) % 7))
        return date
    }

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Browse dates and events for this month.")
    }

    WeekdayTabBar
    {
        Layout.leftMargin: Maui.Style.space.medium
        Layout.rightMargin: Maui.Style.space.medium
        startDate: control.weekdayStartDate
        activeDate: new Date()
        showDateNumbers: false
    }

    MauiCalendar.MonthView
    {
        id: monthCalendar
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: null
        selectedDate: control.selectedDate
        showDayHeaders: false
        dayCards: true
        clip: true

        onDateClicked: function(date) { control.dateClicked(date) }
        onDateDoubleClicked: function(date) { control.dateDoubleClicked(date) }
        onIncidenceClicked: function(incidence, occurrence) { control.incidenceClicked(incidence, occurrence) }
        onDateContextRequested: function(date, anchor, x, y) { control.dateContextRequested(date, anchor, x, y) }
        onIncidenceRightClicked: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { control.eventContextRequested(incidence, occurrence, recurring, collectionId, anchor, x, y) }
        onMoreEventsClicked: function(date) { control.moreEventsClicked(date) }

        Component.onCompleted: setToDate(control.selectedDate)

        Connections
        {
            target: control
            function onSelectedDateChanged() { monthCalendar.setToDate(control.selectedDate) }
        }
    }
}
