import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.calendar as MauiCalendar

ColumnLayout
{
    id: control

    signal incidenceActivated(var incidence, var occurrence, bool isTask, bool hasDate)

    required property string query
    property int calendarRevision: 0
    readonly property var results:
    {
        calendarRevision
        return query.trim().length > 0 ? MauiCalendar.CalendarManager.searchIncidences(query) : []
    }

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: i18n("Search")
        text2: i18n("Search events and tasks by title, description, or location.")
    }


    Maui.ListBrowser
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: null
        model: control.results
        holder.visible: count === 0
        holder.title: control.query.trim().length > 0 ? i18n("No matches") : i18n("Search your calendar")
        holder.body: control.query.trim().length > 0
                     ? i18n("Try a different search.")
                     : i18n("Search event and task titles, descriptions, and locations.")

        delegate: Maui.ListBrowserDelegate
        {
            required property var modelData
            width: ListView.view.width
            label1.text: modelData.summary
            label2.text: modelData.isTask ? i18n("Task") : (modelData.hasDate ? Qt.formatDate(modelData.startTime, "ddd, d MMM yyyy") : i18n("No date"))
            iconSource: modelData.isTask ? "view-task" : "view-calendar"
            onClicked: control.incidenceActivated(modelData.incidencePtr, modelData.startTime, modelData.isTask, modelData.hasDate)
        }
    }

    Connections
    {
        target: MauiCalendar.CalendarManager
        function onCalendarChanged() { control.calendarRevision++ }
    }
}
