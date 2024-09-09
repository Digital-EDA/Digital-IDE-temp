--------------------------------------------------------------------------------
-- (c) Copyright 2011 - 2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
-- Description:
-- This is an example testbench for the Divider Generator IP core.
-- The testbench has been generated by Vivado to accompany the IP core
-- instance you have generated.
--
-- This testbench is for demonstration purposes only.  See note below for
-- instructions on how to use it with your core.
--
-- See the Divider Generator product guide for further information
-- about this core.
--
--------------------------------------------------------------------------------
-- Using this testbench
--
-- This testbench instantiates your generated Divider Generator core
-- instance named "div_gen_div_gen_0_0".
--
-- Use Vivado's Run Simulation flow to run this testbench.  See the Vivado
-- documentation for details.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_div_gen_div_gen_0_0 is
end tb_div_gen_div_gen_0_0;

architecture tb of tb_div_gen_div_gen_0_0 is

  -----------------------------------------------------------------------
  -- Timing constants
  -----------------------------------------------------------------------
  constant CLOCK_PERIOD : time := 100 ns;
  constant T_HOLD       : time := 10 ns;
  constant T_STROBE     : time := CLOCK_PERIOD - (1 ns);
  constant TEST_CYCLES  : integer := 3000;
  constant PHASE_CYCLES : integer := 1000;

  -----------------------------------------------------------------------
  -- DUT input signals
  -----------------------------------------------------------------------

  -- General inputs
  signal aclk               : std_logic := '0';  -- the master clock

  -- Slave channel DIVIDEND inputs
  signal s_axis_dividend_tvalid    : std_logic := '0';  -- TVALID for channel A
  signal s_axis_dividend_tdata     : std_logic_vector(31 downto 0) := (others => 'X');  -- TDATA for channel A

  -- Slave channel DIVISOR inputs
  signal s_axis_divisor_tvalid    : std_logic := '0';  -- TVALID for channel B
  signal s_axis_divisor_tdata     : std_logic_vector(23 downto 0) := (others => 'X');  -- TDATA for channel B


  -- Breakout signals. These signals are the application-specific operands which
  -- become subfields of the TDATA fields.
  signal dividend : std_logic_vector(31 downto 0) := (others => '0');
  signal divisor  : std_logic_vector(23 downto 0) := (others => '0');
  signal quotient : std_logic_vector(31 downto 0) := (others => '0');
  signal fractional : std_logic_vector(23 downto 0) := (others => '0');
  -----------------------------------------------------------------------
  -- DUT output signals
  -----------------------------------------------------------------------

  -- Master channel DOUT outputs
  signal m_axis_dout_tvalid : std_logic := '0';  -- TVALID for channel DOUT
  signal m_axis_dout_tdata  : std_logic_vector(55 downto 0) := (others => '0');  -- TDATA for channel DOUT

  -----------------------------------------------------------------------
  -- Testbench signals
  -----------------------------------------------------------------------

  signal cycles       : integer   := 0;    -- Clock cycle counter

  -----------------------------------------------------------------------
  -- Constants, types and functions to create input data
  -- Feed the divider walking ones on the dividend and walking one's with the
  -- LSB set so as to show simple results which will still use remainder and fraction,
  -- e.g. 8/5.
  -----------------------------------------------------------------------

  constant IP_dividend_DEPTH : integer := 30;
  constant IP_dividend_WIDTH : integer := 32;
  constant IP_divisor_DEPTH : integer := 32;
  constant IP_divisor_WIDTH : integer := 24;
  subtype T_IP_dividend_ENTRY is std_logic_vector(IP_dividend_WIDTH-1 downto 0);
  subtype T_IP_divisor_ENTRY is std_logic_vector(IP_divisor_WIDTH-1 downto 0);
  type T_IP_dividend_TABLE is array (0 to IP_dividend_DEPTH-1) of T_IP_dividend_ENTRY;
  type T_IP_divisor_TABLE is array (0 to IP_divisor_DEPTH-1) of T_IP_divisor_ENTRY;

  -- Use separate functions to calculate channel dividend and divisor
  -- waveforms as they return different widths in general
  function create_ip_dividend_table return T_IP_dividend_TABLE is
    variable result : T_IP_dividend_TABLE;
    variable entry_int : signed(IP_dividend_WIDTH-1 downto 0) := (others => '0');
  begin
    for i in 0 to IP_dividend_DEPTH-1 loop
      entry_int := (others => '0');
      entry_int(i mod IP_dividend_WIDTH) := '1';
      result(i) := std_logic_vector(entry_int);
    end loop;
    return result;
  end function create_ip_dividend_table;

  function create_ip_divisor_table return T_IP_divisor_TABLE is
    variable result : T_IP_divisor_TABLE;
    variable entry_int : signed(IP_divisor_WIDTH-1 downto 0) := (others => '0');
  begin
    for i in 0 to IP_divisor_DEPTH-1 loop
      entry_int := (others => '0');
      entry_int(0) := '1';
      entry_int(i mod IP_divisor_WIDTH) := '1';
      result(i) := std_logic_vector(entry_int);
    end loop;
    return result;
  end function create_ip_divisor_table;

  -- Call the functions to create the data
  constant IP_dividend_DATA : T_IP_dividend_TABLE := create_ip_dividend_table;
  constant IP_divisor_DATA  : T_IP_divisor_TABLE  := create_ip_divisor_table;

  -- Drive zeros when data is invalid to avoid simulator warnings
  constant INVALID : std_logic := '0';
