#!/bin/bash
set -e

export BASE_PATH=$(pwd)/..
export PROJECT_PATH=../../

######## Check existing library ########
if [[ -f "$BASE_PATH/libmicroros/libmicroros.a" && ! -f "$USER_COLCON_META" ]]; then
    echo "micro-ROS library found. Skipping..."
    echo "Delete libmicroros/ for rebuild."
    exit 0
fi

if [ ! -f "$USER_COLCON_META" ]; then
    rm -rf $BASE_PATH/libmicroros
fi

if [ "$USER_COLCON_META" ]; then
    rm -rf $BASE_PATH/libmicroros
fi

######## Trying to retrieve CFLAGS ########

if [ $(MICROROS_USE_CUBEIDE) ]; then
    export RET_CFLAGS=$(find $PROJECT_PATH -type f -name subdir.mk -exec cat {} \; | python3 $BASE_PATH/library_generation/extract_flags.py)
else
    # Use CubeMX approach
    export RET_CFLAGS=$(cd $PROJECT_PATH && make print_cflags)
fi

if [ $RET_CFLAGS != "" ]; then
    echo "Found CFLAGS:"
    echo "-------------"
    echo $RET_CFLAGS
    echo "-------------"
else
    echo "Error retrieving croscompiler flags"
    exit 1;
fi

echo "Using:"
echo "-------------"
echo $(which arm-none-eabi-gcc)
echo Version: $(arm-none-eabi-gcc -dumpversion)
echo "-------------"

######## Build  ########

if [ ! -f "$BASE_PATH/libmicroros/libmicroros.a" ]; then
    # If library does not exist build it

    ######## Add extra packages  ########
    pushd extra_packages
        # Workaround: Copy just tf2_msgs
        git clone -b ros2 https://github.com/ros2/geometry2
        cp -R geometry2/tf2_msgs tf2_msgs
        rm -rf geometry2

        if [ -f $extra_packages.repos ]; then
        	vcs import --input extra_packages.repos
        fi
    popd > /dev/null


    make -f libmicroros.mk
else
    # If exists just rebuild
    make -f libmicroros.mk rebuild_metas
fi

######## Fix include paths  ########
pushd $BASE_PATH/libmicroros/micro_ros_src > /dev/null
    INCLUDE_ROS2_PACKAGES=$(colcon list | awk '{print $1}' | awk -v d=" " '{s=(NR==1?s:s d)$0}END{print s}')
popd > /dev/null

for var in ${INCLUDE_ROS2_PACKAGES}; do
    if [ -d "$BASE_PATH/libmicroros/include/${var}/${var}" ]; then
        rsync -r $BASE_PATH/libmicroros/include/${var}/${var}/* $BASE_PATH/libmicroros/include/${var}
        rm -rf $BASE_PATH/libmicroros/include/${var}/${var}
    fi
done
