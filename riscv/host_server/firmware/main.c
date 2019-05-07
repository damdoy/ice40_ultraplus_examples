/*
   program to run on the riscv cpu
*/

#include <math.h>

#define SPI_ADDRESS 0x8000;
#define GPIO_ADDRESS 0x8100;

typedef unsigned int uint;

void set_led(int *gpio_addr, int rgb24)
{
   *gpio_addr = (rgb24>>16);
}

uint fib(uint n)
{
   if(n == 0)
      return 0;
   else if(n <= 2)
      return 1;
   else
      return fib(n-2)+fib(n-1);
}

//create a soft gradient on the leds, using a soft pwm
void gradient(int *gpio_addr)
{
   int grad_speed = 256;
   for (size_t col = 1; col < 8; col++)
   {
      for (size_t i = 0; i < grad_speed; i++)
      {
         for (size_t j = 0; j < grad_speed; j++)
         {
            if(i > j)
            {
               *gpio_addr = col;
            }
            else
            {
               *gpio_addr = 0;
            }
         }
      }
   }
}

void main()
{
   int *spi_addr = (int*)SPI_ADDRESS;
   int *gpio_addr = (int*)GPIO_ADDRESS; //bit 0=R, 1=G, 2=B

   while(1)
   {
      int read = *spi_addr;
      if(read & 0x00000001 != 0)
      {
         read = *(spi_addr+1);
         int operation = (read&0xff);
         int value = (read>>8);

         *(spi_addr+2) = 1; //assert read

         if(operation == 0x4) //set led
         {
            set_led(gpio_addr, value);
         }
         if(operation == 0x5) //gradient
         {
            gradient(gpio_addr);
         }
         if( operation == 0x6) //fibonacci
         {
            int ret = fib(value);
            *(spi_addr+3) = ret;
         }

         if( operation == 0x7) //pow
         {
            *(spi_addr+3) = value*value;
         }
      }
   }
}
