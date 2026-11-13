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

        Maui.TabBar
        {
            id: weekdayTabs
            Layout.fillWidth: true
            Layout.topMargin: Maui.Style.space.medium
            Layout.bottomMargin: Maui.Style.space.medium
            padding: Maui.Style.defaultPadding
            spacing: Maui.Style.space.small
            showNewTabButton: false
            Maui.Controls.showCSD: false
            currentIndex: control.selectedDayIndex
            clip: true

            readonly property real uniformTabWidth: Math.max(0, (width - leftPadding - rightPadding - spacing * (control.dayCount - 1)) / control.dayCount)

            background: Rectangle
            {
                color: Maui.Theme.alternateBackgroundColor
                radius: height / 2
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < control.dayCount) {
                    const date = new Date(control.weekStartDate.getFullYear(), control.weekStartDate.getMonth(), control.weekStartDate.getDate() + currentIndex)
                    control.dateSelected(date)
                }
            }

            Instantiator
            {
                model: control.dayCount

                delegate: Maui.TabButton
                {
                    required property int index
                    width: weekdayTabs.uniformTabWidth
                    closeButtonVisible: false
                    text: {
                        const date = new Date(control.weekStartDate.getFullYear(), control.weekStartDate.getMonth(), control.weekStartDate.getDate() + index)
                        return Qt.formatDate(date, "ddd") + " " + date.getDate()
                    }
                }

                onObjectAdded: (index, object) => weekdayTabs.insertItem(index, object)
                onObjectRemoved: (index, object) => weekdayTabs.removeItem(object)
            }
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
            onTimeSlotActivated: function(date) { control.timeSlotActivated(date) }
            onDateActivated: function(date) { control.dateActivated(date) }
        }
    }
}
