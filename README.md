# Ethernet for STM32

> eth_stm32

This repository contains the source code for the Ethernet driver for the
STM32F4x and higher. It has two crates and an example. Crates:

* [eth_stm32](eth_stm32) - Ethernet driver for
  [ethernet](https://github.com/reznikmm/ethernet)
  provides MDIO (Management Data Input/Output) also known as SMI (Station
  Management Interface) interface. With it you can control PHYs attached
  to your board, do reset, find link status and parameters, read/write
  MII registers.

* [enet_stm32](enet_stm32) - Ethernet driver for
  [enet](https://github.com/stcarrez/ada-enet) provides MAC interface.
  It lets you send and receive packets, so with help of `enet` you can
  have IPv4, ICMP, UDP, ARP, DNS, DHCPv4, NTP protocols on you STM32
  based board.

* [ping](examples)/ping - The example demonstrates how to send and
  receive ICMP Echo requests on
  [stm32f4xx_m](https://stm32-base.org/boards/STM32F407VGT6-STM32F4XX-M.html)
  with PHY [LAN9303](https://www.microchip.com/en-us/product/LAN9303)
  attached.

## Install

To install this software use the custom Alire index:

  ```sh
  alr index --add git+https://github.com/reznikmm/stm32-alire-index --name stm32
  ```

* To install `eth_stm32` use Alire:

  ```sh
  alr with eth_stm32
  ```

* To install `enet_stm32` use Alire:

  ```sh
  alr with enet_stm32
  ```

## Usage

* `eth_stm32`: declare an object of `Ethernet.STM32_MDIO.STM32_SMI` type,
  initialize it and use to control PHYs attached to your board.

  ```ada
     STM32_MDIO : aliased Ethernet.STM32_MDIO.STM32_SMI;
  begin
     STM32_MDIO.Initialize
       (MDC  => STM32.Device.PC1,
        MDIO => STM32.Device.PA2);

      Ethernet.PHY_Management.Reset
        (MDIO    => STM32_MDIO,
         PHY     => 0,  --  Id of the attached PHY
         Success => Ok);
  ```

* `enet_stm32`: declare an object of `Net.STM32_Interfaces.STM32_Ifnet` type,
  configure pins, initialize it and use to send and receive packets.

  ```ada
     STM32_MAC : aliased Net.STM32_Interfaces.STM32_Ifnet;

     Pins : constant STM32.GPIO.GPIO_Points :=
       (STM32.Device.PA1,    --  RMII_REF_CLK
        STM32.Device.PA2,    --  RMII_MDIO
        STM32.Device.PA7,    --  RMII_CRS_DV
        STM32.Device.PB11,   --  RMII_TX_EN
        STM32.Device.PB12,   --  RMII_TXD0
        STM32.Device.PB13,   --  RMII_TXD1
        STM32.Device.PC1,    --  RMII_MDC
        STM32.Device.PC4,    --  RMII_RXD0
        STM32.Device.PC5);   --  RMII_RXD1
  begin
      STM32_MAC.Configure (Pins, RMII => True);
      STM32_MAC.Initialize;
  ```

* `ping`: Attach LAN9303 to stm32f4xx_m board connecting:
  * `PA1` connect to `RMII_REF_CLK`
  * `PA2` connect to `RMII_MDIO`
  * `PA7` connect to `RMII_CRS_DV`
  * `PB11` connect to `RMII_TX_EN`
  * `PB12` connect to `RMII_TXD0`
  * `PB13` connect to `RMII_TXD1`
  * `PC1` connect to `RMII_MDC`
  * `PC4` connect to `RMII_RXD0`
  * `PC5` connect to `RMII_RXD1`

  Compile, flash and run `ping` example under debugger to see Ada.Text_IO
  output.

## Implementation details

Both drivers uses STM32 registers, so they depend on `STM32.*`
and `STM32_SVD.*` packages. However, there is currently no crate
that offers these packages. So `eth_stm32` and `enet_stm32` crates
depend on a "virtual" `stm32` crate. The idea is that any STM32
based board will provide `stm32` crate and `stm32.gpr` project
through `provides = ["stm32=1.0"]` clause in its `alire.toml`.
See `alire.toml` for
[stm32f4xx_m](https://github.com/reznikmm/Ada_Drivers_Library/tree/stm32f4xx_m_bsp)
as an example. Currently Alire requires an index to make `provides`
works (I mean that `alr pin stm32f4xx_m --use=<path>` does not work).

## Maintainer

[@MaximReznik](https://github.com/reznikmm).

## License

[Apache-2.0 WITH LLVM-exception](LICENSES/) © Maxim Reznik
