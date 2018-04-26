///////////////////////////////////////////////////////////////////////////\file
///
///   Copyright 2018 SINTEF AS
///
///   This Source Code Form is subject to the terms of the Mozilla
///   Public License, v. 2.0. If a copy of the MPL was not distributed
///   with this file, You can obtain one at https://mozilla.org/MPL/2.0/
///
////////////////////////////////////////////////////////////////////////////////

#ifndef __I3DS_IMU_HPP
#define __I3DS_IMU_HPP

#include "../core/IMU.h"

#include "i3ds/sensors/sensor.hpp"
#include "i3ds/core/service.hpp"
#include "i3ds/core/codec.hpp"

namespace i3ds
{

CODEC(IMUMeasurement);

class IMU : public Sensor
{
public:

  // Constructor and destructor.
  IMU(NodeID node) : Sensor(node) {};
  virtual ~IMU() {};

};

} // namespace i3ds

#endif
