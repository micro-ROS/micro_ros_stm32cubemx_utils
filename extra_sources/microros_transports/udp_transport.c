#include <uxr/client/transport.h>

#include <rmw_microxrcedds_c/config.h>

#include "main.h"
#include "cmsis_os.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

// --- LWIP ---
#include "lwip/opt.h"
#include "lwip/sys.h"
#include "lwip/api.h"
#include <lwip/sockets.h>

#ifdef RMW_UXRCE_TRANSPORT_CUSTOM

// --- micro-ROS Transports ---
#define UDP_PORT        8888
static int sock_fd = -1;

bool cubemx_transport_open(struct uxrCustomTransport * transport){
    sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(UDP_PORT);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    
    if (bind(sock_fd, (struct sockaddr *)&addr, sizeof(addr)) == -1)
    {
        return false;
    }

    return true;
}

bool cubemx_transport_close(struct uxrCustomTransport * transport){
    if (sock_fd != -1)
    {
        closesocket(sock_fd);
        sock_fd = -1;
    }
    return true;
}

size_t cubemx_transport_write(struct uxrCustomTransport* transport, uint8_t * buf, size_t len, uint8_t * err){
    if (sock_fd == -1)
    {
        return 0;
    }
    const char * ip_addr = (const char*) transport->args;
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(UDP_PORT);
    addr.sin_addr.s_addr = inet_addr(ip_addr);
    int ret = 0;
    ret = sendto(sock_fd, buf, len, 0, (struct sockaddr *)&addr, sizeof(addr));
    size_t writed = ret>0? ret:0;

    return writed;
}

size_t cubemx_transport_read(struct uxrCustomTransport* transport, uint8_t* buf, size_t len, int timeout, uint8_t* err){

    int ret = 0;
    //set timeout
    struct timeval tv_out;
    tv_out.tv_sec = timeout / 1000;
    tv_out.tv_usec = (timeout % 1000) * 1000;
    setsockopt(sock_fd, SOL_SOCKET, SO_RCVTIMEO,&tv_out, sizeof(tv_out));
    ret = recv(sock_fd, buf, len, MSG_WAITALL);
    size_t readed = ret > 0 ? ret : 0;
    return readed;
}

#endif