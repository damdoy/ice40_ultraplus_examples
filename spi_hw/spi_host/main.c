#include <stdio.h>
#include "spi_lib.h"

#define SPI_NOP 0x00
#define SPI_INIT 0x01
#define SPI_SEND_BIT_INV 0x02
#define SPI_SET_LED 0x04
#define SPI_SEND_VEC 0x06
#define SPI_READ_VEC 0x07

int main()
{
   spi_init();

   uint8_t no_param[7] = {0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};
   //last value is most important (sync of send/receive)
   uint8_t init_param[7] = {0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x11};
   uint8_t spi_status = 0;
   uint8_t data_read[5];
   uint8_t val_inv[7] = {0x38, 0xAE, 0x3B, 0x48, 0x0, 0x0, 0x0};
   uint8_t val_led_yellow[7] = {0x3, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};
   uint8_t val_led_blue[7] = {0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};

   if (spi_command_send(SPI_INIT, init_param) != 0){ // init
      printf("trouble to get answer\n");
   }

   spi_command_send_recv(SPI_SEND_BIT_INV, val_inv, data_read); // send values bit inversion

   for (size_t i = 0; i < 4; i++) {
      printf("bit inversion read idx %lu: 0x%x, should be 0x%x\n", i, data_read[i+1], 0xFF&~val_inv[i]);
   }

   printf("LED command answer from fpga: the first byte should be the command (0x4), the second byte should by the LED colour\n");

   spi_command_send_recv(SPI_SET_LED, val_led_yellow, data_read); // led yellow
   printf("sent yellow led\n");
   for (size_t i = 0; i < 5; i++) {
      printf("received: [%lu]:%x\n", i, data_read[i]);
   }

   //wait 2sec before setting led in blue
   usleep(2000*1000);

   spi_command_send_recv(SPI_SET_LED, val_led_blue, data_read); // set led blue
   printf("sent blue led\n");
   for (size_t i = 0; i < 5; i++) {
      printf("received: [%lu]:%x\n", i, data_read[i]);
   }

   //send 4 values the fastest possible
   for (size_t i = 0; i < 4; i++) {
      int send_value = (i+1)*0x01020304;
      spi_command_send_32(SPI_SEND_VEC, send_value);
      printf("sent vector val: 0x%x\n", send_value);
   }

   usleep(5000);

   //send read request, the fpga will send the 4 values back, in order
   for (size_t i = 0; i < 4; i++) {
      spi_command_send_recv(SPI_READ_VEC, no_param, data_read);
      printf("vector read: 0x%x, 0x%x, 0x%x, 0x%x\n", data_read[4], data_read[3], data_read[2], data_read[1]); //data_read[1] only the cmd
   }

   return 0;
}
