FROM ros:foxy 

RUN mkdir -p uros_ws
WORKDIR uros_ws
RUN git clone https://github.com/micro-ROS/micro-ros-build.git src/micro-ros-build \
    &&  . /opt/ros/$ROS_DISTRO/setup.sh \
    &&  apt update \
    &&  apt install -y python3-pip wget\
    &&  apt install -y python3-pip clang-format pyflakes3 python3-mypy python3-pytest-mock gperf ros-foxy-osrf-testing-tools-cpp python3-lttng ros-foxy-mimick-vendor ros-foxy-rmw-cyclonedds-cpp python3-babeltrace \
    &&  apt install -y gcc-arm-none-eabi \
    &&  rosdep update \
    &&  rosdep install --from-paths src --ignore-src -y \
    &&  colcon build \
    &&  . install/local_setup.sh \
    &&  rm -rf log/ build/ src/* \
    &&  rm -rf /var/lib/apt/lists/* 

COPY ./library_generation.sh /library_generation.sh

ENTRYPOINT ["/library_generation.sh"]