--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Real_Time;
with Ada.Text_IO;

with Net.DHCP;
with Net.Headers;
with Net.Protos.Arp;
with Net.Utils;

with Network;
with Network.UDP_Echo_Sockets;

procedure Echo is
   Prev_DHCP_State : Net.DHCP.State_Type := Net.DHCP.STATE_INIT;

   Echo_Socket : aliased Network.UDP_Echo_Sockets.UDP_Echo_Socket;
begin
   Ada.Text_IO.Put_Line ("Boot");

   declare
      use type Ada.Real_Time.Time;

      Now        : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   begin
      delay until Now + Ada.Real_Time.Seconds (10);
   end;

   Network.Initialize;
   Echo_Socket.Bind
     ((Port => Net.Headers.To_Network (12345),
       Addr => (0, 0, 0, 0)));

   loop
      declare
         use type Ada.Real_Time.Time;
         use all type Net.DHCP.State_Type;

         Now        : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Ignore     : Ada.Real_Time.Time;
         DHCP_State : Net.DHCP.State_Type;
      begin
         --  STM32.Board.Green_LED.Toggle; PA1 is used by LAN!!!
         Net.Protos.Arp.Timeout (Network.LAN.all);
         Network.DHCP.Process (Ignore);
         DHCP_State := Network.DHCP.Get_State;

         if DHCP_State /= Prev_DHCP_State then
            Prev_DHCP_State := DHCP_State;
            Ada.Text_IO.Put_Line (DHCP_State'Image);

            if DHCP_State = STATE_BOUND then
               Ada.Text_IO.Put_Line
                 (Net.Utils.To_String
                    (Network.DHCP.Get_Config.Ip));
            end if;
         end if;

         delay until Now + Ada.Real_Time.Seconds (1);
      end;
   end loop;
end Echo;
