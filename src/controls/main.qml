import QtQuick
import QtQml
import QtQuick.Controls
import QtCore
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar

Maui.ApplicationWindow
{
    id: root

    color: "transparent"
    background: null

    title: i18n("Agenda")
    property int currentView: 0
    property date currentDate: new Date()
    readonly property string currentViewTitle: {
        if (currentView === 0)
            return Qt.formatDate(currentDate, "yyyy")
        if (currentView === 1)
            return Qt.formatDate(currentDate, "MMMM yyyy")
        if (currentView === 2)
            return i18n("Week of %1", Qt.formatDate(weekStart(currentDate), Qt.DefaultLocaleShortDate))
        return Qt.formatDate(currentDate, "dd/MM/yyyy")
    }
    readonly property alias appSettings: agendaSettings

    Settings
    {
        id: agendaSettings
        category: "Agenda"
        property bool sidebarVisible: true
    }

    function selectDate(date)
    {
        root.currentDate = date
    }

    function changeDate(amount)
    {
        const next = new Date(root.currentDate)
        if (root.currentView === 0)
            next.setFullYear(next.getFullYear() + amount)
        else if (root.currentView === 1)
            next.setMonth(next.getMonth() + amount)
        else if (root.currentView === 2)
            next.setDate(next.getDate() + (amount * 7))
        else
            next.setDate(next.getDate() + amount)
        root.selectDate(next)
    }

    function weekStart(date)
    {
        const start = new Date(date)
        start.setDate(start.getDate() - ((start.getDay() + 6) % 7))
        return start
    }

    function openNewEvent()
    {
        eventDialog.openNew(root.currentDate)
    }

    Maui.WindowBlur
    {
        view: root
        geometry: Qt.rect(0, 0, root.width, root.height)
        windowRadius: Maui.Style.radiusV
        enabled: true
    }

    Rectangle
    {
        anchors.fill: parent
        color: Maui.Theme.backgroundColor
        opacity: 0.76
        radius: Maui.Style.radiusV
    }

    Maui.InfoDialog
    {
        id: eventDialog
        property bool editing: false
        title: editing ? i18n("Edit Event") : i18n("Add Event")
        standardButtons: Dialog.NoButton
        padding: 0

        Component.onCompleted:
        {
            contentItem.leftPadding = Maui.Style.space.small
            contentItem.rightPadding = Maui.Style.space.small
            compactEventForm()
        }

        function compactEventForm()
        {
            const groups = eventPage.contentItem.container.children
            for (let groupIndex = 0; groupIndex < groups.length; ++groupIndex)
            {
                const group = groups[groupIndex]
                group.padding = 0

                const items = group.contentItem.children
                for (let itemIndex = 1; itemIndex < items.length; ++itemIndex)
                    items[itemIndex].padding = 0
            }
        }

        function openNew(date)
        {
            editing = false
            eventPage.incidence.setNewEvent()
            eventPage.incidence.setIncidenceStartDate(date.getDate(), date.getMonth(), date.getFullYear())
            open()
        }

        function openExisting(incidence)
        {
            if (!incidence)
                return
            editing = true
            eventPage.incidence.incidencePtr = incidence
            eventPage.incidence.triggerEditMode()
            open()
        }

        property list<Action> eventActions: [
            Action
            {
                text: i18n("Cancel")
                onTriggered: eventDialog.close()
            },
            Action
            {
                text: i18n("Delete")
                Maui.Controls.status: Maui.Controls.Negative
                onTriggered:
                {
                    MauiCalendar.CalendarManager.deleteIncidence(eventPage.incidence.originalIncidencePtr)
                    eventDialog.close()
                }
            },
            Action
            {
                text: eventDialog.editing ? i18n("Save") : i18n("Create")
                Maui.Controls.status: Maui.Controls.Positive
                onTriggered:
                {
                    if (eventDialog.editing)
                        MauiCalendar.CalendarManager.editIncidence(eventPage.incidence)
                    else
                        MauiCalendar.CalendarManager.addIncidence(eventPage.incidence)
                    eventDialog.close()
                }
            }
        ]

        MauiCalendar.EventPage
        {
            id: eventPage
            Layout.fillWidth: true
        }

        RowLayout
        {
            Layout.fillWidth: true
            Layout.topMargin: Maui.Style.space.small
            spacing: Maui.Style.space.small

            Button
            {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: eventDialog.eventActions[0].text
                onClicked: eventDialog.eventActions[0].trigger()
            }

            Button
            {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                visible: eventDialog.editing
                Maui.Controls.status: Maui.Controls.Negative
                text: eventDialog.eventActions[1].text
                onClicked: eventDialog.eventActions[1].trigger()
            }

            Button
            {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Maui.Controls.status: Maui.Controls.Positive
                text: eventDialog.eventActions[2].text
                onClicked: eventDialog.eventActions[2].trigger()
            }
        }
    }

    Maui.SideBarView
    {
        id: sideBarView
        anchors.fill: parent
        background: null
        sideBar.preferredWidth: Maui.Style.units.gridUnit * 12
        sideBar.minimumWidth: Maui.Style.units.gridUnit * 12
        sideBar.autoHide: true
        sideBar.autoShow: agendaSettings.sidebarVisible
        sideBar.floats: sideBar.collapsed
        Maui.Theme.colorSet: Maui.Theme.Window

        sideBarContent: Item
        {
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            anchors.rightMargin: 0

            CalendarSidebar
            {
                anchors.fill: parent
                anchors.rightMargin: 0
                currentView: root.currentView
                onViewSelected: (view) => root.currentView = view
            }
        }

        Connections
        {
            target: sideBarView.sideBar

            function onOpened()
            {
                agendaSettings.sidebarVisible = true
            }

            function onClosed()
            {
                agendaSettings.sidebarVisible = false
            }
        }

        Maui.Page
        {
            anchors.fill: parent
            background: null
            footBar.background: null
            title: root.currentViewTitle
            showTitle: false
            autoHideHeader: false
            altHeader: Maui.Handy.isMobile
            headerMargins: Maui.Style.contentMargins
            floatingHeader: false
            headBar.forceCenterMiddleContent: true
            headBar.preferredHeight: Maui.Style.rowHeightAlt
            headBar.topPadding: Maui.Style.defaultPadding
            headBar.bottomPadding: Maui.Style.defaultPadding
            headBar.middleContent: Label
            {
                text: root.currentViewTitle
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Maui.Controls.showCSD: true

            headBar.leftContent: [
                ToolButton
                {
                    icon.name: sideBarView.sideBar.visible ? "sidebar-collapse" : "sidebar-expand"
                    checked: sideBarView.sideBar.visible
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Toggle sidebar")
                    onClicked: sideBarView.sideBar.toggle()
                },
                ToolSeparator
                {
                    height: Maui.Style.space.medium
                    topPadding: 0
                    bottomPadding: 0
                },
                Maui.ToolActions
                {
                    checkable: false
                    display: ToolButton.IconOnly

                    Action
                    {
                        text: i18n("Previous period")
                        icon.name: "go-previous"
                        onTriggered: root.changeDate(-1)
                    }

                    Action
                    {
                        text: i18n("Next period")
                        icon.name: "go-next"
                        onTriggered: root.changeDate(1)
                    }
                }
            ]

            headBar.rightContent: [
                ToolButton
                {
                    icon.name: "go-jump-today"
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Today")
                    onClicked: root.selectDate(new Date())
                },
                ToolButton
                {
                    icon.name: "list-add"
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("New event")
                    onClicked: root.openNewEvent()
                },
                ToolSeparator
                {
                    height: Maui.Style.space.medium
                    topPadding: 0
                    bottomPadding: 0
                },
                Maui.ToolButtonMenu
                {
                    icon.name: "overflow-menu"

                    MenuItem
                    {
                        text: i18n("About")
                        icon.name: "documentinfo"
                        onTriggered: Maui.App.aboutDialog()
                    }
                }
            ]

            Loader
            {
                id: viewLoader
                anchors.fill: parent
                anchors.leftMargin: Maui.Style.contentMargins
                anchors.rightMargin: Maui.Style.contentMargins
                anchors.bottomMargin: Maui.Style.contentMargins
                sourceComponent: root.currentView === 0 ? yearView : root.currentView === 1 ? monthView : root.currentView === 2 ? weekView : dayView
            }
        }
    }

    Component
    {
        id: yearView

        Item
        {
            id: yearViewRoot
            anchors.fill: parent
            clip: true

            ScrollView
            {
                anchors.fill: parent
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                GridLayout
                {
                    id: yearCards
                    width: parent.width
                    height: Math.max(yearViewRoot.height, implicitHeight)
                    columns: width > Maui.Style.units.gridUnit * 45 ? 4 : width > Maui.Style.units.gridUnit * 30 ? 3 : 2
                    columnSpacing: Maui.Style.space.small
                    rowSpacing: Maui.Style.space.small

                    Repeater
                    {
                        model: 12

                        delegate: Pane
                        {
                            id: monthCard
                            required property int index
                            readonly property int month: index + 1

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: Maui.Style.units.gridUnit * 15
                            padding: Maui.Style.space.small

                            background: Rectangle
                            {
                                color: monthCard.month === root.currentDate.getMonth() + 1 ? Maui.Theme.alternateBackgroundColor : Maui.Theme.backgroundColor
                                radius: Maui.Style.radiusV
                                border.color: Maui.Theme.highlightColor
                                border.width: monthCard.month === root.currentDate.getMonth() + 1 ? 1 : 0
                            }

                            contentItem: ColumnLayout
                            {
                                spacing: Maui.Style.space.small

                                Button
                                {
                                    id: monthButton
                                    Layout.fillWidth: true
                                    flat: true
                                    text: Qt.locale().standaloneMonthName(monthCard.index)
                                    font.weight: Font.DemiBold
                                    background: null
                                    contentItem: Label
                                    {
                                        text: monthButton.text
                                        font: monthButton.font
                                        color: Maui.Theme.textColor
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                    onClicked:
                                    {
                                        root.selectDate(new Date(root.currentDate.getFullYear(), monthCard.index, 1))
                                        root.currentView = 1
                                    }
                                }

                                MauiCalendar.DaysGrid
                                {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    background: null
                                    compact: true
                                    year: root.currentDate.getFullYear()
                                    month: monthCard.month
                                    onDateClicked: root.selectDate(date)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component
    {
        id: monthView

        MauiCalendar.MonthView
        {
            id: monthCalendar
            anchors.fill: parent
            background: null
            selectedDate: root.currentDate
            clip: true

            onDateClicked: root.selectDate(date)
            onDateDoubleClicked:
            {
                root.selectDate(date)
                eventDialog.openNew(date)
            }

            Component.onCompleted: setToDate(root.currentDate)

            Connections
            {
                target: root
                function onCurrentDateChanged()
                {
                    monthCalendar.selectedDate = root.currentDate
                    monthCalendar.setToDate(root.currentDate)
                }
            }
        }
    }

    Component
    {
        id: weekView

        Flickable
        {
            id: weekFlickable
            contentWidth: width
            contentHeight: Math.max(height, weekLayout.implicitHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout
            {
                id: weekLayout
                width: parent.width
                height: Math.max(weekFlickable.height, implicitHeight)
                spacing: Maui.Style.space.medium

                Maui.SectionHeader
                {
                    Layout.fillWidth: true
                    property date firstDay: root.weekStart(root.currentDate)
                    text1: i18n("Week")
                    text2: Qt.formatDate(firstDay, "d MMM") + " – " + Qt.formatDate(new Date(firstDay.getFullYear(), firstDay.getMonth(), firstDay.getDate() + 6), "d MMM yyyy")
                }

                GridLayout
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    columnSpacing: Maui.Style.space.small

                    Repeater
                    {
                        model: 7

                        delegate: Pane
                        {
                            id: weekDay
                            required property int index
                            property date dayDate: new Date(root.weekStart(root.currentDate).getFullYear(), root.weekStart(root.currentDate).getMonth(), root.weekStart(root.currentDate).getDate() + index)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: Maui.Style.units.gridUnit * 12
                            padding: Maui.Style.space.small
                            background: Rectangle
                            {
                                radius: Maui.Style.radiusV
                                color: Maui.Theme.alternateBackgroundColor
                            }

                            MauiCalendar.IncidenceOccurrenceModel
                            {
                                id: dayEvents
                                start: weekDay.dayDate
                                length: 1
                                filter: MauiCalendar.Filter
                            }

                            ColumnLayout
                            {
                                anchors.fill: parent
                                spacing: Maui.Style.space.small

                                Label
                                {
                                    Layout.fillWidth: true
                                    text: Qt.formatDate(weekDay.dayDate, "ddd d")
                                    font.weight: Font.DemiBold
                                }

                                ListView
                                {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: Maui.Style.space.small
                                    model: dayEvents

                                    delegate: Maui.ListDelegate
                                    {
                                        width: ListView.view.width
                                        label: model.summary
                                        iconName: model.allDay ? "view-calendar-day" : "appointment-new"
                                        iconVisible: true
                                        iconSize: Maui.Style.iconSize
                                        onClicked: eventDialog.openExisting(model.incidencePtr)
                                    }
                                }

                                Button
                                {
                                    Layout.fillWidth: true
                                    text: i18n("Add event")
                                    onClicked:
                                    {
                                        root.selectDate(weekDay.dayDate)
                                        eventDialog.openNew(weekDay.dayDate)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component
    {
        id: dayView

        ColumnLayout
        {
            spacing: Maui.Style.space.medium

            MauiCalendar.IncidenceOccurrenceModel
            {
                id: dayEvents
                start: root.currentDate
                length: 1
                filter: MauiCalendar.Filter
            }

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: Qt.formatDate(root.currentDate, "dddd, d MMMM yyyy")
                text2: i18n("Events")
            }

            Maui.ListBrowser
            {
                background: null
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: dayEvents
                holder.visible: count === 0
                holder.emoji: "view-calendar-day"
                holder.title: i18n("No events")
                holder.body: i18n("Create an event for this day to see it here.")

                delegate: Maui.ListBrowserDelegate
                {
                    width: ListView.view.width
                    label1.text: model.summary
                    label2.text: model.allDay ? i18n("All day") : model.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    onClicked: eventDialog.openExisting(model.incidencePtr)
                }
            }
        }
    }
}
