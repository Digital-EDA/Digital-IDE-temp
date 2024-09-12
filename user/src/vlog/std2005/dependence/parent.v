/* 
   CN: 

*/

// CN: 代码转文档测试功能
/* @wavedrom this is wavedrom demo1
{
    signal : [
        { name: "clk",  wave: "p......" },
        { name: "bus",  wave: "x.34.5x", data: "head body tail" },
        { name: "wire", wave: "0.1..0." }
    ]
}
*/

`include "head.v"

`define main_out out

module Main (
    // Main input
    input clk, reset, a, b, c,
    // Main output
    output Qus, Qs, Qa, `main_out
);

// CN: 1. 本地文件依赖，include和非include区别
//     2. 自动跳转至依赖部分
//     3. 依赖注释的悬停提示
//     4. 依赖内容的自动补全
// 1. include from head.v
// 2. no include from child.v or head.v
child u0_child(
    .a(a),
    .b(b),
    .c(c),
    .Result(Qus)
);

// CN: 同名不同端口的模块定位
child u1_child(
    .port_a(a),
    .port_b(b),
    .port_c(c),
    .out_q(Qs)
);

moreModule u_moreModule(
    .port_a(a),
    .port_b(b),
    .Q(Qa)
);

// CN: 库模块（外部文件）的依赖
wire [11:0] 	x_o;
wire [11:0] 	y_o;
wire [11:0] 	phase_out;
wire            valid_out;

Cordic #(
	.XY_BITS      	( 12        ),
	.PH_BITS      	( 32        ),
	.ITERATIONS   	( 32        ),
	.CORDIC_STYLE 	( "ROTATE"  ),
	.PHASE_ACC    	( "ON"      )) 
u_Cordic(
	.clk       	( clk        ),
	.RST       	( reset      ),
	.x_i       	( a          ),
	.y_i       	( b          ),
	.phase_in  	( c          ),
	.x_o       	( x_o        ),
	.y_o       	( y_o        ),
	.phase_out 	( phase_out  ),
	.valid_in  	( 1'b1       ),
	.valid_out 	( valid_out  )
);


// CN: 跨文件宏定义
assign `main_out = `K_COE;

endmodule

/* @wavedrom this is wavedrom demo2
{ 
    signal: [
    { name: "pclk", wave: 'p.......' },
    { name: "Pclk", wave: 'P.......' },
    { name: "nclk", wave: 'n.......' },
    { name: "Nclk", wave: 'N.......' },
    {},
    { name: 'clk0', wave: 'phnlPHNL' },
    { name: 'clk1', wave: 'xhlhLHl.' },
    { name: 'clk2', wave: 'hpHplnLn' },
    { name: 'clk3', wave: 'nhNhplPl' },
    { name: 'clk4', wave: 'xlh.L.Hx' },
]}
*/