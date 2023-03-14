COMPONENT_DIR = $(shell pwd)
INSTALL_DIR = $(COMPONENT_DIR)/../libmicroros

DEBUG ?= 0

ifeq ($(DEBUG), 1)
	BUILD_TYPE = Debug
else
	BUILD_TYPE = Release
endif

ifeq ($(MICROROS_USE_EMBEDDEDRTPS), "ON")
META_FILE = $(COMPONENT_DIR)/colcon-embeddedrtps.meta
else
META_FILE = $(COMPONENT_DIR)/colcon.meta
endif

X_CC := arm-none-eabi-gcc
X_CXX := arm-none-eabi-g++
X_AR := arm-none-eabi-ar
X_STRIP := arm-none-eabi-strip
CFLAGS_INTERNAL := $(RET_CFLAGS) -w -DCLOCK_MONOTONIC=0 -D'__attribute__(x)='
CXXFLAGS_INTERNAL := $(RET_CFLAGS) -w -DCLOCK_MONOTONIC=0 -D'__attribute__(x)='

all: $(INSTALL_DIR)/libmicroros.a

clean:
	rm -rf $(INSTALL_DIR)

$(INSTALL_DIR)/toolchain.cmake: $(COMPONENT_DIR)/toolchain.cmake.in
	rm -f $(INSTALL_DIR)/toolchain.cmake; \
	mkdir -p $(INSTALL_DIR); \
	cat $(COMPONENT_DIR)/toolchain.cmake.in | \
		sed "s/@CMAKE_C_COMPILER@/$(subst /,\/,$(X_CC))/g" | \
		sed "s/@CMAKE_CXX_COMPILER@/$(subst /,\/,$(X_CXX))/g" | \
		sed "s/@CFLAGS@/$(subst /,\/,$(CFLAGS_INTERNAL))/g" | \
		sed "s/@CXXFLAGS@/$(subst /,\/,$(CXXFLAGS_INTERNAL))/g" \
		> $(INSTALL_DIR)/toolchain.cmake

$(INSTALL_DIR)/micro_ros_dev/install:
	rm -rf $(INSTALL_DIR)/micro_ros_dev; \
	mkdir $(INSTALL_DIR)/micro_ros_dev; cd $(INSTALL_DIR)/micro_ros_dev; \
	git clone -b humble https://github.com/ament/ament_cmake src/ament_cmake; \
	git clone -b humble https://github.com/ament/ament_lint src/ament_lint; \
	git clone -b humble https://github.com/ament/ament_package src/ament_package; \
	git clone -b humble https://github.com/ament/googletest src/googletest; \
	git clone -b humble https://github.com/ros2/ament_cmake_ros src/ament_cmake_ros; \
	git clone -b humble https://github.com/ament/ament_index src/ament_index; \
	colcon build --cmake-args -DBUILD_TESTING=OFF;

# TODO(acuadros95): Add EmbeddedRTPS conditional
$(INSTALL_DIR)/micro_ros_src/src:
	rm -rf $(INSTALL_DIR)/micro_ros_src; \
	mkdir $(INSTALL_DIR)/micro_ros_src; cd $(INSTALL_DIR)/micro_ros_src; \
	if [ "$(MICROROS_USE_EMBEDDEDRTPS)" = "ON" ]; then \
		git clone -b humble https://github.com/micro-ROS/embeddedRTPS src/embeddedRTPS; \
		git clone -b humble https://github.com/micro-ROS/rmw_embeddedrtps src/rmw_embeddedrtps; \
	else \
		git clone -b ros2 https://github.com/eProsima/Micro-XRCE-DDS-Client src/Micro-XRCE-DDS-Client; \
		git clone -b humble https://github.com/micro-ROS/rmw_microxrcedds src/rmw_microxrcedds; \
	fi; \
	git clone -b ros2 https://github.com/eProsima/micro-CDR src/micro-CDR; \
	git clone -b humble https://github.com/micro-ROS/rcl src/rcl; \
	git clone -b humble https://github.com/ros2/rclc src/rclc; \
	git clone -b humble https://github.com/micro-ROS/rcutils src/rcutils; \
	git clone -b humble https://github.com/micro-ROS/micro_ros_msgs src/micro_ros_msgs; \
	git clone -b humble https://github.com/micro-ROS/rosidl_typesupport src/rosidl_typesupport; \
	git clone -b humble https://github.com/micro-ROS/rosidl_typesupport_microxrcedds src/rosidl_typesupport_microxrcedds; \
	git clone -b humble https://github.com/ros2/rosidl src/rosidl; \
	git clone -b humble https://github.com/ros2/rmw src/rmw; \
	git clone -b humble https://github.com/ros2/rcl_interfaces src/rcl_interfaces; \
	git clone -b humble https://github.com/ros2/rosidl_defaults src/rosidl_defaults; \
	git clone -b humble https://github.com/ros2/unique_identifier_msgs src/unique_identifier_msgs; \
	git clone -b humble https://github.com/ros2/common_interfaces src/common_interfaces; \
	git clone -b humble https://github.com/ros2/test_interface_files src/test_interface_files; \
	git clone -b humble https://github.com/ros2/rmw_implementation src/rmw_implementation; \
	git clone -b humble https://github.com/ros2/rcl_logging src/rcl_logging; \
	git clone -b humble https://gitlab.com/micro-ROS/ros_tracing/ros2_tracing src/ros2_tracing; \
	git clone -b humble https://github.com/micro-ROS/micro_ros_utilities src/micro_ros_utilities; \
	git clone -b humble https://github.com/ros2/example_interfaces src/example_interfaces; \
    touch src/rosidl/rosidl_typesupport_introspection_cpp/COLCON_IGNORE; \
    touch src/rcl_logging/rcl_logging_log4cxx/COLCON_IGNORE; \
    touch src/rcl_logging/rcl_logging_spdlog/COLCON_IGNORE; \
    touch src/rclc/rclc_examples/COLCON_IGNORE; \
	touch src/rcl/rcl_yaml_param_parser/COLCON_IGNORE; \
	cp -rf $(COMPONENT_DIR)/extra_packages src/extra_packages || :;

