import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property date currentDate
    signal incidenceActivated(var incidence, var occurrence)
    signal eventContextRequested(var incidence, var occurrence, bool recurring, int collectionId, var anchor, real x, real y)
    signal dateContextRequested(date date, var anchor, real x, real y)

    readonly property int daysAhead: 31

    spacing: Maui.Style.space.big

    function dayLabel(date)
    {
        const today = new Date()
        today.setHours(0, 0, 0, 0)
        const tomorrow = new Date(today)
        tomorrow.setDate(tomorrow.getDate() + 1)

        const day = new Date(date)
        day.setHours(0, 0, 0, 0)
        if (day.getTime() === today.getTime())
            return i18n("Today")
        if (day.getTime() === tomorrow.getTime())
            return i18n("Tomorrow")
        return day.toLocaleDateString(Qt.locale(), "dddd, MMMM d, yyyy")
    }

    MauiCalendar.IncidenceOccurrenceModel
    {
        id: agendaEvents
        start: control.currentDate
        length: control.daysAhead
        filter: MauiCalendar.Filter
    }

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: i18n("Agenda")
        text2: i18n("Events for this 31-day period")

        TapHandler
        {
            acceptedButtons: Qt.RightButton
            onTapped: function(eventPoint) { control.dateContextRequested(control.currentDate, parent, eventPoint.position.x, eventPoint.position.y) }
        }
    }

    Maui.ListBrowser
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: null
        model: agendaEvents
        holder.visible: count === 0
        holder.emoji: "view-calendar"
        holder.title: i18n("No upcoming events")
        holder.body: i18n("Create an event to see it in your schedule.")

        delegate: Maui.ListBrowserDelegate
        {
            id: eventCard
            required property string summary
            required property string description
            required property string location
            required property date startTime
            required property string durationString
            required property var color
            required property var incidencePtr
            required property bool recurs
            required property int collectionId
            required property bool allDay
            required property int incidenceType

            width: ListView.view.width
            height: visible ? implicitHeight : 0
            visible: incidenceType === MauiCalendar.IncidenceWrapper.TypeEvent
            iconVisible: false
            onClicked: control.incidenceActivated(incidencePtr, startTime)
            onRightClicked: function(mouse) { control.eventContextRequested(incidencePtr, startTime, recurs, collectionId, this, mouse.x, mouse.y) }

            ColumnLayout
            {
                Layout.fillWidth: true
                spacing: Maui.Style.space.tiny

                Label
                {
                    Layout.fillWidth: true
                    text: eventCard.summary
                    elide: Text.ElideRight
                }

                Label
                {
                    Layout.fillWidth: true
                    text: control.dayLabel(eventCard.startTime) + " · " + (eventCard.allDay ? i18n("All day") : eventCard.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) + (eventCard.durationString.length > 0 ? " · " + eventCard.durationString : ""))
                    elide: Text.ElideRight
                    opacity: 0.7
                }

                Label
                {
                    Layout.fillWidth: true
                    visible: eventCard.location.length > 0
                    text: eventCard.location
                    elide: Text.ElideRight
                    opacity: 0.7
                }

                Label
                {
                    Layout.fillWidth: true
                    visible: eventCard.description.length > 0
                    text: eventCard.description
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    opacity: 0.7
                }
            }

            background: Rectangle
            {
                radius: Maui.Style.radiusV
                color: Qt.tint(Maui.Theme.alternateBackgroundColor, Qt.rgba(eventCard.color.r, eventCard.color.g, eventCard.color.b, 0.2))
                border.color: Maui.Theme.backgroundColor
                border.width: Maui.Style.space.tiny / 4

                Rectangle
                {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Maui.Style.space.small
                    width: Maui.Style.space.tiny / 2
                    radius: Maui.Style.radiusV
                    color: eventCard.color
                }
            }
        }
    }
}
