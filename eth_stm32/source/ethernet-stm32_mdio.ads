--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

pragma Warnings (Off, "is an internal GNAT unit");
with System.STM32;
pragma Warnings (On, "is an internal GNAT unit");

with Ethernet.MDIO;
private with Ethernet.STM32_MDIO_SVD.Ethernet;

package Ethernet.STM32_MDIO is

   type STM32_SMI is new Ethernet.MDIO.MDIO_Interface with private;
   --  Implementaion of MDIO_Interface for STM32 chips

   subtype Pin_Port is Character range 'A' .. 'I';
   subtype Pin_Index is Natural range 0 .. 15;

   procedure Initialize
     (Self      : in out STM32_SMI'Class;
      MDIO_Port : Pin_Port := 'A';
      MDIO_Pin  : Pin_Index := 2;
      MDC_Port  : Pin_Port := 'C';
      MDC_Pin   : Pin_Index := 1;
      HCLK      : System.STM32.Frequency := System.STM32.System_Clocks.HCLK);
   --  Initialize STM32 GPIO pins for MDIO and MDC signals using PA2, PC1 pins
   --  by default. Remember HCLK to be used in Read_Register/Write_Register.

   procedure Set_Clock_Frequency
     (Self : in out STM32_SMI'Class;
      HCLK : System.STM32.Frequency := System.STM32.System_Clocks.HCLK);
   --  Change HCLK to be used in Read_Register/Write_Register procedures.

   overriding procedure Read_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : out Interfaces.Unsigned_16;
      Success  : out Boolean);
   --  Read a register from a PHY. See MDIO_Interface type for details.

   overriding procedure Write_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : Interfaces.Unsigned_16;
      Success  : out Boolean);
   --  Write a value to a register of a PHY. See MDIO_Interface for details.

private

   type STM32_SMI is new Ethernet.MDIO.MDIO_Interface with record
      CR : Ethernet.STM32_MDIO_SVD.Ethernet.MACMIIAR_CR_Field := 0;
   end record;

end Ethernet.STM32_MDIO;
