#!/bin/bash
set -e

######## Init ########

apt update 
apt install -y gcc-arm-none-eabi

cd /uros_ws

source /opt/ros/$ROS_DISTRO/setup.bash
source install/local_setup.bash

ros2 run micro_ros_setup create_firmware_ws.sh generate_lib

######## Adding extra packages ########
pushd firmware/mcu_ws > /dev/null

    # Workaround: Copy just tf2_msgs
    git clone -b foxy https://github.com/ros2/geometry2
    cp -R geometry2/tf2_msgs ros2/tf2_msgs
    rm -rf geometry2

    # Import user defined packages
    mkdir extra_packages
    pushd extra_packages > /dev/null
        cp -R /project/microros_static_library_ide/library_generation/extra_packages/* .
        vcs import --input extra_packages.repos
    popd > /dev/null

popd > /dev/null

######## Trying to retrieve CFLAGS ########
export RET_CFLAGS=$1
echo "Found CFLAGS:"
echo "-------------"
echo $RET_CFLAGS
echo "-------------"

######## Build  ########
export TOOLCHAIN_PREFIX=/usr/bin/arm-none-eabi-
ros2 run micro_ros_setup build_firmware.sh /project/microros_static_library_ide/library_generation/toolchain.cmake /project/microros_static_library_ide/library_generation/colcon.meta

find firmware/build/include/ -name "*.c"  -delete
rm -rf /project/microros_static_library_ide/libmicroros
mkdir -p /project/microros_static_library_ide/libmicroros/microros_include
cp -R firmware/build/include/* /project/microros_static_library_ide/libmicroros/microros_include/ 
cp -R firmware/build/libmicroros.a /project/microros_static_library_ide/libmicroros/libmicroros.a

######## Generate extra files ########
find firmware/mcu_ws/ros2 \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' > /project/microros_static_library_ide/libmicroros/available_ros2_types
find firmware/mcu_ws/extra_packages \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' >> /project/microros_static_library_ide/libmicroros/available_ros2_types

cd firmware
echo "" > /project/microros_static_library_ide/libmicroros/built_packages
for f in $(find $(pwd) -name .git -type d); do pushd $f > /dev/null; echo $(git config --get remote.origin.url) $(git rev-parse HEAD) >> /project/microros_static_library_ide/libmicroros/built_packages; popd > /dev/null; done;

######## Fix permissions ########
sudo chmod -R 777 /project/microros_static_library_ide/libmicroros/microros_include/ 
sudo chmod -R 777 /project/microros_static_library_ide/libmicroros/libmicroros.a