--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ethernet.MDIO;
with Ethernet.STM32_MDIO;

with Net.Buffers;
with Net.DHCP;
with Net.Interfaces;
with Net.STM32_Interfaces;

package Network is

   procedure Initialize;

   function MDIO return not null Ethernet.MDIO.MDIO_Interface_Access;
   --  Station management interface (SMI or MDIO)

   function LAN return not null access Net.Interfaces.Ifnet_Type'Class;
   --  Network interface

   DHCP : Net.DHCP.Client;

   procedure ICMP_Handler
     (Ifnet  : in out Net.Interfaces.Ifnet_Type'Class;
      Packet : in out Net.Buffers.Buffer_Type);
   --  Custom ICMP handler to pring ICMP echo responses

private

   STM32_MDIO : aliased Ethernet.STM32_MDIO.STM32_SMI;

   STM32_MAC : aliased Net.STM32_Interfaces.STM32_Ifnet;

   function MDIO return not null Ethernet.MDIO.MDIO_Interface_Access is
     (STM32_MDIO'Access);

   function LAN return not null access Net.Interfaces.Ifnet_Type'Class is
     (STM32_MAC'Access);

end Network;
