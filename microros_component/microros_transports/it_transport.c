#include <uxr/client/transport.h>

#include <rmw_microxrcedds_c/config.h>

#include "main.h"
#include "cmsis_os.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#ifdef RMW_UXRCE_TRANSPORT_CUSTOM

// --- micro-ROS Transports ---
#define UART_IT_BUFFER_SIZE 2048

static uint8_t it_buffer[UART_IT_BUFFER_SIZE];
static uint8_t it_data;
static size_t it_head = 0, it_tail = 0;


bool cubemx_transport_open(struct uxrCustomTransport * transport){
    UART_HandleTypeDef * uart = (UART_HandleTypeDef*) transport->args;
    HAL_UART_Receive_IT(uart, &it_data, 1);
    return true;
}

bool cubemx_transport_close(struct uxrCustomTransport * transport){
    UART_HandleTypeDef * uart = (UART_HandleTypeDef*) transport->args;
    HAL_UART_Abort_IT(uart);
    return true;
}

size_t cubemx_transport_write(struct uxrCustomTransport* transport, uint8_t * buf, size_t len, uint8_t * err){
    UART_HandleTypeDef * uart = (UART_HandleTypeDef*) transport->args;

    HAL_StatusTypeDef ret;
    if (uart->gState == HAL_UART_STATE_READY){
        ret = HAL_UART_Transmit_IT(uart, buf, len);
        while (ret == HAL_OK && uart->gState != HAL_UART_STATE_READY){
            osDelay(1);
        }

        return (ret == HAL_OK) ? len : 0;
    }else{
        return 0;
    }
}

size_t cubemx_transport_read(struct uxrCustomTransport* transport, uint8_t* buf, size_t len, int timeout, uint8_t* err){
    size_t wrote = 0;
    while ((it_head != it_tail) && (wrote < len)){
        buf[wrote] = it_buffer[it_head];
        it_head = (it_head + 1) % UART_IT_BUFFER_SIZE;
        wrote++;
    }

    return wrote;
}

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if(it_tail == UART_IT_BUFFER_SIZE)
        it_tail = 0;

    it_buffer[it_tail] = it_data;
    it_tail++;

    HAL_UART_Receive_IT(huart, &it_data, 1);
}

#endif //RMW_UXRCE_TRANSPORT_CUSTOM