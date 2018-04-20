///////////////////////////////////////////////////////////////////////////\file
///
///   Copyright 2018 SINTEF AS
///
///   This Source Code Form is subject to the terms of the Mozilla
///   Public License, v. 2.0. If a copy of the MPL was not distributed
///   with this file, You can obtain one at https://mozilla.org/MPL/2.0/
///
////////////////////////////////////////////////////////////////////////////////

#include <iostream>

#include "i3ds/emulators/emulated_tof_camera.hpp"

i3ds::EmulatedToFCamera::EmulatedToFCamera(Context::Ptr context, NodeID node, int resx, int resy)
  : ToFCamera(node),
    resx_(resx),
    resy_(resy),
    sampler_(std::bind(&i3ds::EmulatedToFCamera::send_sample, this, std::placeholders::_1)),
    publisher_(context, node)
{
  region_.size_x = resx;
  region_.size_y = resy;
  region_.offset_x = 0;
  region_.offset_y = 0;

  ToFMeasurement500KCodec::Initialize(frame_);

  frame_.region.size_x = resx_;
  frame_.region.size_y = resy_;
}

i3ds::EmulatedToFCamera::~EmulatedToFCamera()
{
}

void
i3ds::EmulatedToFCamera::do_activate()
{
}

void
i3ds::EmulatedToFCamera::do_start()
{
  sampler_.Start(rate());
}

void
i3ds::EmulatedToFCamera::do_stop()
{
  sampler_.Stop();
}

void
i3ds::EmulatedToFCamera::do_deactivate()
{
}

bool
i3ds::EmulatedToFCamera::is_rate_supported(SampleRate rate)
{
  return 0 < rate && rate <= 10000000;
}

void
i3ds::EmulatedToFCamera::handle_region(RegionService::Data& command)
{
  region_enabled_ = command.request.enable;

  if (command.request.enable)
    {
      region_ = command.request.region;
    }
}

bool
i3ds::EmulatedToFCamera::send_sample(unsigned long timestamp_us)
{
  std::cout << "Send: " << timestamp_us << std::endl;

  frame_.attributes.timestamp.microseconds = timestamp_us;
  frame_.attributes.validity = sample_valid;

  publisher_.Send<ToFMeasurement>(frame_);

  return true;
}