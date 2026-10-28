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

    Component.onCompleted: MauiCalendar.Filter.setCollectionIds(hiddenCollectionIds.length === 0 ? [] : hiddenCollectionIds.split(","))

    function viewLabel(view)
    {
        return [i18n("Year"), i18n("Month"), i18n("Week"), i18n("Day"), i18n("Schedule")][view]
    }

    ListModel
    {
        id: calendarViews

        ListElement { view: 0; icon: "view-calendar" }
        ListElement { view: 1; icon: "view-calendar" }
        ListElement { view: 2; icon: "view-calendar" }
        ListElement { view: 3; icon: "view-calendar-day" }
        ListElement { view: 4; icon: "view-list-details" }
    }

    padding: 0
    focus: false
    clip: true
    Maui.Theme.colorSet: Maui.Theme.Window

    Maui.PopupPage
    {
        id: collectionColorDialog
        property int collectionId: -1
        title: i18n("Calendar color")
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
        currentIndex: control.currentView

        flickable.header: Maui.SectionHeader
        {
            width: listBrowser.availableWidth
            text1: i18n("Views")
            label1.font.weight: Font.Bold
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

            onClicked:
            {
                listBrowser.currentIndex = view
                control.viewSelected(view)
            }
        }
    }

        Maui.SectionHeader
        {
            Layout.fillWidth: true
            text1: i18n("Calendars")
            label1.font.weight: Font.Bold
            label2.visible: false
        }

        ListView
        {
            id: calendarList
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    const hidden = MauiCalendar.Filter.collectionIds.includes(String(collectionId))
                    calendarList.model.setData(calendarList.model.index(index, 0), hidden ? Qt.Checked : Qt.Unchecked, Qt.CheckStateRole)
                    MauiCalendar.Filter.toggleCollection(collectionId)
                    control.collectionVisibilityChanged(MauiCalendar.Filter.collectionIds.join(","))
                }

            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
    }

    onCurrentViewChanged: listBrowser.currentIndex = currentView
}
