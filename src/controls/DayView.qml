import QtQuick
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property date selectedDate
    required property string viewTitle
    signal incidenceActivated(var incidence, var occurrence)
    signal timeSlotActivated(date date)
    signal dateActivated(date date)

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Events for this day")
    }

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: 1
        implicitHeight: timelineLayout.implicitHeight + Maui.Style.contentMargins * 2

        ColumnLayout
        {
            id: timelineLayout
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            spacing: Maui.Style.space.small

            DayTimeline
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                startDate: control.selectedDate
                filter: MauiCalendar.Filter
                onIncidenceActivated: function(incidence, occurrence) { control.incidenceActivated(incidence, occurrence) }
                onTimeSlotActivated: function(date) { control.timeSlotActivated(date) }
                onDateActivated: function(date) { control.dateActivated(date) }
            }
        }
    }
}
