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

    spacing: Maui.Style.space.big

    MauiCalendar.IncidenceOccurrenceModel
    {
        id: agendaEvents
        start: control.currentDate
        length: 31
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
            width: ListView.view.width
            label1.text: model.summary
            label2.text: model.allDay ? i18n("All day") : model.startTime.toLocaleString(Qt.locale(), Locale.ShortFormat)
            onClicked: control.incidenceActivated(model.incidencePtr, model.startTime)
            onRightClicked: function(mouse) { control.eventContextRequested(model.incidencePtr, model.startTime, model.recurs, model.collectionId, this, mouse.x, mouse.y) }
        }
    }
}