$(INSTALL_DIR)/micro_ros_src/install: $(INSTALL_DIR)/toolchain.cmake $(INSTALL_DIR)/micro_ros_dev/install $(INSTALL_DIR)/micro_ros_src/src
	cd $(INSTALL_DIR)/micro_ros_src; \
	unset AMENT_PREFIX_PATH; \
	unset RMW_IMPLEMENTATION; \
	PATH=$(subst /opt/ros/$(ROS_DISTRO)/bin,,$(PATH)); \
	. ../micro_ros_dev/install/local_setup.sh; \
	colcon build \
		--merge-install \
		--packages-ignore-regex=.*_cpp \
		--metas $(META_FILE) $(COMPONENT_DIR)/../../app_colcon.meta $(USER_COLCON_META) \
		--cmake-force-configure \
		--cmake-clean-cache \
		--cmake-args \
		"--no-warn-unused-cli" \
		--log-level=ERROR \
		-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=OFF \
		-DTHIRDPARTY=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=$(INSTALL_DIR)/toolchain.cmake \
		-DCMAKE_VERBOSE_MAKEFILE=OFF;

$(INSTALL_DIR)/libmicroros.a: $(INSTALL_DIR)/micro_ros_src/install
	mkdir -p $(INSTALL_DIR)/micro_ros_src/aux; cd $(INSTALL_DIR)/micro_ros_src/aux; \
	for file in $$(find $(INSTALL_DIR)/micro_ros_src/install/lib/ -name '*.a'); do \
		folder=$$(echo $$file | sed -E "s/(.+)\/(.+).a/\2/"); \
		mkdir -p $$folder; cd $$folder; $(AR) x $$file; \
		for f in *; do \
			mv $$f ../$$folder-$$f; \
		done; \
		cd ..; rm -rf $$folder; \
	done ; \
	$(AR) rc -s libmicroros.a *.obj; cp libmicroros.a $(INSTALL_DIR); \
	cd ..; rm -rf aux; \
	cp -R $(INSTALL_DIR)/micro_ros_src/install/include $(INSTALL_DIR)/include;

rebuild_metas:
	export META_PACKAGES=$$(python3 $(COMPONENT_DIR)/get_metas_packages.py $(USER_COLCON_META)); \
	cd $(INSTALL_DIR)/micro_ros_src; \
	unset AMENT_PREFIX_PATH; \
	PATH=$(subst /opt/ros/$(ROS_DISTRO)/bin,,$(PATH)); \
	. ../micro_ros_dev/install/local_setup.sh; \
	colcon build \
		--merge-install \
		--packages-ignore-regex=.*_cpp \
		--packages-select $$META_PACKAGES \
		--metas $(COMPONENT_DIR)/colcon.meta $(COMPONENT_DIR)/../../app_colcon.meta $(USER_COLCON_META) \
		--cmake-force-configure \
		--cmake-clean-cache \
		--cmake-args \
		"--no-warn-unused-cli" \
		--log-level=ERROR \
		-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=OFF \
		-DTHIRDPARTY=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=$(INSTALL_DIR)/toolchain.cmake \
		-DCMAKE_VERBOSE_MAKEFILE=OFF;\
	mkdir -p $(INSTALL_DIR)/micro_ros_src/aux; cd $(INSTALL_DIR)/micro_ros_src/aux; \
	for file in $$(find $(INSTALL_DIR)/micro_ros_src/install/lib/ -name '*.a'); do \
		folder=$$(echo $$file | sed -E "s/(.+)\/(.+).a/\2/"); \
		mkdir -p $$folder; cd $$folder; $(AR) x $$file; \
		for f in *; do \
			mv $$f ../$$folder-$$f; \
		done; \
		cd ..; rm -rf $$folder; \
	done ; \
	$(AR) rc -s libmicroros.a *.obj; cp libmicroros.a $(INSTALL_DIR); \
	cd ..; rm -rf aux; \
	rm -rf $(INSTALL_DIR)/include; \
	cp -R $(INSTALL_DIR)/micro_ros_src/install/include $(INSTALL_DIR)/include;
