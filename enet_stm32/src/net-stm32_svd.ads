--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with System;

pragma Warnings (Off, "is an internal GNAT unit");
with Interfaces.STM32;
pragma Warnings (On, "is an internal GNAT unit");

package Net.STM32_SVD is
   pragma Preelaborate;

   Ethernet_DMA_Base : System.Address renames
     Interfaces.STM32.Ethernet_DMA_Base;

   Ethernet_MAC_Base : System.Address renames
     Interfaces.STM32.Ethernet_MAC_Base;

   Ethernet_MMC_Base : System.Address renames
     Interfaces.STM32.Ethernet_MMC_Base;

   Ethernet_PTP_Base : System.Address renames
     Interfaces.STM32.Ethernet_PTP_Base;

end Net.STM32_SVD;
