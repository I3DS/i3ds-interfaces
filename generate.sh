#! /bin/dash

if [ -z "$ASN1CC" ]; then
    ASN1CC=$(find $HOME -executable -name asn1.exe -print -quit)
fi

ROOT=$(dirname $0)

ESROCOS_BASE_DIR="$ROOT/esrocos/types-base/asn"
I3DS_BASE_DIR="$ROOT/i3ds/types-base/asn"
I3DS_EXTRA_DIR="$ROOT/i3ds/types-extra/asn"

I3DS_ASN1_FILES="$ESROCOS_BASE_DIR/base.asn \
    $ESROCOS_BASE_DIR/taste-extended.asn \
    $ESROCOS_BASE_DIR/taste-types.asn \
    $ESROCOS_BASE_DIR/userdefs-base.asn \
    $I3DS_BASE_DIR/Analog.asn \
    $I3DS_BASE_DIR/Common.asn \
    $I3DS_BASE_DIR/IMU.asn \
    $I3DS_BASE_DIR/DepthMap.asn \
    $I3DS_BASE_DIR/PointCloud.asn \
    $I3DS_BASE_DIR/Sensor.asn \
    $I3DS_BASE_DIR/Camera.asn \
    $I3DS_BASE_DIR/Frame.asn \
    $I3DS_BASE_DIR/LIDAR.asn \
    $I3DS_BASE_DIR/Radar.asn \
    $I3DS_BASE_DIR/Region.asn \
    $I3DS_BASE_DIR/SampleAttribute.asn \
    $I3DS_BASE_DIR/StarTracker.asn \
    $I3DS_BASE_DIR/ToFCamera.asn \
    $I3DS_EXTRA_DIR/Trigger.asn \
    $I3DS_EXTRA_DIR/Power.asn \
    $I3DS_EXTRA_DIR/Flash.asn"

if [ $(command -v $ASN1CC) ]; then
    $ASN1CC $@ $I3DS_ASN1_FILES
fi
