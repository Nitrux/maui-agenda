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
    property bool tableRules: false
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
    signal eventContextRequested(var incidence, var occurrence, bool recurring, int collectionId, var anchor, real x, real y)
    signal timeContextRequested(date date, var anchor, real x, real y)
    signal timeSlotActivated(var date)
    signal dateActivated(var date)

    readonly property real hourHeight: Maui.Style.units.gridUnit * 4
    readonly property real gutterWidth: Maui.Style.units.gridUnit * 4
    readonly property real minimumDayWidth: Maui.Style.units.gridUnit * 8
    readonly property real ruleInset: Maui.Style.space.small
    readonly property real timelineOffset: Maui.Style.rowHeight / 2
    readonly property real timelineHeight: 24 * hourHeight + 2 * timelineOffset
    readonly property bool currentDateInWeek: {
        const today = new Date(currentTime)
        today.setHours(0, 0, 0, 0)
        const weekStart = new Date(startDate)
        weekStart.setHours(0, 0, 0, 0)
        const weekEnd = new Date(weekStart)
        weekEnd.setDate(weekEnd.getDate() + 7)
        return today >= weekStart && today < weekEnd
    }

    Flickable
    {
        id: timelineFlickable
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
                }

                Repeater
                {
                    model: control.dayCount

                    delegate: Item
                    {
                        id: allDayColumn
                        required property int index
                        Layout.fillWidth: true
                        Layout.minimumWidth: control.minimumDayWidth
                        implicitHeight: allDayCount * Maui.Style.rowHeight
                        property int allDayCount: 0
                        property date dayDate: new Date(control.startDate.getFullYear(), control.startDate.getMonth(), control.startDate.getDate() + index)

                        MauiCalendar.IncidenceOccurrenceModel
                        {
                            id: allDayIncidences
                            start: allDayColumn.dayDate
                            length: 1
                            filter: control.filter
                        }

                        Column
                        {
                            id: allDayItems
                            width: parent.width
                            spacing: Maui.Style.space.tiny - Maui.Style.space.tiny

                            Repeater
                            {
                                model: allDayIncidences

                                delegate: Button
                                {
                                    id: allDayChip
                                    required property bool allDay
                                    required property string summary
                                    required property var color
                                    required property var incidencePtr
                                    required property var startTime
                                    required property bool recurs
                                    required property int collectionId
                                    visible: allDay
                                    width: allDayItems.width
                                    height: allDay ? Maui.Style.rowHeight : 0
                                    implicitHeight: height
                                    padding: Maui.Style.space.tiny
                                    Component.onCompleted: if (allDay) allDayColumn.allDayCount++
                                    Component.onDestruction: if (allDay) allDayColumn.allDayCount--
                                    onClicked: control.incidenceActivated(incidencePtr, startTime)

                                    TapHandler
                                    {
                                        acceptedButtons: Qt.RightButton
                                        onTapped: function(eventPoint) { control.eventContextRequested(allDayChip.incidencePtr, allDayChip.startTime, allDayChip.recurs, allDayChip.collectionId, allDayChip, eventPoint.position.x, eventPoint.position.y) }
                                    }

                                    background: Rectangle
                                    {
                                        radius: Maui.Style.radiusV
                                        color: Qt.alpha(allDayChip.color, 0.28)
                                        border.color: allDayChip.color
                                        border.width: Maui.Style.space.tiny / 4
                                    }

                                    contentItem: RowLayout
                                    {
                                        spacing: Maui.Style.space.tiny

                                        Rectangle
                                        {
                                            Layout.preferredWidth: Maui.Style.space.tiny / 2
                                            Layout.preferredHeight: Maui.Style.space.medium
                                            Layout.alignment: Qt.AlignVCenter
                                            radius: Maui.Style.radiusV
                                            color: allDayChip.color
                                        }

                                        Label
                                        {
                                            Layout.fillWidth: true
                                            text: allDayChip.summary
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

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
                            y: control.timelineOffset + (control.tableRules && index < 24 ? index + 0.5 : index) * control.hourHeight - height / 2
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
                        clip: control.dayCount === 1

                        property date dayDate: new Date(control.startDate.getFullYear(), control.startDate.getMonth(), control.startDate.getDate() + index)
                        readonly property bool isToday: dayDate.getFullYear() === control.currentTime.getFullYear()
                                                        && dayDate.getMonth() === control.currentTime.getMonth()
                                                        && dayDate.getDate() === control.currentTime.getDate()

                        Item
                        {
                            id: currentTimeLine
                            visible: dayColumn.isToday || (control.tableRules && control.dayCount < 7 && dayColumn.index === 0 && control.currentDateInWeek)
                            x: control.dayCount === 1 ? control.ruleInset : -dayColumn.index * dayColumn.width
                            y: Math.round(control.timelineOffset + (control.currentTime.getHours() + control.currentTime.getMinutes() / 60 + control.currentTime.getSeconds() / 3600) * control.hourHeight - timelineFlickable.contentY) + timelineFlickable.contentY
                            width: control.dayCount === 1 ? parent.width - 2 * control.ruleInset : dayColumn.width * control.dayCount
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
                            model: 25

                            delegate: Rectangle
                            {
                                required property int index
                                x: control.tableRules ? 0 : control.ruleInset
                                width: control.tableRules ? parent.width : parent.width - 2 * control.ruleInset
                                height: Maui.Style.space.tiny / 4
                                y: Math.round(control.timelineOffset + index * control.hourHeight - height / 2)
                                color: Qt.darker(Maui.Theme.textColor, 2.2)
                                z: 0
                            }
                        }

                        Rectangle
                        {
                            visible: control.tableRules
                            y: control.tableRules ? control.timelineOffset : 0
                            width: Maui.Style.space.tiny / 4
                            height: control.tableRules ? 24 * control.hourHeight : parent.height
                            color: Qt.darker(Maui.Theme.textColor, 2.2)
                            z: 0
                        }

                        Rectangle
                        {
                            visible: control.tableRules && dayColumn.index === control.dayCount - 1
                            x: parent.width - width
                            y: control.tableRules ? control.timelineOffset : 0
                            width: Maui.Style.space.tiny / 4
                            height: control.tableRules ? 24 * control.hourHeight : parent.height
                            color: Qt.darker(Maui.Theme.textColor, 2.2)
                            z: 0
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
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: function(mouse)
                                            {
                                                if (mouse.button === Qt.RightButton)
                                                    control.eventContextRequested(modelData.incidencePtr, modelData.startTime, modelData.recurs, modelData.collectionId, parent, mouse.x, mouse.y)
                                                else
                                                    control.incidenceActivated(modelData.incidencePtr, modelData.startTime)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            z: -1
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse)
                            {
                                if (mouse.button !== Qt.RightButton)
                                    return
                                const minutes = Math.floor(Math.max(0, mouse.y - control.timelineOffset) / control.hourHeight * 4) * 15
                                const date = new Date(dayColumn.dayDate.getFullYear(), dayColumn.dayDate.getMonth(), dayColumn.dayDate.getDate(), Math.floor(minutes / 60), minutes % 60)
                                control.timeContextRequested(date, parent, mouse.x, mouse.y)
                            }
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
