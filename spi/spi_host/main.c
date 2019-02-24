#include <stdio.h>
#include <ftdi.h>

// ftdi initialization taken from iceprog https://github.com/cliffordwolf/icestorm/blob/master/iceprog/iceprog.c
// ---------------------------------------------------------
// MPSSE / FTDI definitions
// ---------------------------------------------------------

/* FTDI bank pinout typically used for iCE dev boards
 * BUS IO | Signal | Control
 * -------+--------+--------------
 * xDBUS0 |    SCK | MPSSE
 * xDBUS1 |   MOSI | MPSSE
 * xDBUS2 |   MISO | MPSSE
 * xDBUS3 |     nc |
 * xDBUS4 |     CS | GPIO
 * xDBUS5 |     nc |
 * xDBUS6 |  CDONE | GPIO
 * xDBUS7 | CRESET | GPIO
 */

static struct ftdi_context ftdic;
static int ftdic_open = 0; //false
static int verbose = 0; //false
static int ftdic_latency_set = 0; //false
static unsigned char ftdi_latency;

/* MPSSE engine command definitions */
enum mpsse_cmd
{
	/* Mode commands */
	MC_SETB_LOW = 0x80, /* Set Data bits LowByte */
	MC_READB_LOW = 0x81, /* Read Data bits LowByte */
	MC_SETB_HIGH = 0x82, /* Set Data bits HighByte */
	MC_READB_HIGH = 0x83, /* Read data bits HighByte */
	MC_LOOPBACK_EN = 0x84, /* Enable loopback */
	MC_LOOPBACK_DIS = 0x85, /* Disable loopback */
	MC_SET_CLK_DIV = 0x86, /* Set clock divisor */
	MC_FLUSH = 0x87, /* Flush buffer fifos to the PC. */
	MC_WAIT_H = 0x88, /* Wait on GPIOL1 to go high. */
	MC_WAIT_L = 0x89, /* Wait on GPIOL1 to go low. */
	MC_TCK_X5 = 0x8A, /* Disable /5 div, enables 60MHz master clock */
	MC_TCK_D5 = 0x8B, /* Enable /5 div, backward compat to FT2232D */
	MC_EN_3PH_CLK = 0x8C, /* Enable 3 phase clk, DDR I2C */
	MC_DIS_3PH_CLK = 0x8D, /* Disable 3 phase clk */
	MC_CLK_N = 0x8E, /* Clock every bit, used for JTAG */
	MC_CLK_N8 = 0x8F, /* Clock every byte, used for JTAG */
	MC_CLK_TO_H = 0x94, /* Clock until GPIOL1 goes high */
	MC_CLK_TO_L = 0x95, /* Clock until GPIOL1 goes low */
	MC_EN_ADPT_CLK = 0x96, /* Enable adaptive clocking */
	MC_DIS_ADPT_CLK = 0x97, /* Disable adaptive clocking */
	MC_CLK8_TO_H = 0x9C, /* Clock until GPIOL1 goes high, count bytes */
	MC_CLK8_TO_L = 0x9D, /* Clock until GPIOL1 goes low, count bytes */
	MC_TRI = 0x9E, /* Set IO to only drive on 0 and tristate on 1 */
	/* CPU mode commands */
	MC_CPU_RS = 0x90, /* CPUMode read short address */
	MC_CPU_RE = 0x91, /* CPUMode read extended address */
	MC_CPU_WS = 0x92, /* CPUMode write short address */
	MC_CPU_WE = 0x93, /* CPUMode write extended address */
};

#define MC_DATA_TMS  (0x40) /* When set use TMS mode */
#define MC_DATA_IN   (0x20) /* When set read data (Data IN) */
#define MC_DATA_OUT  (0x10) /* When set write data (Data OUT) */
#define MC_DATA_LSB  (0x08) /* When set input/output data LSB first. */
#define MC_DATA_ICN  (0x04) /* When set receive data on negative clock edge */
#define MC_DATA_BITS (0x02) /* When set count bits not bytes */
#define MC_DATA_OCN  (0x01) /* When set update data on negative clock edge */


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
	//send_byte(MC_DATA_IN | MC_DATA_OUT | MC_DATA_LSB | MC_DATA_OCN);
	send_byte(MC_DATA_IN | MC_DATA_OUT | MC_DATA_LSB);
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

