# micro-ROS for STM32CubeMX

This tool aims to ease the micro-ROS integration in a STM32CubeMX project.

## How to use it

1. In the `root` folder, generate your STM32CubeMX project. A sample project can be generated with the provided `sample_project.ioc`.
2. Modify the generated `Makefile` to include the following code before the `build the application` section:

```makefile
#######################################
# micro-ROS addons
#######################################
LDFLAGS += microros_component/libmicroros.a
C_INCLUDES += -Imicroros_component/microros_include

# Removing heap4 manager while being polite with STM32CubeMX
TMPVAR := $(C_SOURCES)
C_SOURCES := $(filter-out Middlewares/Third_Party/FreeRTOS/Source/portable/MemMang/heap_4.c, $(TMPVAR))

# Add micro-ROS utils
C_SOURCES += microros_component/custom_memory_manager.c
C_SOURCES += microros_component/microros_allocators.c
C_SOURCES += microros_component/microros_transports.c
C_SOURCES += microros_component/microros_time.c

print_cflags:
	@echo $(CFLAGS)
```

3. Go to `microros_component` and execute the static library generation tool. Compiler flags will retrieved automatically from your `Makefile` and user will be prompted to check if they are correct.

<!-- 
pushd microros_component
docker build . -t micro_ros_cubemx_builder:foxy
popd
 -->

```bash
cd microros_component
docker pull microros/micro_ros_cubemx_builder:foxy
docker run -it --rm -v $(pwd)/../:/microros_library microros/micro_ros_cubemx_builder:foxy
cd ..
```

4. Modify your `main.c` to use micro-ROS. An example application can be found in `sample_main.c`.
5. Continue your usual workflow building your project and flashing the binary:

```bash
make -j$(nproc)
```

## Customizing the micro-ROS library

All the micro-ROS configuration can be done in `colcon.meta` file before step 3. You can find detailed information about how to tune the static memory usage of the library in the [Middleware Configuration tutorial](https://micro.ros.org/docs/tutorials/core/microxrcedds_rmw_configuration/).

## Adding custom packages

Note that folders added to `microros_component/extra_packages` and entries added to `microros_component/extra_packages/extra_packages.repos` will be taken into account by this build system.


## Purpose of the Project

This software is not ready for production use. It has neither been developed nor
tested for a specific use case. However, the license conditions of the
applicable Open Source licenses allow you to adapt the software to your needs.
Before using it in a safety relevant setting, make sure that the software
fulfills your requirements and adjust it according to any applicable safety
standards, e.g., ISO 26262.

## License

This repository is open-sourced under the Apache-2.0 license. See the [LICENSE](LICENSE) file for details.

For a list of other open-source components included in this repository,
see the file [3rd-party-licenses.txt](3rd-party-licenses.txt).

## Known Issues/Limitations

There are no known limitations.
