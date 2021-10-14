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
LDFLAGS += microros_static_library/libmicroros/libmicroros.a
C_INCLUDES += -Imicroros_static_library/libmicroros/microros_include

# Add micro-ROS utils
C_SOURCES += extra_sources/custom_memory_manager.c
C_SOURCES += extra_sources/microros_allocators.c
C_SOURCES += extra_sources/microros_time.c

# Set here the custom transport implementation
C_SOURCES += extra_sources/microros_transports/dma_transport.c

print_cflags:
	@echo $(CFLAGS)
```

6. Execute the static library generation tool. Compiler flags will retrieved automatically from your `Makefile` and user will be prompted to check if they are correct.


```bash
docker pull microros/micro_ros_static_library_builder:galactic
docker run -it --rm -v $(pwd):/project microros/micro_ros_static_library_builder:galactic
cd ..
```

1. Modify your `main.c` to use micro-ROS. An example application can be found in `sample_main.c`.
2. Continue your usual workflow building your project and flashing the binary:

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

micro-ROS can be used with SMT32CubeIDE following these steps:

1. Clone this repository in your STM32CubeIDE project folder
2. Go to `Project -> Settings -> C/C++ Build -> Settings -> Build Steps Tab` and in `Pre-build steps` add:

```bash
docker pull microros/micro_ros_static_library_builder:galactic && docker run --rm -v ${workspace_loc:/${ProjName}}:/project --env MICROROS_LIBRARY_FOLDER=micro_ros_stm32cubemx_utils/microros_static_library_ide microros/micro_ros_static_library_builder:galactic
```

3. Add micro-ROS include directory. In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU GCC Compiler -> Include paths` add `micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`
4. Add the micro-ROS precompiled library. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Linker -> Libraries`
      - add `<ABSOLUTE_PATH_TO>/micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros` in `Library search path (-L)`
      - add `microros` in `Libraries (-l)`
5. Add the following source code files to your project, dragging them to source folder:
      - `extra_sources/microros_time.c`
      - `extra_sources/microros_allocators.c`
      - `extra_sources/custom_memory_manager.c`
      - `extra_sources/microros_transports/dma_transport.c` or your transport selection.
6. Make sure that if you are using FreeRTOS, the micro-ROS task **has more than 10 kB of stack**: [Detail](.images/Set_freertos_stack.jpg)
7. Configure the transport interface on the STM32CubeMX project, check the [Transport configuration](#Transport-configuration) section for instructions on the custom transports provided.
8. Build and run your project

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






EMbeddeded RTPS:

- Create a cpp project
- Enable LwIP and freertos and ethernet
- Clone the repo

Add to prebuild:

docker pull microros/micro_ros_static_library_builder:galactic && docker run --rm -v ${workspace_loc:/${ProjName}}:/project --env MICROROS_USE_EMBEDDEDRTPS --env MICROROS_LIBRARY_FOLDER=micro_ros_stm32cubemx_utils/microros_static_library_ide microros/micro_ros_static_library_builder:galactic


- Fix middlewares/lwip/sc/include/lwip/errno.h adding <sys/errno.h>
- Enable IGMP in lwip

- Copy
      - `extra_sources/microros_time.c`
      - `extra_sources/microros_allocators.c`
      - `extra_sources/custom_memory_manager.c`

3. Add micro-ROS include directory. In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU GCC Compiler -> Include paths` add `micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`
4. Add the micro-ROS precompiled library. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Linker -> Libraries`
      - add `<ABSOLUTE_PATH_TO>/micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros` in `Library search path (-L)`
      - add `microros` in `Libraries (-l)`

Increase task stack
Increase task heap
Task prio?
cuiadado con el IGMP flag: NETIF_FLAG_IGMP
memp num udp pcb config




MULTICAST:
      stm32f7xx_hal_eth.c:1878:
      macinit.MulticastFramesFilter = ETH_MULTICASTFRAMESFILTER_NONE;

Freertos max task name lenght


embedded rtps priorities to more than 25?
Task                                                           State   Prio    Stack  Num
defaultTask                                                     X       24      7170    1
tcpip_thread                                                    R       20      2489    4
LinkThr                                                         R       16      245     6
Tmr Svc                                                         R       2       245     3
IDLE                                                            R       0       118     2
HBThreadSub                                                     B       25      957     8
SPDPThread                                                      B       25      861     11
HBThread                                                        B       25      957     12
HBThreadPub                                                     B       25      957     7
ReaderThread                                                    B       25      929     10
WriterThread                                                    B       25      842     9
EthIf                                                           B       48      44      5

Pbuf sizes?


## How to configure micro-ROS with embeddedRTPS


**IT IS HIGHLY RECOMMENDED TO HAVE THE BOARD AND THE ROS 2 COMPUTER IN AN ISOLATED ETHERNET NETWORK**

1. Create a a new STM32 project based on C++

2. In the `.ioc` file enable:
    - Middleware -> FreeRTOS: with CMSIS_V2
    - Middleware -> LwIP
    - Connectivity -> ETH

3. Make sure that your HAL timebase is not Systick (FreeRTOS requeriments) and `USE_NEWLIB_REENTRANT` is enabled (FreeRTOS -> Advanced settings).

4. Enable IGMP support:
   - LwIP -> Key Options (Show advanced parameters) -> Multicast Options -> LWIP_MULTICAST_TX_OPTIONS -> Enabled
   - LwIP -> General Settings -> LWIP IGMP -> Enabled

5. Configure IP at LwIP level:
   - LwIP -> General Settings -> LWIP_DHCP -> Disabled
   - LwIP -> General Settings -> IP Address Settings

6. Make sure that FreeRTOS has the following configuration:
   - FreeRTOS -> Config parameters -> Memory management settings -> TOTAL_HEAP_SIZE -> 100000 Bytes
   - FreeRTOS -> Config parameters -> Kernal settings -> MAX_TASK_NAME_LEN -> 30
   - FreeRTOS -> Tasks and Queues -> defaultTask -> Stack Size -> 8000 Words
   - FreeRTOS -> Tasks and Queues -> defaultTask -> Priority -> Belownormal3

7. Make sure that LwIP has the following configuration:
   - LwIP -> General Settings -> Procols Options -> MEMP_NUM_UDP_PCB -> 15
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Heap and Memory Pools Options -> MEM_SIZE -> 30000 Bytes
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Threading options -> TCPIP_THREAD_STACKSIZE -> 10000 Words
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Threading options -> TCPIP_THREAD_PRIO -> 20
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Pbuf Options -> PBUF_POOL_SIZE -> 20

8. In file `LWIP/Target/ethernetif.c` add the following line in block `USER CODE BEGIN MACADDRESS` inside `low_level_init()` function: `netif->flags |= NETIF_FLAG_IGMP;`
9. Make sure that `macinit.MulticastFramesFilter` is set to `ETH_MULTICASTFRAMESFILTER_NONE`. Usually this configuration is set in `Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_eth.c:1878` and by default its value is `ETH_MULTICASTFRAMESFILTER_PERFECT`. **Probably this is modified automatically every time code is generated**.

10. Clone this repository in your STM32CubeIDE project folder
11. Go to `Project -> Settings -> C/C++ Build -> Settings -> Build Steps Tab` and in `Pre-build steps` add:

```bash
docker pull microros/micro_ros_static_library_builder:galactic && docker run --rm -v ${workspace_loc:/${ProjName}}:/project --env MICROROS_USE_EMBEDDEDRTPS --env MICROROS_LIBRARY_FOLDER=micro_ros_stm32cubemx_utils/microros_static_library_ide microros/micro_ros_static_library_builder:galactic
```

12. Add the following source code files to your project, dragging them to source folder:
   - `extra_sources/microros_time.c`
   - `extra_sources/microros_allocators.c`
   - `extra_sources/custom_memory_manager.c`

13. Add micro-ROS include directory:
   - In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU GCC Compiler -> Include paths` add `micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`
   - In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU G++ Compiler -> Include paths` add `micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`

14.  Add the micro-ROS precompiled library. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Linker -> Libraries`
  - add `<ABSOLUTE_PATH_TO>/micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros` in `Library search path (-L)`
  - add `microros` in `Libraries (-l)`

15. Use `sample_main_embeddedrtps.c` as reference for writing you application code.

16. In `Core/Inc/FreeRTOSConfig.h`. Explanation [here](https://community.st.com/s/question/0D50X0000BJ1iquSQB/bug-in-cubemx-ide-lwip-freertos-on-nucleo-f429zi)
   ```c
   // FROM THIS:
   // #define configASSERT( x ) if ((x) == 0) {taskDISABLE_INTERRUPTS(); for( ;; );}
   // TO THIS:
   #define configASSERT( x )
   ```