int spi_send_data(uint8_t command, uint8_t data0, uint8_t data1, uint8_t *status_recv)
{
   uint8_t to_send[] = {command, data0, data1};

   xfer_spi(to_send, 3);

   *status_recv = to_send[0];

   return 0;
}

int spi_read_data(uint8_t command, uint8_t *data0, uint8_t *data1, uint8_t *status_recv)
{
   uint8_t to_send[] = {command, 0x00, 0x00};

   xfer_spi(to_send, 3);

   uint8_t nop_command[] = {0x00, 0x00, 0x00}; //nop

   xfer_spi(nop_command, 3);

   *status_recv = nop_command[0];
   *data0 = nop_command[1];
   *data1 = nop_command[2];

   return 0;
}

int main()
{

   // ftdi initialization taken from iceprog https://github.com/cliffordwolf/icestorm/blob/master/iceprog/iceprog.c
   enum ftdi_interface ifnum = INTERFACE_A;
   int status = 0;

   printf("init..\n");

   status = ftdi_init(&ftdic);
	if( status != 0)
   {
      printf("couldn't initalize ftdi\n");
      return 0;
   }

	status = ftdi_set_interface(&ftdic, ifnum);
   if(status != 0)
   {
      printf("couldn't initalize ftdi interface\n");
      return 0;
   }

   if (ftdi_usb_open(&ftdic, 0x0403, 0x6010) && ftdi_usb_open(&ftdic, 0x0403, 0x6014)) {
		printf("Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).\n");
		return 0;
	}

   if (ftdi_usb_reset(&ftdic)) {
		fprintf(stderr, "Failed to reset iCE FTDI USB device.\n");
		error(2);
	}

	if (ftdi_usb_purge_buffers(&ftdic)) {
		fprintf(stderr, "Failed to purge buffers on iCE FTDI USB device.\n");
		error(2);
	}

	if (ftdi_get_latency_timer(&ftdic, &ftdi_latency) < 0) {
		fprintf(stderr, "Failed to get latency timer (%s).\n", ftdi_get_error_string(&ftdic));
		error(2);
	}

	/* 1 is the fastest polling, it means 1 kHz polling */
	if (ftdi_set_latency_timer(&ftdic, 1) < 0) {
		fprintf(stderr, "Failed to set latency timer (%s).\n", ftdi_get_error_string(&ftdic));
		error(2);
	}

	// ftdic_latency_set = 1;

	/* Enter MPSSE (Multi-Protocol Synchronous Serial Engine) mode. Set all pins to output. */
	if (ftdi_set_bitmode(&ftdic, 0xff, BITMODE_MPSSE) < 0) {
		fprintf(stderr, "Failed to set BITMODE_MPSSE on iCE FTDI USB device.\n");
		error(2);
	}

   //enable clock divide by 5
   send_byte(MC_TCK_D5);
   //6Mhz
	send_byte(MC_SET_CLK_DIV);
	send_byte(0);
	send_byte(0x00);

	usleep(100);

	sram_chip_select();
	usleep(2000);

   uint8_t spi_status = 0;
   uint8_t data0, data1;
   uint8_t val_inv0 = 0x38, val_inv1 = 0xAE;

   spi_send_data(0x01, 0x00, 0x00, &spi_status); // init

   usleep(2000);

   spi_send_data(0x02, val_inv0, val_inv1, &spi_status); // send values bit inversion
   printf("send inversion data, status: 0x%x\n", spi_status);

   usleep(2000);

   spi_read_data(0x03, &data0, &data1, &spi_status); // read data inversion
   printf("bit inversion read: 0x%x, 0x%x, should be 0x%x, 0x%x, status: 0x%x\n", data1, data0, 0xFF&~val_inv1, 0xFF&~val_inv0, spi_status);

   usleep(2000);

   spi_send_data(0x04, 0x00, 0x03, &spi_status); // led yellow
   printf("send yellow led, status: 0x%x\n", spi_status);

   usleep(2000);

   spi_read_data(0x05, &data0, &data1, &spi_status); // read led data
   printf("led_data read: 0x%x, 0x%x, status:0x%x\n", data1, data0, spi_status);

   usleep(2000*1000);

   spi_send_data(0x04, 0x00, 0x04, &spi_status); // set led blue
   printf("send blue led, status: 0x%x\n", spi_status);

   return 0;
}
