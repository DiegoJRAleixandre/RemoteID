#pragma once

#include "SettingsGroup.h"

class RemoteIDSettings : public SettingsGroup
{
    Q_OBJECT
public:
    RemoteIDSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(enable)
};