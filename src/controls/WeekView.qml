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
    signal incidenceActivated(var incidence, var occurrence)
    signal timeSlotActivated(date date)
    signal dateActivated(date date)

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Events for this week")
    }

    MauiCalendar.WeekView
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        selectedDate: control.selectedDate
        workWeek: control.workWeek
        filter: MauiCalendar.Filter
        onIncidenceActivated: function(incidence, occurrence) { control.incidenceActivated(incidence, occurrence) }
        onTimeSlotActivated: function(date) { control.timeSlotActivated(date) }
        onDateActivated: function(date) { control.dateActivated(date) }
    }
}
