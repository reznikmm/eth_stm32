--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;
with Interfaces;

with Net.Headers;
with Net.Protos.Icmp;
with Net.Utils;

with STM32.Device;
with STM32.GPIO;

with Ethernet.PHY_Management;

with Network.Receiver;

package body Network is

   package LAN_Receiver is new Network.Receiver
     (Net.Interfaces.Ifnet_Type'Class (STM32_MAC));

   procedure ICMP_Handler
     (Ifnet  : in out Net.Interfaces.Ifnet_Type'Class;
      Packet : in out Net.Buffers.Buffer_Type)
   is
      use type Net.Uint8;
      IP : constant Net.Headers.IP_Header_Access := Packet.IP;
      ICMP : constant Net.Headers.ICMP_Header_Access := Packet.ICMP;
   begin
      if ICMP.Icmp_Type = Net.Headers.ICMP_ECHO_REPLY then
         Ada.Text_IO.Put (Packet.Get_Length'Image);
         Ada.Text_IO.Put (" bytes from ");
         Ada.Text_IO.Put (Net.Utils.To_String (IP.Ip_Src));
         Ada.Text_IO.Put (" seq=");
         Ada.Text_IO.Put (Net.Headers.To_Host (ICMP.Icmp_Seq)'Image);
         Ada.Text_IO.New_Line;
      else
         Net.Protos.Icmp.Receive (Ifnet, Packet);
      end if;
   end ICMP_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type Interfaces.Unsigned_32;

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

      function Read_LAN_9303
        (Reg : Interfaces.Unsigned_16) return Interfaces.Unsigned_32;

      -------------------
      -- Read_LAN_9303 --
      -------------------

      function Read_LAN_9303
        (Reg : Interfaces.Unsigned_16) return Interfaces.Unsigned_32
      is
         use type Interfaces.Unsigned_16;
         use type Ethernet.MDIO.Register_Index;

         Ok       : Boolean;
         Low      : Interfaces.Unsigned_16;
         High     : Interfaces.Unsigned_16;

         Phy      : constant Ethernet.MDIO.PHY_Index :=
           Ethernet.MDIO.PHY_Index (Reg / 2 ** 6 + 16#10#);

         Register : constant Ethernet.MDIO.Register_Index :=
           Ethernet.MDIO.Register_Index ((Reg / 2) and 16#1E#);
      begin
         STM32_MDIO.Read_Register (Phy, Register, Low, Ok);
         STM32_MDIO.Read_Register (Phy, Register + 1, High, Ok);

         return 2**16 * Interfaces.Unsigned_32 (High)
           + Interfaces.Unsigned_32 (Low);
      end Read_LAN_9303;

      Ok : Boolean;
   begin
      STM32_MDIO.Initialize
        (MDC  => STM32.Device.PC1,
         MDIO => STM32.Device.PA2);

      pragma Assert (Read_LAN_9303 (16#64#) = 16#8765_4321#);
      pragma Assert (Read_LAN_9303 (16#50#) / 2 ** 16 = 16#9303#);

      Ethernet.PHY_Management.Reset
        (MDIO    => STM32_MDIO,
         PHY     => 0,
         Success => Ok);

      --  Enable CLK_REF on LAN9303
      declare
         use type Interfaces.Unsigned_16;

         Clock_In : constant Interfaces.Unsigned_16 := 2**6;
         Data     : Interfaces.Unsigned_16;
      begin
         STM32_MDIO.Read_Register
           (PHY      => 0,
            Register => 31,
            Value    => Data,
            Success  => Ok);

         STM32_MDIO.Write_Register
           (PHY      => 0,
            Register => 31,
            Value    => Data or Clock_In,
            Success  => Ok);

         declare
            CLK : constant Boolean := STM32.Device.PA1.Set;
         begin
            for J in 1 .. 1000 loop
               if CLK /= STM32.Device.PA1.Set then
                  exit;
               end if;
            end loop;
         end;
      end;

      STM32_MAC.Configure (Pins, RMII => True);
      STM32_MAC.Initialize;
      LAN_Receiver.Start;
      DHCP.Initialize (STM32_MAC'Access);
   end Initialize;

end Network;
