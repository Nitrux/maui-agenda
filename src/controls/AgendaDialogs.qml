import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar
import org.mauikit.accounts 1.0 as MA
import org.mauikit.filebrowsing 1.0 as FM

Item
{
    id: root

    anchors.fill: parent
    required property date currentDate
    required property int currentView
    required property real availableHeight

    signal selectDateRequested(date date)
    signal selectViewRequested(int view)
    signal refreshTasksRequested()
    signal taskCompletionRequested(var task, bool completed)
    signal taskDeletionRequested(var incidence)
    function openNewEvent(date) { eventDialog.openNew(date) }
    function openNewEventAt(date) { eventDialog.openNewAt(date) }
    function openExistingEvent(incidence, occurrence) { eventDialog.openExisting(incidence, occurrence) }
    function openNewTask(date) { taskDialog.openNew(date) }
    function openExistingTask(incidence) { taskDialog.openExisting(incidence) }
    function openDateDialog() { dateDialog.pickedDate = root.currentDate; dateDialog.open() }
    function openCalendarManagement() { calendarManagementDialog.open() }
    function openAccountsDialog() { caldavAccountsDialog.open() }
    function openSubscriptionDialog() { subscriptionDialog.open() }
    function openNewCalendarDialog() { newCalendarDialog.open() }
    function openPermissions(collectionId) { permissionsDialog.openForCollection(collectionId) }

    function popupAt(menu, anchor, x, y)
    {
        const point = anchor.mapToItem(root, x, y)
        menu.popup(point.x, point.y)
    }

    function showEventContext(incidence, occurrence, recurring, collectionId, anchor, x, y)
    {
        eventContextMenu.incidence = incidence
        eventContextMenu.occurrence = occurrence
        eventContextMenu.recurring = recurring
        eventContextMenu.collectionId = collectionId
        popupAt(eventContextMenu, anchor, x, y)
    }

    function showDateContext(date, anchor, x, y)
    {
        dayContextMenu.date = date
        popupAt(dayContextMenu, anchor, x, y)
    }

    function showTaskContext(task, anchor, x, y)
    {
        taskContextMenu.task = task
        popupAt(taskContextMenu, anchor, x, y)
    }

    function showAccountContext(account, anchor, x, y)
    {
        accountContextMenu.account = account
        popupAt(accountContextMenu, anchor, x, y)
    }

    function requestRemoveAccount(account)
    {
        deleteConfirmation.pendingKind = "account"
        deleteConfirmation.accountUrl = account.url
        deleteConfirmation.open()
    }

    function editCalDavAccount(account)
    {
        caldavUrlField.text = account.url
        caldavUsernameField.text = account.username
        caldavAuthTypeField.currentIndex = account.authType === "bearer" ? 1 : 0
        caldavTokenUrlField.text = account.tokenUrl || ""
        caldavClientIdField.text = account.clientId || ""
        caldavAuthorizationUrlField.text = account.authorizationUrl || ""
        caldavPasswordField.clear()
        caldavRefreshTokenField.clear()
        caldavClientSecretField.clear()
        caldavAutoSyncCheck.checked = account.enabled
        caldavAccountsDialog.close()
        caldavDialog.open()
    }

    Component {
        id: fileDialogComponent
        FM.FileDialog { onClosed: destroy() }
    }

    function localFilePath(value)
    {
        const path = String(value)
        return path.startsWith("file://") ? decodeURIComponent(path.substring(7)) : path
    }

    Component.onCompleted: {
        refreshTasksRequested()
        const commandLineArguments = Qt.application.arguments
        for (let i = 1; i < commandLineArguments.length; ++i) {
            if (String(commandLineArguments[i]).toLowerCase().endsWith(".ics"))
                MauiCalendar.CalendarManager.importFile(root.localFilePath(commandLineArguments[i]))
        }
    }

    function openCalendarFile()
    {
        const dialog = fileDialogComponent.createObject(root, {
            mode: FM.FileDialog.Modes.Open,
            callback: function(urls) {
                if (urls && urls.length > 0)
                    MauiCalendar.CalendarManager.importFile(root.localFilePath(urls[0]))
            }
        })
        dialog.open()
    }

    function saveCalendarFile()
    {
        const dialog = fileDialogComponent.createObject(root, {
            mode: FM.FileDialog.Modes.Save,
            suggestedFileName: "agenda.ics",
            callback: function(urls) {
                if (urls && urls.length > 0)
                    MauiCalendar.CalendarManager.exportFile(root.localFilePath(urls[0]))
            }
        })
        dialog.open()
    }

    Maui.PopupPage
    {
        id: dateDialog
        property date pickedDate: root.currentDate
        title: i18n("Go to Date")
        actions: [
            Action { text: i18n("Cancel"); onTriggered: dateDialog.close() },
            Action { text: i18n("Go"); Maui.Controls.status: Maui.Controls.Positive; onTriggered: { root.selectDateRequested(dateDialog.pickedDate); dateDialog.close() } }
        ]

        MauiCalendar.DateComboBox
        {
            Layout.fillWidth: true
            displayText: Qt.formatDate(dateDialog.pickedDate, "dd/MM/yyyy")
            selectedDate: dateDialog.pickedDate
            onDatePicked: function(date) { dateDialog.pickedDate = date }
        }
    }

    Maui.InfoDialog
    {
        id: calendarManagementDialog
        title: i18n("Manage Calendars")
        standardButtons: Dialog.Close

        ColumnLayout
        {
            Layout.fillWidth: true

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: i18n("Calendars")
                text2: i18n("Create, import, export, or subscribe to calendars.")
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("New calendar")
                icon.name: "list-add"
                onClicked: { calendarManagementDialog.close(); root.openNewCalendarDialog() }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Subscribe to calendar")
                icon.name: "internet-services"
                onClicked: { calendarManagementDialog.close(); root.openSubscriptionDialog() }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Import calendar")
                icon.name: "document-import"
                onClicked: { calendarManagementDialog.close(); root.openCalendarFile() }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Export calendar")
                icon.name: "document-export"
                onClicked: { calendarManagementDialog.close(); root.saveCalendarFile() }
            }

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: i18n("Accounts")
                text2: i18n("Connect to and manage CalDAV accounts.")
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Manage CalDAV accounts")
                icon.name: "network-server"
                onClicked: { calendarManagementDialog.close(); root.openAccountsDialog() }
            }
        }
    }

    Maui.InputDialog
    {
        id: subscriptionDialog
        title: i18n("Subscribe to Calendar")
        message: i18n("Enter a webcal or HTTPS calendar URL.")
        onFinished: function(url) { MauiCalendar.CalendarManager.subscribeUrl(url) }
    }

    Maui.InputDialog
    {
        id: newCalendarDialog
        title: i18n("New Calendar")
        message: i18n("Enter a name for the new calendar.")
        onFinished: function(name) { MauiCalendar.CalendarManager.addCollection(name) }
    }

    Maui.InfoDialog
    {
        id: caldavDialog
        property string oauthMessage: ""
        title: i18n("CalDAV Account")
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted:
        {
            const account = {
                url: caldavUrlField.text,
                username: caldavUsernameField.text,
                password: caldavPasswordField.text,
                authType: caldavAuthTypeField.currentIndex === 1 ? "bearer" : "basic",
                refreshToken: caldavRefreshTokenField.text,
                tokenUrl: caldavTokenUrlField.text,
                clientId: caldavClientIdField.text,
                clientSecret: caldavClientSecretField.text,
                authorizationUrl: caldavAuthorizationUrlField.text,
                enabled: caldavAutoSyncCheck.checked
            }
            if (MA.Accounts.saveCalDavAccount(account)) close()
        }
        onRejected: close()

        Maui.TextField
        {
            id: caldavUrlField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Calendar URL")
            text: ""
        }

        ComboBox
        {
            id: caldavAuthTypeField
            Layout.fillWidth: true
            model: [i18n("Username and password"), i18n("OAuth 2 access token")]
            currentIndex: 0
        }

        Maui.TextField
        {
            id: caldavUsernameField
            visible: caldavAuthTypeField.currentIndex === 0
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Username")
            text: ""
        }

        Maui.PasswordField
        {
            id: caldavPasswordField
            Layout.fillWidth: true
            Maui.Controls.title: caldavAuthTypeField.currentIndex === 1 ? i18n("OAuth 2 access token") : i18n("Password")
        }

        Maui.TextField
        {
            id: caldavAuthorizationUrlField
            visible: caldavAuthTypeField.currentIndex === 1
            Layout.fillWidth: true
            Maui.Controls.title: i18n("OAuth 2 authorization endpoint")
            text: ""
        }

        Maui.TextField
        {
            id: caldavTokenUrlField
            visible: caldavAuthTypeField.currentIndex === 1
            Layout.fillWidth: true
            Maui.Controls.title: i18n("OAuth 2 token endpoint")
            text: ""
        }

        Maui.TextField
        {
            id: caldavClientIdField
            visible: caldavAuthTypeField.currentIndex === 1
            Layout.fillWidth: true
            Maui.Controls.title: i18n("OAuth 2 client ID")
            text: ""
        }

        Maui.PasswordField
        {
            id: caldavRefreshTokenField
            visible: caldavAuthTypeField.currentIndex === 1
            Layout.fillWidth: true
            Maui.Controls.title: i18n("OAuth 2 refresh token")
        }

        Maui.PasswordField
        {
            id: caldavClientSecretField
            visible: caldavAuthTypeField.currentIndex === 1
            Layout.fillWidth: true
            Maui.Controls.title: i18n("OAuth 2 client secret")
        }

        Label
        {
            Layout.fillWidth: true
            visible: caldavDialog.oauthMessage.length > 0
            text: caldavDialog.oauthMessage
            color: Maui.Theme.negativeTextColor
            wrapMode: Text.WordWrap
        }

        Button
        {
            Layout.fillWidth: true
            visible: caldavAuthTypeField.currentIndex === 1
            text: i18n("Authorize with provider")
            onClicked:
            {
                if (MauiCalendar.CalendarManager.startCalDavOAuthAuthorization(caldavUrlField.text, caldavAuthorizationUrlField.text, caldavTokenUrlField.text, caldavClientIdField.text, caldavClientSecretField.text))
                    caldavDialog.oauthMessage = i18n("Authorization started in the web browser.")
                else
                    caldavDialog.oauthMessage = i18n("The OAuth authorization could not be started.")
            }
        }

        CheckBox
        {
            id: caldavAutoSyncCheck
            Layout.fillWidth: true
            text: i18n("Synchronize automatically")
            checked: true
        }
    }

    Maui.InfoDialog
    {
        id: caldavAccountsDialog
        title: i18n("Manage CalDAV Accounts")
        standardButtons: Dialog.Close

        ListView
        {
            id: caldavAccountsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: contentHeight
            model: MA.Accounts.caldavAccounts
            delegate: RowLayout
            {
                required property var modelData
                width: caldavAccountsList.width

                TapHandler
                {
                    acceptedButtons: Qt.RightButton
                    onTapped: function(eventPoint) { root.showAccountContext(modelData, parent, eventPoint.position.x, eventPoint.position.y) }
                }

                Label
                {
                    Layout.fillWidth: true
                    text: modelData.url
                    elide: Text.ElideMiddle
                }

                ToolButton
                {
                    icon.name: "document-edit"
                    onClicked: root.editCalDavAccount(modelData)
                }

                ToolButton
                {
                    icon.name: "edit-delete"
                    onClicked: root.requestRemoveAccount(modelData)
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Button
        {
            Layout.fillWidth: true
            text: i18n("Add CalDAV account")
            onClicked:
            {
                caldavUrlField.clear()
                caldavUsernameField.clear()
                caldavAuthTypeField.currentIndex = 0
                caldavTokenUrlField.clear()
                caldavClientIdField.clear()
                caldavAuthorizationUrlField.clear()
                caldavPasswordField.clear()
                caldavRefreshTokenField.clear()
                caldavClientSecretField.clear()
                caldavAutoSyncCheck.checked = true
                caldavAccountsDialog.close()
                caldavDialog.open()
            }
        }
    }

    Maui.PopupPage
    {
        id: permissionsDialog
        property int collectionId: -1
        property var permissionEntries: []
        property string errorMessage: ""
        title: i18n("Calendar Permissions")
        hint: 1

        function openForCollection(id)
        {
            collectionId = id
            permissionEntries = []
            errorMessage = ""
            MauiCalendar.CalendarManager.loadCalDavPermissions(id)
            open()
        }

        function updateEntry(index, key, value)
        {
            const entries = permissionEntries.slice()
            const entry = Object.assign({}, entries[index])
            entry[key] = value
            entries[index] = entry
            permissionEntries = entries
        }

        function addEntry()
        {
            const entries = permissionEntries.slice()
            entries.push({principal: "", read: true, write: false, denied: []})
            permissionEntries = entries
        }

        actions: [
            Action { text: i18n("Cancel"); onTriggered: permissionsDialog.close() },
            Action
            {
                text: i18n("Save")
                Maui.Controls.status: Maui.Controls.Positive
                onTriggered:
                {
                    if (!MauiCalendar.CalendarManager.saveCalDavPermissions(permissionsDialog.permissionEntries))
                        permissionsDialog.errorMessage = i18n("The permission changes could not be sent to the CalDAV server.")
                }
            }
        ]

        Label
        {
            Layout.fillWidth: true
            visible: permissionsDialog.errorMessage.length > 0
            text: permissionsDialog.errorMessage
            color: Maui.Theme.negativeTextColor
            wrapMode: Text.WordWrap
        }

        ListView
        {
            id: permissionsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: contentHeight
            model: permissionsDialog.permissionEntries
            delegate: RowLayout
            {
                required property var modelData
                required property int index
                width: permissionsList.width

                Maui.TextField
                {
                    Layout.fillWidth: true
                    Maui.Controls.title: i18n("Principal")
                    text: modelData.principal
                    onEditingFinished: permissionsDialog.updateEntry(index, "principal", text)
                }

                CheckBox
                {
                    text: i18n("Read")
                    checked: modelData.read
                    onToggled: permissionsDialog.updateEntry(index, "read", checked)
                }

                CheckBox
                {
                    text: i18n("Write")
                    checked: modelData.write
                    onToggled: permissionsDialog.updateEntry(index, "write", checked)
                }

                ToolButton
                {
                    icon.name: "edit-delete"
                    onClicked:
                    {
                        const entries = permissionsDialog.permissionEntries.slice()
                        entries.splice(index, 1)
                        permissionsDialog.permissionEntries = entries
                    }
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Button
        {
            Layout.fillWidth: true
            text: i18n("Add principal")
            onClicked: permissionsDialog.addEntry()
        }
    }

    Connections
    {
        target: MauiCalendar.CalendarManager
        function onCalendarChanged()
        {
            root.refreshTasksRequested()
        }
        function onCaldavPermissionsChanged()
        {
            if (MauiCalendar.CalendarManager.caldavPermissionsCollectionId === permissionsDialog.collectionId)
                permissionsDialog.permissionEntries = MauiCalendar.CalendarManager.caldavPermissions
        }
        function onCaldavPermissionsError(message)
        {
            if (permissionsDialog.opened) permissionsDialog.errorMessage = message
        }
        function onCaldavPermissionsSaved()
        {
            if (permissionsDialog.opened) permissionsDialog.close()
        }
    }

    Connections
    {
        target: MauiCalendar.CalendarManager
        function onCaldavOAuthAuthorized() { caldavDialog.oauthMessage = i18n("Authorization completed. Save the account to continue.") }
        function onCaldavOAuthError(message) { caldavDialog.oauthMessage = message }
    }

    Maui.PopupPage
    {
        id: syncConflictDialog
        property string conflictUid: ""
        property string conflictMessage: ""
        title: i18n("Calendar Sync Conflict")
        hint: 1
        actions: [
            Action
            {
                text: i18n("Use remote")
                onTriggered: { MauiCalendar.CalendarManager.resolveSyncConflict(syncConflictDialog.conflictUid, false); close() }
            },
            Action
            {
                text: i18n("Keep local")
                Maui.Controls.status: Maui.Controls.Positive
                onTriggered: { MauiCalendar.CalendarManager.resolveSyncConflict(syncConflictDialog.conflictUid, true); close() }
            }
        ]

        Label
        {
            Layout.fillWidth: true
            text: syncConflictDialog.conflictMessage
            wrapMode: Text.WordWrap
        }
    }

    Connections
    {
        target: MauiCalendar.CalendarManager
        function onSyncConflict(uid)
        {
            syncConflictDialog.conflictUid = uid
            syncConflictDialog.conflictMessage = uid.length > 0 ? i18n("The event \"%1\" changed remotely. Choose which copy to keep.", uid) : i18n("The remote calendar changed while this calendar was being synchronized. Choose which copy to keep.")
            syncConflictDialog.open()
        }
    }

    Maui.PopupPage
    {
        id: eventDialog
        property bool editing: false
        property bool allDayChoiceMade: false
        property bool titleTouched: false
        property bool advancedOptionsEnabled: false
        property bool attendeeEntryExpanded: false
        property var occurrenceStart: null
        readonly property var quickReminderValues: [0, 5, 10, 15, 30, 60, 1440]
        readonly property var quickReminderLabels: [i18n("No Reminder"), i18n("5 Minutes Before"), i18n("10 Minutes Before"), i18n("15 Minutes Before"), i18n("30 Minutes Before"), i18n("1 Hour Before"), i18n("1 Day Before"), i18n("Custom")]
        title: editing ? i18n("Edit Event") : i18n("Add Event")
        hint: 1
        maxWidth: Maui.Style.units.gridUnit * (Maui.Handy.isMobile ? 22 : 40)
        persistent: true
        spacing: Maui.Style.space.medium

        onOpened: _eventTitleField.forceActiveFocus()

        function openNew(date)
        {
            editing = false
            allDayChoiceMade = false
            titleTouched = false
            advancedOptionsEnabled = false
            attendeeEntryExpanded = false
            eventIncidence.setNewEvent()
            eventIncidence.eventStatus = 2
            eventIncidence.allDay = false
            _attendeeNameField.text = ""
            _attendeeEmailField.text = ""
            occurrenceStart = null
            eventIncidence.setIncidenceStartDate(date.getDate(), date.getMonth() + 1, date.getFullYear())
            open()
        }

        function openNewAt(date)
        {
            openNew(date)
            eventIncidence.allDay = false
            eventIncidence.setIncidenceStartTime(date.getHours(), date.getMinutes())
        }

        function openExisting(incidence, occurrence)
        {
            if (!incidence)
                return
            editing = true
            occurrenceStart = occurrence || null
            eventIncidence.incidencePtr = incidence
            eventIncidence.triggerEditMode()
            titleTouched = false
            attendeeEntryExpanded = false
            const reminders = eventIncidence.reminders
            const simpleReminderValues = [5, 10, 15, 30, 60, 1440]
            const hasAdvancedReminders = reminders.length > 1 || (reminders.length === 1 && (reminders[0].absolute || simpleReminderValues.indexOf(reminders[0].minutes) < 0))
            advancedOptionsEnabled = eventIncidence.attendees.length > 0 || eventIncidence.eventStatus !== 2 || eventIncidence.recurrenceData.frequency > 0 || hasAdvancedReminders
            _attendeeNameField.text = ""
            _attendeeEmailField.text = ""
            if (occurrenceStart !== null) eventIncidence.setIncidenceStart(occurrenceStart, true)
            open()
        }

        property Action cancelAction: Action
        {
            text: i18n("Cancel")
            onTriggered: eventDialog.close()
        }

        property Action deleteSeriesAction: Action
        {
            text: eventDialog.occurrenceStart !== null ? i18n("Delete series") : i18n("Delete")
            Maui.Controls.status: Maui.Controls.Negative
            enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(eventIncidence.collectionId)
            onTriggered:
            {
                MauiCalendar.CalendarManager.deleteIncidenceSeries(eventIncidence.originalIncidencePtr)
                eventDialog.close()
            }
        }

        property Action deleteOccurrenceAction: Action
        {
            text: i18n("Delete occurrence")
            Maui.Controls.status: Maui.Controls.Negative
            enabled: !MauiCalendar.CalendarManager.isCollectionReadOnly(eventIncidence.collectionId)
            onTriggered:
            {
                MauiCalendar.CalendarManager.deleteIncidenceOccurrence(eventIncidence.originalIncidencePtr, eventDialog.occurrenceStart)
                eventDialog.close()
            }
        }

        property Action saveAction: Action
        {
            text: eventDialog.editing ? i18n("Save") : i18n("Create")
            Maui.Controls.status: Maui.Controls.Positive
            enabled: eventIncidence.summary.trim().length > 0 && (eventIncidence.allDay ? Qt.formatDate(eventIncidence.incidenceEnd, "yyyyMMdd") >= Qt.formatDate(eventIncidence.incidenceStart, "yyyyMMdd") : eventIncidence.incidenceEnd > eventIncidence.incidenceStart) && !MauiCalendar.CalendarManager.isCollectionReadOnly(eventIncidence.collectionId)
            onTriggered:
            {
                if (!eventDialog.editing && !eventDialog.allDayChoiceMade)
                    eventIncidence.allDay = false
                if (eventDialog.editing)
                {
                    if (eventDialog.occurrenceStart !== null)
                        MauiCalendar.CalendarManager.editIncidence(eventIncidence, eventDialog.occurrenceStart)
                    else
                        MauiCalendar.CalendarManager.editIncidence(eventIncidence)
                }
                else
                {
                    MauiCalendar.CalendarManager.addIncidence(eventIncidence)
                    if (root.currentView === 0)
                    {
                        root.selectDateRequested(eventIncidence.incidenceStart)
                        root.selectViewRequested(1)
                    }
                }
                eventDialog.close()
            }
        }

        property list<Action> eventActions: {
            const actions = [cancelAction]
            if (eventDialog.editing)
            {
                actions.push(deleteSeriesAction)
                if (eventDialog.occurrenceStart !== null)
                    actions.push(deleteOccurrenceAction)
            }
            actions.push(saveAction)
            return actions
        }

        actions: eventActions

        MauiCalendar.IncidenceWrapper
        {
            id: eventIncidence
        }

        Maui.TextField
        {
            id: _eventTitleField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Event title")
            Maui.Controls.subtitle: eventDialog.titleTouched && eventIncidence.summary.trim().length === 0 ? i18n("Event title cannot be empty.") : ""
            Maui.Controls.status: eventDialog.titleTouched && eventIncidence.summary.trim().length === 0 ? Maui.Controls.Negative : Maui.Controls.Normal
            text: eventIncidence.summary
            onTextEdited: { eventDialog.titleTouched = true; eventIncidence.summary = text }
            onAccepted: eventIncidence.summary = text
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            flat: true
            leftPadding: 0
            rightPadding: 0
            label1.text: i18n("All day")

            template.content: Switch
            {
                id: _allDaySwitch
                checked: eventIncidence.allDay
                onClicked:
                {
                    eventDialog.allDayChoiceMade = true
                    if (!checked)
                        eventIncidence.setIncidenceTimeToNearestQuarterHour()
                    eventIncidence.allDay = checked
                }
            }
        }


        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Date & Time")

            GridLayout
            {
                Layout.fillWidth: true
                columns: Maui.Handy.isMobile ? 1 : 2
                columnSpacing: Maui.Style.space.medium
                rowSpacing: Maui.Style.space.small

                ColumnLayout
                {
                    Layout.fillWidth: true
                    Label { text: i18n("Start") }
                    MauiCalendar.DateComboBox
                    {
                        id: _startDateComboBox
                        Layout.fillWidth: true
                        displayText: eventIncidence.incidenceStartDateDisplay
                        selectedDate: eventIncidence.incidenceStart
                        onDatePicked: function(date) { eventIncidence.setIncidenceStartDate(date.getDate(), date.getMonth() + 1, date.getFullYear()) }
                    }
                    MauiCalendar.TimeComboBox
                    {
                        id: _startTimeComboBox
                        Layout.fillWidth: true
                        visible: !_allDaySwitch.checked
                        timeZoneOffset: eventIncidence.startTimeZoneUTCOffsetMins
                        displayText: eventIncidence.incidenceStartTimeDisplay
                        selectedTime: eventIncidence.incidenceStart
                        onTimePicked: function(time) { eventIncidence.setIncidenceStartTime(time.getHours(), time.getMinutes()) }
                    }
                }

                ColumnLayout
                {
                    Layout.fillWidth: true
                    Label { text: i18n("End") }
                    MauiCalendar.DateComboBox
                    {
                        id: _endDateComboBox
                        Layout.fillWidth: true
                        displayText: eventIncidence.incidenceEndDateDisplay
                        selectedDate: eventIncidence.incidenceEnd
                        onDatePicked: function(date) { eventIncidence.setIncidenceEndDate(date.getDate(), date.getMonth() + 1, date.getFullYear()) }
                    }
                    MauiCalendar.TimeComboBox
                    {
                        id: _endTimeComboBox
                        Layout.fillWidth: true
                        visible: !_allDaySwitch.checked
                        timeZoneOffset: eventIncidence.endTimeZoneUTCOffsetMins
                        displayText: eventIncidence.incidenceEndTimeDisplay
                        selectedTime: eventIncidence.incidenceEnd
                        onTimePicked: function(time) { eventIncidence.setIncidenceEndTime(time.getHours(), time.getMinutes()) }
                    }
                }
            }
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Calendar")

            ComboBox
            {
                id: _calendarComboBox
                Layout.fillWidth: true
                model: MauiCalendar.CalendarManager.collections
                textRole: "display"
                valueRole: "collectionId"
                currentIndex: _calendarComboBox.indexOfValue(eventIncidence.collectionId)
                onActivated: eventIncidence.collectionId = currentValue
            }
        }

        Maui.TextField
        {
            id: _eventLocationField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Location")
            text: eventIncidence.location
            onTextEdited: eventIncidence.location = text
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            visible: !eventDialog.advancedOptionsEnabled
            label1.text: i18n("Reminder")

            ComboBox
            {
                Layout.fillWidth: true
                model: eventDialog.quickReminderLabels
                currentIndex: {
                    const reminders = eventIncidence.reminders
                    if (reminders.length === 0)
                        return 0
                    if (reminders.length !== 1 || reminders[0].absolute)
                        return eventDialog.quickReminderLabels.length - 1
                    const position = eventDialog.quickReminderValues.indexOf(reminders[0].minutes)
                    return position > 0 ? position : eventDialog.quickReminderLabels.length - 1
                }
                onActivated: function(index)
                {
                    if (index === eventDialog.quickReminderLabels.length - 1)
                        eventDialog.advancedOptionsEnabled = true
                    else
                        eventIncidence.setReminderMinutes(eventDialog.quickReminderValues[index])
                }
            }
        }

        Maui.TextField
        {
            id: _eventDescriptionField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Description")
            text: eventIncidence.description
            onTextEdited: eventIncidence.description = text
        }

        Maui.FlexSectionItem
        {
            Layout.fillWidth: true
            label1.text: i18n("Show advanced options")
            label2.text: i18n("Configure additional event options.")
            label2.wrapMode: Text.Wrap

            template.content: Switch
            {
                checked: eventDialog.advancedOptionsEnabled
                onToggled: eventDialog.advancedOptionsEnabled = checked
            }
        }

        Maui.SectionItem
        {
            visible: eventDialog.advancedOptionsEnabled
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Status")

            ComboBox
            {
                Layout.fillWidth: true
                model: [i18n("None"), i18n("Tentative"), i18n("Confirmed")]
                currentIndex: eventIncidence.eventStatus
                onActivated: eventIncidence.eventStatus = currentIndex
            }
        }

        Maui.SectionItem
        {
            visible: eventDialog.advancedOptionsEnabled
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Attendees")

            Repeater
            {
                model: eventIncidence.attendees

                delegate: RowLayout
                {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        Label { text: modelData.fullName.length > 0 ? modelData.fullName : modelData.name }
                        Label { text: modelData.email; color: Qt.alpha(Maui.Theme.textColor, 0.72) }
                        Label { text: modelData.status; color: Qt.alpha(Maui.Theme.textColor, 0.72) }
                    }

                    ComboBox
                    {
                        model: [i18n("Required"), i18n("Optional"), i18n("Non participant"), i18n("Chairperson")]
                        property var roleKeys: ["required", "optional", "nonparticipant", "chair"]
                        currentIndex: Math.max(0, roleKeys.indexOf(modelData.role))
                        onActivated: function(selection) { eventIncidence.setAttendeeRole(index, roleKeys[selection]) }
                    }

                    ToolButton
                    {
                        icon.name: "edit-delete"
                        onClicked: eventIncidence.removeAttendee(index)
                    }
                }
            }

            Maui.TextField
            {
                id: _attendeeNameField
                Layout.fillWidth: true
                visible: eventDialog.attendeeEntryExpanded
                Maui.Controls.title: i18n("Name")
            }

            Maui.TextField
            {
                id: _attendeeEmailField
                Layout.fillWidth: true
                visible: eventDialog.attendeeEntryExpanded
                Maui.Controls.title: i18n("Email")
                inputMethodHints: Qt.ImhEmailCharactersOnly
            }

            RowLayout
            {
                Layout.fillWidth: true

                Button
                {
                    Layout.fillWidth: true
                    visible: eventDialog.attendeeEntryExpanded
                    text: i18n("Add Guest")
                    enabled: _attendeeEmailField.text.trim().length > 0
                    onClicked:
                    {
                        eventIncidence.addAttendee(_attendeeNameField.text, _attendeeEmailField.text)
                        _attendeeNameField.text = ""
                        _attendeeEmailField.text = ""
                    }
                }

                Button
                {
                    Layout.fillWidth: true
                    visible: eventDialog.attendeeEntryExpanded
                    text: i18n("Cancel")
                    onClicked:
                    {
                        eventDialog.attendeeEntryExpanded = false
                        _attendeeNameField.text = ""
                        _attendeeEmailField.text = ""
                    }
                }

                Button
                {
                    Layout.fillWidth: true
                    visible: !eventDialog.attendeeEntryExpanded
                    text: i18n("Add Guests")
                    onClicked:
                    {
                        eventDialog.attendeeEntryExpanded = true
                        _attendeeNameField.forceActiveFocus()
                    }
                }
            }
        }

        Maui.SectionItem
        {
            visible: eventDialog.advancedOptionsEnabled
            id: _recurrenceSection
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Repeat")

            ComboBox
            {
                id: _recurrenceComboBox
                Layout.fillWidth: true
                currentIndex: {
                    const data = eventIncidence.recurrenceData
                    if (!data || data.frequency <= 0) return 0
                    return data.type >= 1 && data.type <= 4 ? data.type : 0
                }
                model: [i18n("Does not repeat"), i18n("Daily"), i18n("Weekly"), i18n("Monthly"), i18n("Yearly")]
                onActivated: function(index)
                {
                    if (index === 0)
                        eventIncidence.clearRecurrences()
                    else
                        eventIncidence.setRegularRecurrence(index - 1, 1)
                }
            }

            Flow
            {
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex === 2
                spacing: Maui.Style.space.small

                Repeater
                {
                    model: [i18n("Mon"), i18n("Tue"), i18n("Wed"), i18n("Thu"), i18n("Fri"), i18n("Sat"), i18n("Sun")]
                    delegate: CheckBox
                    {
                        required property string modelData
                        required property int index
                        text: modelData
                        checked: eventIncidence.recurrenceData.weekdays[index] === true
                        onToggled:
                        {
                            const weekdays = []
                            for (let day = 0; day < 7; ++day) weekdays.push(day === index ? checked : eventIncidence.recurrenceData.weekdays[day] === true)
                            eventIncidence.setRecurrenceDataItem("weekdays", weekdays)
                        }
                    }
                }
            }

            ComboBox
            {
                id: _monthlyRuleComboBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex === 3
                model: [i18n("Day of month"), i18n("Weekday position")]
            }

            SpinBox
            {
                id: _monthlyDaySpinBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex === 3 && _monthlyRuleComboBox.currentIndex === 0
                from: 1
                to: 31
                value: eventIncidence.incidenceStart.getDate()
                onValueModified: eventIncidence.setRecurrenceDataItem("monthDays", [value])
            }

            ComboBox
            {
                id: _monthlyWeekdayComboBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex === 3 && _monthlyRuleComboBox.currentIndex === 1
                model: [i18n("Monday"), i18n("Tuesday"), i18n("Wednesday"), i18n("Thursday"), i18n("Friday"), i18n("Saturday"), i18n("Sunday")]
            }

            SpinBox
            {
                id: _monthlyPositionSpinBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex === 3 && _monthlyRuleComboBox.currentIndex === 1
                from: -5
                to: 5
                value: 1
                onValueModified: { if (value === 0) value = 1; eventIncidence.setMonthlyPositionRecurrence(value, _monthlyWeekdayComboBox.currentIndex) }
            }

            Maui.TextField
            {
                id: _recurrenceIntervalField
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex > 0
                Maui.Controls.title: i18n("Repeat every")
                text: eventIncidence.recurrenceData.frequency > 0 ? String(eventIncidence.recurrenceData.frequency) : "1"
                inputMethodHints: Qt.ImhDigitsOnly
                onTextEdited: {
                    const frequency = Number(text)
                    if (Number.isInteger(frequency) && frequency > 0)
                        eventIncidence.setRecurrenceDataItem("frequency", frequency)
                }
            }

            ComboBox
            {
                id: _recurrenceEndModeComboBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex > 0
                currentIndex: {
                    const data = eventIncidence.recurrenceData
                    if (data && data.duration > 0) return 1
                    if (data && data.duration === 0) return 2
                    return 0
                }
                model: [i18n("Never"), i18n("After occurrences"), i18n("On date")]
                onActivated: function(index)
                {
                    if (index === 0)
                        eventIncidence.clearRecurrenceEnd()
                    else if (index === 1)
                        eventIncidence.setRecurrenceOccurrences(_recurrenceCountSpinBox.value)
                    else
                        eventIncidence.setRecurrenceEndDate(_recurrenceEndDateComboBox.selectedDate)
                }
            }

            SpinBox
            {
                id: _recurrenceCountSpinBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex > 0 && _recurrenceEndModeComboBox.currentIndex === 1
                from: 1
                to: 9999
                value: eventIncidence.recurrenceData.duration > 0 ? eventIncidence.recurrenceData.duration : 10
                onValueModified: eventIncidence.setRecurrenceOccurrences(value)
            }

            MauiCalendar.DateComboBox
            {
                id: _recurrenceEndDateComboBox
                Layout.fillWidth: true
                visible: _recurrenceComboBox.currentIndex > 0 && _recurrenceEndModeComboBox.currentIndex === 2
                displayText: Qt.formatDate(selectedDate, "dd/MM/yyyy")
                selectedDate: eventIncidence.recurrenceData.endDateTime
                onDatePicked: function(date) { eventIncidence.setRecurrenceEndDate(date) }
            }

            MauiCalendar.RecurrenceExceptionsModel
            {
                id: _recurrenceExceptionsModel
                incidencePtr: eventIncidence.incidencePtr
            }

            ListView
            {
                id: _recurrenceExceptionsList
                Layout.fillWidth: true
                implicitHeight: contentHeight
                visible: count > 0
                model: _recurrenceExceptionsModel
                delegate: RowLayout
                {
                    required property var date
                    width: _recurrenceExceptionsList.width

                    Label
                    {
                        Layout.fillWidth: true
                        text: Qt.formatDate(date, "dd/MM/yyyy")
                    }

                    ToolButton
                    {
                        icon.name: "edit-delete"
                        onClicked: _recurrenceExceptionsModel.deleteExceptionDateTime(date)
                    }
                }
            }

            Button
            {
                Layout.fillWidth: true
                visible: eventIncidence.recurrenceData.frequency > 0
                text: i18n("Exclude start date")
                onClicked: _recurrenceExceptionsModel.addExceptionDateTime(eventIncidence.incidenceStart)
            }
        }

        Maui.SectionItem
        {
            visible: eventDialog.advancedOptionsEnabled
            id: _reminderSection
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Reminders")

            Repeater
            {
                model: eventIncidence.reminders

                delegate: ColumnLayout
                {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true

                    RowLayout
                    {
                        Layout.fillWidth: true

                        ComboBox
                        {
                            Layout.fillWidth: true
                            model: [i18n("Before event"), i18n("At a specific time")]
                            currentIndex: modelData.absolute ? 1 : 0
                            onActivated: function(selection)
                            {
                                if (selection === 0)
                                    eventIncidence.setReminderMinutesAt(index, modelData.minutes > 0 ? modelData.minutes : 10)
                                else
                                    eventIncidence.setReminderTimeAt(index, modelData.time && modelData.time.getTime() > 0 ? modelData.time : eventIncidence.incidenceStart)
                            }
                        }

                        ComboBox
                        {
                            Layout.fillWidth: true
                            visible: !modelData.absolute
                            model: [i18n("5 minutes before"), i18n("10 minutes before"), i18n("15 minutes before"), i18n("30 minutes before"), i18n("1 hour before"), i18n("1 day before")]
                            property var reminderMinutes: [5, 10, 15, 30, 60, 1440]
                            currentIndex: {
                                const position = reminderMinutes.indexOf(modelData.minutes)
                                return position >= 0 ? position : 1
                            }
                            onActivated: function(selection) { eventIncidence.setReminderMinutesAt(index, reminderMinutes[selection]) }
                        }

                        ToolButton
                        {
                            icon.name: "edit-delete"
                            onClicked: eventIncidence.removeReminderAt(index)
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        visible: modelData.absolute

                        MauiCalendar.DateComboBox
                        {
                            Layout.fillWidth: true
                            displayText: modelData.time && modelData.time.getTime() > 0 ? Qt.formatDate(modelData.time, "dd/MM/yyyy") : ""
                            selectedDate: modelData.time
                            onDatePicked: function(date)
                            {
                                const current = modelData.time && modelData.time.getTime() > 0 ? modelData.time : eventIncidence.incidenceStart
                                eventIncidence.setReminderTimeAt(index, new Date(date.getFullYear(), date.getMonth(), date.getDate(), current.getHours(), current.getMinutes()))
                            }
                        }

                        MauiCalendar.TimeComboBox
                        {
                            Layout.fillWidth: true
                            visible: !_allDaySwitch.checked
                            timeZoneOffset: eventIncidence.startTimeZoneUTCOffsetMins
                            displayText: modelData.time && modelData.time.getTime() > 0 ? Qt.formatTime(modelData.time, "HH:mm") : ""
                            selectedTime: modelData.time
                            onTimePicked: function(time)
                            {
                                const current = modelData.time && modelData.time.getTime() > 0 ? modelData.time : eventIncidence.incidenceStart
                                eventIncidence.setReminderTimeAt(index, new Date(current.getFullYear(), current.getMonth(), current.getDate(), time.getHours(), time.getMinutes()))
                            }
                        }
                    }
                }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Add reminder")
                onClicked: eventIncidence.addReminderMinutes(10)
            }
        }

        Maui.SectionItem
        {
            visible: eventDialog.advancedOptionsEnabled
            id: _timeZoneSection
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Time zone")

            ComboBox
            {
                id: _timeZoneComboBox
                Layout.fillWidth: true
                popupScrollBar: true
                model: MauiCalendar.TimeZoneListModel
                {
                    id: _timeZonesModel
                }

                textRole: "display"
                valueRole: "id"
                displayText: String(eventIncidence.timeZone) === "Floating" ? i18n("Auto") : String(eventIncidence.timeZone).replace("_", " ")
                onActivated: function(index)
                {
                    if (currentValue !== undefined && currentValue !== null && String(currentValue).length > 0)
                        eventIncidence.timeZone = currentValue
                }

                popup.implicitHeight: popup.contentItem ? Math.min(popup.contentItem.contentHeight + popup.topPadding + popup.bottomPadding, root.availableHeight * 0.5) : 0

            }
        }
    }

    Maui.PopupPage
    {
        id: taskDialog
        property bool editing: false
        title: editing ? i18n("Edit Task") : i18n("New Task")
        hint: 1
        maxWidth: Maui.Style.units.gridUnit * 22
        persistent: true
        spacing: Maui.Style.space.medium

        function openNew(date)
        {
            editing = false
            taskIncidence.setNewTodo()
            taskIncidence.allDay = true
            const selected = new Date(date.getFullYear(), date.getMonth(), date.getDate())
            taskIncidence.incidenceStart = selected
            taskIncidence.incidenceEnd = selected
            taskIncidence.collectionId = 0
            open()
        }

        function openExisting(incidence)
        {
            if (!incidence) return
            editing = true
            taskIncidence.incidencePtr = incidence
            taskIncidence.triggerEditMode()
            open()
        }

        property Action cancelAction: Action
        {
            text: i18n("Cancel")
            onTriggered: taskDialog.close()
        }

        property Action saveAction: Action
        {
            text: taskDialog.editing ? i18n("Save") : i18n("Create task")
            Maui.Controls.status: Maui.Controls.Positive
            enabled: {
                const start = taskIncidence.incidenceStart
                const end = taskIncidence.incidenceEnd
                const hasStart = start && start.getTime() >= 0
                const hasEnd = end && end.getTime() >= 0
                const validRange = !hasStart || !hasEnd || (taskIncidence.allDay ? start.toDateString() === end.toDateString() : end >= start)
                return taskIncidence.summary.trim().length > 0 && validRange && !MauiCalendar.CalendarManager.isCollectionReadOnly(taskIncidence.collectionId)
            }
            onTriggered:
            {
                if (taskDialog.editing)
                    MauiCalendar.CalendarManager.editIncidence(taskIncidence)
                else
                    MauiCalendar.CalendarManager.addIncidence(taskIncidence)
                taskDialog.close()
            }
        }

        actions: [cancelAction, saveAction]

        MauiCalendar.IncidenceWrapper
        {
            id: taskIncidence
        }

        Maui.TextField
        {
            id: taskTitleField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Task title")
            text: taskIncidence.summary
            onTextEdited: taskIncidence.summary = text
            onAccepted: taskIncidence.summary = text
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Calendar")

            ComboBox
            {
                id: taskCalendarComboBox
                Layout.fillWidth: true
                model: MauiCalendar.CalendarManager.collections
                textRole: "display"
                valueRole: "collectionId"
                currentIndex: taskCalendarComboBox.indexOfValue(taskIncidence.collectionId)
                onActivated: taskIncidence.collectionId = currentValue
            }
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Start date")

            RowLayout
            {
                MauiCalendar.DateComboBox
                {
                    Layout.fillWidth: true
                    displayText: taskIncidence.incidenceStartDateDisplay
                    selectedDate: taskIncidence.incidenceStart
                    onDatePicked: function(date) { taskIncidence.setIncidenceStartDate(date.getDate(), date.getMonth() + 1, date.getFullYear()) }
                }

                ToolButton
                {
                    icon.name: "edit-clear-all"
                    ToolTip.text: i18n("Clear start date")
                    onClicked: {
                        const due = taskIncidence.incidenceEnd
                        taskIncidence.incidenceStart = new Date(NaN)
                        if (due && due.getTime() >= 0) taskIncidence.incidenceEnd = due
                    }
                }
            }
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Due date")

            RowLayout
            {
                MauiCalendar.DateComboBox
                {
                    Layout.fillWidth: true
                    displayText: taskIncidence.incidenceEndDateDisplay
                    selectedDate: taskIncidence.incidenceEnd
                    onDatePicked: function(date) { taskIncidence.setIncidenceEndDate(date.getDate(), date.getMonth() + 1, date.getFullYear()) }
                }

                ToolButton
                {
                    icon.name: "edit-clear-all"
                    ToolTip.text: i18n("Clear due date")
                    onClicked: taskIncidence.incidenceEnd = new Date(NaN)
                }
            }
        }

        CheckBox
        {
            text: i18n("All day")
            enabled: !taskIncidence.todoCompleted && ((taskIncidence.incidenceStart && taskIncidence.incidenceStart.getTime() >= 0) || (taskIncidence.incidenceEnd && taskIncidence.incidenceEnd.getTime() >= 0))
            checked: taskIncidence.allDay
            onToggled: taskIncidence.allDay = checked
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Start time")
            enabled: taskIncidence.incidenceStart && taskIncidence.incidenceStart.getTime() >= 0 && !taskIncidence.allDay

            MauiCalendar.TimeComboBox
            {
                Layout.fillWidth: true
                timeZoneOffset: taskIncidence.startTimeZoneUTCOffsetMins
                selectedTime: taskIncidence.incidenceStart
                onTimePicked: function(time) { taskIncidence.setIncidenceStartTime(time.getHours(), time.getMinutes()) }
            }
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Due time")
            enabled: taskIncidence.incidenceEnd && taskIncidence.incidenceEnd.getTime() >= 0 && !taskIncidence.allDay

            MauiCalendar.TimeComboBox
            {
                Layout.fillWidth: true
                timeZoneOffset: taskIncidence.endTimeZoneUTCOffsetMins
                selectedTime: taskIncidence.incidenceEnd
                onTimePicked: function(time) { taskIncidence.setIncidenceEndTime(time.getHours(), time.getMinutes()) }
            }
        }

        Label
        {
            Layout.fillWidth: true
            visible: taskIncidence.incidenceStart && taskIncidence.incidenceStart.getTime() >= 0 && taskIncidence.incidenceEnd && taskIncidence.incidenceEnd.getTime() >= 0 && (taskIncidence.allDay ? taskIncidence.incidenceStart.toDateString() !== taskIncidence.incidenceEnd.toDateString() : taskIncidence.incidenceEnd < taskIncidence.incidenceStart)
            text: taskIncidence.allDay ? i18n("For an all-day task, the start and due dates must match.") : i18n("The due date and time must not be earlier than the start.")
            color: Maui.Theme.negativeTextColor
            wrapMode: Text.WordWrap
        }

        Maui.TextField
        {
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Location")
            text: taskIncidence.location
            onTextEdited: taskIncidence.location = text
        }

        Maui.TextField
        {
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Notes")
            text: taskIncidence.description
            onTextEdited: taskIncidence.description = text
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Reminders")
            enabled: taskIncidence.incidenceStart && taskIncidence.incidenceStart.getTime() >= 0 && !taskIncidence.todoCompleted

            Repeater
            {
                model: taskIncidence.reminders

                delegate: ColumnLayout
                {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true

                    RowLayout
                    {
                        Layout.fillWidth: true

                        ComboBox
                        {
                            Layout.fillWidth: true
                            model: [i18n("Before task"), i18n("At a specific time")]
                            currentIndex: modelData.absolute ? 1 : 0
                            onActivated: function(selection)
                            {
                                if (selection === 0)
                                    taskIncidence.setReminderMinutesAt(index, modelData.minutes > 0 ? modelData.minutes : 10)
                                else
                                    taskIncidence.setReminderTimeAt(index, modelData.time && modelData.time.getTime() > 0 ? modelData.time : taskIncidence.incidenceStart)
                            }
                        }

                        ComboBox
                        {
                            Layout.fillWidth: true
                            visible: !modelData.absolute
                            model: [i18n("5 minutes before"), i18n("10 minutes before"), i18n("15 minutes before"), i18n("30 minutes before"), i18n("1 hour before"), i18n("1 day before")]
                            property var reminderMinutes: [5, 10, 15, 30, 60, 1440]
                            currentIndex: {
                                const position = reminderMinutes.indexOf(modelData.minutes)
                                return position >= 0 ? position : 1
                            }
                            onActivated: function(selection) { taskIncidence.setReminderMinutesAt(index, reminderMinutes[selection]) }
                        }

                        ToolButton
                        {
                            icon.name: "edit-delete"
                            onClicked: taskIncidence.removeReminderAt(index)
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        visible: modelData.absolute

                        MauiCalendar.DateComboBox
                        {
                            Layout.fillWidth: true
                            displayText: modelData.time && modelData.time.getTime() > 0 ? Qt.formatDate(modelData.time, "dd/MM/yyyy") : ""
                            selectedDate: modelData.time
                            onDatePicked: function(date)
                            {
                                const current = modelData.time && modelData.time.getTime() > 0 ? modelData.time : taskIncidence.incidenceStart
                                taskIncidence.setReminderTimeAt(index, new Date(date.getFullYear(), date.getMonth(), date.getDate(), current.getHours(), current.getMinutes()))
                            }
                        }

                        MauiCalendar.TimeComboBox
                        {
                            Layout.fillWidth: true
                            timeZoneOffset: taskIncidence.startTimeZoneUTCOffsetMins
                            visible: !taskIncidence.allDay
                            displayText: modelData.time && modelData.time.getTime() > 0 ? Qt.formatTime(modelData.time, "HH:mm") : ""
                            selectedTime: modelData.time
                            onTimePicked: function(time)
                            {
                                const current = modelData.time && modelData.time.getTime() > 0 ? modelData.time : taskIncidence.incidenceStart
                                taskIncidence.setReminderTimeAt(index, new Date(current.getFullYear(), current.getMonth(), current.getDate(), time.getHours(), time.getMinutes()))
                            }
                        }
                    }
                }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Add reminder")
                onClicked: taskIncidence.addReminderMinutes(10)
            }
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Priority")

            SpinBox
            {
                Layout.fillWidth: true
                from: 0
                to: 9
                value: taskIncidence.priority
                onValueModified: taskIncidence.priority = value
            }
        }

        CheckBox
        {
            visible: taskDialog.editing
            text: i18n("Completed")
            checked: taskIncidence.todoCompleted
            onToggled: taskIncidence.todoCompleted = checked
        }
    }


    Maui.ContextualMenu
    {
        id: eventContextMenu
        property var incidence: null
        property var occurrence: null
        property bool recurring: false
        property int collectionId: -1
        title: incidence ? incidence.summary : ""

        MenuItem
        {
            text: i18n("Open event")
            icon.name: "document-edit"
            onTriggered: root.openExistingEvent(eventContextMenu.incidence, eventContextMenu.occurrence)
        }

        MenuSeparator {}

        MenuItem
        {
            visible: !eventContextMenu.recurring
            text: i18n("Delete event…")
            icon.name: "edit-delete"
            enabled: eventContextMenu.incidence && !MauiCalendar.CalendarManager.isCollectionReadOnly(eventContextMenu.collectionId)
            onTriggered:
            {
                deleteConfirmation.pendingKind = "event"
                deleteConfirmation.incidence = eventContextMenu.incidence
                deleteConfirmation.occurrence = eventContextMenu.occurrence
                deleteConfirmation.open()
            }
        }

        MenuItem
        {
            visible: eventContextMenu.recurring
            text: i18n("Delete this occurrence…")
            icon.name: "edit-delete"
            enabled: eventContextMenu.incidence && !MauiCalendar.CalendarManager.isCollectionReadOnly(eventContextMenu.collectionId)
            onTriggered:
            {
                deleteConfirmation.pendingKind = "occurrence"
                deleteConfirmation.incidence = eventContextMenu.incidence
                deleteConfirmation.occurrence = eventContextMenu.occurrence
                deleteConfirmation.open()
            }
        }

        MenuItem
        {
            visible: eventContextMenu.recurring
            text: i18n("Delete series…")
            icon.name: "edit-delete"
            enabled: eventContextMenu.incidence && !MauiCalendar.CalendarManager.isCollectionReadOnly(eventContextMenu.collectionId)
            onTriggered:
            {
                deleteConfirmation.pendingKind = "series"
                deleteConfirmation.incidence = eventContextMenu.incidence
                deleteConfirmation.occurrence = eventContextMenu.occurrence
                deleteConfirmation.open()
            }
        }
    }

    Maui.ContextualMenu
    {
        id: dayContextMenu
        property date date: new Date()
        title: Qt.formatDate(date, "dddd, MMMM d, yyyy")

        MenuItem
        {
            text: i18n("New event")
            icon.name: "list-add"
            onTriggered: root.openNewEvent(dayContextMenu.date)
        }

        MenuItem
        {
            text: i18n("New task")
            icon.name: "view-task"
            onTriggered: root.openNewTask(dayContextMenu.date)
        }
    }

    Maui.ContextualMenu
    {
        id: taskContextMenu
        property var task: null
        title: taskContextMenu.task ? taskContextMenu.task.summary : ""

        MenuItem
        {
            text: i18n("Open task")
            icon.name: "document-edit"
            onTriggered: root.openExistingTask(taskContextMenu.task.incidencePtr)
        }

        MenuItem
        {
            text: taskContextMenu.task && taskContextMenu.task.completed ? i18n("Mark incomplete") : i18n("Mark complete")
            icon.name: taskContextMenu.task && taskContextMenu.task.completed ? "edit-undo" : "task-complete"
            enabled: taskContextMenu.task && !MauiCalendar.CalendarManager.isCollectionReadOnly(taskContextMenu.task.collectionId)
            onTriggered: root.taskCompletionRequested(taskContextMenu.task, !taskContextMenu.task.completed)
        }

        MenuSeparator {}

        MenuItem
        {
            text: i18n("Delete task…")
            icon.name: "edit-delete"
            enabled: taskContextMenu.task && !MauiCalendar.CalendarManager.isCollectionReadOnly(taskContextMenu.task.collectionId)
            onTriggered:
            {
                deleteConfirmation.pendingKind = "task"
                deleteConfirmation.incidence = taskContextMenu.task.incidencePtr
                deleteConfirmation.open()
            }
        }
    }

    Maui.ContextualMenu
    {
        id: accountContextMenu
        property var account: null
        title: account ? account.url : ""

        MenuItem
        {
            text: i18n("Edit account")
            icon.name: "document-edit"
            onTriggered: root.editCalDavAccount(accountContextMenu.account)
        }

        MenuItem
        {
            text: i18n("Remove account…")
            icon.name: "edit-delete"
            onTriggered:
            {
                root.requestRemoveAccount(accountContextMenu.account)
            }
        }
    }

    Maui.InfoDialog
    {
        id: deleteConfirmation
        property string pendingKind: ""
        property var incidence: null
        property var occurrence: null
        property string accountUrl: ""
        title: pendingKind === "task" ? i18n("Delete Task") : pendingKind === "account" ? i18n("Remove Account") : i18n("Delete Event")
        message: pendingKind === "account" ? i18n("Remove this CalDAV account?") : i18n("This action cannot be undone.")
        standardButtons: Dialog.Yes | Dialog.Cancel

        onAccepted:
        {
            if (pendingKind === "task")
                root.taskDeletionRequested(incidence)
            else if (pendingKind === "account")
                MA.Accounts.removeCalDavAccount(accountUrl)
            else if (pendingKind === "series")
                MauiCalendar.CalendarManager.deleteIncidenceSeries(incidence)
            else if (pendingKind === "occurrence")
                MauiCalendar.CalendarManager.deleteIncidenceOccurrence(incidence, occurrence)
            else if (pendingKind === "event")
                MauiCalendar.CalendarManager.deleteIncidence(incidence)
            pendingKind = ""
            incidence = null
            occurrence = null
            accountUrl = ""
        }
    }


}
