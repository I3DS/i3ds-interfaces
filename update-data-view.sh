#! /bin/dash

ROOT=$(pwd)

ESROCOS="$ROOT/esrocos/types-base/asn"
I3DS="$ROOT/i3ds/types-base/asn"
SENSORS="$ROOT/i3ds/types-sensors/asn"

export FILES="$ESROCOS/Eigen.asn \
$ESROCOS/Point.asn \
$ESROCOS/taste-extended.asn \
$ESROCOS/taste-types.asn \
$ESROCOS/Temperature.asn \
$I3DS/Common.asn \
$I3DS/Analog.asn \
$I3DS/DepthMap.asn \
$I3DS/IMU.asn \
$I3DS/PointCloud.asn \
$I3DS/Sensor.asn \
$I3DS/Camera.asn \
$I3DS/Frame.asn \
$I3DS/LIDAR.asn \
$I3DS/Radar.asn \
$I3DS/Region.asn \
$I3DS/SampleAttribute.asn \
$I3DS/StarTracker.asn \
$I3DS/ToFCamera.asn"

taste-update-data-view $FILES
