import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.calendar as MauiCalendar

Pane
{
    id: control

    required property int currentView
    property string hiddenCollectionIds: ""
    signal viewSelected(int view)
    signal collectionVisibilityChanged(string ids)
    signal collectionPermissionsRequested(int collectionId)

    function toggleCollection(collectionId, index)
    {
        const hidden = MauiCalendar.Filter.collectionIds.includes(String(collectionId))
        calendarList.model.setData(calendarList.model.index(index, 0), hidden ? Qt.Checked : Qt.Unchecked, Qt.CheckStateRole)
        MauiCalendar.Filter.toggleCollection(collectionId)
        control.collectionVisibilityChanged(MauiCalendar.Filter.collectionIds.join(","))
    }

    Component.onCompleted: MauiCalendar.Filter.setCollectionIds(hiddenCollectionIds.length === 0 ? [] : hiddenCollectionIds.split(","))

    function viewLabel(view)
    {
        return [i18n("Year"), i18n("Day"), i18n("Month"), i18n("Week"), i18n("Agenda"), i18n("Tasks")][view]
    }

    function viewIndex(view)
    {
        for (let index = 0; index < calendarViews.count; ++index)
        {
            if (calendarViews.get(index).view === view)
                return index
        }
        return -1
    }

    ListModel
    {
        id: calendarViews

        ListElement { view: 0; icon: "view-calendar" }
        ListElement { view: 1; icon: "view-calendar-day" }
        ListElement { view: 3; icon: "view-calendar" }
        ListElement { view: 2; icon: "view-calendar" }
        ListElement { view: 4; icon: "view-list-details" }
        ListElement { view: 5; icon: "view-task" }
    }

    padding: 0
    focus: false
    clip: true
    Maui.Theme.colorSet: Maui.Theme.Window

    Maui.PopupPage
    {
        id: collectionColorDialog
        property int collectionId: -1
        title: i18n("Calendar Color")
        hint: 1
        actions: [Action { text: i18n("Cancel"); onTriggered: close() }]

        GridLayout
        {
            Layout.fillWidth: true
            columns: 4

            Repeater
            {
                model: ["#1d99f3", "#52b788", "#d89b4a", "#d1495b", "#7b61ff", "#00a6a6", "#e07a5f", "#6c757d"]
                delegate: ToolButton
                {
                    required property string modelData
                    Layout.fillWidth: true
                    background: Rectangle
                    {
                        implicitWidth: Maui.Style.iconSize
                        implicitHeight: Maui.Style.iconSize
                        radius: Maui.Style.radiusV
                        color: modelData
                    }
                    onClicked:
                    {
                        MauiCalendar.CalendarManager.setCollectionColor(collectionColorDialog.collectionId, modelData)
                        collectionColorDialog.close()
                    }
                }
            }
        }
    }

    Maui.ContextualMenu
    {
        id: calendarContextMenu
        property int collectionId: -1
        property int collectionIndex: -1
        property string collectionName: ""
        readonly property bool canDeleteCollection: collectionId > 0
                && !MauiCalendar.CalendarManager.isCalDavCollection(collectionId)
                && MauiCalendar.CalendarManager.subscriptionForCollection(collectionId).length === 0
        title: collectionName

        MenuItem
        {
            text: i18n("Show calendar")
            visible: MauiCalendar.Filter.collectionIds.includes(String(calendarContextMenu.collectionId))
            icon.name: "view-visible"
            onTriggered: control.toggleCollection(calendarContextMenu.collectionId, calendarContextMenu.collectionIndex)
        }

        MenuItem
        {
            text: i18n("Hide calendar")
            visible: !MauiCalendar.Filter.collectionIds.includes(String(calendarContextMenu.collectionId))
            icon.name: "view-hidden"
            onTriggered: control.toggleCollection(calendarContextMenu.collectionId, calendarContextMenu.collectionIndex)
        }

        MenuItem
        {
            text: i18n("Set calendar color")
            icon.name: "color-picker"
            onTriggered:
            {
                collectionColorDialog.collectionId = calendarContextMenu.collectionId
                collectionColorDialog.open()
            }
        }

        MenuItem
        {
            text: i18n("Permissions")
            icon.name: "user-group-properties"
            visible: MauiCalendar.CalendarManager.isCalDavCollection(calendarContextMenu.collectionId)
            onTriggered: control.collectionPermissionsRequested(calendarContextMenu.collectionId)
        }

        MenuSeparator { visible: calendarContextMenu.canDeleteCollection }

        MenuItem
        {
            text: i18n("Delete calendar…")
            icon.name: "edit-delete"
            visible: calendarContextMenu.canDeleteCollection
            enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(calendarContextMenu.collectionId)
            onTriggered:
            {
                deleteCalendarDialog.collectionId = calendarContextMenu.collectionId
                deleteCalendarDialog.collectionName = calendarContextMenu.collectionName
                deleteCalendarDialog.open()
            }
        }
    }

    Maui.InfoDialog
    {
        id: deleteCalendarDialog
        property int collectionId: -1
        property string collectionName: ""
        title: i18n("Delete Calendar")
        message: i18n("Delete “%1” and its events? This action cannot be undone.", collectionName)
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: MauiCalendar.CalendarManager.removeCollection(collectionId)
    }

    background: Rectangle
    {
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: 1
    }

    contentItem: ColumnLayout
    {
        spacing: Maui.Style.defaultSpacing - Maui.Style.defaultSpacing

        Maui.ListBrowser
        {
        id: listBrowser
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.preferredHeight: implicitHeight
        background: null
        verticalScrollBarPolicy: ScrollBar.AlwaysOff
        focus: false
        focusPolicy: Qt.NoFocus
        Keys.enabled: false
        currentIndex: control.viewIndex(control.currentView)

        flickable.header: Maui.SectionHeader
        {
            width: listBrowser.availableWidth
            text1: i18n("Views")
            label1.font.weight: Font.Bold
            label1.font.pixelSize: 14
            label2.visible: false
        }

        model: calendarViews

        delegate: Maui.ListDelegate
        {
            required property int view
            required property string icon

            width: listBrowser.availableWidth
            label: control.viewLabel(view)
            iconName: icon
            iconVisible: true
            iconSize: Maui.Style.iconSize
            isCurrentItem: view === control.currentView

            onClicked: control.viewSelected(view)
        }
    }

        Maui.SectionHeader
        {
            Layout.fillWidth: true
            text1: i18n("Calendars")
            label1.font.weight: Font.Bold
            label1.font.pixelSize: 14
            label2.visible: false
        }

        ListView
        {
            id: calendarList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Maui.Style.contentMargins
            Layout.rightMargin: Maui.Style.contentMargins
            clip: true
            model: MauiCalendar.CalendarManager.collections
            delegate: Maui.ListDelegate
            {
                required property int collectionId
                required property int index
                width: calendarList.width
                label: calendarList.model.data(calendarList.model.index(index, 0), Qt.DisplayRole)
                iconName: "view-calendar"
                iconVisible: true
                iconSize: Maui.Style.iconSize
                flat: true

                onClicked:
                {
                    calendarList.currentIndex = index
                    control.toggleCollection(collectionId, index)
                }

                onRightClicked: function(mouse)
                {
                    calendarContextMenu.collectionId = collectionId
                    calendarContextMenu.collectionName = label
                    calendarContextMenu.collectionIndex = index
                    calendarList.currentIndex = index
                    const point = mapToItem(control, mouse.x, mouse.y)
                    calendarContextMenu.popup(point.x, point.y)
                }

            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
    }

}
