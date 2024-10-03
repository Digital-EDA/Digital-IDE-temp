/*

Copyright (c) 2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 lite crossbar
 */
module axil_crossbar #
(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Number of concurrent operations for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_ACCEPT = {S_COUNT{32'd16}},
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    parameter M_BASE_ADDR = 0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Read connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_READ = {M_COUNT{{S_COUNT{1'b1}}}},
    // Write connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT_WRITE = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd16}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AW channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AW_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface W channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_W_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface B channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_B_REG_TYPE = {S_COUNT{2'd1}},
    // Slave interface AR channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AR_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface R channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_R_REG_TYPE = {S_COUNT{2'd2}},
    // Master interface AW channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AW_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface W channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_W_REG_TYPE = {M_COUNT{2'd2}},
    // Master interface B channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_B_REG_TYPE = {M_COUNT{2'd0}},
    // Master interface AR channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AR_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface R channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_R_REG_TYPE = {M_COUNT{2'd0}}
)
(
    input  wire                             clk,
    input  wire                             rst,

    /*
     * AXI lite slave interfaces
     */
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [S_COUNT*3-1:0]             s_axil_awprot,
    input  wire [S_COUNT-1:0]               s_axil_awvalid,
    output wire [S_COUNT-1:0]               s_axil_awready,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [S_COUNT*STRB_WIDTH-1:0]    s_axil_wstrb,
    input  wire [S_COUNT-1:0]               s_axil_wvalid,
    output wire [S_COUNT-1:0]               s_axil_wready,
    output wire [S_COUNT*2-1:0]             s_axil_bresp,
    output wire [S_COUNT-1:0]               s_axil_bvalid,
    input  wire [S_COUNT-1:0]               s_axil_bready,
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [S_COUNT*3-1:0]             s_axil_arprot,
    input  wire [S_COUNT-1:0]               s_axil_arvalid,
    output wire [S_COUNT-1:0]               s_axil_arready,
    output wire [S_COUNT*DATA_WIDTH-1:0]    s_axil_rdata,
    output wire [S_COUNT*2-1:0]             s_axil_rresp,
    output wire [S_COUNT-1:0]               s_axil_rvalid,
    input  wire [S_COUNT-1:0]               s_axil_rready,

    /*
     * AXI lite master interfaces
     */
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axil_awaddr,
    output wire [M_COUNT*3-1:0]             m_axil_awprot,
    output wire [M_COUNT-1:0]               m_axil_awvalid,
    input  wire [M_COUNT-1:0]               m_axil_awready,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axil_wdata,
    output wire [M_COUNT*STRB_WIDTH-1:0]    m_axil_wstrb,
    output wire [M_COUNT-1:0]               m_axil_wvalid,
    input  wire [M_COUNT-1:0]               m_axil_wready,
    input  wire [M_COUNT*2-1:0]             m_axil_bresp,
    input  wire [M_COUNT-1:0]               m_axil_bvalid,
    output wire [M_COUNT-1:0]               m_axil_bready,
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axil_araddr,
    output wire [M_COUNT*3-1:0]             m_axil_arprot,
    output wire [M_COUNT-1:0]               m_axil_arvalid,
    input  wire [M_COUNT-1:0]               m_axil_arready,
    input  wire [M_COUNT*DATA_WIDTH-1:0]    m_axil_rdata,
    input  wire [M_COUNT*2-1:0]             m_axil_rresp,
    input  wire [M_COUNT-1:0]               m_axil_rvalid,
    output wire [M_COUNT-1:0]               m_axil_rready
);

axil_crossbar_wr #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .S_ACCEPT(S_ACCEPT),
    .M_REGIONS(M_REGIONS),
    .M_BASE_ADDR(M_BASE_ADDR),
    .M_ADDR_WIDTH(M_ADDR_WIDTH),
    .M_CONNECT(M_CONNECT_WRITE),
    .M_ISSUE(M_ISSUE),
    .M_SECURE(M_SECURE),
    .S_AW_REG_TYPE(S_AW_REG_TYPE),
    .S_W_REG_TYPE (S_W_REG_TYPE),
    .S_B_REG_TYPE (S_B_REG_TYPE)
)
axil_crossbar_wr_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI lite slave interfaces
     */
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),

    /*
     * AXI lite master interfaces
     */
    .m_axil_awaddr(m_axil_awaddr),
    .m_axil_awprot(m_axil_awprot),
    .m_axil_awvalid(m_axil_awvalid),
    .m_axil_awready(m_axil_awready),
    .m_axil_wdata(m_axil_wdata),
    .m_axil_wstrb(m_axil_wstrb),
    .m_axil_wvalid(m_axil_wvalid),
    .m_axil_wready(m_axil_wready),
    .m_axil_bresp(m_axil_bresp),
    .m_axil_bvalid(m_axil_bvalid),
    .m_axil_bready(m_axil_bready)
);

axil_crossbar_rd #(
    .S_COUNT(S_COUNT),
    .M_COUNT(M_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .S_ACCEPT(S_ACCEPT),
    .M_REGIONS(M_REGIONS),
    .M_BASE_ADDR(M_BASE_ADDR),
    .M_ADDR_WIDTH(M_ADDR_WIDTH),
    .M_CONNECT(M_CONNECT_READ),
    .M_ISSUE(M_ISSUE),
    .M_SECURE(M_SECURE),
    .S_AR_REG_TYPE(S_AR_REG_TYPE),
    .S_R_REG_TYPE (S_R_REG_TYPE)
)
axil_crossbar_rd_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI lite slave interfaces
     */
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),

    /*
     * AXI lite master interfaces
     */
    .m_axil_araddr(m_axil_araddr),
    .m_axil_arprot(m_axil_arprot),
    .m_axil_arvalid(m_axil_arvalid),
    .m_axil_arready(m_axil_arready),
    .m_axil_rdata(m_axil_rdata),
    .m_axil_rresp(m_axil_rresp),
    .m_axil_rvalid(m_axil_rvalid),
    .m_axil_rready(m_axil_rready)
);

endmodule

/*

Copyright (c) 2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001


/*
 * AXI4 lite crossbar (write)
 */
module axil_crossbar_wr #
(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Number of concurrent operations for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_ACCEPT = {S_COUNT{32'd16}},
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    parameter M_BASE_ADDR = 0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Write connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd16}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AW channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AW_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface W channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_W_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface B channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_B_REG_TYPE = {S_COUNT{2'd1}},
    // Master interface AW channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AW_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface W channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_W_REG_TYPE = {M_COUNT{2'd2}},
    // Master interface B channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_B_REG_TYPE = {M_COUNT{2'd0}}
)
(
    input  wire                             clk,
    input  wire                             rst,

    /*
     * AXI lite slave interfaces
     */
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [S_COUNT*3-1:0]             s_axil_awprot,
    input  wire [S_COUNT-1:0]               s_axil_awvalid,
    output wire [S_COUNT-1:0]               s_axil_awready,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [S_COUNT*STRB_WIDTH-1:0]    s_axil_wstrb,
    input  wire [S_COUNT-1:0]               s_axil_wvalid,
    output wire [S_COUNT-1:0]               s_axil_wready,
    output wire [S_COUNT*2-1:0]             s_axil_bresp,
    output wire [S_COUNT-1:0]               s_axil_bvalid,
    input  wire [S_COUNT-1:0]               s_axil_bready,

    /*
     * AXI lite master interfaces
     */
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axil_awaddr,
    output wire [M_COUNT*3-1:0]             m_axil_awprot,
    output wire [M_COUNT-1:0]               m_axil_awvalid,
    input  wire [M_COUNT-1:0]               m_axil_awready,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axil_wdata,
    output wire [M_COUNT*STRB_WIDTH-1:0]    m_axil_wstrb,
    output wire [M_COUNT-1:0]               m_axil_wvalid,
    input  wire [M_COUNT-1:0]               m_axil_wready,
    input  wire [M_COUNT*2-1:0]             m_axil_bresp,
    input  wire [M_COUNT-1:0]               m_axil_bvalid,
    output wire [M_COUNT-1:0]               m_axil_bready
);

parameter CL_S_COUNT = $clog2(S_COUNT);
parameter CL_M_COUNT = $clog2(M_COUNT);
parameter M_COUNT_P1 = M_COUNT+1;
parameter CL_M_COUNT_P1 = $clog2(M_COUNT_P1);

integer i;

// check configuration
initial begin
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        if (M_ADDR_WIDTH[i*32 +: 32] && (M_ADDR_WIDTH[i*32 +: 32] < $clog2(STRB_WIDTH) || M_ADDR_WIDTH[i*32 +: 32] > ADDR_WIDTH)) begin
            $error("Error: value out of range (instance %m)");
            $finish;
        end
    end
end

wire [S_COUNT*ADDR_WIDTH-1:0]    int_s_axil_awaddr;
wire [S_COUNT*3-1:0]             int_s_axil_awprot;
wire [S_COUNT-1:0]               int_s_axil_awvalid;
wire [S_COUNT-1:0]               int_s_axil_awready;

wire [S_COUNT*M_COUNT-1:0]       int_axil_awvalid;
wire [M_COUNT*S_COUNT-1:0]       int_axil_awready;

wire [S_COUNT*DATA_WIDTH-1:0]    int_s_axil_wdata;
wire [S_COUNT*STRB_WIDTH-1:0]    int_s_axil_wstrb;
wire [S_COUNT-1:0]               int_s_axil_wvalid;
wire [S_COUNT-1:0]               int_s_axil_wready;

wire [S_COUNT*M_COUNT-1:0]       int_axil_wvalid;
wire [M_COUNT*S_COUNT-1:0]       int_axil_wready;

wire [M_COUNT*2-1:0]             int_m_axil_bresp;
wire [M_COUNT-1:0]               int_m_axil_bvalid;
wire [M_COUNT-1:0]               int_m_axil_bready;

wire [M_COUNT*S_COUNT-1:0]       int_axil_bvalid;
wire [S_COUNT*M_COUNT-1:0]       int_axil_bready;

generate

    genvar m, n;

    for (m = 0; m < S_COUNT; m = m + 1) begin : s_ifaces
        // response routing FIFO
        localparam FIFO_ADDR_WIDTH = $clog2(S_ACCEPT[m*32 +: 32])+1;

        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_wr_ptr_reg = 0;
        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_rd_ptr_reg = 0;

        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg [CL_M_COUNT-1:0] fifo_select[(2**FIFO_ADDR_WIDTH)-1:0];
        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg fifo_decerr[(2**FIFO_ADDR_WIDTH)-1:0];

        wire [CL_M_COUNT-1:0] fifo_wr_select;
        wire fifo_wr_decerr;
        wire fifo_wr_en;

        reg [CL_M_COUNT-1:0] fifo_rd_select_reg = 0;
        reg fifo_rd_decerr_reg = 0;
        reg fifo_rd_valid_reg = 0;
        wire fifo_rd_en;
        reg fifo_half_full_reg = 1'b0;

        wire fifo_empty = fifo_rd_ptr_reg == fifo_wr_ptr_reg;

        integer i;

        initial begin
            for (i = 0; i < 2**FIFO_ADDR_WIDTH; i = i + 1) begin
                fifo_select[i] = 0;
                fifo_decerr[i] = 0;
            end
        end

        always @(posedge clk) begin
            if (fifo_wr_en) begin
                fifo_select[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_select;
                fifo_decerr[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_decerr;
                fifo_wr_ptr_reg <= fifo_wr_ptr_reg + 1;
            end

            fifo_rd_valid_reg <= fifo_rd_valid_reg && !fifo_rd_en;

            if ((fifo_rd_ptr_reg != fifo_wr_ptr_reg) && (!fifo_rd_valid_reg || fifo_rd_en)) begin
                fifo_rd_select_reg <= fifo_select[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]];
                fifo_rd_decerr_reg <= fifo_decerr[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]];
                fifo_rd_valid_reg <= 1'b1;
                fifo_rd_ptr_reg <= fifo_rd_ptr_reg + 1;
            end

            fifo_half_full_reg <= $unsigned(fifo_wr_ptr_reg - fifo_rd_ptr_reg) >= 2**(FIFO_ADDR_WIDTH-1);

            if (rst) begin
                fifo_wr_ptr_reg <= 0;
                fifo_rd_ptr_reg <= 0;
                fifo_rd_valid_reg <= 1'b0;
            end
        end

        // address decode and admission control
        wire [CL_M_COUNT-1:0] a_select;

        wire m_axil_avalid;
        wire m_axil_aready;

        wire [CL_M_COUNT-1:0] m_wc_select;
        wire m_wc_decerr;
        wire m_wc_valid;
        wire m_wc_ready;

        wire [CL_M_COUNT-1:0] m_rc_select;
        wire m_rc_decerr;
        wire m_rc_valid;
        wire m_rc_ready;

        axil_crossbar_addr #(
            .S(m),
            .S_COUNT(S_COUNT),
            .M_COUNT(M_COUNT),
            .ADDR_WIDTH(ADDR_WIDTH),
            .M_REGIONS(M_REGIONS),
            .M_BASE_ADDR(M_BASE_ADDR),
            .M_ADDR_WIDTH(M_ADDR_WIDTH),
            .M_CONNECT(M_CONNECT),
            .M_SECURE(M_SECURE),
            .WC_OUTPUT(1)
        )
        addr_inst (
            .clk(clk),
            .rst(rst),

            /*
             * Address input
             */
            .s_axil_aaddr(int_s_axil_awaddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .s_axil_aprot(int_s_axil_awprot[m*3 +: 3]),
            .s_axil_avalid(int_s_axil_awvalid[m]),
            .s_axil_aready(int_s_axil_awready[m]),

            /*
             * Address output
             */
            .m_select(a_select),
            .m_axil_avalid(m_axil_avalid),
            .m_axil_aready(m_axil_aready),

            /*
             * Write command output
             */
            .m_wc_select(m_wc_select),
            .m_wc_decerr(m_wc_decerr),
            .m_wc_valid(m_wc_valid),
            .m_wc_ready(m_wc_ready),

            /*
             * Response command output
             */
            .m_rc_select(m_rc_select),
            .m_rc_decerr(m_rc_decerr),
            .m_rc_valid(m_rc_valid),
            .m_rc_ready(m_rc_ready)
        );

        assign int_axil_awvalid[m*M_COUNT +: M_COUNT] = m_axil_avalid << a_select;
        assign m_axil_aready = int_axil_awready[a_select*S_COUNT+m];

        // write command handling
        reg [CL_M_COUNT-1:0] w_select_reg = 0, w_select_next;
        reg w_drop_reg = 1'b0, w_drop_next;
        reg w_select_valid_reg = 1'b0, w_select_valid_next;

        assign m_wc_ready = !w_select_valid_reg;

        always @* begin
            w_select_next = w_select_reg;
            w_drop_next = w_drop_reg && !(int_s_axil_wvalid[m] && int_s_axil_wready[m]);
            w_select_valid_next = w_select_valid_reg && !(int_s_axil_wvalid[m] && int_s_axil_wready[m]);

            if (m_wc_valid && !w_select_valid_reg) begin
                w_select_next = m_wc_select;
                w_drop_next = m_wc_decerr;
                w_select_valid_next = m_wc_valid;
            end
        end

        always @(posedge clk) begin
            if (rst) begin
                w_select_valid_reg <= 1'b0;
            end else begin
                w_select_valid_reg <= w_select_valid_next;
            end

            w_select_reg <= w_select_next;
            w_drop_reg <= w_drop_next;
        end

        // write data forwarding
        assign int_axil_wvalid[m*M_COUNT +: M_COUNT] = (int_s_axil_wvalid[m] && w_select_valid_reg && !w_drop_reg) << w_select_reg;
        assign int_s_axil_wready[m] = int_axil_wready[w_select_reg*S_COUNT+m] || w_drop_reg;

        // response handling
        assign fifo_wr_select = m_rc_select;
        assign fifo_wr_decerr = m_rc_decerr;
        assign fifo_wr_en = m_rc_valid && !fifo_half_full_reg;
        assign m_rc_ready = !fifo_half_full_reg;

        // write response handling
        wire [CL_M_COUNT-1:0] b_select = M_COUNT > 1 ? fifo_rd_select_reg : 0;
        wire b_decerr = fifo_rd_decerr_reg;
        wire b_valid = fifo_rd_valid_reg;

        // write response mux
        wire [1:0]  m_axil_bresp_mux  = b_decerr ? 2'b11 : int_m_axil_bresp[b_select*2 +: 2];
        wire        m_axil_bvalid_mux = (b_decerr ? 1'b1 : int_axil_bvalid[b_select*S_COUNT+m]) && b_valid;
        wire        m_axil_bready_mux;

        assign int_axil_bready[m*M_COUNT +: M_COUNT] = (b_valid && m_axil_bready_mux) << b_select;

        assign fifo_rd_en = m_axil_bvalid_mux && m_axil_bready_mux && b_valid;

        // S side register
        axil_register_wr #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .STRB_WIDTH(STRB_WIDTH),
            .AW_REG_TYPE(S_AW_REG_TYPE[m*2 +: 2]),
            .W_REG_TYPE(S_W_REG_TYPE[m*2 +: 2]),
            .B_REG_TYPE(S_B_REG_TYPE[m*2 +: 2])
        )
        reg_inst (
            .clk(clk),
            .rst(rst),
            .s_axil_awaddr(s_axil_awaddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .s_axil_awprot(s_axil_awprot[m*3 +: 3]),
            .s_axil_awvalid(s_axil_awvalid[m]),
            .s_axil_awready(s_axil_awready[m]),
            .s_axil_wdata(s_axil_wdata[m*DATA_WIDTH +: DATA_WIDTH]),
            .s_axil_wstrb(s_axil_wstrb[m*STRB_WIDTH +: STRB_WIDTH]),
            .s_axil_wvalid(s_axil_wvalid[m]),
            .s_axil_wready(s_axil_wready[m]),
            .s_axil_bresp(s_axil_bresp[m*2 +: 2]),
            .s_axil_bvalid(s_axil_bvalid[m]),
            .s_axil_bready(s_axil_bready[m]),
            .m_axil_awaddr(int_s_axil_awaddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .m_axil_awprot(int_s_axil_awprot[m*3 +: 3]),
            .m_axil_awvalid(int_s_axil_awvalid[m]),
            .m_axil_awready(int_s_axil_awready[m]),
            .m_axil_wdata(int_s_axil_wdata[m*DATA_WIDTH +: DATA_WIDTH]),
            .m_axil_wstrb(int_s_axil_wstrb[m*STRB_WIDTH +: STRB_WIDTH]),
            .m_axil_wvalid(int_s_axil_wvalid[m]),
            .m_axil_wready(int_s_axil_wready[m]),
            .m_axil_bresp(m_axil_bresp_mux),
            .m_axil_bvalid(m_axil_bvalid_mux),
            .m_axil_bready(m_axil_bready_mux)
        );
    end // s_ifaces

    for (n = 0; n < M_COUNT; n = n + 1) begin : m_ifaces
        // response routing FIFO
        localparam FIFO_ADDR_WIDTH = $clog2(M_ISSUE[n*32 +: 32])+1;

        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_wr_ptr_reg = 0;
        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_rd_ptr_reg = 0;

        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg [CL_S_COUNT-1:0] fifo_select[(2**FIFO_ADDR_WIDTH)-1:0];
        wire [CL_S_COUNT-1:0] fifo_wr_select;
        wire fifo_wr_en;
        wire fifo_rd_en;
        reg fifo_half_full_reg = 1'b0;

        wire fifo_empty = fifo_rd_ptr_reg == fifo_wr_ptr_reg;

        integer i;

        initial begin
            for (i = 0; i < 2**FIFO_ADDR_WIDTH; i = i + 1) begin
                fifo_select[i] = 0;
            end
        end

        always @(posedge clk) begin
            if (fifo_wr_en) begin
                fifo_select[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_select;
                fifo_wr_ptr_reg <= fifo_wr_ptr_reg + 1;
            end
            if (fifo_rd_en) begin
                fifo_rd_ptr_reg <= fifo_rd_ptr_reg + 1;
            end

            fifo_half_full_reg <= $unsigned(fifo_wr_ptr_reg - fifo_rd_ptr_reg) >= 2**(FIFO_ADDR_WIDTH-1);

            if (rst) begin
                fifo_wr_ptr_reg <= 0;
                fifo_rd_ptr_reg <= 0;
            end
        end

        // address arbitration
        reg [CL_S_COUNT-1:0] w_select_reg = 0, w_select_next = 0;
        reg w_select_valid_reg = 1'b0, w_select_valid_next;
        reg w_select_new_reg = 1'b0, w_select_new_next;

        wire [S_COUNT-1:0] a_request;
        wire [S_COUNT-1:0] a_acknowledge;
        wire [S_COUNT-1:0] a_grant;
        wire a_grant_valid;
        wire [CL_S_COUNT-1:0] a_grant_encoded;

        arbiter #(
            .PORTS(S_COUNT),
            .ARB_TYPE_ROUND_ROBIN(1),
            .ARB_BLOCK(1),
            .ARB_BLOCK_ACK(1),
            .ARB_LSB_HIGH_PRIORITY(1)
        )
        a_arb_inst (
            .clk(clk),
            .rst(rst),
            .request(a_request),
            .acknowledge(a_acknowledge),
            .grant(a_grant),
            .grant_valid(a_grant_valid),
            .grant_encoded(a_grant_encoded)
        );

        // address mux
        wire [ADDR_WIDTH-1:0]  s_axil_awaddr_mux   = int_s_axil_awaddr[a_grant_encoded*ADDR_WIDTH +: ADDR_WIDTH];
        wire [2:0]             s_axil_awprot_mux   = int_s_axil_awprot[a_grant_encoded*3 +: 3];
        wire                   s_axil_awvalid_mux  = int_axil_awvalid[a_grant_encoded*M_COUNT+n] && a_grant_valid;
        wire                   s_axil_awready_mux;

        assign int_axil_awready[n*S_COUNT +: S_COUNT] = (a_grant_valid && s_axil_awready_mux) << a_grant_encoded;

        for (m = 0; m < S_COUNT; m = m + 1) begin
            assign a_request[m] = int_axil_awvalid[m*M_COUNT+n] && !a_grant[m] && !fifo_half_full_reg && !w_select_valid_next;
            assign a_acknowledge[m] = a_grant[m] && int_axil_awvalid[m*M_COUNT+n] && s_axil_awready_mux;
        end

        assign fifo_wr_select = a_grant_encoded;
        assign fifo_wr_en = s_axil_awvalid_mux && s_axil_awready_mux && a_grant_valid;

        // write data mux
        wire [DATA_WIDTH-1:0]  s_axil_wdata_mux   = int_s_axil_wdata[w_select_reg*DATA_WIDTH +: DATA_WIDTH];
        wire [STRB_WIDTH-1:0]  s_axil_wstrb_mux   = int_s_axil_wstrb[w_select_reg*STRB_WIDTH +: STRB_WIDTH];
        wire                   s_axil_wvalid_mux  = int_axil_wvalid[w_select_reg*M_COUNT+n] && w_select_valid_reg;
        wire                   s_axil_wready_mux;

        assign int_axil_wready[n*S_COUNT +: S_COUNT] = (w_select_valid_reg && s_axil_wready_mux) << w_select_reg;

        // write data routing
        always @* begin
            w_select_next = w_select_reg;
            w_select_valid_next = w_select_valid_reg && !(s_axil_wvalid_mux && s_axil_wready_mux);
            w_select_new_next = w_select_new_reg || !a_grant_valid || a_acknowledge;

            if (a_grant_valid && !w_select_valid_reg && w_select_new_reg) begin
                w_select_next = a_grant_encoded;
                w_select_valid_next = a_grant_valid;
                w_select_new_next = 1'b0;
            end
        end

        always @(posedge clk) begin
            if (rst) begin
                w_select_valid_reg <= 1'b0;
                w_select_new_reg <= 1'b1;
            end else begin
                w_select_valid_reg <= w_select_valid_next;
                w_select_new_reg <= w_select_new_next;
            end

            w_select_reg <= w_select_next;
        end

        // write response forwarding
        wire [CL_S_COUNT-1:0] b_select = S_COUNT > 1 ? fifo_select[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]] : 0;

        assign int_axil_bvalid[n*S_COUNT +: S_COUNT] = int_m_axil_bvalid[n] << b_select;
        assign int_m_axil_bready[n] = int_axil_bready[b_select*M_COUNT+n];

        assign fifo_rd_en = int_m_axil_bvalid[n] && int_m_axil_bready[n];

        // M side register
        axil_register_wr #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .STRB_WIDTH(STRB_WIDTH),
            .AW_REG_TYPE(M_AW_REG_TYPE[n*2 +: 2]),
            .W_REG_TYPE(M_W_REG_TYPE[n*2 +: 2]),
            .B_REG_TYPE(M_B_REG_TYPE[n*2 +: 2])
        )
        reg_inst (
            .clk(clk),
            .rst(rst),
            .s_axil_awaddr(s_axil_awaddr_mux),
            .s_axil_awprot(s_axil_awprot_mux),
            .s_axil_awvalid(s_axil_awvalid_mux),
            .s_axil_awready(s_axil_awready_mux),
            .s_axil_wdata(s_axil_wdata_mux),
            .s_axil_wstrb(s_axil_wstrb_mux),
            .s_axil_wvalid(s_axil_wvalid_mux),
            .s_axil_wready(s_axil_wready_mux),
            .s_axil_bresp(int_m_axil_bresp[n*2 +: 2]),
            .s_axil_bvalid(int_m_axil_bvalid[n]),
            .s_axil_bready(int_m_axil_bready[n]),
            .m_axil_awaddr(m_axil_awaddr[n*ADDR_WIDTH +: ADDR_WIDTH]),
            .m_axil_awprot(m_axil_awprot[n*3 +: 3]),
            .m_axil_awvalid(m_axil_awvalid[n]),
            .m_axil_awready(m_axil_awready[n]),
            .m_axil_wdata(m_axil_wdata[n*DATA_WIDTH +: DATA_WIDTH]),
            .m_axil_wstrb(m_axil_wstrb[n*STRB_WIDTH +: STRB_WIDTH]),
            .m_axil_wvalid(m_axil_wvalid[n]),
            .m_axil_wready(m_axil_wready[n]),
            .m_axil_bresp(m_axil_bresp[n*2 +: 2]),
            .m_axil_bvalid(m_axil_bvalid[n]),
            .m_axil_bready(m_axil_bready[n])
        );
    end // m_ifaces

endgenerate

endmodule

/*

Copyright (c) 2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001


/*
 * AXI4 lite crossbar (read)
 */
module axil_crossbar_rd #
(
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Number of concurrent operations for each slave interface
    // S_COUNT concatenated fields of 32 bits
    parameter S_ACCEPT = {S_COUNT{32'd16}},
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    parameter M_BASE_ADDR = 0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Read connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    // Number of concurrent operations for each master interface
    // M_COUNT concatenated fields of 32 bits
    parameter M_ISSUE = {M_COUNT{32'd16}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Slave interface AR channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_AR_REG_TYPE = {S_COUNT{2'd0}},
    // Slave interface R channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter S_R_REG_TYPE = {S_COUNT{2'd2}},
    // Master interface AR channel register type (output)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_AR_REG_TYPE = {M_COUNT{2'd1}},
    // Master interface R channel register type (input)
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    parameter M_R_REG_TYPE = {M_COUNT{2'd0}}
)
(
    input  wire                             clk,
    input  wire                             rst,

    /*
     * AXI lite slave interfaces
     */
    input  wire [S_COUNT*ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [S_COUNT*3-1:0]             s_axil_arprot,
    input  wire [S_COUNT-1:0]               s_axil_arvalid,
    output wire [S_COUNT-1:0]               s_axil_arready,
    output wire [S_COUNT*DATA_WIDTH-1:0]    s_axil_rdata,
    output wire [S_COUNT*2-1:0]             s_axil_rresp,
    output wire [S_COUNT-1:0]               s_axil_rvalid,
    input  wire [S_COUNT-1:0]               s_axil_rready,

    /*
     * AXI lite master interfaces
     */
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_axil_araddr,
    output wire [M_COUNT*3-1:0]             m_axil_arprot,
    output wire [M_COUNT-1:0]               m_axil_arvalid,
    input  wire [M_COUNT-1:0]               m_axil_arready,
    input  wire [M_COUNT*DATA_WIDTH-1:0]    m_axil_rdata,
    input  wire [M_COUNT*2-1:0]             m_axil_rresp,
    input  wire [M_COUNT-1:0]               m_axil_rvalid,
    output wire [M_COUNT-1:0]               m_axil_rready
);

parameter CL_S_COUNT = $clog2(S_COUNT);
parameter CL_M_COUNT = $clog2(M_COUNT);
parameter M_COUNT_P1 = M_COUNT+1;
parameter CL_M_COUNT_P1 = $clog2(M_COUNT_P1);

integer i;

// check configuration
initial begin
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        if (M_ADDR_WIDTH[i*32 +: 32] && (M_ADDR_WIDTH[i*32 +: 32] < $clog2(STRB_WIDTH) || M_ADDR_WIDTH[i*32 +: 32] > ADDR_WIDTH)) begin
            $error("Error: value out of range (instance %m)");
            $finish;
        end
    end
end

wire [S_COUNT*ADDR_WIDTH-1:0]    int_s_axil_araddr;
wire [S_COUNT*3-1:0]             int_s_axil_arprot;
wire [S_COUNT-1:0]               int_s_axil_arvalid;
wire [S_COUNT-1:0]               int_s_axil_arready;

wire [S_COUNT*M_COUNT-1:0]       int_axil_arvalid;
wire [M_COUNT*S_COUNT-1:0]       int_axil_arready;

wire [M_COUNT*DATA_WIDTH-1:0]    int_m_axil_rdata;
wire [M_COUNT*2-1:0]             int_m_axil_rresp;
wire [M_COUNT-1:0]               int_m_axil_rvalid;
wire [M_COUNT-1:0]               int_m_axil_rready;

wire [M_COUNT*S_COUNT-1:0]       int_axil_rvalid;
wire [S_COUNT*M_COUNT-1:0]       int_axil_rready;

generate

    genvar m, n;

    for (m = 0; m < S_COUNT; m = m + 1) begin : s_ifaces
        // response routing FIFO
        localparam FIFO_ADDR_WIDTH = $clog2(S_ACCEPT[m*32 +: 32])+1;

        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_wr_ptr_reg = 0;
        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_rd_ptr_reg = 0;

        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg [CL_M_COUNT-1:0] fifo_select[(2**FIFO_ADDR_WIDTH)-1:0];
        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg fifo_decerr[(2**FIFO_ADDR_WIDTH)-1:0];

        wire [CL_M_COUNT-1:0] fifo_wr_select;
        wire fifo_wr_decerr;
        wire fifo_wr_en;

        reg [CL_M_COUNT-1:0] fifo_rd_select_reg = 0;
        reg fifo_rd_decerr_reg = 0;
        reg fifo_rd_valid_reg = 0;
        wire fifo_rd_en;
        reg fifo_half_full_reg = 1'b0;

        wire fifo_empty = fifo_rd_ptr_reg == fifo_wr_ptr_reg;

        integer i;

        initial begin
            for (i = 0; i < 2**FIFO_ADDR_WIDTH; i = i + 1) begin
                fifo_select[i] = 0;
                fifo_decerr[i] = 0;
            end
        end

        always @(posedge clk) begin
            if (fifo_wr_en) begin
                fifo_select[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_select;
                fifo_decerr[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_decerr;
                fifo_wr_ptr_reg <= fifo_wr_ptr_reg + 1;
            end

            fifo_rd_valid_reg <= fifo_rd_valid_reg && !fifo_rd_en;

            if ((fifo_rd_ptr_reg != fifo_wr_ptr_reg) && (!fifo_rd_valid_reg || fifo_rd_en)) begin
                fifo_rd_select_reg <= fifo_select[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]];
                fifo_rd_decerr_reg <= fifo_decerr[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]];
                fifo_rd_valid_reg <= 1'b1;
                fifo_rd_ptr_reg <= fifo_rd_ptr_reg + 1;
            end

            fifo_half_full_reg <= $unsigned(fifo_wr_ptr_reg - fifo_rd_ptr_reg) >= 2**(FIFO_ADDR_WIDTH-1);

            if (rst) begin
                fifo_wr_ptr_reg <= 0;
                fifo_rd_ptr_reg <= 0;
                fifo_rd_valid_reg <= 1'b0;
            end
        end

        // address decode and admission control
        wire [CL_M_COUNT-1:0] a_select;

        wire m_axil_avalid;
        wire m_axil_aready;

        wire [CL_M_COUNT-1:0] m_rc_select;
        wire m_rc_decerr;
        wire m_rc_valid;
        wire m_rc_ready;

        axil_crossbar_addr #(
            .S(m),
            .S_COUNT(S_COUNT),
            .M_COUNT(M_COUNT),
            .ADDR_WIDTH(ADDR_WIDTH),
            .M_REGIONS(M_REGIONS),
            .M_BASE_ADDR(M_BASE_ADDR),
            .M_ADDR_WIDTH(M_ADDR_WIDTH),
            .M_CONNECT(M_CONNECT),
            .M_SECURE(M_SECURE),
            .WC_OUTPUT(0)
        )
        addr_inst (
            .clk(clk),
            .rst(rst),

            /*
             * Address input
             */
            .s_axil_aaddr(int_s_axil_araddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .s_axil_aprot(int_s_axil_arprot[m*3 +: 3]),
            .s_axil_avalid(int_s_axil_arvalid[m]),
            .s_axil_aready(int_s_axil_arready[m]),

            /*
             * Address output
             */
            .m_select(a_select),
            .m_axil_avalid(m_axil_avalid),
            .m_axil_aready(m_axil_aready),

            /*
             * Write command output
             */
            .m_wc_select(),
            .m_wc_decerr(),
            .m_wc_valid(),
            .m_wc_ready(1'b1),

            /*
             * Response command output
             */
            .m_rc_select(m_rc_select),
            .m_rc_decerr(m_rc_decerr),
            .m_rc_valid(m_rc_valid),
            .m_rc_ready(m_rc_ready)
        );

        assign int_axil_arvalid[m*M_COUNT +: M_COUNT] = m_axil_avalid << a_select;
        assign m_axil_aready = int_axil_arready[a_select*S_COUNT+m];

        // response handling
        assign fifo_wr_select = m_rc_select;
        assign fifo_wr_decerr = m_rc_decerr;
        assign fifo_wr_en = m_rc_valid && !fifo_half_full_reg;
        assign m_rc_ready = !fifo_half_full_reg;

        // write response handling
        wire [CL_M_COUNT-1:0] r_select = M_COUNT > 1 ? fifo_rd_select_reg : 0;
        wire r_decerr = fifo_rd_decerr_reg;
        wire r_valid = fifo_rd_valid_reg;

        // read response mux
        wire [DATA_WIDTH-1:0]  m_axil_rdata_mux  = r_decerr ? {DATA_WIDTH{1'b0}} : int_m_axil_rdata[r_select*DATA_WIDTH +: DATA_WIDTH];
        wire [1:0]             m_axil_rresp_mux  = r_decerr ? 2'b11 : int_m_axil_rresp[r_select*2 +: 2];
        wire                   m_axil_rvalid_mux = (r_decerr ? 1'b1 : int_axil_rvalid[r_select*S_COUNT+m]) && r_valid;
        wire                   m_axil_rready_mux;

        assign int_axil_rready[m*M_COUNT +: M_COUNT] = (r_valid && m_axil_rready_mux) << r_select;

        assign fifo_rd_en = m_axil_rvalid_mux && m_axil_rready_mux && r_valid;

        // S side register
        axil_register_rd #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .STRB_WIDTH(STRB_WIDTH),
            .AR_REG_TYPE(S_AR_REG_TYPE[m*2 +: 2]),
            .R_REG_TYPE(S_R_REG_TYPE[m*2 +: 2])
        )
        reg_inst (
            .clk(clk),
            .rst(rst),
            .s_axil_araddr(s_axil_araddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .s_axil_arprot(s_axil_arprot[m*3 +: 3]),
            .s_axil_arvalid(s_axil_arvalid[m]),
            .s_axil_arready(s_axil_arready[m]),
            .s_axil_rdata(s_axil_rdata[m*DATA_WIDTH +: DATA_WIDTH]),
            .s_axil_rresp(s_axil_rresp[m*2 +: 2]),
            .s_axil_rvalid(s_axil_rvalid[m]),
            .s_axil_rready(s_axil_rready[m]),
            .m_axil_araddr(int_s_axil_araddr[m*ADDR_WIDTH +: ADDR_WIDTH]),
            .m_axil_arprot(int_s_axil_arprot[m*3 +: 3]),
            .m_axil_arvalid(int_s_axil_arvalid[m]),
            .m_axil_arready(int_s_axil_arready[m]),
            .m_axil_rdata(m_axil_rdata_mux),
            .m_axil_rresp(m_axil_rresp_mux),
            .m_axil_rvalid(m_axil_rvalid_mux),
            .m_axil_rready(m_axil_rready_mux)
        );
    end // s_ifaces

    for (n = 0; n < M_COUNT; n = n + 1) begin : m_ifaces
        // response routing FIFO
        localparam FIFO_ADDR_WIDTH = $clog2(M_ISSUE[n*32 +: 32])+1;

        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_wr_ptr_reg = 0;
        reg [FIFO_ADDR_WIDTH+1-1:0] fifo_rd_ptr_reg = 0;

        (* ram_style = "distributed", ramstyle = "no_rw_check, mlab" *)
        reg [CL_S_COUNT-1:0] fifo_select[(2**FIFO_ADDR_WIDTH)-1:0];
        wire [CL_S_COUNT-1:0] fifo_wr_select;
        wire fifo_wr_en;
        wire fifo_rd_en;
        reg fifo_half_full_reg = 1'b0;

        wire fifo_empty = fifo_rd_ptr_reg == fifo_wr_ptr_reg;

        integer i;

        initial begin
            for (i = 0; i < 2**FIFO_ADDR_WIDTH; i = i + 1) begin
                fifo_select[i] = 0;
            end
        end

        always @(posedge clk) begin
            if (fifo_wr_en) begin
                fifo_select[fifo_wr_ptr_reg[FIFO_ADDR_WIDTH-1:0]] <= fifo_wr_select;
                fifo_wr_ptr_reg <= fifo_wr_ptr_reg + 1;
            end
            if (fifo_rd_en) begin
                fifo_rd_ptr_reg <= fifo_rd_ptr_reg + 1;
            end

            fifo_half_full_reg <= $unsigned(fifo_wr_ptr_reg - fifo_rd_ptr_reg) >= 2**(FIFO_ADDR_WIDTH-1);

            if (rst) begin
                fifo_wr_ptr_reg <= 0;
                fifo_rd_ptr_reg <= 0;
            end
        end

        // address arbitration
        wire [S_COUNT-1:0] a_request;
        wire [S_COUNT-1:0] a_acknowledge;
        wire [S_COUNT-1:0] a_grant;
        wire a_grant_valid;
        wire [CL_S_COUNT-1:0] a_grant_encoded;

        arbiter #(
            .PORTS(S_COUNT),
            .ARB_TYPE_ROUND_ROBIN(1),
            .ARB_BLOCK(1),
            .ARB_BLOCK_ACK(1),
            .ARB_LSB_HIGH_PRIORITY(1)
        )
        a_arb_inst (
            .clk(clk),
            .rst(rst),
            .request(a_request),
            .acknowledge(a_acknowledge),
            .grant(a_grant),
            .grant_valid(a_grant_valid),
            .grant_encoded(a_grant_encoded)
        );

        // address mux
        wire [ADDR_WIDTH-1:0]  s_axil_araddr_mux   = int_s_axil_araddr[a_grant_encoded*ADDR_WIDTH +: ADDR_WIDTH];
        wire [2:0]             s_axil_arprot_mux   = int_s_axil_arprot[a_grant_encoded*3 +: 3];
        wire                   s_axil_arvalid_mux  = int_axil_arvalid[a_grant_encoded*M_COUNT+n] && a_grant_valid;
        wire                   s_axil_arready_mux;

        assign int_axil_arready[n*S_COUNT +: S_COUNT] = (a_grant_valid && s_axil_arready_mux) << a_grant_encoded;

        for (m = 0; m < S_COUNT; m = m + 1) begin
            assign a_request[m] = int_axil_arvalid[m*M_COUNT+n] && !a_grant[m] && !fifo_half_full_reg;
            assign a_acknowledge[m] = a_grant[m] && int_axil_arvalid[m*M_COUNT+n] && s_axil_arready_mux;
        end

        assign fifo_wr_select = a_grant_encoded;
        assign fifo_wr_en = s_axil_arvalid_mux && s_axil_arready_mux && a_grant_valid;

        // read response forwarding
        wire [CL_S_COUNT-1:0] r_select = S_COUNT > 1 ? fifo_select[fifo_rd_ptr_reg[FIFO_ADDR_WIDTH-1:0]] : 0;

        assign int_axil_rvalid[n*S_COUNT +: S_COUNT] = int_m_axil_rvalid[n] << r_select;
        assign int_m_axil_rready[n] = int_axil_rready[r_select*M_COUNT+n];

        assign fifo_rd_en = int_m_axil_rvalid[n] && int_m_axil_rready[n];

        // M side register
        axil_register_rd #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .STRB_WIDTH(STRB_WIDTH),
            .AR_REG_TYPE(M_AR_REG_TYPE[n*2 +: 2]),
            .R_REG_TYPE(M_R_REG_TYPE[n*2 +: 2])
        )
        reg_inst (
            .clk(clk),
            .rst(rst),
            .s_axil_araddr(s_axil_araddr_mux),
            .s_axil_arprot(s_axil_arprot_mux),
            .s_axil_arvalid(s_axil_arvalid_mux),
            .s_axil_arready(s_axil_arready_mux),
            .s_axil_rdata(int_m_axil_rdata[n*DATA_WIDTH +: DATA_WIDTH]),
            .s_axil_rresp(int_m_axil_rresp[n*2 +: 2]),
            .s_axil_rvalid(int_m_axil_rvalid[n]),
            .s_axil_rready(int_m_axil_rready[n]),
            .m_axil_araddr(m_axil_araddr[n*ADDR_WIDTH +: ADDR_WIDTH]),
            .m_axil_arprot(m_axil_arprot[n*3 +: 3]),
            .m_axil_arvalid(m_axil_arvalid[n]),
            .m_axil_arready(m_axil_arready[n]),
            .m_axil_rdata(m_axil_rdata[n*DATA_WIDTH +: DATA_WIDTH]),
            .m_axil_rresp(m_axil_rresp[n*2 +: 2]),
            .m_axil_rvalid(m_axil_rvalid[n]),
            .m_axil_rready(m_axil_rready[n])
        );
    end // m_ifaces

endgenerate

endmodule

`resetall

/*

Copyright (c) 2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001


/*
 * AXI4 lite crossbar address decode and admission control
 */
module axil_crossbar_addr #
(
    // Slave interface index
    parameter S = 0,
    // Number of AXI inputs (slave interfaces)
    parameter S_COUNT = 4,
    // Number of AXI outputs (master interfaces)
    parameter M_COUNT = 4,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Number of regions per master interface
    parameter M_REGIONS = 1,
    // Master interface base addresses
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of ADDR_WIDTH bits
    // set to zero for default addressing based on M_ADDR_WIDTH
    parameter M_BASE_ADDR = 0,
    // Master interface address widths
    // M_COUNT concatenated fields of M_REGIONS concatenated fields of 32 bits
    parameter M_ADDR_WIDTH = {M_COUNT{{M_REGIONS{32'd24}}}},
    // Connections between interfaces
    // M_COUNT concatenated fields of S_COUNT bits
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    // Secure master (fail operations based on awprot/arprot)
    // M_COUNT bits
    parameter M_SECURE = {M_COUNT{1'b0}},
    // Enable write command output
    parameter WC_OUTPUT = 0
)
(
    input  wire                       clk,
    input  wire                       rst,

    /*
     * Address input
     */
    input  wire [ADDR_WIDTH-1:0]      s_axil_aaddr,
    input  wire [2:0]                 s_axil_aprot,
    input  wire                       s_axil_avalid,
    output wire                       s_axil_aready,

    /*
     * Address output
     */
    output wire [$clog2(M_COUNT)-1:0] m_select,
    output wire                       m_axil_avalid,
    input  wire                       m_axil_aready,

    /*
     * Write command output
     */
    output wire [$clog2(M_COUNT)-1:0] m_wc_select,
    output wire                       m_wc_decerr,
    output wire                       m_wc_valid,
    input  wire                       m_wc_ready,

    /*
     * Reply command output
     */
    output wire [$clog2(M_COUNT)-1:0] m_rc_select,
    output wire                       m_rc_decerr,
    output wire                       m_rc_valid,
    input  wire                       m_rc_ready
);

parameter CL_S_COUNT = $clog2(S_COUNT);
parameter CL_M_COUNT = $clog2(M_COUNT);

// default address computation
function [M_COUNT*M_REGIONS*ADDR_WIDTH-1:0] calcBaseAddrs(input [31:0] dummy);
    integer i;
    reg [ADDR_WIDTH-1:0] base;
    reg [ADDR_WIDTH-1:0] width;
    reg [ADDR_WIDTH-1:0] size;
    reg [ADDR_WIDTH-1:0] mask;
    begin
        calcBaseAddrs = {M_COUNT*M_REGIONS*ADDR_WIDTH{1'b0}};
        base = 0;
        for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
            width = M_ADDR_WIDTH[i*32 +: 32];
            mask = {ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - width);
            size = mask + 1;
            if (width > 0) begin
                if ((base & mask) != 0) begin
                   base = base + size - (base & mask); // align
                end
                calcBaseAddrs[i * ADDR_WIDTH +: ADDR_WIDTH] = base;
                base = base + size; // increment
            end
        end
    end
endfunction

parameter M_BASE_ADDR_INT = M_BASE_ADDR ? M_BASE_ADDR : calcBaseAddrs(0);

integer i, j;

// check configuration
initial begin
    if (M_REGIONS < 1) begin
        $error("Error: need at least 1 region (instance %m)");
        $finish;
    end

    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        if (M_ADDR_WIDTH[i*32 +: 32] && M_ADDR_WIDTH[i*32 +: 32] > ADDR_WIDTH) begin
            $error("Error: address width out of range (instance %m)");
            $finish;
        end
    end

    $display("Addressing configuration for axil_crossbar_addr instance %m");
    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        if (M_ADDR_WIDTH[i*32 +: 32]) begin
            $display("%2d (%2d): %x / %02d -- %x-%x",
                i/M_REGIONS, i%M_REGIONS,
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
                M_ADDR_WIDTH[i*32 +: 32],
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
            );
        end
    end

    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        if ((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & (2**M_ADDR_WIDTH[i*32 +: 32]-1)) != 0) begin
            $display("Region not aligned:");
            $display("%2d (%2d): %x / %2d -- %x-%x",
                i/M_REGIONS, i%M_REGIONS,
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
                M_ADDR_WIDTH[i*32 +: 32],
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
                M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
            );
            $error("Error: address range not aligned (instance %m)");
            $finish;
        end
    end

    for (i = 0; i < M_COUNT*M_REGIONS; i = i + 1) begin
        for (j = i+1; j < M_COUNT*M_REGIONS; j = j + 1) begin
            if (M_ADDR_WIDTH[i*32 +: 32] && M_ADDR_WIDTH[j*32 +: 32]) begin
                if (((M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32])) <= (M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))))
                        && ((M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32])) <= (M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))))) begin
                    $display("Overlapping regions:");
                    $display("%2d (%2d): %x / %2d -- %x-%x",
                        i/M_REGIONS, i%M_REGIONS,
                        M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH],
                        M_ADDR_WIDTH[i*32 +: 32],
                        M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[i*32 +: 32]),
                        M_BASE_ADDR_INT[i*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[i*32 +: 32]))
                    );
                    $display("%2d (%2d): %x / %2d -- %x-%x",
                        j/M_REGIONS, j%M_REGIONS,
                        M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH],
                        M_ADDR_WIDTH[j*32 +: 32],
                        M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] & ({ADDR_WIDTH{1'b1}} << M_ADDR_WIDTH[j*32 +: 32]),
                        M_BASE_ADDR_INT[j*ADDR_WIDTH +: ADDR_WIDTH] | ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - M_ADDR_WIDTH[j*32 +: 32]))
                    );
                    $error("Error: address ranges overlap (instance %m)");
                    $finish;
                end
            end
        end
    end
end

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_DECODE = 3'd1;

reg [2:0] state_reg = STATE_IDLE, state_next;

reg s_axil_aready_reg = 0, s_axil_aready_next;

reg [CL_M_COUNT-1:0] m_select_reg = 0, m_select_next;
reg m_axil_avalid_reg = 1'b0, m_axil_avalid_next;
reg m_decerr_reg = 1'b0, m_decerr_next;
reg m_wc_valid_reg = 1'b0, m_wc_valid_next;
reg m_rc_valid_reg = 1'b0, m_rc_valid_next;

assign s_axil_aready = s_axil_aready_reg;

assign m_select = m_select_reg;
assign m_axil_avalid = m_axil_avalid_reg;

assign m_wc_select = m_select_reg;
assign m_wc_decerr = m_decerr_reg;
assign m_wc_valid = m_wc_valid_reg;

assign m_rc_select = m_select_reg;
assign m_rc_decerr = m_decerr_reg;
assign m_rc_valid = m_rc_valid_reg;

reg match;

always @* begin
    state_next = STATE_IDLE;

    match = 1'b0;

    s_axil_aready_next = 1'b0;

    m_select_next = m_select_reg;
    m_axil_avalid_next = m_axil_avalid_reg && !m_axil_aready;
    m_decerr_next = m_decerr_reg;
    m_wc_valid_next = m_wc_valid_reg && !m_wc_ready;
    m_rc_valid_next = m_rc_valid_reg && !m_rc_ready;

    case (state_reg)
        STATE_IDLE: begin
            // idle state, store values
            s_axil_aready_next = 1'b0;

            if (s_axil_avalid && !s_axil_aready) begin
                match = 1'b0;
                for (i = 0; i < M_COUNT; i = i + 1) begin
                    for (j = 0; j < M_REGIONS; j = j + 1) begin
                        if (M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32] && (!M_SECURE[i] || !s_axil_aprot[1]) && (M_CONNECT & (1 << (S+i*S_COUNT))) && (s_axil_aaddr >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32]) == (M_BASE_ADDR_INT[(i*M_REGIONS+j)*ADDR_WIDTH +: ADDR_WIDTH] >> M_ADDR_WIDTH[(i*M_REGIONS+j)*32 +: 32])) begin
                            m_select_next = i;
                            match = 1'b1;
                        end
                    end
                end

                if (match) begin
                    // address decode successful
                    m_axil_avalid_next = 1'b1;
                    m_decerr_next = 1'b0;
                    m_wc_valid_next = WC_OUTPUT;
                    m_rc_valid_next = 1'b1;
                    state_next = STATE_DECODE;
                end else begin
                    // decode error
                    m_axil_avalid_next = 1'b0;
                    m_decerr_next = 1'b1;
                    m_wc_valid_next = WC_OUTPUT;
                    m_rc_valid_next = 1'b1;
                    state_next = STATE_DECODE;
                end
            end else begin
                state_next = STATE_IDLE;
            end
        end
        STATE_DECODE: begin
            if (!m_axil_avalid_next && (!m_wc_valid_next || !WC_OUTPUT) && !m_rc_valid_next) begin
                s_axil_aready_next = 1'b1;
                state_next = STATE_IDLE;
            end else begin
                state_next = STATE_DECODE;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        s_axil_aready_reg <= 1'b0;
        m_axil_avalid_reg <= 1'b0;
        m_wc_valid_reg <= 1'b0;
        m_rc_valid_reg <= 1'b0;
    end else begin
        state_reg <= state_next;
        s_axil_aready_reg <= s_axil_aready_next;
        m_axil_avalid_reg <= m_axil_avalid_next;
        m_wc_valid_reg <= m_wc_valid_next;
        m_rc_valid_reg <= m_rc_valid_next;
    end

    m_select_reg <= m_select_next;
    m_decerr_reg <= m_decerr_next;
end

endmodule

/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * AXI4 lite register (write)
 */
module axil_register_wr #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // AW channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AW_REG_TYPE = 1,
    // W channel register type
    // 0 to bypass, 1 for simple buffer
    parameter W_REG_TYPE = 1,
    // B channel register type
    // 0 to bypass, 1 for simple buffer
    parameter B_REG_TYPE = 1
)
(
    input  wire                     clk,
    input  wire                     rst,

    /*
     * AXI lite slave interface
     */
    input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [2:0]               s_axil_awprot,
    input  wire                     s_axil_awvalid,
    output wire                     s_axil_awready,
    input  wire [DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]    s_axil_wstrb,
    input  wire                     s_axil_wvalid,
    output wire                     s_axil_wready,
    output wire [1:0]               s_axil_bresp,
    output wire                     s_axil_bvalid,
    input  wire                     s_axil_bready,

    /*
     * AXI lite master interface
     */
    output wire [ADDR_WIDTH-1:0]    m_axil_awaddr,
    output wire [2:0]               m_axil_awprot,
    output wire                     m_axil_awvalid,
    input  wire                     m_axil_awready,
    output wire [DATA_WIDTH-1:0]    m_axil_wdata,
    output wire [STRB_WIDTH-1:0]    m_axil_wstrb,
    output wire                     m_axil_wvalid,
    input  wire                     m_axil_wready,
    input  wire [1:0]               m_axil_bresp,
    input  wire                     m_axil_bvalid,
    output wire                     m_axil_bready
);

generate

// AW channel

if (AW_REG_TYPE > 1) begin
// skid buffer, no bubble cycles

// datapath registers
reg                    s_axil_awready_reg = 1'b0;

reg [ADDR_WIDTH-1:0]   m_axil_awaddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              m_axil_awprot_reg   = 3'd0;
reg                    m_axil_awvalid_reg  = 1'b0, m_axil_awvalid_next;

reg [ADDR_WIDTH-1:0]   temp_m_axil_awaddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              temp_m_axil_awprot_reg   = 3'd0;
reg                    temp_m_axil_awvalid_reg  = 1'b0, temp_m_axil_awvalid_next;

// datapath control
reg store_axil_aw_input_to_output;
reg store_axil_aw_input_to_temp;
reg store_axil_aw_temp_to_output;

assign s_axil_awready  = s_axil_awready_reg;

assign m_axil_awaddr   = m_axil_awaddr_reg;
assign m_axil_awprot   = m_axil_awprot_reg;
assign m_axil_awvalid  = m_axil_awvalid_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire s_axil_awready_early = m_axil_awready | (~temp_m_axil_awvalid_reg & (~m_axil_awvalid_reg | ~s_axil_awvalid));

always @* begin
    // transfer sink ready state to source
    m_axil_awvalid_next = m_axil_awvalid_reg;
    temp_m_axil_awvalid_next = temp_m_axil_awvalid_reg;

    store_axil_aw_input_to_output = 1'b0;
    store_axil_aw_input_to_temp = 1'b0;
    store_axil_aw_temp_to_output = 1'b0;

    if (s_axil_awready_reg) begin
        // input is ready
        if (m_axil_awready | ~m_axil_awvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axil_awvalid_next = s_axil_awvalid;
            store_axil_aw_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axil_awvalid_next = s_axil_awvalid;
            store_axil_aw_input_to_temp = 1'b1;
        end
    end else if (m_axil_awready) begin
        // input is not ready, but output is ready
        m_axil_awvalid_next = temp_m_axil_awvalid_reg;
        temp_m_axil_awvalid_next = 1'b0;
        store_axil_aw_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_awready_reg <= 1'b0;
        m_axil_awvalid_reg <= 1'b0;
        temp_m_axil_awvalid_reg <= 1'b0;
    end else begin
        s_axil_awready_reg <= s_axil_awready_early;
        m_axil_awvalid_reg <= m_axil_awvalid_next;
        temp_m_axil_awvalid_reg <= temp_m_axil_awvalid_next;
    end

    // datapath
    if (store_axil_aw_input_to_output) begin
        m_axil_awaddr_reg <= s_axil_awaddr;
        m_axil_awprot_reg <= s_axil_awprot;
    end else if (store_axil_aw_temp_to_output) begin
        m_axil_awaddr_reg <= temp_m_axil_awaddr_reg;
        m_axil_awprot_reg <= temp_m_axil_awprot_reg;
    end

    if (store_axil_aw_input_to_temp) begin
        temp_m_axil_awaddr_reg <= s_axil_awaddr;
        temp_m_axil_awprot_reg <= s_axil_awprot;
    end
end

end else if (AW_REG_TYPE == 1) begin
// simple register, inserts bubble cycles

// datapath registers
reg                    s_axil_awready_reg = 1'b0;

reg [ADDR_WIDTH-1:0]   m_axil_awaddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              m_axil_awprot_reg   = 3'd0;
reg                    m_axil_awvalid_reg  = 1'b0, m_axil_awvalid_next;

// datapath control
reg store_axil_aw_input_to_output;

assign s_axil_awready  = s_axil_awready_reg;

assign m_axil_awaddr   = m_axil_awaddr_reg;
assign m_axil_awprot   = m_axil_awprot_reg;
assign m_axil_awvalid  = m_axil_awvalid_reg;

// enable ready input next cycle if output buffer will be empty
wire s_axil_awready_early = !m_axil_awvalid_next;

always @* begin
    // transfer sink ready state to source
    m_axil_awvalid_next = m_axil_awvalid_reg;

    store_axil_aw_input_to_output = 1'b0;

    if (s_axil_awready_reg) begin
        m_axil_awvalid_next = s_axil_awvalid;
        store_axil_aw_input_to_output = 1'b1;
    end else if (m_axil_awready) begin
        m_axil_awvalid_next = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_awready_reg <= 1'b0;
        m_axil_awvalid_reg <= 1'b0;
    end else begin
        s_axil_awready_reg <= s_axil_awready_early;
        m_axil_awvalid_reg <= m_axil_awvalid_next;
    end

    // datapath
    if (store_axil_aw_input_to_output) begin
        m_axil_awaddr_reg <= s_axil_awaddr;
        m_axil_awprot_reg <= s_axil_awprot;
    end
end

end else begin

    // bypass AW channel
    assign m_axil_awaddr = s_axil_awaddr;
    assign m_axil_awprot = s_axil_awprot;
    assign m_axil_awvalid = s_axil_awvalid;
    assign s_axil_awready = m_axil_awready;

end

// W channel

if (W_REG_TYPE > 1) begin
// skid buffer, no bubble cycles

// datapath registers
reg                   s_axil_wready_reg = 1'b0;

reg [DATA_WIDTH-1:0]  m_axil_wdata_reg  = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0]  m_axil_wstrb_reg  = {STRB_WIDTH{1'b0}};
reg                   m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

reg [DATA_WIDTH-1:0]  temp_m_axil_wdata_reg  = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0]  temp_m_axil_wstrb_reg  = {STRB_WIDTH{1'b0}};
reg                   temp_m_axil_wvalid_reg = 1'b0, temp_m_axil_wvalid_next;

// datapath control
reg store_axil_w_input_to_output;
reg store_axil_w_input_to_temp;
reg store_axil_w_temp_to_output;

assign s_axil_wready = s_axil_wready_reg;

assign m_axil_wdata  = m_axil_wdata_reg;
assign m_axil_wstrb  = m_axil_wstrb_reg;
assign m_axil_wvalid = m_axil_wvalid_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire s_axil_wready_early = m_axil_wready | (~temp_m_axil_wvalid_reg & (~m_axil_wvalid_reg | ~s_axil_wvalid));

always @* begin
    // transfer sink ready state to source
    m_axil_wvalid_next = m_axil_wvalid_reg;
    temp_m_axil_wvalid_next = temp_m_axil_wvalid_reg;

    store_axil_w_input_to_output = 1'b0;
    store_axil_w_input_to_temp = 1'b0;
    store_axil_w_temp_to_output = 1'b0;

    if (s_axil_wready_reg) begin
        // input is ready
        if (m_axil_wready | ~m_axil_wvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axil_wvalid_next = s_axil_wvalid;
            store_axil_w_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axil_wvalid_next = s_axil_wvalid;
            store_axil_w_input_to_temp = 1'b1;
        end
    end else if (m_axil_wready) begin
        // input is not ready, but output is ready
        m_axil_wvalid_next = temp_m_axil_wvalid_reg;
        temp_m_axil_wvalid_next = 1'b0;
        store_axil_w_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_wready_reg <= 1'b0;
        m_axil_wvalid_reg <= 1'b0;
        temp_m_axil_wvalid_reg <= 1'b0;
    end else begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;
        temp_m_axil_wvalid_reg <= temp_m_axil_wvalid_next;
    end

    // datapath
    if (store_axil_w_input_to_output) begin
        m_axil_wdata_reg <= s_axil_wdata;
        m_axil_wstrb_reg <= s_axil_wstrb;
    end else if (store_axil_w_temp_to_output) begin
        m_axil_wdata_reg <= temp_m_axil_wdata_reg;
        m_axil_wstrb_reg <= temp_m_axil_wstrb_reg;
    end

    if (store_axil_w_input_to_temp) begin
        temp_m_axil_wdata_reg <= s_axil_wdata;
        temp_m_axil_wstrb_reg <= s_axil_wstrb;
    end
end

end else if (W_REG_TYPE == 1) begin
// simple register, inserts bubble cycles

// datapath registers
reg                   s_axil_wready_reg = 1'b0;

reg [DATA_WIDTH-1:0]  m_axil_wdata_reg  = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0]  m_axil_wstrb_reg  = {STRB_WIDTH{1'b0}};
reg                   m_axil_wvalid_reg = 1'b0, m_axil_wvalid_next;

// datapath control
reg store_axil_w_input_to_output;

assign s_axil_wready = s_axil_wready_reg;

assign m_axil_wdata  = m_axil_wdata_reg;
assign m_axil_wstrb  = m_axil_wstrb_reg;
assign m_axil_wvalid = m_axil_wvalid_reg;

// enable ready input next cycle if output buffer will be empty
wire s_axil_wready_early = !m_axil_wvalid_next;

always @* begin
    // transfer sink ready state to source
    m_axil_wvalid_next = m_axil_wvalid_reg;

    store_axil_w_input_to_output = 1'b0;

    if (s_axil_wready_reg) begin
        m_axil_wvalid_next = s_axil_wvalid;
        store_axil_w_input_to_output = 1'b1;
    end else if (m_axil_wready) begin
        m_axil_wvalid_next = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_wready_reg <= 1'b0;
        m_axil_wvalid_reg <= 1'b0;
    end else begin
        s_axil_wready_reg <= s_axil_wready_early;
        m_axil_wvalid_reg <= m_axil_wvalid_next;
    end

    // datapath
    if (store_axil_w_input_to_output) begin
        m_axil_wdata_reg <= s_axil_wdata;
        m_axil_wstrb_reg <= s_axil_wstrb;
    end
end

end else begin

    // bypass W channel
    assign m_axil_wdata = s_axil_wdata;
    assign m_axil_wstrb = s_axil_wstrb;
    assign m_axil_wvalid = s_axil_wvalid;
    assign s_axil_wready = m_axil_wready;

end

// B channel

if (B_REG_TYPE > 1) begin
// skid buffer, no bubble cycles

// datapath registers
reg                   m_axil_bready_reg = 1'b0;

reg [1:0]             s_axil_bresp_reg  = 2'b0;
reg                   s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

reg [1:0]             temp_s_axil_bresp_reg  = 2'b0;
reg                   temp_s_axil_bvalid_reg = 1'b0, temp_s_axil_bvalid_next;

// datapath control
reg store_axil_b_input_to_output;
reg store_axil_b_input_to_temp;
reg store_axil_b_temp_to_output;

assign m_axil_bready = m_axil_bready_reg;

assign s_axil_bresp  = s_axil_bresp_reg;
assign s_axil_bvalid = s_axil_bvalid_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire m_axil_bready_early = s_axil_bready | (~temp_s_axil_bvalid_reg & (~s_axil_bvalid_reg | ~m_axil_bvalid));

always @* begin
    // transfer sink ready state to source
    s_axil_bvalid_next = s_axil_bvalid_reg;
    temp_s_axil_bvalid_next = temp_s_axil_bvalid_reg;

    store_axil_b_input_to_output = 1'b0;
    store_axil_b_input_to_temp = 1'b0;
    store_axil_b_temp_to_output = 1'b0;

    if (m_axil_bready_reg) begin
        // input is ready
        if (s_axil_bready | ~s_axil_bvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            s_axil_bvalid_next = m_axil_bvalid;
            store_axil_b_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_s_axil_bvalid_next = m_axil_bvalid;
            store_axil_b_input_to_temp = 1'b1;
        end
    end else if (s_axil_bready) begin
        // input is not ready, but output is ready
        s_axil_bvalid_next = temp_s_axil_bvalid_reg;
        temp_s_axil_bvalid_next = 1'b0;
        store_axil_b_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axil_bready_reg <= 1'b0;
        s_axil_bvalid_reg <= 1'b0;
        temp_s_axil_bvalid_reg <= 1'b0;
    end else begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;
        temp_s_axil_bvalid_reg <= temp_s_axil_bvalid_next;
    end

    // datapath
    if (store_axil_b_input_to_output) begin
        s_axil_bresp_reg <= m_axil_bresp;
    end else if (store_axil_b_temp_to_output) begin
        s_axil_bresp_reg <= temp_s_axil_bresp_reg;
    end

    if (store_axil_b_input_to_temp) begin
        temp_s_axil_bresp_reg <= m_axil_bresp;
    end
end

end else if (B_REG_TYPE == 1) begin
// simple register, inserts bubble cycles

// datapath registers
reg                   m_axil_bready_reg = 1'b0;

reg [1:0]             s_axil_bresp_reg  = 2'b0;
reg                   s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;

// datapath control
reg store_axil_b_input_to_output;

assign m_axil_bready = m_axil_bready_reg;

assign s_axil_bresp  = s_axil_bresp_reg;
assign s_axil_bvalid = s_axil_bvalid_reg;

// enable ready input next cycle if output buffer will be empty
wire m_axil_bready_early = !s_axil_bvalid_next;

always @* begin
    // transfer sink ready state to source
    s_axil_bvalid_next = s_axil_bvalid_reg;

    store_axil_b_input_to_output = 1'b0;

    if (m_axil_bready_reg) begin
        s_axil_bvalid_next = m_axil_bvalid;
        store_axil_b_input_to_output = 1'b1;
    end else if (s_axil_bready) begin
        s_axil_bvalid_next = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axil_bready_reg <= 1'b0;
        s_axil_bvalid_reg <= 1'b0;
    end else begin
        m_axil_bready_reg <= m_axil_bready_early;
        s_axil_bvalid_reg <= s_axil_bvalid_next;
    end

    // datapath
    if (store_axil_b_input_to_output) begin
        s_axil_bresp_reg <= m_axil_bresp;
    end
end

end else begin

    // bypass B channel
    assign s_axil_bresp = m_axil_bresp;
    assign s_axil_bvalid = m_axil_bvalid;
    assign m_axil_bready = s_axil_bready;

end

endgenerate

endmodule

/*

Copyright (c) 2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * AXI4 lite register (read)
 */
module axil_register_rd #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // AR channel register type
    // 0 to bypass, 1 for simple buffer
    parameter AR_REG_TYPE = 1,
    // R channel register type
    // 0 to bypass, 1 for simple buffer
    parameter R_REG_TYPE = 1
)
(
    input  wire                     clk,
    input  wire                     rst,

    /*
     * AXI lite slave interface
     */
    input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [2:0]               s_axil_arprot,
    input  wire                     s_axil_arvalid,
    output wire                     s_axil_arready,
    output wire [DATA_WIDTH-1:0]    s_axil_rdata,
    output wire [1:0]               s_axil_rresp,
    output wire                     s_axil_rvalid,
    input  wire                     s_axil_rready,

    /*
     * AXI lite master interface
     */
    output wire [ADDR_WIDTH-1:0]    m_axil_araddr,
    output wire [2:0]               m_axil_arprot,
    output wire                     m_axil_arvalid,
    input  wire                     m_axil_arready,
    input  wire [DATA_WIDTH-1:0]    m_axil_rdata,
    input  wire [1:0]               m_axil_rresp,
    input  wire                     m_axil_rvalid,
    output wire                     m_axil_rready
);

generate

// AR channel

if (AR_REG_TYPE > 1) begin
// skid buffer, no bubble cycles

// datapath registers
reg                    s_axil_arready_reg = 1'b0;

reg [ADDR_WIDTH-1:0]   m_axil_araddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              m_axil_arprot_reg   = 3'd0;
reg                    m_axil_arvalid_reg  = 1'b0, m_axil_arvalid_next;

reg [ADDR_WIDTH-1:0]   temp_m_axil_araddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              temp_m_axil_arprot_reg   = 3'd0;
reg                    temp_m_axil_arvalid_reg  = 1'b0, temp_m_axil_arvalid_next;

// datapath control
reg store_axil_ar_input_to_output;
reg store_axil_ar_input_to_temp;
reg store_axil_ar_temp_to_output;

assign s_axil_arready  = s_axil_arready_reg;

assign m_axil_araddr   = m_axil_araddr_reg;
assign m_axil_arprot   = m_axil_arprot_reg;
assign m_axil_arvalid  = m_axil_arvalid_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire s_axil_arready_early = m_axil_arready | (~temp_m_axil_arvalid_reg & (~m_axil_arvalid_reg | ~s_axil_arvalid));

always @* begin
    // transfer sink ready state to source
    m_axil_arvalid_next = m_axil_arvalid_reg;
    temp_m_axil_arvalid_next = temp_m_axil_arvalid_reg;

    store_axil_ar_input_to_output = 1'b0;
    store_axil_ar_input_to_temp = 1'b0;
    store_axil_ar_temp_to_output = 1'b0;

    if (s_axil_arready_reg) begin
        // input is ready
        if (m_axil_arready | ~m_axil_arvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            m_axil_arvalid_next = s_axil_arvalid;
            store_axil_ar_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_m_axil_arvalid_next = s_axil_arvalid;
            store_axil_ar_input_to_temp = 1'b1;
        end
    end else if (m_axil_arready) begin
        // input is not ready, but output is ready
        m_axil_arvalid_next = temp_m_axil_arvalid_reg;
        temp_m_axil_arvalid_next = 1'b0;
        store_axil_ar_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_arready_reg <= 1'b0;
        m_axil_arvalid_reg <= 1'b0;
        temp_m_axil_arvalid_reg <= 1'b0;
    end else begin
        s_axil_arready_reg <= s_axil_arready_early;
        m_axil_arvalid_reg <= m_axil_arvalid_next;
        temp_m_axil_arvalid_reg <= temp_m_axil_arvalid_next;
    end

    // datapath
    if (store_axil_ar_input_to_output) begin
        m_axil_araddr_reg <= s_axil_araddr;
        m_axil_arprot_reg <= s_axil_arprot;
    end else if (store_axil_ar_temp_to_output) begin
        m_axil_araddr_reg <= temp_m_axil_araddr_reg;
        m_axil_arprot_reg <= temp_m_axil_arprot_reg;
    end

    if (store_axil_ar_input_to_temp) begin
        temp_m_axil_araddr_reg <= s_axil_araddr;
        temp_m_axil_arprot_reg <= s_axil_arprot;
    end
end

end else if (AR_REG_TYPE == 1) begin
// simple register, inserts bubble cycles

// datapath registers
reg                    s_axil_arready_reg = 1'b0;

reg [ADDR_WIDTH-1:0]   m_axil_araddr_reg   = {ADDR_WIDTH{1'b0}};
reg [2:0]              m_axil_arprot_reg   = 3'd0;
reg                    m_axil_arvalid_reg  = 1'b0, m_axil_arvalid_next;

// datapath control
reg store_axil_ar_input_to_output;

assign s_axil_arready  = s_axil_arready_reg;

assign m_axil_araddr   = m_axil_araddr_reg;
assign m_axil_arprot   = m_axil_arprot_reg;
assign m_axil_arvalid  = m_axil_arvalid_reg;

// enable ready input next cycle if output buffer will be empty
wire s_axil_arready_early = !m_axil_arvalid_next;

always @* begin
    // transfer sink ready state to source
    m_axil_arvalid_next = m_axil_arvalid_reg;

    store_axil_ar_input_to_output = 1'b0;

    if (s_axil_arready_reg) begin
        m_axil_arvalid_next = s_axil_arvalid;
        store_axil_ar_input_to_output = 1'b1;
    end else if (m_axil_arready) begin
        m_axil_arvalid_next = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        s_axil_arready_reg <= 1'b0;
        m_axil_arvalid_reg <= 1'b0;
    end else begin
        s_axil_arready_reg <= s_axil_arready_early;
        m_axil_arvalid_reg <= m_axil_arvalid_next;
    end

    // datapath
    if (store_axil_ar_input_to_output) begin
        m_axil_araddr_reg <= s_axil_araddr;
        m_axil_arprot_reg <= s_axil_arprot;
    end
end

end else begin

    // bypass AR channel
    assign m_axil_araddr = s_axil_araddr;
    assign m_axil_arprot = s_axil_arprot;
    assign m_axil_arvalid = s_axil_arvalid;
    assign s_axil_arready = m_axil_arready;

end

// R channel

if (R_REG_TYPE > 1) begin
// skid buffer, no bubble cycles

// datapath registers
reg                   m_axil_rready_reg = 1'b0;

reg [DATA_WIDTH-1:0]  s_axil_rdata_reg  = {DATA_WIDTH{1'b0}};
reg [1:0]             s_axil_rresp_reg  = 2'b0;
reg                   s_axil_rvalid_reg = 1'b0, s_axil_rvalid_next;

reg [DATA_WIDTH-1:0]  temp_s_axil_rdata_reg  = {DATA_WIDTH{1'b0}};
reg [1:0]             temp_s_axil_rresp_reg  = 2'b0;
reg                   temp_s_axil_rvalid_reg = 1'b0, temp_s_axil_rvalid_next;

// datapath control
reg store_axil_r_input_to_output;
reg store_axil_r_input_to_temp;
reg store_axil_r_temp_to_output;

assign m_axil_rready = m_axil_rready_reg;

assign s_axil_rdata  = s_axil_rdata_reg;
assign s_axil_rresp  = s_axil_rresp_reg;
assign s_axil_rvalid = s_axil_rvalid_reg;

// enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
wire m_axil_rready_early = s_axil_rready | (~temp_s_axil_rvalid_reg & (~s_axil_rvalid_reg | ~m_axil_rvalid));

always @* begin
    // transfer sink ready state to source
    s_axil_rvalid_next = s_axil_rvalid_reg;
    temp_s_axil_rvalid_next = temp_s_axil_rvalid_reg;

    store_axil_r_input_to_output = 1'b0;
    store_axil_r_input_to_temp = 1'b0;
    store_axil_r_temp_to_output = 1'b0;

    if (m_axil_rready_reg) begin
        // input is ready
        if (s_axil_rready | ~s_axil_rvalid_reg) begin
            // output is ready or currently not valid, transfer data to output
            s_axil_rvalid_next = m_axil_rvalid;
            store_axil_r_input_to_output = 1'b1;
        end else begin
            // output is not ready, store input in temp
            temp_s_axil_rvalid_next = m_axil_rvalid;
            store_axil_r_input_to_temp = 1'b1;
        end
    end else if (s_axil_rready) begin
        // input is not ready, but output is ready
        s_axil_rvalid_next = temp_s_axil_rvalid_reg;
        temp_s_axil_rvalid_next = 1'b0;
        store_axil_r_temp_to_output = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axil_rready_reg <= 1'b0;
        s_axil_rvalid_reg <= 1'b0;
        temp_s_axil_rvalid_reg <= 1'b0;
    end else begin
        m_axil_rready_reg <= m_axil_rready_early;
        s_axil_rvalid_reg <= s_axil_rvalid_next;
        temp_s_axil_rvalid_reg <= temp_s_axil_rvalid_next;
    end

    // datapath
    if (store_axil_r_input_to_output) begin
        s_axil_rdata_reg <= m_axil_rdata;
        s_axil_rresp_reg <= m_axil_rresp;
    end else if (store_axil_r_temp_to_output) begin
        s_axil_rdata_reg <= temp_s_axil_rdata_reg;
        s_axil_rresp_reg <= temp_s_axil_rresp_reg;
    end

    if (store_axil_r_input_to_temp) begin
        temp_s_axil_rdata_reg <= m_axil_rdata;
        temp_s_axil_rresp_reg <= m_axil_rresp;
    end
end

end else if (R_REG_TYPE == 1) begin
// simple register, inserts bubble cycles

// datapath registers
reg                   m_axil_rready_reg = 1'b0;

reg [DATA_WIDTH-1:0]  s_axil_rdata_reg  = {DATA_WIDTH{1'b0}};
reg [1:0]             s_axil_rresp_reg  = 2'b0;
reg                   s_axil_rvalid_reg = 1'b0, s_axil_rvalid_next;

// datapath control
reg store_axil_r_input_to_output;

assign m_axil_rready = m_axil_rready_reg;

assign s_axil_rdata  = s_axil_rdata_reg;
assign s_axil_rresp  = s_axil_rresp_reg;
assign s_axil_rvalid = s_axil_rvalid_reg;

// enable ready input next cycle if output buffer will be empty
wire m_axil_rready_early = !s_axil_rvalid_next;

always @* begin
    // transfer sink ready state to source
    s_axil_rvalid_next = s_axil_rvalid_reg;

    store_axil_r_input_to_output = 1'b0;

    if (m_axil_rready_reg) begin
        s_axil_rvalid_next = m_axil_rvalid;
        store_axil_r_input_to_output = 1'b1;
    end else if (s_axil_rready) begin
        s_axil_rvalid_next = 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        m_axil_rready_reg <= 1'b0;
        s_axil_rvalid_reg <= 1'b0;
    end else begin
        m_axil_rready_reg <= m_axil_rready_early;
        s_axil_rvalid_reg <= s_axil_rvalid_next;
    end

    // datapath
    if (store_axil_r_input_to_output) begin
        s_axil_rdata_reg <= m_axil_rdata;
        s_axil_rresp_reg <= m_axil_rresp;
    end
end

end else begin

    // bypass R channel
    assign s_axil_rdata = m_axil_rdata;
    assign s_axil_rresp = m_axil_rresp;
    assign s_axil_rvalid = m_axil_rvalid;
    assign m_axil_rready = s_axil_rready;

end

endgenerate

endmodule

/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * Arbiter module
 */
module arbiter #
(
    parameter PORTS = 4,
    // select round robin arbitration
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    // blocking arbiter enable
    parameter ARB_BLOCK = 0,
    // block on acknowledge assert when nonzero, request deassert when 0
    parameter ARB_BLOCK_ACK = 1,
    // LSB priority selection
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,

    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,

    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

reg [PORTS-1:0] grant_reg = 0, grant_next;
reg grant_valid_reg = 0, grant_valid_next;
reg [$clog2(PORTS)-1:0] grant_encoded_reg = 0, grant_encoded_next;

assign grant_valid = grant_valid_reg;
assign grant = grant_reg;
assign grant_encoded = grant_encoded_reg;

wire request_valid;
wire [$clog2(PORTS)-1:0] request_index;
wire [PORTS-1:0] request_mask;

priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_inst (
    .input_unencoded(request),
    .output_valid(request_valid),
    .output_encoded(request_index),
    .output_unencoded(request_mask)
);

reg [PORTS-1:0] mask_reg = 0, mask_next;

wire masked_request_valid;
wire [$clog2(PORTS)-1:0] masked_request_index;
wire [PORTS-1:0] masked_request_mask;

priority_encoder #(
    .WIDTH(PORTS),
    .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
priority_encoder_masked (
    .input_unencoded(request & mask_reg),
    .output_valid(masked_request_valid),
    .output_encoded(masked_request_index),
    .output_unencoded(masked_request_mask)
);

always @* begin
    grant_next = 0;
    grant_valid_next = 0;
    grant_encoded_next = 0;
    mask_next = mask_reg;

    if (ARB_BLOCK && !ARB_BLOCK_ACK && grant_reg & request) begin
        // granted request still asserted; hold it
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_encoded_next = grant_encoded_reg;
    end else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid && !(grant_reg & acknowledge)) begin
        // granted request not yet acknowledged; hold it
        grant_valid_next = grant_valid_reg;
        grant_next = grant_reg;
        grant_encoded_next = grant_encoded_reg;
    end else if (request_valid) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (masked_request_valid) begin
                grant_valid_next = 1;
                grant_next = masked_request_mask;
                grant_encoded_next = masked_request_index;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    mask_next = {PORTS{1'b1}} << (masked_request_index + 1);
                end else begin
                    mask_next = {PORTS{1'b1}} >> (PORTS - masked_request_index);
                end
            end else begin
                grant_valid_next = 1;
                grant_next = request_mask;
                grant_encoded_next = request_index;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    mask_next = {PORTS{1'b1}} << (request_index + 1);
                end else begin
                    mask_next = {PORTS{1'b1}} >> (PORTS - request_index);
                end
            end
        end else begin
            grant_valid_next = 1;
            grant_next = request_mask;
            grant_encoded_next = request_index;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        grant_reg <= 0;
        grant_valid_reg <= 0;
        grant_encoded_reg <= 0;
        mask_reg <= 0;
    end else begin
        grant_reg <= grant_next;
        grant_valid_reg <= grant_valid_next;
        grant_encoded_reg <= grant_encoded_next;
        mask_reg <= mask_next;
    end
end

endmodule

/*

Copyright (c) 2014-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

/*
 * Priority encoder module
 */
module priority_encoder #
(
    parameter WIDTH = 4,
    // LSB priority selection
    parameter LSB_HIGH_PRIORITY = 0
)
(
    input  wire [WIDTH-1:0]         input_unencoded,
    output wire                     output_valid,
    output wire [$clog2(WIDTH)-1:0] output_encoded,
    output wire [WIDTH-1:0]         output_unencoded
);

parameter LEVELS = WIDTH > 2 ? $clog2(WIDTH) : 1;
parameter W = 2**LEVELS;

// pad input to even power of two
wire [W-1:0] input_padded = {{W-WIDTH{1'b0}}, input_unencoded};

wire [W/2-1:0] stage_valid[LEVELS-1:0];
wire [W/2-1:0] stage_enc[LEVELS-1:0];

generate
    genvar l, n;

    // process input bits; generate valid bit and encoded bit for each pair
    for (n = 0; n < W/2; n = n + 1) begin : loop_in
        assign stage_valid[0][n] = |input_padded[n*2+1:n*2];
        if (LSB_HIGH_PRIORITY) begin
            // bit 0 is highest priority
            assign stage_enc[0][n] = !input_padded[n*2+0];
        end else begin
            // bit 0 is lowest priority
            assign stage_enc[0][n] = input_padded[n*2+1];
        end
    end

    // compress down to single valid bit and encoded bus
    for (l = 1; l < LEVELS; l = l + 1) begin : loop_levels
        for (n = 0; n < W/(2*2**l); n = n + 1) begin : loop_compress
            assign stage_valid[l][n] = |stage_valid[l-1][n*2+1:n*2];
            if (LSB_HIGH_PRIORITY) begin
                // bit 0 is highest priority
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+0] ? {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]} : {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]};
            end else begin
                // bit 0 is lowest priority
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+1] ? {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]} : {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]};
            end
        end
    end
endgenerate

assign output_valid = stage_valid[LEVELS-1];
assign output_encoded = stage_enc[LEVELS-1];
assign output_unencoded = 1 << output_encoded;

endmodule

`resetall