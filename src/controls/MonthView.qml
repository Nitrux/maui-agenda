import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
    signal eventContextRequested(var incidence, var occurrence, bool recurring, int collectionId, var anchor, real x, real y)
    signal dateContextRequested(date date, var anchor, real x, real y)

    spacing: Maui.Style.space.big

    property date overflowDate: new Date()

    function showMoreEvents(date, anchor, x, y)
    {
        overflowDate = date
        const point = anchor.mapToItem(control, x, y)
        if (Maui.Handy.isMobile)
            overflowMenu.open()
        else
            overflowMenu.popup(control, point.x, point.y)
    }

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

    MauiCalendar.IncidenceOccurrenceModel
    {
        id: overflowEvents
        start: control.overflowDate
        length: 1
        filter: MauiCalendar.Filter
    }

    Maui.ContextualMenu
    {
        id: overflowMenu
        title: control.overflowDate.toLocaleDateString(Qt.locale(), "dddd, MMMM d")

        Instantiator
        {
            model: overflowEvents

            delegate: MenuItem
            {
                id: overflowEventItem
                required property string summary
                required property bool allDay
                required property var color
                required property var startTime
                required property var incidencePtr

                implicitHeight: Maui.Style.rowHeight
                text: (allDay ? i18n("All day") : Qt.formatTime(startTime, "HH:mm")) + "  " + summary
                onTriggered: control.incidenceClicked(incidencePtr, startTime)

                contentItem: RowLayout
                {
                    spacing: Maui.Style.space.tiny

                    Rectangle
                    {
                        Layout.preferredWidth: Maui.Style.space.tiny / 2
                        Layout.preferredHeight: Maui.Style.space.medium
                        Layout.alignment: Qt.AlignVCenter
                        radius: Maui.Style.radiusV
                        color: overflowEventItem.color
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        text: overflowEventItem.text
                        color: Maui.Theme.textColor
                        elide: Text.ElideRight
                    }
                }

                background: Rectangle
                {
                    radius: Maui.Style.radiusV
                    color: Qt.alpha(overflowEventItem.color, overflowEventItem.hovered ? 0.28 : 0.18)
                }
            }

            onObjectAdded: function(index, object) { overflowMenu.insertItem(index, object) }
            onObjectRemoved: function(index, object) { overflowMenu.removeItem(object) }
        }
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
        onMoreEventsClicked: function(date, anchor, x, y) { control.showMoreEvents(date, anchor, x, y) }

        Component.onCompleted: setToDate(control.selectedDate)

        Connections
        {
            target: control
            function onSelectedDateChanged() { monthCalendar.setToDate(control.selectedDate) }
        }
    }
}
