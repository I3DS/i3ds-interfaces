///////////////////////////////////////////////////////////////////////////\file
///
///   Copyright 2018 SINTEF AS
///
///   This Source Code Form is subject to the terms of the Mozilla
///   Public License, v. 2.0. If a copy of the MPL was not distributed
///   with this file, You can obtain one at https://mozilla.org/MPL/2.0/
///
////////////////////////////////////////////////////////////////////////////////

#ifndef __I3DS_EMULATED_TOF_CAMERA_HPP
#define __I3DS_EMULATED_TOF_CAMERA_HPP

#include "i3ds/core/topic.hpp"
#include "i3ds/core/publisher.hpp"
#include "i3ds/sensors/tof_camera.hpp"
#include "i3ds/emulators/periodic_sampler.hpp"

namespace i3ds
{

class EmulatedToFCamera : public ToFCamera
{
public:

  typedef Topic<128, ToFMeasurement500KCodec> ToFMeasurement;

  EmulatedToFCamera(Context::Ptr context, NodeID id, int resx, int resy);
  virtual ~EmulatedToFCamera();

  // Getters.
  virtual bool region_enabled() const {return region_enabled_;}
  virtual PlanarRegion region() const {return region_;}

  // Supported rate.
  virtual bool is_rate_supported(SampleRate rate);

protected:

  // Actions.
  virtual void do_activate();
  virtual void do_start();
  virtual void do_stop();
  virtual void do_deactivate();

  // Handlers.
  virtual void handle_region(RegionService::Data& command);

private:

  bool send_sample(unsigned long timestamp_us);

  const int resx_;
  const int resy_;

  bool region_enabled_;
  PlanarRegion region_;

  Sampler sampler_;

  Publisher publisher_;
  ToFMeasurement500K frame_;
};

} // namespace i3ds

#endif