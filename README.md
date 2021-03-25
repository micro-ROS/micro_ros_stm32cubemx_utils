# micro-ROS for STM32CubeMX

This tool aims to ease the micro-ROS integration in a STM32CubeMX project.

## How to use it

1. In the `root` folder, generate your STM32CubeMX project. A sample project can be generated with the provided `sample_project.ioc`.
2. Make sure that your STM32CubeMX project is using a `Makefile` toolchain under `Project Manager -> Project`
3. Make sure that if you are using FreeRTOS, the micro-ROS task **has more than 10 kB of stack**: [Detail](.images/Set_freertos_stack.jpg)
4. Configure the transport interface on the STM32CubeMX project, check the [Transport configuration](#Transport-configuration) section for instructions on the custom transports provided.
5. Modify the generated `Makefile` to include the following code **before the `build the application` section**:

<!-- # Removing heap4 manager while being polite with STM32CubeMX
TMPVAR := $(C_SOURCES)
C_SOURCES := $(filter-out Middlewares/Third_Party/FreeRTOS/Source/portable/MemMang/heap_4.c, $(TMPVAR)) -->

```makefile
#######################################
# micro-ROS addons
#######################################
LDFLAGS += microros_component/libmicroros.a
C_INCLUDES += -Imicroros_component/microros_include

# Add micro-ROS utils
C_SOURCES += microros_component/custom_memory_manager.c
C_SOURCES += microros_component/microros_allocators.c
C_SOURCES += microros_component/microros_time.c

# Set here the custom transport implementation
C_SOURCES += microros_component/microros_transports/dma_transport.c

print_cflags:
	@echo $(CFLAGS)
```

6. Go to `microros_component` and execute the static library generation tool. Compiler flags will retrieved automatically from your `Makefile` and user will be prompted to check if they are correct.

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

7. Modify your `main.c` to use micro-ROS. An example application can be found in `sample_main.c`.
8. Continue your usual workflow building your project and flashing the binary:

```bash
make -j$(nproc)
```
## Transport configuration

Available transport for this platform are:
### U(S)ART with DMA

Steps to configure:
   - Enable U(S)ART in your STM32CubeMX 
   - For the selected USART, enable DMA for Tx and Rx under `DMA Settings`
   - Set the DMA priotity to `Very High` for Tx and Rx
   - Set the DMA mode to `Circular` for Rx: [Detail](.images/Set_UART_DMA1.jpg)
   - For the selected, enable `global interrupt` under `NVIC Settings`: [Detail](.images/Set_UART_DMA_2.jpg)

### U(S)ART with Interrupts

Steps to configure:
   - Enable U(S)ART in your STM32CubeMX 
   - For the selected USART, enable `global interrupt` under `NVIC Settings`: [Detail](.images/Set_UART_IT.jpg)
## Customizing the micro-ROS library

All the micro-ROS configuration can be done in `colcon.meta` file before step 3. You can find detailed information about how to tune the static memory usage of the library in the [Middleware Configuration tutorial](https://micro.ros.org/docs/tutorials/core/microxrcedds_rmw_configuration/).
## Adding custom packages

Note that folders added to `microros_component/extra_packages` and entries added to `microros_component/extra_packages/extra_packages.repos` will be taken into account by this build system.

## Using this package with STM32CubeIDE

micro-ROS precompiled library can be used in an SMT32CubeIDE but SMT32CubeIMX should be used for generating it.
Once you have followed the steps in this first section:

1. Add micro-ROS include directory. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Compiler -> Include paths` add `microros_component/include`
2. Add the micro-ROS precompiled library. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Linker -> Libraries`
      - add `microros_component` in `Library search path (-L)`
      - add `microros` in `Libraries (-l)`
3. Add the following source code files to your project:
      - `microros_component/microros_time.c`
      - `microros_component/microros_allocators.c`
      - `microros_component/microros_custom_memory_manager.c`
      - `microros_component/microros_transports/dma_transport.c` or your transport selection.
4. Build and run your project

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
