--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Net.Sockets.Udp;

package Network.UDP_Echo_Sockets is

   type UDP_Echo_Socket is new Net.Sockets.Udp.Socket with private;

   procedure Bind
     (Self : access UDP_Echo_Socket;
      Addr : Net.Sockets.Sockaddr_In);

private

   type UDP_Echo_Socket is new Net.Sockets.Udp.Socket with null record;

   overriding procedure Receive
     (Self   : in out UDP_Echo_Socket;
      From   : Net.Sockets.Sockaddr_In;
      Packet : in out Net.Buffers.Buffer_Type);

end Network.UDP_Echo_Sockets;
