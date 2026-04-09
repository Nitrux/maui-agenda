#include <QApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QDate>
#include <QIcon>
#include <QQmlContext>

#include <MauiKit4/Core/mauiapp.h>

#include <KAboutData>
#include <KLocalizedString>

#include "../project_version.h"

#define AGENDA_URI "org.kde.agenda"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/logo.png"));

    KLocalizedString::setApplicationDomain("agenda");

    KAboutData about(QStringLiteral("agenda"),
                     i18n("Agenda"),
                     PROJECT_VERSION_STRING,
                     i18n("View and organize your events"),
                     KAboutLicense::LGPL_V3,
                     i18n("© %1 Made by Nitrux | Built with MauiKit", QString::number(QDate::currentDate().year())),
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.setHomepage("https://nxos.org");
    about.setProductName("nitrux/agenda");
    about.setBugAddress("https://invent.kde.org/maui/agenda/-/issues");
    about.setOrganizationDomain(AGENDA_URI);
    about.setDesktopFileName("org.kde.agenda");
    about.setProgramLogo(app.windowIcon());

    KAboutData::setApplicationData(about);
    app.setOrganizationName(QStringLiteral("Maui"));
    MauiApp::instance()->setIconName("qrc:/logo.svg");

    QCommandLineParser parser;

    about.setupCommandLine(&parser);
    parser.process(app);
    about.processCommandLine(&parser);

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    const QUrl url(QStringLiteral("qrc:/app/maui/agenda/controls/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
