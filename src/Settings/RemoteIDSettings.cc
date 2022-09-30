#include "RemoteIDSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(RemoteID, "RemoteID")
{
    qmlRegisterUncreatableType<RemoteIDSettings>("QGroundControl.SettingsManager", 1, 0, "RemoteIDSettings", "Reference only"); \
}

DECLARE_SETTINGSFACT(RemoteIDSettings, enable)