create_clock -period 20.000 -name proc_clk -waveform {0.000 10.00} [get_ports clk_in]
create_clock -period 100.000 -name sck_clk -waveform {0.000 50.00} [get_ports SCK]