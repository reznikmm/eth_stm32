--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;

package body Network.UDP_Echo_Sockets is

   procedure Bind
     (Self : access UDP_Echo_Socket;
      Addr : Net.Sockets.Sockaddr_In) is
   begin
      Self.Bind (STM32_MAC'Access, Addr);
   end Bind;

   overriding procedure Receive
     (Self   : in out UDP_Echo_Socket;
      From   : Net.Sockets.Sockaddr_In;
      Packet : in out Net.Buffers.Buffer_Type)
   is
      use all type Net.Error_Code;

      Error : Net.Error_Code;
   begin
      Self.Send
        (To       => From,
         Packet   => Packet,
         Status   => Error);

      if Error /= EOK then
         Ada.Text_IO.Put_Line ("Send error: " & Error'Image);
      end if;
   end Receive;

end Network.UDP_Echo_Sockets;
