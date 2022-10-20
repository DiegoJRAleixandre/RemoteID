#pragma once

#include <QObject>

#include "QGCLoggingCategory.h"
#include "QGCMAVLink.h"
#include "Vehicle.h"

Q_DECLARE_LOGGING_CATEGORY(RemoteIDManagerLog)

// Supporting Opend Dron ID protocol
class RemoteIDManager : public QObject
{
    Q_OBJECT

public:
    RemoteIDManager(Vehicle* vehicle);

    void    mavlinkMessageReceived  (mavlink_message_t& message);

private:
    void _handleBasicID (mavlink_message_t& message);

    bool _uasIDInitialized; 
    bool _uasIDReceived;
};