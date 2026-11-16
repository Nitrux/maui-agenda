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
            id: taskCard
            required property var modelData
            width: ListView.view.width
            height: implicitHeight
            iconVisible: false
            onClicked: control.taskActivated(modelData.incidencePtr)
            onRightClicked: function(mouse) { control.taskContextRequested(modelData, this, mouse.x, mouse.y) }

            ColumnLayout
            {
                id: taskContent
                Layout.fillWidth: true
                spacing: Maui.Style.space.tiny

                Label
                {
                    Layout.fillWidth: true
                    text: taskCard.modelData.summary
                    font.strikeout: taskCard.modelData.completed
                    elide: Text.ElideRight
                }

                Label
                {
                    Layout.fillWidth: true
                    text: {
                        const dueDate = taskCard.modelData.endTime
                        const due = dueDate && dueDate.getTime() >= 0 ? Qt.formatDate(dueDate, "ddd, d MMM yyyy") : i18n("No due date")
                        const priority = taskCard.modelData.priority > 0 ? i18n("Priority %1", taskCard.modelData.priority) : ""
                        return priority.length > 0 ? due + " · " + priority : due
                    }
                    elide: Text.ElideRight
                    opacity: 0.7
                }

                Label
                {
                    Layout.fillWidth: true
                    visible: taskCard.modelData.description.length > 0
                    text: taskCard.modelData.description
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    opacity: 0.7
                }
            }

            background: Rectangle
            {
                radius: taskCard.radius
                color: Qt.tint(Maui.Theme.alternateBackgroundColor, Qt.rgba(taskCard.modelData.color.r, taskCard.modelData.color.g, taskCard.modelData.color.b, 0.2))
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
                    color: taskCard.modelData.color
                }
            }

            CheckBox
            {
                checked: taskCard.modelData.completed
                enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(taskCard.modelData.collectionId)
                onToggled: control.completionRequested(taskCard.modelData, checked)
            }

            ToolButton
            {
                icon.name: "edit-delete"
                enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(taskCard.modelData.collectionId)
                onClicked: control.deletionRequested(taskCard.modelData.incidencePtr)
            }
        }
    }
}