begin

  -----------------------------------------------------------------------
  -- Instantiate the DUT
  -----------------------------------------------------------------------

  dut : entity work.div_gen_div_gen_0_0
    port map (
      aclk                => aclk,
      s_axis_dividend_tvalid     => s_axis_dividend_tvalid,
      s_axis_dividend_tdata      => s_axis_dividend_tdata,
      s_axis_divisor_tvalid     => s_axis_divisor_tvalid,
      s_axis_divisor_tdata      => s_axis_divisor_tdata,
      m_axis_dout_tvalid  => m_axis_dout_tvalid,
      m_axis_dout_tdata   => m_axis_dout_tdata
      );

  -----------------------------------------------------------------------
  -- Generate clock
  -----------------------------------------------------------------------

  clock_gen : process
  begin
    aclk <= '0';
    wait for CLOCK_PERIOD;
    loop
      cycles <= cycles + 1;
      aclk <= '0';
      wait for CLOCK_PERIOD/2;
      aclk <= '1';
      wait for CLOCK_PERIOD/2;
      if cycles >= TEST_CYCLES then    
        report "Not a real failure. Simulation finished successfully. Test completed successfully" severity failure;
        wait;
      end if;
    end loop;
  end process clock_gen;

  -----------------------------------------------------------------------
  -- Generate inputs
  -----------------------------------------------------------------------

  stimuli : process
    variable ip_dividend_index       : integer   := 0;
    variable ip_divisor_index       : integer   := 0;
    variable dividend_tvalid_nxt     : std_logic := '0';
    variable divisor_tvalid_nxt     : std_logic := '0';
    variable phase2_cycles : integer := 1;
    variable phase2_count  : integer := 0;
    constant PHASE2_LIMIT  : integer := 30;
  begin

    -- Test is stopped in clock_gen process, use endless loop here
    loop

      -- Drive inputs T_HOLD time after rising edge of clock
      wait until rising_edge(aclk);
      wait for T_HOLD;

      -- Drive AXI TVALID signals to demonstrate different types of operation
      case cycles is  -- do different types of operation at different phases of the test
        when 0 to PHASE_CYCLES * 1 - 1 =>
          -- Phase 1: inputs always valid, no missing input data
          dividend_tvalid_nxt    := '1';
          divisor_tvalid_nxt    := '1';
        when PHASE_CYCLES * 1 to PHASE_CYCLES * 2 - 1 =>
          -- Phase 2: deprive channel A of valid transactions at an increasing rate
          divisor_tvalid_nxt    := '1';
          if phase2_count < phase2_cycles then
            dividend_tvalid_nxt := '0';
          else
            dividend_tvalid_nxt := '1';
          end if;
          phase2_count := phase2_count + 1;
          if phase2_count >= PHASE2_LIMIT then
            phase2_count  := 0;
            phase2_cycles := phase2_cycles + 1;
          end if;
        when PHASE_CYCLES * 2 to PHASE_CYCLES * 3 - 1 =>
          -- Phase 3: deprive channel A of 1 out of 2 transactions, and channel B of 1 out of 3 transactions
          if cycles mod 2 = 0 then
            dividend_tvalid_nxt := '0';
          else
            dividend_tvalid_nxt := '1';
          end if;
          if cycles mod 3 = 0 then
            divisor_tvalid_nxt := '0';
          else
            divisor_tvalid_nxt := '1';
          end if;
        when others =>
          -- Test will stop imminently - do nothing
          null;
      end case;

      -- Drive handshake signals with local variable values
      s_axis_dividend_tvalid <= dividend_tvalid_nxt;
      s_axis_divisor_tvalid <= divisor_tvalid_nxt;

      -- Drive AXI slave channel A payload
      -- Drive 'X's on payload signals when not valid
      if dividend_tvalid_nxt /= '1' then
        s_axis_dividend_tdata <= (others => INVALID);
      else
        -- TDATA: This holds the dividend operand. It is 32 bits wide and byte-aligned with the operand in the LSBs
        s_axis_dividend_tdata <= std_logic_vector(resize(signed(IP_dividend_DATA(ip_dividend_index)),32));
      end if;

      -- Drive AXI slave channel B payload
      -- Drive 'X's on payload signals when not valid
      if divisor_tvalid_nxt /= '1' then
        s_axis_divisor_tdata <= (others => INVALID);
      else
        -- TDATA: Holds the divisor operand. It is 24 bits wide and byte-aligned with the operand in the LSBs
            s_axis_divisor_tdata <= std_logic_vector(resize(signed(IP_divisor_DATA(ip_divisor_index)),24));
      end if;

      -- Increment input data indices
      if dividend_tvalid_nxt = '1' then
        ip_dividend_index := ip_dividend_index + 1;
        if ip_dividend_index = IP_dividend_DEPTH then
          ip_dividend_index := 0;
        end if;
      end if;
      if divisor_tvalid_nxt = '1' then
        ip_divisor_index := ip_divisor_index + 1;
        if ip_divisor_index = IP_divisor_DEPTH then
          ip_divisor_index := 0;
        end if;
      end if;

    end loop;

  end process stimuli;

  -----------------------------------------------------------------------
  -- Check outputs
  -----------------------------------------------------------------------

  check_outputs : process
    variable check_ok : boolean := true;
  begin

    -- Check outputs T_STROBE time after rising edge of clock
    wait until rising_edge(aclk);
    wait for T_STROBE;

    -- Do not check the output payload values, as this requires the behavioral model
    -- which would make this demonstration testbench unwieldy.
    -- Instead, check the protocol of the DOUT channel:
    -- check that the payload is valid (not X) when TVALID is high

    if m_axis_dout_tvalid = '1' then
      if is_x(m_axis_dout_tdata) then
        report "ERROR: m_axis_dout_tdata is invalid when m_axis_dout_tvalid is high" severity error;
        check_ok := false;
      end if;

    end if;

    assert check_ok
      report "ERROR: terminating test with failures." severity failure;

  end process check_outputs;

  -----------------------------------------------------------------------
  -- Assign TDATA fields to aliases, for easy simulator waveform viewing
  -----------------------------------------------------------------------

  divisor  <= s_axis_divisor_tdata(23 downto 0);
  dividend <= s_axis_dividend_tdata(31 downto 0);
  fractional <= m_axis_dout_tdata(23 downto 0);
  quotient <= m_axis_dout_tdata(55 downto 24);

end tb;

