import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

Pane
{
    id: control

    required property int currentView
    signal viewSelected(int view)

    function viewLabel(view)
    {
        return [i18n("Year"), i18n("Month"), i18n("Week"), i18n("Day")][view]
    }

    ListModel
    {
        id: calendarViews

        ListElement { view: 0; icon: "view-calendar" }
        ListElement { view: 1; icon: "view-calendar" }
        ListElement { view: 2; icon: "view-calendar" }
        ListElement { view: 3; icon: "view-calendar-day" }
    }

    padding: 0
    focus: false
    clip: true
    Maui.Theme.colorSet: Maui.Theme.Window

    background: Rectangle
    {
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: 1
    }

    contentItem: Maui.ListBrowser
    {
        id: listBrowser
        background: null
        verticalScrollBarPolicy: ScrollBar.AlwaysOff
        focus: false
        focusPolicy: Qt.NoFocus
        Keys.enabled: false
        currentIndex: control.currentView

        flickable.header: Maui.SectionHeader
        {
            width: listBrowser.availableWidth
            text1: i18n("Calendar")
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

    onCurrentViewChanged: listBrowser.currentIndex = currentView
}
