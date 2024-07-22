-----------------------------------------------------------------------
--  net-interfaces-stm32 -- Ethernet driver for STM32F74x
--  Copyright (C) 2016-2024 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------

with Net.Buffers;
with Net.Interfaces;

package Net.STM32_Interfaces is

   type STM32_Ifnet is limited new Net.Interfaces.Ifnet_Type with null record;
   --  The STM32Fxx Ethernet driver.

   subtype Pin_Port is Character range 'A' .. 'I';
   subtype Pin_Index is Natural range 0 .. 15;
   type Pin_Index_Set is array (Pin_Index) of Boolean with Pack;
   type Pin_Set is array (Pin_Port) of Pin_Index_Set;

   procedure Configure
     (Self : in out STM32_Ifnet'Class;
      Pins : Pin_Set;
      RMII : Boolean := True);
   --  Reset and configure STM32 peripherals.
   --  Corresponding PHY should be configured before call this if needed to
   --  provide CLK_REF to STM32 chip.

   overriding procedure Initialize (Self : in out STM32_Ifnet);
   --  Initialize the network interface.

   overriding procedure Send
     (Self   : in out STM32_Ifnet;
      Packet : in out Net.Buffers.Buffer_Type);
   --  Send a packet to the interface.

   overriding procedure Receive
     (Self   : in out STM32_Ifnet;
      Packet : in out Net.Buffers.Buffer_Type);
   --  Receive a packet from the interface.

end Net.STM32_Interfaces;
