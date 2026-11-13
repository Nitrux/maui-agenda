import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

Item
{
    id: control

    property date startDate: new Date()
    property int dayCount: 1
    property var filter: MauiCalendar.Filter
    property date currentTime: new Date()

    Timer
    {
        interval: 1000
        repeat: true
        running: true
        onTriggered: control.currentTime = new Date()
    }

    signal incidenceActivated(var incidence, var occurrence)
    signal timeSlotActivated(var date)
    signal dateActivated(var date)

    readonly property real hourHeight: Maui.Style.units.gridUnit * 4
    readonly property real gutterWidth: Maui.Style.units.gridUnit * 4
    readonly property real minimumDayWidth: Maui.Style.units.gridUnit * 8
    readonly property real ruleInset: Maui.Style.space.small
    readonly property real timelineOffset: Maui.Style.rowHeight / 2
    readonly property real timelineHeight: 24 * hourHeight + 2 * timelineOffset

    Flickable
    {
        anchors.fill: parent
        contentWidth: Math.max(width, control.gutterWidth + control.dayCount * control.minimumDayWidth)
        contentHeight: timeline.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout
        {
            id: timeline
            width: Math.max(parent.width, control.gutterWidth + control.dayCount * control.minimumDayWidth)
            spacing: Maui.Style.space.tiny - Maui.Style.space.tiny

            RowLayout
            {
                Layout.fillWidth: true
                spacing: Maui.Style.space.tiny - Maui.Style.space.tiny

                Item
                {
                    Layout.preferredWidth: control.gutterWidth
                    Layout.preferredHeight: control.timelineHeight

                    Repeater
                    {
                        model: 25

                        delegate: Label
                        {
                            required property int index
                            y: control.timelineOffset + index * control.hourHeight - height / 2
                            width: parent.width - Maui.Style.space.small
                            height: Maui.Style.rowHeight
                            text: index === 24 ? "24:00" : Qt.formatTime(new Date(2000, 0, 1, index), "HH:mm")
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            color: Qt.alpha(Maui.Theme.textColor, 0.75)
                        }
                    }
                }

                Repeater
                {
                    model: control.dayCount

                    delegate: Item
                    {
                        id: dayColumn
                        required property int index
                        Layout.fillWidth: true
                        Layout.minimumWidth: control.minimumDayWidth
                        Layout.preferredHeight: control.timelineHeight
                        clip: true

                        property date dayDate: new Date(control.startDate.getFullYear(), control.startDate.getMonth(), control.startDate.getDate() + index)
                        readonly property bool isToday: Qt.formatDate(dayDate, "yyyyMMdd") === Qt.formatDate(control.currentTime, "yyyyMMdd")

                        Item
                        {
                            id: currentTimeLine
                            visible: dayColumn.isToday
                            x: control.ruleInset
                            y: control.timelineOffset + (control.currentTime.getHours() + control.currentTime.getMinutes() / 60 + control.currentTime.getSeconds() / 3600) * control.hourHeight
                            width: parent.width - 2 * control.ruleInset
                            height: 0
                            z: 10

                            Rectangle
                            {
                                id: currentTimeDot
                                x: 0
                                y: -height / 2
                                width: Maui.Style.iconSize / 3 + Maui.Style.space.small / 2
                                height: width
                                radius: width / 2
                                color: Maui.Theme.negativeBackgroundColor
                            }

                            Rectangle
                            {
                                x: currentTimeDot.width
                                y: -height / 2
                                width: parent.width - currentTimeDot.width
                                height: Maui.Style.units.gridUnit / 8
                                color: Maui.Theme.negativeBackgroundColor
                            }
                        }

                        MauiCalendar.IncidenceOccurrenceModel
                        {
                            id: dayEvents
                            start: dayColumn.dayDate
                            length: 1
                            filter: control.filter
                        }

                        MauiCalendar.HourlyIncidenceModel
                        {
                            id: hourlyEvents
                            model: dayEvents
                            filters: MauiCalendar.HourlyIncidenceModel.NoAllDay
                        }

                        Repeater
                        {
                            z: -1
                            model: dayEvents

                            delegate: Item
                            {
                                id: allDayBackground
                                required property bool allDay
                                required property var color
                                visible: allDay
                                anchors.fill: parent

                                Rectangle
                                {
                                    anchors.fill: parent
                                    color: Qt.alpha(allDayBackground.color, 0.10)
                                    border.color: Qt.alpha(allDayBackground.color, 0.48)
                                    border.width: Maui.Style.space.tiny / 4
                                }
                            }
                        }

                        Column
                        {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            z: 2
                            spacing: Maui.Style.space.tiny
                            clip: true

                            Repeater
                            {
                                model: dayEvents

                                delegate: Maui.ListDelegate
                                {
                                    id: allDayLabel
                                    required property bool allDay
                                    required property string summary
                                    required property var color
                                    required property var incidencePtr
                                    required property var startTime
                                    visible: allDay
                                    width: parent.width
                                    height: allDay ? Maui.Style.rowHeight : 0
                                    label: summary
                                    background: Rectangle
                                    {
                                        color: Qt.alpha(allDayLabel.color, 0.24)
                                        border.color: allDayLabel.color
                                        border.width: Maui.Style.space.tiny / 4
                                    }
                                    onClicked: control.incidenceActivated(incidencePtr, startTime)
                                }
                            }
                        }

                        Repeater
                        {
                            model: 25

                            delegate: Rectangle
                            {
                                required property int index
                                x: control.ruleInset
                                width: parent.width - 2 * control.ruleInset
                                height: Maui.Style.space.tiny / 4
                                y: Math.round(control.timelineOffset + index * control.hourHeight - height / 2)
                                color: Qt.alpha(Maui.Theme.textColor, 0.35)
                                z: 3
                            }
                        }

                        Repeater
                        {
                            z: 1
                            model: hourlyEvents

                            delegate: Item
                            {
                                required property var incidences
                                anchors.fill: parent

                                Repeater
                                {
                                    model: parent.incidences

                                    delegate: Rectangle
                                    {
                                        required property var modelData
                                        z: 4
                                        x: parent.width * Number(modelData.priorTakenWidthShare || 0)
                                        y: control.timelineOffset + Number(modelData.starts) * control.hourHeight / 4
                                        width: parent.width * Number(modelData.widthShare || 1)
                                        height: Math.max(Maui.Style.units.gridUnit * 1.5, Number(modelData.duration) * control.hourHeight / 4)
                                        visible: !modelData.allDay
                                        clip: true
                                        radius: Maui.Style.radiusV
                                        color: Qt.alpha(modelData.color, 0.28)
                                        border.color: modelData.color
                                        border.width: Maui.Style.space.tiny / 4

                                        Column
                                        {
                                            anchors.fill: parent
                                            anchors.margins: Maui.Style.space.tiny
                                            spacing: Maui.Style.space.tiny

                                            Label
                                            {
                                                width: parent.width
                                                text: modelData.text
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label
                                            {
                                                width: parent.width
                                                visible: parent.parent.height > Maui.Style.rowHeight
                                                text: Qt.formatTime(modelData.startTime, "HH:mm")
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea
                                        {
                                            anchors.fill: parent
                                            onClicked: control.incidenceActivated(modelData.incidencePtr, modelData.startTime)
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            z: -1
                            acceptedButtons: Qt.LeftButton
                            onDoubleClicked: function(mouse)
                            {
                                const minutes = Math.floor(Math.max(0, mouse.y - control.timelineOffset) / control.hourHeight * 4) * 15
                                const date = new Date(dayColumn.dayDate.getFullYear(), dayColumn.dayDate.getMonth(), dayColumn.dayDate.getDate(), Math.floor(minutes / 60), minutes % 60)
                                control.timeSlotActivated(date)
                            }
                        }
                    }
                }
            }
        }
    }
}
