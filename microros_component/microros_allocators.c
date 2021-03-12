
#include <unistd.h>
#include "cmsis_os.h"

int absoluteUsedMemory = 0;
int usedMemory = 0;

void *pvPortRealloc( void *pv, size_t xWantedSize );
size_t getBlockSize( void *pv );
void *pvPortCalloc( size_t num, size_t xWantedSize );

void * microros_allocate(size_t size, void * state){
  (void) state;
  // printf("-- Alloc %d (prev: %d B)\n",size, xPortGetFreeHeapSize());
  absoluteUsedMemory += size;
  usedMemory += size;
  return pvPortMalloc(size);
}

void microros_deallocate(void * pointer, void * state){
  (void) state;
  // printf("-- Free %d (prev: %d B)\n",getBlockSize(pointer), xPortGetFreeHeapSize());
  if (NULL != pointer){
    usedMemory -= getBlockSize(pointer);
    vPortFree(pointer);
  }
}

void * microros_reallocate(void * pointer, size_t size, void * state){
  (void) state;
  // printf("-- Realloc %d -> %d (prev: %d B)\n",getBlockSize(pointer),size, xPortGetFreeHeapSize());
  absoluteUsedMemory += size;
  usedMemory += size;
  if (NULL == pointer){
    return pvPortMalloc(size);
  } else {
    usedMemory -= getBlockSize(pointer);
    return pvPortRealloc(pointer,size);
  }
}

void * microros_zero_allocate(size_t number_of_elements, size_t size_of_element, void * state){
  (void) state;
  // printf("-- Calloc %d x %d = %d -> (prev: %d B)\n",number_of_elements,size_of_element, number_of_elements*size_of_element, xPortGetFreeHeapSize());
  absoluteUsedMemory += number_of_elements*size_of_element;
  usedMemory += number_of_elements*size_of_element;
  return pvPortCalloc(number_of_elements,size_of_element);
}