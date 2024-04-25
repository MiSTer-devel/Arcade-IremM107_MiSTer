//============================================================================
//  Irem M92 for MiSTer FPGA - PAL address decoders
//
//  Copyright (C) 2023 Martin Donlon
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


import m92_pkg::*;

module address_translator
(
    input logic [19:0] A,

    input logic [3:0] bank_select,
  
    input board_cfg_t board_cfg,

    output [19:0] rom_addr,
    output cpu_rom_memrq,
    output cpu_ram_memrq,

    output buffer_memrq,
    output sprite_control_memrq,
    output video_control_memrq,
    output pf_vram_memrq,
	output eeprom_memrq,
	output timer_memrq
);

wire [3:0] bank_a19_16 = ( bank_select & board_cfg.bank_mask ) | ( A[19:16] & ~board_cfg.bank_mask );

always_comb begin
    cpu_ram_memrq = 0;
    cpu_rom_memrq = 0;
    rom_addr = 0;

    buffer_memrq = 0;
    sprite_control_memrq = 0;
    video_control_memrq = 0;
    pf_vram_memrq = 0;
	eeprom_memrq = 0;
	timer_memrq = 0;

	casex (A[19:0])
	// 0xc0000-0xcffff
	20'b1100_xxxx_xxxx_xxxx_xxxx: begin cpu_rom_memrq = 1; rom_addr = { 4'b0, A[15:0] }; end
	// 0xd0000-0xdffff
	20'b1101_xxxx_xxxx_xxxx_xxxx: pf_vram_memrq = 1;
	// 0xe0000-0xeffff
	20'b1110_xxxx_xxxx_xxxx_xxxx: begin cpu_ram_memrq = 1; end
	// 0xf0000-0xf3fff
	20'b1111_00xx_xxxx_xxxx_xxxx: eeprom_memrq = 1;
	// 0xf8000-0xf9fff
	20'b1111_100x_xxxx_xxxx_xxxx: buffer_memrq = 1;
	// 0xffff0-0xfffff
	20'b1111_1111_1111_1111_xxxx: begin cpu_rom_memrq = 1; rom_addr = { 16'h7fff, A[3:0] }; end
	// 0x00000-0xbffff
	default: begin
		if (board_cfg.alt_map && A[19:16] == 4'h8) begin
			pf_vram_memrq = 1;
		end else if (board_cfg.debug_board && A[19:16] == 4'hb) begin
			timer_memrq = 1;
		end else begin
			cpu_rom_memrq = 1;
			rom_addr = { A[19:17] == 3'b101 ? bank_a19_16 : A[19:16], A[15:0] };
		end
	end
	endcase
end
endmodule
