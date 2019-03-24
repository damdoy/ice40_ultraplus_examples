#include <stdio.h>
#include "spi_lib.h"

static struct ftdi_context ftdic;
static int ftdic_open = 0; //false
static int verbose = 0; //false
static int ftdic_latency_set = 0; //false
static unsigned char ftdi_latency;

static void send_byte(uint8_t data)
{
  int rc = ftdi_write_data(&ftdic, &data, 1);
  if (rc != 1) {
     fprintf(stderr, "Write error (single byte, rc=%d, expected %d) data: 0x%x.\n", rc, 1, data);
     error(2);
  }
}

static uint8_t recv_byte()
{
  uint8_t data;
  while (1) {
     int rc = ftdi_read_data(&ftdic, &data, 1);
     if (rc < 0) {
        fprintf(stderr, "Read error.\n");
        error(2);
     }
     if (rc == 1)
        break;
     usleep(100);
  }
  return data;
}

static void send_spi(uint8_t *data, int n)
{
  if (n < 1)
     return;

  /* Output only, update data on negative clock edge. */
  send_byte(MC_DATA_OUT | MC_DATA_LSB);
  send_byte(n - 1);
  send_byte((n - 1) >> 8);

  int rc = ftdi_write_data(&ftdic, data, n);
  if (rc != n) {
     fprintf(stderr, "Write error (chunk, rc=%d, expected %d).\n", rc, n);
     error(2);
  }
}

static uint8_t xfer_spi_bits(uint8_t data, int n)
{
  if (n < 1)
     return 0;

  /* Input and output, update data on negative edge read on positive, bits. */
  send_byte(MC_DATA_IN | MC_DATA_OUT | MC_DATA_BITS | MC_DATA_LSB );
  send_byte(n - 1);
  send_byte(data);

  return recv_byte();
}

static void xfer_spi(uint8_t *data, int n)
{
  if (n < 1)
     return;

  /* Input and output, update data on negative edge read on positive. */
  send_byte(MC_DATA_IN | MC_DATA_OUT | MC_DATA_LSB | MC_DATA_OCN);
  send_byte(n - 1);
  send_byte((n - 1) >> 8);

  int rc = ftdi_write_data(&ftdic, data, n);
  if (rc != n) {
     fprintf(stderr, "Write error (chunk, rc=%d, expected %d).\n", rc, n);
     error(2);
  }

  for (int i = 0; i < n; i++)
     data[i] = recv_byte();
}


static void set_gpio(int slavesel_b, int creset_b)
{
  uint8_t gpio = 0;

  if (slavesel_b) {
     // ADBUS4 (GPIOL0)
     gpio |= 0x10;
  }

  if (creset_b) {
     // ADBUS7 (GPIOL3)
     gpio |= 0x80;
  }

  send_byte(MC_SETB_LOW);
  send_byte(gpio); /* Value */
  send_byte(0x93); /* Direction */
}

// the FPGA reset is released so also FLASH chip select should be deasserted
static void flash_release_reset()
{
  set_gpio(1, 1);
}

// SRAM reset is the same as flash_chip_select()
// For ease of code reading we use this function instead
static void sram_reset()
{
  // Asserting chip select and reset lines
  set_gpio(0, 0);
}

// SRAM chip select assert
// When accessing FPGA SRAM the reset should be released
static void sram_chip_select()
{
  set_gpio(0, 1);
}


int spi_init()
{
   // ftdi initialization taken from iceprog https://github.com/cliffordwolf/icestorm/blob/master/iceprog/iceprog.c
   enum ftdi_interface ifnum = INTERFACE_A;
   int status = 0;

   printf("init..\n");

   status = ftdi_init(&ftdic);
	if( status != 0)
   {
      printf("couldn't initalize ftdi\n");
      return 1;
   }

	status = ftdi_set_interface(&ftdic, ifnum);
   if(status != 0)
   {
      printf("couldn't initalize ftdi interface\n");
      return 1;
   }

   if (ftdi_usb_open(&ftdic, 0x0403, 0x6010) && ftdi_usb_open(&ftdic, 0x0403, 0x6014)) {
		printf("Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).\n");
		return 1;
	}

   if (ftdi_usb_reset(&ftdic)) {
		fprintf(stderr, "Failed to reset iCE FTDI USB device.\n");
		return 1;
	}

	if (ftdi_usb_purge_buffers(&ftdic)) {
		fprintf(stderr, "Failed to purge buffers on iCE FTDI USB device.\n");
		return 1;
	}

	if (ftdi_get_latency_timer(&ftdic, &ftdi_latency) < 0) {
		fprintf(stderr, "Failed to get latency timer (%s).\n", ftdi_get_error_string(&ftdic));
		return 1;
	}

	/* 1 is the fastest polling, it means 1 kHz polling */
	if (ftdi_set_latency_timer(&ftdic, 1) < 0) {
		fprintf(stderr, "Failed to set latency timer (%s).\n", ftdi_get_error_string(&ftdic));
		return 1;
	}

	// ftdic_latency_set = 1;

	/* Enter MPSSE (Multi-Protocol Synchronous Serial Engine) mode. Set all pins to output. */
	if (ftdi_set_bitmode(&ftdic, 0xff, BITMODE_MPSSE) < 0) {
		fprintf(stderr, "Failed to set BITMODE_MPSSE on iCE FTDI USB device.\n");
		error(2);
	}

   //enable clock divide by 5 ==> 6MHz
   send_byte(MC_TCK_D5);

   //divides by value+1
	send_byte(MC_SET_CLK_DIV);
	send_byte(0);
	send_byte(0x01);
   //so, 6/2 MHz ==> 3MHz

	usleep(100);

	sram_chip_select();
	usleep(2000);

   return 0;
}

int spi_send(uint8_t cmd, uint8_t val[3], uint8_t *status)
{
   uint8_t to_send[] = {cmd, val[0], val[1], val[2]};
   uint8_t status_recv = 0;
   uint32_t retries = 0;

   do{
      // usleep(2);
      xfer_spi(to_send, 4);
      status_recv = to_send[0];
      retries++;
   } while(retries < 100 && (status_recv & STATUS_FPGA_RECV_MASK) == 0);

   if(status != NULL)
   {
      *status = status_recv;
   }

   return retries < 100;
}

int spi_read(uint8_t val[3], uint8_t *status)
{
   uint8_t nop_command[] = {0x00, 0x00, 0x00, 0x00}; //nop
   uint8_t status_recv = 0;
   uint32_t retries = 0;

   do{
      usleep(2);
      xfer_spi(nop_command, 4);
      status_recv = nop_command[0];
      retries++;
   } while(retries < 100 && (status_recv & STATUS_FPGA_SEND_MASK) == 0 );

   val[0] = nop_command[1];
   val[1] = nop_command[2];
   val[2] = nop_command[3];

   if(status != NULL){
      *status = status_recv;
   }

   return retries < 100;
}
