#ifndef SPI_LIB_H
#define SPI_LIB_H
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

#define STATUS_RECV_OFFSET 6
#define STATUS_SEND_OFFSET 7

#define STATUS_RECV_MASK (0x1<<STATUS_RECV_OFFSET)
#define STATUS_SEND_MASK (0x1<<STATUS_SEND_OFFSET)

//init spi comm, returns 0 if there is no problem
int spi_init();

int spi_send(uint8_t cmd, uint8_t val[3], uint8_t *status);

int spi_read(uint8_t val[3], uint8_t *status);

#endif
