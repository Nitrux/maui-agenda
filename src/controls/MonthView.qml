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

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Browse dates and events for this month.")
    }

    MauiCalendar.MonthView
    {
        id: monthCalendar
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: null
        selectedDate: control.selectedDate
        clip: true

        onDateClicked: function(date) { control.dateClicked(date) }
        onDateDoubleClicked: function(date) { control.dateDoubleClicked(date) }
        onIncidenceClicked: function(incidence, occurrence) { control.incidenceClicked(incidence, occurrence) }
        onMoreEventsClicked: function(date) { control.moreEventsClicked(date) }

        Component.onCompleted: setToDate(control.selectedDate)

        Connections
        {
            target: control
            function onSelectedDateChanged() { monthCalendar.setToDate(control.selectedDate) }
        }
    }
}
