## How to configure micro-ROS with embeddedRTPS

This is a **experimental** approach for using micro-ROS with [embeddedRTPS](https://github.com/embedded-software-laboratory/embeddedRTPS) as middleware.
This instructions are an approach to a [STMCubeIDE v1.7.0](https://www.st.com/en/development-tools/stm32cubeide.html) + [FreeRTOS](https://www.freertos.org/) + [LwIP](https://www.nongnu.org/lwip/2_1_x/index.html) configuration and has been tested with [Nucleo F746ZG](https://www.st.com/en/evaluation-tools/nucleo-f746zg.html) board against ROS 2 Galactic with [Fast-DDS](https://github.com/eProsima/Fast-DDS) as [default middleware](https://github.com/eProsima/Fast-DDS-docs/blob/master/docs/fastdds/ros2/ros2.rst).

**IT IS HIGHLY RECOMMENDED TO HAVE THE BOARD AND THE ROS 2 COMPUTER IN AN ISOLATED ETHERNET NETWORK**

1. Create a a new STM32 project based on C++

2. In the `.ioc` file enable:
    - Middleware -> FreeRTOS: with CMSIS_V2
    - Middleware -> LwIP
    - Connectivity -> ETH

3. Make sure that your HAL timebase is not Systick (FreeRTOS requeriment) and `USE_NEWLIB_REENTRANT` is enabled (FreeRTOS -> Advanced settings).

4. Make sure that FreeRTOS has the following configuration:
   - FreeRTOS -> Config parameters -> Memory management settings -> TOTAL_HEAP_SIZE -> 100000 Bytes
   - FreeRTOS -> Config parameters -> Kernel settings -> MAX_TASK_NAME_LEN -> 30
   - FreeRTOS -> Tasks and Queues -> defaultTask -> Stack Size -> 8000 Words
   - FreeRTOS -> Tasks and Queues -> defaultTask -> Priority -> Belownormal3

5. Make sure that LwIP has the following configuration:
   - LwIP -> Key Options (Show advanced parameters) -> Multicast Options -> LWIP_MULTICAST_TX_OPTIONS -> Enabled
   - LwIP -> General Settings -> LWIP IGMP -> Enabled
   - LwIP -> General Settings -> LWIP_DHCP -> Disabled
   - LwIP -> General Settings -> IP Address Settings (Set here the board address and mask)
   - LwIP -> General Settings -> Procols Options -> MEMP_NUM_UDP_PCB -> 15
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Heap and Memory Pools Options -> MEM_SIZE -> 30000 Bytes
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Threading options -> TCPIP_THREAD_STACKSIZE -> 10000 Words
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Threading options -> TCPIP_THREAD_PRIO -> 20
   - LwIP -> Key Options (Show advanced parameters) -> Infraestructure - Pbuf Options -> PBUF_POOL_SIZE -> 20

6. Save the file and generate the code.

7. In file `LWIP/Target/ethernetif.c` add the following line in block `USER CODE BEGIN MACADDRESS` inside `low_level_init()` function: `netif->flags |= NETIF_FLAG_IGMP;`

8.  Make sure that `macinit.MulticastFramesFilter` is set to `ETH_MULTICASTFRAMESFILTER_NONE`. Usually this configuration is set in `Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_eth.c:1878` and by default its value is `ETH_MULTICASTFRAMESFILTER_PERFECT`. **Probably this is modified automatically every time code is generated**.

9.  Clone this repository in your STM32CubeIDE project folder.

10. Go to `Project -> Settings -> C/C++ Build -> Settings -> Build Steps Tab` and in `Pre-build steps` add:

```bash
docker pull microros/micro_ros_static_library_builder:humble && docker run --rm -v ${workspace_loc:/${ProjName}}:/project --env MICROROS_USE_EMBEDDEDRTPS=ON --env MICROROS_LIBRARY_FOLDER=micro_ros_stm32cubemx_utils/microros_static_library_ide microros/micro_ros_static_library_builder:humble
```

12. Add the following source code files to your project, dragging them to source folder:
   - `extra_sources/microros_time.c`
   - `extra_sources/microros_allocators.c`
   - `extra_sources/custom_memory_manager.c`

13. Add micro-ROS include directory:
   - In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU GCC Compiler -> Include paths` add `../micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`
   - In `Project -> Settings -> C/C++ Build -> Settings -> Tool Settings Tab -> MCU G++ Compiler -> Include paths` add `../micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros/include`

14.  Add the micro-ROS precompiled library. In `Project -> Settings -> C/C++ Build -> Settings -> MCU GCC Linker -> Libraries`
  - add `../micro_ros_stm32cubemx_utils/microros_static_library_ide/libmicroros` in `Library search path (-L)`
  - add `microros` in `Libraries (-l)`

15. Use `sample_main_embeddedrtps.c` as reference for writing you application code.

16. In `Core/Inc/FreeRTOSConfig.h`. Explanation [here](https://community.st.com/s/question/0D50X0000BJ1iquSQB/bug-in-cubemx-ide-lwip-freertos-on-nucleo-f429zi)
   ```c
   // FROM THIS:
   // #define configASSERT( x ) if ((x) == 0) {taskDISABLE_INTERRUPTS(); for( ;; );}
   // TO THIS:
   #define configASSERT( x )
   ```
