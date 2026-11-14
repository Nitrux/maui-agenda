import QtQuick
import QtQuick.Layouts

import org.mauikit.controls as Maui

Maui.TabBar
{
    id: control

    property date startDate: new Date()
    property date activeDate: new Date()
    property int dayCount: 7
    property bool showDateNumbers: true
    signal dateSelected(date date)

    readonly property int activeIndex: {
        for (let index = 0; index < dayCount; ++index) {
            const date = dateAtIndex(index)
            if (Qt.formatDate(date, "yyyyMMdd") === Qt.formatDate(activeDate, "yyyyMMdd"))
                return index
        }
        return -1
    }

    function dateAtIndex(index)
    {
        return new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + index)
    }

    Layout.fillWidth: true
    Layout.topMargin: Maui.Style.space.medium
    Layout.bottomMargin: Maui.Style.space.medium
    padding: Maui.Style.defaultPadding
    spacing: Maui.Style.space.small
    showNewTabButton: false
    Maui.Controls.showCSD: false
    currentIndex: control.activeIndex
    clip: true

    readonly property real uniformTabWidth: Math.max(0, (width - leftPadding - rightPadding - spacing * (dayCount - 1)) / dayCount)

    background: Rectangle
    {
        color: Maui.Theme.alternateBackgroundColor
        radius: height / 2
    }

    Instantiator
    {
        model: control.dayCount

        delegate: Maui.TabButton
        {
            required property int index
            width: control.uniformTabWidth
            closeButtonVisible: false
            text: {
                const date = control.dateAtIndex(index)
                return control.showDateNumbers ? Qt.formatDate(date, "ddd") + " " + date.getDate() : Qt.formatDate(date, "ddd")
            }
            onClicked: {
                const date = control.dateAtIndex(index)
                control.dateSelected(date)
            }
        }

        onObjectAdded: (index, object) => control.insertItem(index, object)
        onObjectRemoved: (index, object) => control.removeItem(object)
    }
}
