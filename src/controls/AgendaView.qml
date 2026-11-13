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
        text2: i18n("The next 31 days")
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
        }
    }
}
