--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

pragma Warnings (Off, "is an internal GNAT unit");
with System.STM32;
pragma Warnings (On, "is an internal GNAT unit");

with STM32.GPIO;
with STM32_SVD.Ethernet;

with Ethernet.MDIO;

package Ethernet.STM32_MDIO is

   type STM32_SMI is new Ethernet.MDIO.MDIO_Interface with private;

   procedure Initialize
     (Self : in out STM32_SMI'Class;
      MDC  : STM32.GPIO.GPIO_Point;
      MDIO : STM32.GPIO.GPIO_Point;
      HCLK : System.STM32.Frequency := System.STM32.System_Clocks.HCLK);

   procedure Set_Clock_Frequency
     (Self : in out STM32_SMI'Class;
      HCLK : System.STM32.Frequency := System.STM32.System_Clocks.HCLK);

   overriding procedure Read_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : out Interfaces.Unsigned_16;
      Success  : out Boolean);

   overriding procedure Write_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : Interfaces.Unsigned_16;
      Success  : out Boolean);

private

   type STM32_SMI is new Ethernet.MDIO.MDIO_Interface with record
      CR : STM32_SVD.Ethernet.MACMIIAR_CR_Field := 0;
   end record;

end Ethernet.STM32_MDIO;
