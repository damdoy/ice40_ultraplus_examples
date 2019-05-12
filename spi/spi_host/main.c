#include <stdio.h>
#include "spi_lib.h"

#define SPI_NOP 0x00
#define SPI_INIT 0x01
#define SPI_SEND_BIT_INV 0x02
#define SPI_READ_REQ_BIT_INV 0x03
#define SPI_SET_LED 0x04
#define SPI_READ_REQ_LED 0x05
#define SPI_SEND_VEC 0x06
#define SPI_READ_VEC 0x07

int main()
{
   spi_init();

   uint8_t no_param[3] = {0x0, 0x0, 0x0};
   uint8_t spi_status = 0;
   uint8_t data_read[3];
   uint8_t val_inv[3] = {0x38, 0xAE, 0x3B};
   uint8_t val_led_yellow[3] = {0x0, 0x0, 0x3};
   uint8_t val_led_blue[3] = {0x0, 0x0, 0x4};

   spi_send(SPI_INIT, no_param, NULL); // init

   spi_send(SPI_SEND_BIT_INV, val_inv, &spi_status); // send values bit inversion
   printf("send inversion data, status: 0x%x\n", spi_status);

   spi_send(SPI_READ_REQ_BIT_INV, no_param, NULL); //send read request
   spi_read(data_read, &spi_status); // read data inversion

   for (size_t i = 0; i < 3; i++) {
      printf("bit inversion read idx %i: 0x%x, should be 0x%x\n", i, data_read[i], 0xFF&~val_inv[i]);
   }
   printf("status: 0x%x\n", spi_status);

   spi_send(SPI_SET_LED, val_led_yellow, &spi_status); // led yellow
   printf("send yellow led, status: 0x%x\n", spi_status);

   spi_send(SPI_READ_REQ_LED, no_param, NULL); //send led read request

   spi_read(data_read, &spi_status); // read led data
   printf("led_data read: 0x%x, 0x%x, 0x%x, status:0x%x\n", data_read[2], data_read[1], data_read[0], spi_status);

   //wait 2sec before setting led in blue
   usleep(2000*1000);

   spi_send(SPI_SET_LED, val_led_blue, &spi_status); // set led blue
   printf("send blue led, status: 0x%x\n", spi_status);

   //send 4 values the fastest possible
   for (size_t i = 0; i < 4; i++) {
      int send_value = (i+1)*16;
      spi_send24b(SPI_SEND_VEC, send_value, &spi_status);
      printf("sent vector val: 0x%x, status: 0x%x\n", send_value, spi_status);
   }

   usleep(1000);

   //send read request, the fpga will send the 4 values
   spi_send(SPI_READ_VEC, no_param, &spi_status);
   printf("sent read req vector, status: 0x%x\n", spi_status);

   //read values the fastest possible
   for (size_t i = 0; i < 4; i++) {
      spi_read(data_read, &spi_status);
      printf("vector read: 0x%x, 0x%x, 0x%x, status:0x%x\n", data_read[2], data_read[1], data_read[0], spi_status);
   }

   return 0;
}
