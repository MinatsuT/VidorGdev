
         // system signals
         input         iCLK,
         input         iRESETn,
         input         iSAM_INT,
         output        oSAM_INT,

         // SDRAM
         output        oSDRAM_CLK,
         output [11:0] oSDRAM_ADDR,
         output [1:0]  oSDRAM_BA,
         output        oSDRAM_CASn,
         output        oSDRAM_CKE,
         output        oSDRAM_CSn,
         inout  [15:0] bSDRAM_DQ,
         output [1:0]  oSDRAM_DQM,
         output        oSDRAM_RASn,
         output        oSDRAM_WEn,

         // SAM D21 PINS
         inout         bMKR_AREF,
         inout  [6:0]  bMKR_A,
         inout  [14:0] bMKR_D,

         // Mini PCIe
         inout         bPEX_RST,
         inout         bPEX_PIN6,
         inout         bPEX_PIN8,
         inout         bPEX_PIN10,
         input         iPEX_PIN11,
         inout         bPEX_PIN12,
         input         iPEX_PIN13,
         inout         bPEX_PIN14,
         inout         bPEX_PIN16,
         inout         bPEX_PIN20,
         input         iPEX_PIN23,
         input         iPEX_PIN25,
         inout         bPEX_PIN28,
         inout         bPEX_PIN30,
         input         iPEX_PIN31,
         inout         bPEX_PIN32,
         input         iPEX_PIN33,
         inout         bPEX_PIN42,
         inout         bPEX_PIN44,
         inout         bPEX_PIN45,
         inout         bPEX_PIN46,
         inout         bPEX_PIN47,
         inout         bPEX_PIN48,
         inout         bPEX_PIN49,
         inout         bPEX_PIN51,

         // NINA interface
         inout         bWM_PIO1,
         inout         bWM_PIO2,
         inout         bWM_PIO3,
         inout         bWM_PIO4,
         inout         bWM_PIO5,
         inout         bWM_PIO7,
         inout         bWM_PIO8,
         inout         bWM_PIO18,
         inout         bWM_PIO20,
         inout         bWM_PIO21,
         inout         bWM_PIO27,
         inout         bWM_PIO28,
         inout         bWM_PIO29,
         inout         bWM_PIO31,
         input         iWM_PIO32,
         inout         bWM_PIO34,
         inout         bWM_PIO35,
         inout         bWM_PIO36,
         input         iWM_TX,
         inout         oWM_RX,
         inout         oWM_RESET,

         // HDMI output
         output [2:0]  oHDMI_TX,
         output        oHDMI_CLK,

         inout         bHDMI_SDA,
         inout         bHDMI_SCL,

         input         iHDMI_HPD,

         // MIPI input
         input  [1:0]  iMIPI_D,
         input         iMIPI_CLK,
         inout         bMIPI_SDA,
         inout         bMIPI_SCL,
         inout  [1:0]  bMIPI_GP,

         // Q-SPI Flash interface
         output        oFLASH_SCK,
         output        oFLASH_CS,
         inout         oFLASH_MOSI,
         inout         iFLASH_MISO,
         inout         oFLASH_HOLD,
         inout         oFLASH_WP

