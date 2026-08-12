#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDir>
#include <QFile>
#include "DBController.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QString iconPath = QCoreApplication::applicationDirPath() + "/icontoon/icontoon.ico";
    if (QFile::exists(iconPath)) {
        app.setWindowIcon(QIcon(iconPath));
    } else if (QFile::exists("icontoon/icontoon.ico")) {
        app.setWindowIcon(QIcon("icontoon/icontoon.ico"));
    } else if (QFile::exists("../icontoon/icontoon.ico")) {
        app.setWindowIcon(QIcon("../icontoon/icontoon.ico"));
    }

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
