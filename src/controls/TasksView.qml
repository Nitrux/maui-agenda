import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property var taskItems
    signal taskActivated(var incidence)
    signal completionRequested(var task, bool completed)
    signal deletionRequested(var incidence)
    signal taskContextRequested(var task, var anchor, real x, real y)

    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: i18n("Tasks")
        text2: i18n("Open and completed tasks")
    }

    Maui.ListBrowser
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: null
        model: control.taskItems
        holder.visible: count === 0
        holder.emoji: "view-task"
        holder.title: i18n("No tasks")
        holder.body: i18n("Create a task to keep track of things to do.")

        delegate: Maui.ListBrowserDelegate
        {
            required property var modelData
            width: ListView.view.width
            label1.text: modelData.summary
            label1.font.strikeout: modelData.completed
            label2.text: modelData.endTime && modelData.endTime.getTime() >= 0 ? Qt.formatDate(modelData.endTime, "ddd, d MMM yyyy") : i18n("No due date")
            label3.text: modelData.priority > 0 ? i18n("Priority %1", modelData.priority) : ""
            label3.visible: modelData.priority > 0
            iconSource: "view-task"
            onClicked: control.taskActivated(modelData.incidencePtr)
            onRightClicked: function(mouse) { control.taskContextRequested(modelData, this, mouse.x, mouse.y) }

            CheckBox
            {
                checked: modelData.completed
                enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(modelData.collectionId)
                onToggled: control.completionRequested(modelData, checked)
            }

            ToolButton
            {
                icon.name: "edit-delete"
                enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(modelData.collectionId)
                onClicked: control.deletionRequested(modelData.incidencePtr)
            }
        }
    }
}
