--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with STM32.Device;

with STM32_SVD.RCC;

with Ada.Real_Time;
--  with STM32_SVD.SYSCFG;

package body Ethernet.STM32_MDIO is

   Eth : STM32_SVD.Ethernet.Ethernet_MAC_Peripheral renames
     STM32_SVD.Ethernet.Ethernet_MAC_Periph;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self : in out STM32_SMI'Class;
      MDC  : STM32.GPIO.GPIO_Point;
      MDIO : STM32.GPIO.GPIO_Point;
      HCLK : System.STM32.Frequency := System.STM32.System_Clocks.HCLK)
   is
      Config : constant STM32.GPIO.GPIO_Port_Configuration :=
        (Mode           => STM32.GPIO.Mode_AF,
         AF_Output_Type => STM32.GPIO.Push_Pull,
         AF_Speed       => STM32.GPIO.Speed_100MHz,
         AF             => STM32.Device.GPIO_AF_ETH_11,
         Resistors      => STM32.GPIO.Floating);

   begin
      Self.Set_Clock_Frequency (HCLK);
      STM32.Device.Enable_Clock (MDC);
      STM32.Device.Enable_Clock (MDIO);
      MDC.Configure_IO (Config);
      MDIO.Configure_IO (Config);

      STM32_SVD.RCC.RCC_Periph.AHB1ENR.ETHMACEN := True;
   end Initialize;

   -------------------
   -- Read_Register --
   -------------------

   overriding procedure Read_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : out Interfaces.Unsigned_16;
      Success  : out Boolean)
   is
      use type Ada.Real_Time.Time;
   begin
      Eth.MACMIIAR :=
        (PA => Ethernet.MDIO.PHY_Index'Pos (PHY),  --  PHY address
         MR => Ethernet.MDIO.Register_Index'Pos (Register),  --  MII register
         CR => Self.CR,
         MB => True,  --  MII busy
         MW => False,  --  MII write
         others => <>);

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Microseconds (25);
      --  64 pulses at 2.5MHz takes 25.6 us

      for J in 1 .. 10_000 loop
         if not Eth.MACMIIAR.MB then
            Value := Interfaces.Unsigned_16 (Eth.MACMIIDR.TD);
            Success := True;
            return;
         end if;
      end loop;

      Value := 0;
      Success := False;
   end Read_Register;

   -------------------------
   -- Set_Clock_Frequency --
   -------------------------

   procedure Set_Clock_Frequency
     (Self : in out STM32_SMI'Class;
      HCLK : System.STM32.Frequency := System.STM32.System_Clocks.HCLK)
   is
      use type System.STM32.Frequency;
   begin
      Self.CR :=
        (case HCLK is
            when  60e6 .. 100e6 - 1 => 2#000#,   --  AHB clock / 42
            when 100e6 .. 150e6 - 1 => 2#001#,   --  AHB clock / 62
            when  20e6 ..  35e6 - 1 => 2#010#,   --  AHB clock / 16
            when  35e6 ..  60e6 - 1 => 2#011#,   --  AHB clock / 26
            when 150e6 .. 180e6 - 1 => 2#100#,   --  AHB clock / 102
            when others => raise Program_Error);
   end Set_Clock_Frequency;

   --------------------
   -- Write_Register --
   --------------------

   overriding procedure Write_Register
     (Self     : in out STM32_SMI;
      PHY      : Ethernet.MDIO.PHY_Index;
      Register : Ethernet.MDIO.Register_Index;
      Value    : Interfaces.Unsigned_16;
      Success  : out Boolean)
   is
      use type Ada.Real_Time.Time;
   begin
      Eth.MACMIIDR.TD := Interfaces.Unsigned_16'Pos (Value);

      Eth.MACMIIAR :=
        (PA => Ethernet.MDIO.PHY_Index'Pos (PHY),  --  PHY address
         MR => Ethernet.MDIO.Register_Index'Pos (Register),  --  MII register
         CR => Self.CR,
         MB => True,  --  MII busy
         MW => True,  --  MII write
         others => <>);

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Microseconds (25);
      --  64 pulses at 2.5MHz takes 25.6 us

      for J in 1 .. 10_000 loop
         if not Eth.MACMIIAR.MB then
            Success := True;
            return;
         end if;
      end loop;

      Success := False;
   end Write_Register;

end Ethernet.STM32_MDIO;
