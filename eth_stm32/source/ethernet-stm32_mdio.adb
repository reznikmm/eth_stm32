--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Real_Time;

with Interfaces.STM32.RCC;
with Interfaces.STM32.GPIO;

package body Ethernet.STM32_MDIO is

   Eth : Ethernet.STM32_MDIO_SVD.Ethernet.Ethernet_MAC_Peripheral renames
     Ethernet.STM32_MDIO_SVD.Ethernet.Ethernet_MAC_Periph;

   procedure Configure_Pin
     (Port : Pin_Port;
      Pin  : Pin_Index);

   procedure Configure_GPIO_Pin
     (Port : in out Interfaces.STM32.GPIO.GPIO_Peripheral;
      Pin  : Pin_Index);

   ------------------------
   -- Configure_GPIO_Pin --
   ------------------------

   procedure Configure_GPIO_Pin
     (Port : in out Interfaces.STM32.GPIO.GPIO_Peripheral;
      Pin  : Pin_Index)
   is
      AF : constant := 11;  --  Alternate Function: Eth
   begin
      Port.MODER.Arr (Pin) := 2;  --  AF
      Port.PUPDR.Arr (Pin) := 0;  --  Floating
      Port.OTYPER.OT.Arr (Pin) := 0; --  Open drain: no
      Port.OSPEEDR.Arr (Pin) := 3; --  Very high speed

      if Pin in Port.AFRL.Arr'Range then
         Port.AFRL.Arr (Pin) := AF;
      else
         Port.AFRH.Arr (Pin) := AF;
      end if;
   end Configure_GPIO_Pin;

   -------------------
   -- Configure_Pin --
   -------------------

   procedure Configure_Pin
     (Port : Pin_Port;
      Pin  : Pin_Index) is
   begin
      case Port is
         when 'A' =>
            Interfaces.STM32.RCC.RCC_Periph.AHB1ENR.GPIOAEN := 1;
            Configure_GPIO_Pin (Interfaces.STM32.GPIO.GPIOA_Periph, Pin);
         when 'C' =>
            Interfaces.STM32.RCC.RCC_Periph.AHB1ENR.GPIOCEN := 1;
            Configure_GPIO_Pin (Interfaces.STM32.GPIO.GPIOC_Periph, Pin);
         when others =>
            raise Program_Error;  --  Unimplemented
      end case;
   end Configure_Pin;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self      : in out STM32_SMI'Class;
      MDIO_Port : Pin_Port := 'A';
      MDIO_Pin  : Pin_Index := 2;
      MDC_Port  : Pin_Port := 'C';
      MDC_Pin   : Pin_Index := 1;
      HCLK      : System.STM32.Frequency := System.STM32.System_Clocks.HCLK) is
   begin
      Configure_Pin (MDIO_Port, MDIO_Pin);
      Configure_Pin (MDC_Port, MDC_Pin);
      Self.Set_Clock_Frequency (HCLK);
      Interfaces.STM32.RCC.RCC_Periph.AHB1ENR.ETHMACEN := 1;  --  True
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
