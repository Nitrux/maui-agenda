import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

ColumnLayout
{
    id: control

    required property date currentDate
    required property string viewTitle
    signal dateSelected(date date)
    signal monthSelected(date date)

    clip: true
    spacing: Maui.Style.space.big

    Maui.SectionHeader
    {
        Layout.fillWidth: true
        text1: control.viewTitle
        text2: i18n("Browse the months and select a date.")
    }

    ScrollView
    {
        id: yearScrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        GridLayout
        {
            id: yearCards
            width: parent.width
            height: Math.max(yearScrollView.height, implicitHeight)
            columns: width > Maui.Style.units.gridUnit * 45 ? 4 : width > Maui.Style.units.gridUnit * 30 ? 3 : 2
            columnSpacing: Maui.Style.space.small
            rowSpacing: Maui.Style.space.small

            Repeater
            {
                model: 12

                delegate: Rectangle
                {
                    id: monthCard
                    required property int index
                    readonly property int month: index + 1

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Maui.Style.units.gridUnit * 15
                    color: Maui.Theme.alternateBackgroundColor
                    radius: Maui.Style.radiusV
                    border.color: Maui.Theme.backgroundColor
                    border.width: 1
                    implicitHeight: monthLayout.implicitHeight + Maui.Style.contentMargins * 2

                    ColumnLayout
                    {
                        id: monthLayout
                        anchors.fill: parent
                        anchors.margins: Maui.Style.contentMargins
                        spacing: Maui.Style.space.small

                        Button
                        {
                            Layout.fillWidth: true
                            flat: true
                            background: null
                            contentItem: Maui.SectionHeader
                            {
                                text1: Qt.locale().standaloneMonthName(monthCard.index)
                                text2: String(control.currentDate.getFullYear())
                                label2.wrapMode: Text.Wrap
                            }
                            onClicked: control.monthSelected(new Date(control.currentDate.getFullYear(), monthCard.index, 1))
                        }

                        MauiCalendar.DaysGrid
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            background: null
                            compact: true
                            year: control.currentDate.getFullYear()
                            month: monthCard.month
                            onDateClicked: function(date) { control.dateSelected(date) }
                        }
                    }
                }
            }
        }
    }
}
