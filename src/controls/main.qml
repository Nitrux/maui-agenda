import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Effects
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
    property bool workWeek: agendaSettings.workWeek
    property bool searchActive: false
    property string searchQuery: ""
    property var taskItems: []
    readonly property string currentViewTitle: {
        if (currentView === 0)
            return Qt.formatDate(currentDate, "yyyy")
        if (currentView === 1)
            return Qt.formatDate(currentDate, "dddd, MMMM d, yyyy")
        if (currentView === 2)
            return Qt.formatDate(currentDate, "MMMM yyyy")
        if (currentView === 3)
        {
            const start = weekStart(currentDate)
            const end = new Date(start)
            end.setDate(end.getDate() + 6)
            return i18n("Week of %1 to %2", Qt.formatDate(start, "MMMM d"), Qt.formatDate(end, "MMMM d, yyyy"))
        }
        if (currentView === 4)
            return i18n("Agenda")
        if (currentView === 5)
            return i18n("Tasks")
        return Qt.formatDate(currentDate, "dd/MM/yyyy")
    }
    readonly property alias appSettings: agendaSettings

    Settings
    {
        id: agendaSettings
        category: "Agenda"
        property bool sidebarVisible: true
        property bool workWeek: false
        property string hiddenCollectionIds: ""
    }

    function selectDate(date)
    {
        root.currentDate = date
    }

    function refreshTaskItems()
    {
        const hiddenCollections = MauiCalendar.Filter.collectionIds
        root.taskItems = MauiCalendar.CalendarManager.todos().filter(task => !hiddenCollections.includes(String(task.collectionId)))
    }

    function setTaskCompleted(task, completed)
    {
        const wrapper = Qt.createQmlObject("import org.mauikit.calendar 1.0; IncidenceWrapper {}", root, "taskCompletion")
        wrapper.incidencePtr = task.incidencePtr
        wrapper.triggerEditMode()
        wrapper.todoCompleted = completed
        MauiCalendar.CalendarManager.editIncidence(wrapper)
        wrapper.destroy()
    }

    function changeDate(amount)
    {
        if (root.currentView === 5)
            return

        const next = new Date(root.currentDate)
        if (root.currentView === 0)
            next.setFullYear(next.getFullYear() + amount)
        else if (root.currentView === 2)
            next.setMonth(next.getMonth() + amount)
        else if (root.currentView === 3)
            next.setDate(next.getDate() + (amount * 7))
        else if (root.currentView === 4)
            next.setDate(next.getDate() + (amount * 31))
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
        agendaDialogs.openNewEvent(root.currentDate)
    }

    function openNewTask()
    {
        agendaDialogs.openNewTask(root.currentDate)
    }

    onCurrentViewChanged: if (currentView === 5) refreshTaskItems()

    Connections
    {
        target: MauiCalendar.Filter
        function onCollectionIdsChanged()
        {
            agendaSettings.hiddenCollectionIds = MauiCalendar.Filter.collectionIds.join(",")
            root.refreshTaskItems()
        }
    }

    AgendaDialogs
    {
        id: agendaDialogs
        currentDate: root.currentDate
        currentView: root.currentView
        availableHeight: root.height
        onSelectDateRequested: function(date) { root.selectDate(date) }
        onSelectViewRequested: function(view) { root.currentView = view }
        onRefreshTasksRequested: root.refreshTaskItems()
        onTaskCompletionRequested: function(task, completed) { root.setTaskCompleted(task, completed) }
        onTaskDeletionRequested: function(incidence) { MauiCalendar.CalendarManager.deleteIncidence(incidence); root.refreshTaskItems() }
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
                hiddenCollectionIds: agendaSettings.hiddenCollectionIds
                onCollectionVisibilityChanged: function(ids) { agendaSettings.hiddenCollectionIds = ids }
                onCollectionPermissionsRequested: function(collectionId) { agendaDialogs.openPermissions(collectionId) }
                onViewSelected: (view) => { root.searchActive = false; root.currentView = view }
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
            id: mainPage
            property Action createEventAction: Action
            {
                text: i18n("New Event")
                icon.name: "list-add"
                onTriggered: root.openNewEvent()
            }

            property Action createTaskAction: Action
            {
                text: i18n("New Task")
                icon.name: "view-task"
                onTriggered: root.openNewTask()
            }

            property Action goToDateAction: Action
            {
                text: i18n("Go to Date")
                icon.name: "view-calendar"
                onTriggered: agendaDialogs.openDateDialog()
            }

            property Action synchronizeCalendarsAction: Action
            {
                text: i18n("Synchronize Calendars")
                icon.name: "view-refresh"
                onTriggered: MauiCalendar.CalendarManager.syncAllCalDavAccounts()
            }

            readonly property list<Action> floatingActions: root.currentView === 5 ? [createTaskAction, goToDateAction, synchronizeCalendarsAction] : [createEventAction, goToDateAction, synchronizeCalendarsAction]

            focus: true
            Keys.enabled: true
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Left) {
                    root.changeDate(-1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.changeDate(1)
                    event.accepted = true
                } else if (event.key === Qt.Key_T) {
                    root.selectDate(new Date())
                    event.accepted = true
                }
            }

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
            headBar.middleContent: Loader
            {
                active: root.searchActive
                visible: active
                Layout.fillWidth: true
                sourceComponent: searchBarComponent
                onLoaded: item.forceActiveFocus()
            }
            headBar.preferredHeight: Maui.Style.rowHeightAlt
            headBar.topPadding: Maui.Style.defaultPadding
            headBar.bottomPadding: Maui.Style.defaultPadding
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
                    visible: root.currentView !== 5
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
                    visible: root.currentView !== 5
                    icon.name: "go-jump-today"
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Today")
                    onClicked: root.selectDate(new Date())
                },
                ToolButton
                {
                    icon.name: "edit-find"
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    checkable: true
                    checked: root.searchActive
                    ToolTip.text: root.searchActive ? i18n("Close search") : i18n("Search")
                    onClicked:
                    {
                        if (!root.searchActive)
                            root.searchQuery = ""
                        root.searchActive = !root.searchActive
                    }
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
                        text: i18n("Show Work Week")
                        checkable: true
                        checked: root.workWeek
                        onTriggered: agendaSettings.workWeek = !agendaSettings.workWeek
                    }

                    MenuItem
                    {
                        text: i18n("Manage Calendars")
                        icon.name: "view-calendar"
                        onTriggered: agendaDialogs.openCalendarManagement()
                    }

                    MenuSeparator {}

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
                sourceComponent: root.searchActive ? searchView : root.currentView === 0 ? yearView : root.currentView === 1 ? dayView : root.currentView === 2 ? monthView : root.currentView === 3 ? weekView : root.currentView === 4 ? agendaView : tasksView
            }

            Pane
            {
                id: floatingActionsBar
                z: 1
                x: parent.width - width - Maui.Style.space.big
                y: parent.height - height - Maui.Style.space.big
                Maui.Theme.colorSet: Maui.Theme.Complementary
                Maui.Theme.inherit: false

                background: Rectangle
                {
                    radius: Maui.Style.radiusV
                    color: Maui.Theme.alternateBackgroundColor
                    border.color: Maui.Theme.alternateBackgroundColor
                    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                    layer.effect: MultiEffect
                    {
                        autoPaddingEnabled: true
                        shadowEnabled: true
                        shadowColor: "#000000"
                    }
                }

                ScaleAnimator on scale
                {
                    from: 0
                    to: 1
                    duration: Maui.Style.units.longDuration
                    running: visible
                    easing.type: Easing.OutInQuad
                }

                OpacityAnimator on opacity
                {
                    from: 0
                    to: 1
                    duration: Maui.Style.units.longDuration
                    running: visible
                }

                contentItem: Row
                {
                    spacing: Maui.Style.defaultSpacing

                    Item
                    {
                        id: floatingActionsDragHandle
                        width: Maui.Style.space.big
                        height: floatingActionsGrid.implicitHeight

                        Row
                        {
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater
                            {
                                model: 2

                                Column
                                {
                                    spacing: 3

                                    Repeater
                                    {
                                        model: 4

                                        Rectangle
                                        {
                                            width: 2
                                            height: width
                                            radius: width / 2
                                            color: Maui.Theme.textColor
                                            opacity: floatingActionsDragHandler.active ? 0.9 : 0.55
                                        }
                                    }
                                }
                            }
                        }

                        DragHandler
                        {
                            id: floatingActionsDragHandler
                            target: floatingActionsBar
                            xAxis.maximum: floatingActionsBar.parent.width - floatingActionsBar.width
                            xAxis.minimum: 0
                            yAxis.enabled: false

                            onActiveChanged:
                            {
                                if (!active)
                                {
                                    const position = centroid.velocity.x
                                    floatingActionsBar.x = Qt.binding(() => position < 0 ? Maui.Style.space.big : floatingActionsBar.parent.width - floatingActionsBar.width - Maui.Style.space.big)
                                    floatingActionsBar.y = Qt.binding(() => floatingActionsBar.parent.height - floatingActionsBar.height - Maui.Style.space.big)
                                }
                            }
                        }

                        HoverHandler
                        {
                            cursorShape: floatingActionsDragHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        }
                    }

                    Grid
                    {
                        id: floatingActionsGrid
                        rows: 2
                        columns: Math.max(1, Math.ceil(mainPage.floatingActions.length / rows))
                        spacing: Maui.Style.space.tiny

                        Repeater
                        {
                            model: mainPage.floatingActions

                            ToolButton
                            {
                                id: floatingActionButton
                                required property var modelData
                                readonly property bool destructive: modelData && modelData.Maui.Controls.status === Maui.Controls.Negative
                                Maui.Theme.colorSet: Maui.Theme.Complementary
                                Maui.Controls.status: modelData && modelData.Maui.Controls.status ? modelData.Maui.Controls.status : Maui.Controls.Normal
                                action: modelData
                                display: ToolButton.IconOnly
                                flat: false
                                ToolTip.delay: 1000
                                ToolTip.timeout: 5000
                                ToolTip.visible: hovered
                                ToolTip.text: modelData.text
                                icon.color: destructive ? "#fafafa" : floatingActionButton.color

                                background: Rectangle
                                {
                                    radius: Maui.Style.radiusV
                                    color: floatingActionButton.destructive
                                        ? (floatingActionButton.pressed || floatingActionButton.down || floatingActionButton.checked
                                           ? Qt.darker(Maui.Theme.negativeBackgroundColor, 1.12)
                                           : (floatingActionButton.hovered
                                              ? Qt.lighter(Maui.Theme.negativeBackgroundColor, 1.05)
                                              : Maui.Theme.negativeBackgroundColor))
                                        : (floatingActionButton.pressed || floatingActionButton.down || floatingActionButton.checked
                                           ? floatingActionButton.Maui.Theme.highlightColor
                                           : (floatingActionButton.highlighted || floatingActionButton.hovered
                                              ? floatingActionButton.Maui.Theme.hoverColor
                                              : floatingActionButton.Maui.Theme.backgroundColor))

                                    function statusBorderColor()
                                    {
                                        switch(floatingActionButton.Maui.Controls.status)
                                        {
                                        case Maui.Controls.Positive:
                                            return floatingActionButton.Maui.Theme.positiveBackgroundColor
                                        case Maui.Controls.Negative:
                                            return floatingActionButton.Maui.Theme.negativeBackgroundColor
                                        case Maui.Controls.Neutral:
                                            return floatingActionButton.Maui.Theme.neutralBackgroundColor
                                        case Maui.Controls.Normal:
                                        default:
                                            return "transparent"
                                        }
                                    }

                                    border.color: floatingActionButton.destructive
                                        ? "transparent"
                                        : (floatingActionButton.Maui.Controls.status ? statusBorderColor() : "transparent")
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
        id: yearView
        YearView
        {
            currentDate: root.currentDate
            viewTitle: root.currentViewTitle
            onDateSelected: function(date) { root.selectDate(date) }
            onMonthSelected: function(date) { root.selectDate(date); root.currentView = 2 }
            onDateContextRequested: function(date, anchor, x, y) { agendaDialogs.showDateContext(date, anchor, x, y) }
        }
    }

    Component
    {
        id: monthView
        MonthView
        {
            selectedDate: root.currentDate
            viewTitle: root.currentViewTitle
            onDateClicked: function(date) { root.selectDate(date) }
            onDateDoubleClicked: function(date) { root.selectDate(date); agendaDialogs.openNewEvent(date) }
            onIncidenceClicked: function(incidence, occurrence) { agendaDialogs.openEventDetails(incidence, occurrence) }
            onEventContextRequested: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { agendaDialogs.showEventContext(incidence, occurrence, recurring, collectionId, anchor, x, y) }
            onDateContextRequested: function(date, anchor, x, y) { agendaDialogs.showDateContext(date, anchor, x, y) }
        }
    }

    Component
    {
        id: weekView
        WeekView
        {
            selectedDate: root.currentDate
            viewTitle: root.currentViewTitle
            workWeek: root.workWeek
            onDateSelected: function(date) { root.selectDate(date) }
            onIncidenceActivated: function(incidence, occurrence) { agendaDialogs.openEventDetails(incidence, occurrence) }
            onTimeSlotActivated: function(date) { root.selectDate(date); agendaDialogs.openNewEventAt(date) }
            onDateActivated: function(date) { root.selectDate(date); agendaDialogs.openNewEvent(date) }
            onEventContextRequested: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { agendaDialogs.showEventContext(incidence, occurrence, recurring, collectionId, anchor, x, y) }
            onDateContextRequested: function(date, anchor, x, y) { agendaDialogs.showDateContext(date, anchor, x, y) }
        }
    }

    Component
    {
        id: agendaView
        AgendaView
        {
            currentDate: root.currentDate
            onIncidenceActivated: function(incidence, occurrence) { agendaDialogs.openEventDetails(incidence, occurrence) }
            onEventContextRequested: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { agendaDialogs.showEventContext(incidence, occurrence, recurring, collectionId, anchor, x, y) }
            onDateContextRequested: function(date, anchor, x, y) { agendaDialogs.showDateContext(date, anchor, x, y) }
        }
    }

    Component
    {
        id: dayView
        DayView
        {
            selectedDate: root.currentDate
            viewTitle: root.currentViewTitle
            onIncidenceActivated: function(incidence, occurrence) { agendaDialogs.openEventDetails(incidence, occurrence) }
            onTimeSlotActivated: function(date) { root.selectDate(date); agendaDialogs.openNewEventAt(date) }
            onDateActivated: function(date) { root.selectDate(date); agendaDialogs.openNewEvent(date) }
            onEventContextRequested: function(incidence, occurrence, recurring, collectionId, anchor, x, y) { agendaDialogs.showEventContext(incidence, occurrence, recurring, collectionId, anchor, x, y) }
            onDateContextRequested: function(date, anchor, x, y) { agendaDialogs.showDateContext(date, anchor, x, y) }
        }
    }

    Component
    {
        id: tasksView
        TasksView
        {
            taskItems: root.taskItems
            onTaskActivated: function(incidence) { agendaDialogs.openExistingTask(incidence) }
            onCompletionRequested: function(task, completed) { root.setTaskCompleted(task, completed) }
            onDeletionRequested: function(incidence) { MauiCalendar.CalendarManager.deleteIncidence(incidence); root.refreshTaskItems() }
            onTaskContextRequested: function(task, anchor, x, y) { agendaDialogs.showTaskContext(task, anchor, x, y) }
        }
    }

    Component
    {
        id: searchView
        SearchView
        {
            query: root.searchQuery
            onIncidenceActivated: function(incidence, occurrence, isTask, hasDate)
            {
                root.searchActive = false
                root.searchQuery = ""
                if (isTask)
                    agendaDialogs.openExistingTask(incidence)
                else
                {
                    if (hasDate)
                        root.selectDate(occurrence)
                    agendaDialogs.openEventDetails(incidence, occurrence)
                }
            }
        }
    }

    Component
    {
        id: searchBarComponent
        Maui.SearchField
        {
            placeholderText: i18n("Search events and tasks")
            text: root.searchQuery
            onTextChanged: root.searchQuery = text
        }
    }

}
