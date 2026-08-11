#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "DBController.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon("iconset/icon4.ico"));

    QQmlApplicationEngine engine;

    DBController dbController;
    engine.rootContext()->setContextProperty("dbController", &dbController);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("flowui", "Main");

    return QGuiApplication::exec();
}
