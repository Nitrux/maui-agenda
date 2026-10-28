import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Effects
import QtCore
import QtQuick.Layouts

import org.mauikit.controls 1.0 as Maui
import org.mauikit.calendar 1.0 as MauiCalendar
import org.mauikit.accounts 1.0 as MA
import org.mauikit.filebrowsing 1.0 as FM

Maui.ApplicationWindow
{
    id: root

    color: "transparent"
    background: null

    title: i18n("Agenda")
    property int currentView: 0
    property date currentDate: new Date()
    property bool workWeek: agendaSettings.workWeek
    readonly property string currentViewTitle: {
        if (currentView === 0)
            return Qt.formatDate(currentDate, "yyyy")
        if (currentView === 1)
            return Qt.formatDate(currentDate, "MMMM yyyy")
        if (currentView === 2)
            return i18n("Week of %1", Qt.formatDate(weekStart(currentDate), "dd/MM/yyyy"))
        if (currentView === 4)
            return i18n("Schedule")
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

    Maui.PopupPage
    {
        id: dateDialog
        property date pickedDate: root.currentDate
        title: i18n("Go to date")
        actions: [
            Action { text: i18n("Cancel"); onTriggered: dateDialog.close() },
            Action { text: i18n("Go"); Maui.Controls.status: Maui.Controls.Positive; onTriggered: { root.selectDate(dateDialog.pickedDate); dateDialog.close() } }
        ]

        MauiCalendar.DateComboBox
        {
            Layout.fillWidth: true
            displayText: Qt.formatDate(dateDialog.pickedDate, "dd/MM/yyyy")
            selectedDate: dateDialog.pickedDate
            onDatePicked: function(date) { dateDialog.pickedDate = date }
        }
    }

    Maui.InputDialog
    {
        id: subscriptionDialog
        title: i18n("Subscribe calendar")
        message: i18n("Enter a webcal or HTTPS calendar URL.")
        onFinished: function(url) { MauiCalendar.CalendarManager.subscribeUrl(url) }
    }

    Maui.InputDialog
    {
        id: newCalendarDialog
        title: i18n("New calendar")
        message: i18n("Enter a name for the new calendar.")
        onFinished: function(name) { MauiCalendar.CalendarManager.addCollection(name) }
    }

    Maui.InfoDialog
    {
        id: caldavDialog
        property string oauthMessage: ""
        title: i18n("Sync CalDAV")
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
        title: i18n("CalDAV accounts")
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

                Label
                {
                    Layout.fillWidth: true
                    text: modelData.url
                    elide: Text.ElideMiddle
                }

                ToolButton
                {
                    icon.name: "document-edit"
                    onClicked:
                    {
                        caldavUrlField.text = modelData.url
                        caldavUsernameField.text = modelData.username
                        caldavAuthTypeField.currentIndex = modelData.authType === "bearer" ? 1 : 0
                        caldavTokenUrlField.text = modelData.tokenUrl || ""
                        caldavClientIdField.text = modelData.clientId || ""
                        caldavAuthorizationUrlField.text = modelData.authorizationUrl || ""
                        caldavPasswordField.clear()
                        caldavRefreshTokenField.clear()
                        caldavClientSecretField.clear()
                        caldavAutoSyncCheck.checked = modelData.enabled
                        caldavAccountsDialog.close()
                        caldavDialog.open()
                    }
                }

                ToolButton
                {
                    icon.name: "edit-delete"
                    onClicked: MA.Accounts.removeCalDavAccount(modelData.url)
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }

        Button
        {
            Layout.fillWidth: true
            text: i18n("Add account")
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
        title: i18n("Calendar permissions")
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
            console.log("[Agenda] CalendarManager calendarChanged emitted")
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
        title: i18n("Calendar sync conflict")
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
        property var occurrenceStart: null
        title: editing ? i18n("Edit Event") : i18n("Add Event")
        hint: 1
        maxWidth: Maui.Style.units.gridUnit * 22
        persistent: true
        spacing: Maui.Style.space.big

        onOpened: _eventTitleField.forceActiveFocus()

        function openNew(date)
        {
            editing = false
            eventIncidence.setNewEvent()
            occurrenceStart = null
            eventIncidence.setIncidenceStartDate(date.getDate(), date.getMonth() + 1, date.getFullYear())
            open()
        }

        function openExisting(incidence, occurrence)
        {
            if (!incidence)
                return
            editing = true
            occurrenceStart = occurrence || null
            eventIncidence.incidencePtr = incidence
            eventIncidence.triggerEditMode()
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
            enabled: eventIncidence.summary.trim().length > 0 && eventIncidence.incidenceEnd > eventIncidence.incidenceStart && !MauiCalendar.CalendarManager.isCollectionReadOnly(eventIncidence.collectionId)
            onTriggered:
            {
                console.log("[Agenda] event save triggered", "editing:", eventDialog.editing, "title:", eventIncidence.summary, "collectionId:", eventIncidence.collectionId, "start:", eventIncidence.incidenceStart.toString(), "end:", eventIncidence.incidenceEnd.toString(), "allDay:", eventIncidence.allDay)
                if (eventDialog.editing)
                {
                    if (eventDialog.occurrenceStart !== null)
                        MauiCalendar.CalendarManager.editIncidence(eventIncidence, eventDialog.occurrenceStart)
                    else
                        MauiCalendar.CalendarManager.editIncidence(eventIncidence)
                }
                else
                    MauiCalendar.CalendarManager.addIncidence(eventIncidence)
                console.log("[Agenda] event save request dispatched")
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
            Maui.Controls.subtitle: eventIncidence.summary.trim().length === 0 ? i18n("Event title cannot be empty.") : ""
            Maui.Controls.status: eventIncidence.summary.trim().length === 0 ? Maui.Controls.Negative : Maui.Controls.Normal
            text: eventIncidence.summary
            onTextChanged: eventIncidence.summary = text
            onAccepted: eventIncidence.summary = text
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
                currentIndex: eventIncidence.collectionId
                onActivated: eventIncidence.collectionId = currentValue
            }
        }

        Maui.TextField
        {
            id: _eventLocationField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Location")
            text: eventIncidence.location
            onTextChanged: eventIncidence.location = text
        }

        Maui.TextField
        {
            id: _eventDescriptionField
            Layout.fillWidth: true
            Maui.Controls.title: i18n("Description")
            text: eventIncidence.description
            onTextChanged: eventIncidence.description = text
        }

        Maui.SectionItem
        {
            Layout.fillWidth: true
            flat: true
            leftPadding: 0
            rightPadding: 0
            label1.text: i18n("All day")
            label2.text: i18n("The event lasts the entire day.")
            label2.wrapMode: Text.Wrap

            template.content: Switch
            {
                id: _allDaySwitch
                checked: eventIncidence.allDay
                onToggled:
                {
                    if (!checked)
                        eventIncidence.setIncidenceTimeToNearestQuarterHour()
                    eventIncidence.allDay = checked
                }
            }
        }

        Maui.SectionItem
        {
            id: _durationSection
            Layout.fillWidth: true
            padding: 0
            flat: true
            label1.text: i18n("Duration")
            label2.text: i18n("From")
            label2.wrapMode: Text.Wrap

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


        Maui.SectionItem
        {
            id: _endSection
            Layout.fillWidth: true
            padding: 0
            flat: true
            label2.text: i18n("To")

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


        Maui.SectionItem
        {
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
                visible: _recurrenceEndModeComboBox.currentIndex === 1
                from: 1
                to: 9999
                value: eventIncidence.recurrenceData.duration > 0 ? eventIncidence.recurrenceData.duration : 10
                onValueModified: eventIncidence.setRecurrenceOccurrences(value)
            }

            MauiCalendar.DateComboBox
            {
                id: _recurrenceEndDateComboBox
                Layout.fillWidth: true
                visible: _recurrenceEndModeComboBox.currentIndex === 2
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

                popup.implicitHeight: popup.contentItem ? Math.min(popup.contentItem.contentHeight + popup.topPadding + popup.bottomPadding, root.height * 0.5) : 0

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
                hiddenCollectionIds: agendaSettings.hiddenCollectionIds
                onCollectionVisibilityChanged: function(ids) { agendaSettings.hiddenCollectionIds = ids }
                onCollectionPermissionsRequested: function(collectionId) { permissionsDialog.openForCollection(collectionId) }
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
            id: mainPage
            property Action importCalendarAction: Action
            {
                text: i18n("Import calendar")
                icon.name: "document-import"
                onTriggered: root.openCalendarFile()
            }

            property Action exportCalendarAction: Action
            {
                text: i18n("Export calendar")
                icon.name: "document-export"
                onTriggered: root.saveCalendarFile()
            }

            property Action subscribeCalendarAction: Action
            {
                text: i18n("Subscribe calendar")
                icon.name: "internet-services"
                onTriggered: subscriptionDialog.open()
            }

            property Action newCalendarAction: Action
            {
                text: i18n("New calendar")
                icon.name: "list-add"
                onTriggered: newCalendarDialog.open()
            }

            property Action workWeekAction: Action
            {
                text: i18n("Work week")
                checkable: true
                checked: root.workWeek
                onTriggered: { agendaSettings.workWeek = checked; root.workWeek = checked }
            }

            readonly property list<Action> floatingActions: {
                const actions = [importCalendarAction, exportCalendarAction, subscribeCalendarAction, newCalendarAction]
                if (root.currentView === 2)
                    actions.push(workWeekAction)
                return actions
            }

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
                        text: i18n("Go to date")
                        icon.name: "view-calendar"
                        onTriggered: { dateDialog.pickedDate = root.currentDate; dateDialog.open() }
                    }

                    MenuItem
                    {
                        text: i18n("CalDAV accounts")
                        icon.name: "network-server"
                        onTriggered: caldavAccountsDialog.open()
                    }

                    MenuItem
                    {
                        text: i18n("Sync CalDAV")
                        icon.name: "view-refresh"
                        onTriggered: caldavDialog.open()
                    }

                    MenuItem
                    {
                        text: i18n("Work week")
                        checkable: true
                        checked: root.workWeek
                        onTriggered: { agendaSettings.workWeek = checked; root.workWeek = checked }
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
                sourceComponent: root.currentView === 0 ? yearView : root.currentView === 1 ? monthView : root.currentView === 2 ? weekView : root.currentView === 3 ? dayView : agendaView
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
                                    onDateClicked: function(date) { root.selectDate(date) }
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

            onDateClicked: function(date) { root.selectDate(date) }
            onDateDoubleClicked: function(date)
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
                    text2: Qt.formatDate(firstDay, "d MMM") + " – " + Qt.formatDate(new Date(firstDay.getFullYear(), firstDay.getMonth(), firstDay.getDate() + (root.workWeek ? 4 : 6)), "d MMM yyyy")
                }

                GridLayout
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: root.workWeek ? 5 : 7
                    columnSpacing: Maui.Style.space.small

                    Repeater
                    {
                        model: root.workWeek ? 5 : 7

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
                                        onClicked: eventDialog.openExisting(model.incidencePtr, model.startTime)
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
        id: agendaView

        ColumnLayout
        {
            spacing: Maui.Style.space.medium

            MauiCalendar.IncidenceOccurrenceModel
            {
                id: agendaEvents
                start: root.currentDate
                length: 31
                filter: MauiCalendar.Filter
            }

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: i18n("Schedule")
                text2: i18n("The next 31 days")
            }

            Maui.ListBrowser
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: null
                model: agendaEvents
                holder.visible: count === 0
                holder.emoji: "view-calendar"
                holder.title: i18n("No upcoming events")
                holder.body: i18n("Create an event to see it in your schedule.")

                delegate: Maui.ListBrowserDelegate
                {
                    width: ListView.view.width
                    label1.text: model.summary
                    label2.text: model.allDay ? i18n("All day") : model.startTime.toLocaleString(Qt.locale(), Locale.ShortFormat)
                    onClicked: eventDialog.openExisting(model.incidencePtr, model.startTime)
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
                    onClicked: eventDialog.openExisting(model.incidencePtr, model.startTime)
                }
            }
        }
    }
}
