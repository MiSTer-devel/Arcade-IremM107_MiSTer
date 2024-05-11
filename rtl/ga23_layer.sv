//============================================================================
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

module ga23_layer(
    input clk,
    input ce_pix,

    input NL,

    input large_tileset,

    // io registers
    input [15:0] control,

    // position
    input [9:0] x_base,
    input [9:0] y_base,
    input [9:0] rowscroll,
    input [9:0] rowselect,

    // vram address for current tile
    output [14:0] vram_addr,

    // 
    input load,
    input [15:0] attrib,
    input [15:0] index,

    output prio_out,
    output [10:0] color_out,
    output color_enabled,

    input [31:0] sdr_data,
    output reg [21:0] sdr_addr,
    output reg sdr_req,
    input sdr_rdy,

    input dbg_enabled
);

// TODO: scroll select
wire [14:0] vram_base = { control[11:8], 11'd0 };
wire wide = 0;
wire enabled = ~control[7] & dbg_enabled;
wire en_rowscroll = control[0];
wire en_rowselect = control[1];
wire [9:0] x = x_base + ( en_rowscroll ? rowscroll : 10'd0 );
wire [9:0] y = y_base + ( en_rowselect ? rowselect : 10'd0 );
wire [6:0] tile_x = NL ? ( x[9:3] - ( wide ? 7'd32 : 7'd0) ) : ( x[9:3] + ( wide ? 7'd32 : 7'd0) );
wire [5:0] tile_y = y[8:3];

assign vram_addr = vram_base + {tile_y, tile_x[5:0], 1'b0};

reg [3:0] cnt;

reg [1:0] prio;
reg [6:0] palette;
reg flip_x;
wire flip_y = attrib[11];
reg [2:0] offset;

always_ff @(posedge clk) begin
    sdr_req <= 0;

    if (ce_pix) begin
        cnt <= cnt + 4'd1;
        if (load & enabled) begin
            cnt <= 4'd0;
            sdr_addr <= { attrib[12], index, flip_y ? ~y[2:0] : y[2:0], 2'b00 };
            sdr_req <= 1;
            palette <= attrib[6:0];
            prio <= attrib[9:8];
            flip_x <= attrib[10] ^ NL;
            offset <= x[2:0] ^ {3{NL}};
        end
    end
end

wire [1:0] shift_prio_out;
wire [10:0] shift_color_out;

ga23_shifter shifter(
    .clk(clk),
    .ce_pix(ce_pix),

    .offset(offset),

    .load(load),
    .reverse(flip_x),
    .row(sdr_data),
    .palette(palette),
    .prio(prio),

    .color_out(shift_color_out),
    .prio_out(shift_prio_out)
);

assign color_out = enabled ? shift_color_out : 11'd0;
assign prio_out = enabled ? ( ( shift_prio_out[0] & shift_color_out[3] ) | ( shift_prio_out[1] & |shift_color_out[3:0] ) ) : 1'b0;
assign color_enabled = enabled;
endmodule