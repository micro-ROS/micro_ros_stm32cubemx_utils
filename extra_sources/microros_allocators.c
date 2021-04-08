
#include <unistd.h>
#include "cmsis_os.h"

int absoluteUsedMemory = 0;
int usedMemory = 0;

void *pvPortMallocMicroROS( size_t xWantedSize );
void vPortFreeMicroROS( void *pv );
void *pvPortReallocMicroROS( void *pv, size_t xWantedSize );
size_t getBlockSize( void *pv );
void *pvPortCallocMicroROS( size_t num, size_t xWantedSize );

void * microros_allocate(size_t size, void * state){
  (void) state;
  // printf("-- Alloc %d (prev: %d B)\n",size, xPortGetFreeHeapSize());
  absoluteUsedMemory += size;
  usedMemory += size;
  return pvPortMallocMicroROS(size);
}

void microros_deallocate(void * pointer, void * state){
  (void) state;
  // printf("-- Free %d (prev: %d B)\n",getBlockSize(pointer), xPortGetFreeHeapSize());
  if (NULL != pointer){
    usedMemory -= getBlockSize(pointer);
    vPortFreeMicroROS(pointer);
  }
}

void * microros_reallocate(void * pointer, size_t size, void * state){
  (void) state;
  // printf("-- Realloc %d -> %d (prev: %d B)\n",getBlockSize(pointer),size, xPortGetFreeHeapSize());
  absoluteUsedMemory += size;
  usedMemory += size;
  if (NULL == pointer){
    return pvPortMallocMicroROS(size);
  } else {
    usedMemory -= getBlockSize(pointer);
    return pvPortReallocMicroROS(pointer,size);
  }
}

void * microros_zero_allocate(size_t number_of_elements, size_t size_of_element, void * state){
  (void) state;
  // printf("-- Calloc %d x %d = %d -> (prev: %d B)\n",number_of_elements,size_of_element, number_of_elements*size_of_element, xPortGetFreeHeapSize());
  absoluteUsedMemory += number_of_elements*size_of_element;
  usedMemory += number_of_elements*size_of_element;
  return pvPortCallocMicroROS(number_of_elements,size_of_element);
}