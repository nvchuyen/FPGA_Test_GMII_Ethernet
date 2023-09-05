`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test
//////////////////////////////////////////////////////////////////////////////////
module ethernet_test(
					input  reset_n,                           
					input  fpga_gclk,                   
					output e_reset,
//               output CLK_25_ASIC,
                    output e_mdc,
					inout  e_mdio,
		
            
					input  e_rxc,                       //125Mhz ethernet gmii rx clock
					input  e_rxdv,	
					input  e_rxer,						
					input  [7:0] e_rxd,        

					input  e_txc,                     //25Mhz ethernet mii tx clock         
					output e_gtxc,                    //25Mhz ethernet gmii tx clock  
					output e_txen, 
					output e_txer, 					
					output [7:0] e_txd	 
    );

wire [31:0] ram_wr_data;
wire [31:0] ram_rd_data;
wire [8:0] ram_wr_addr;
wire [8:0] ram_rd_addr;

assign e_gtxc=e_rxc;	                //gtxc输出125Mhz的时�?
assign e_reset = 1'b1; 

wire [31:0] datain_reg;
         
wire [3:0] tx_state;
wire [3:0] rx_state;
wire [15:0] rx_total_length;          //rx 的IP包的长度
wire [15:0] tx_total_length;          //tx 的IP包的长度
wire [15:0] rx_data_length;           //rx 的UDP的数据包长度
wire [15:0] tx_data_length;           //rx 的UDP的数据包长度

wire data_receive;
reg ram_wr_finish;

reg [31:0] udp_data [4:0];                        //存储发�?�字�?
reg ram_wren_i;
reg [8:0] ram_addr_i;
reg [31:0] ram_data_i;
reg [4:0] i;

wire data_o_valid;
wire wea;
wire [8:0] addra;
wire [31:0] dina;

assign wea=ram_wr_finish?data_o_valid:ram_wren_i;
assign addra=ram_wr_finish?ram_wr_addr:ram_addr_i;
assign dina=ram_wr_finish?ram_wr_data:ram_data_i;

assign tx_data_length=data_receive?rx_data_length:16'd28;
assign tx_total_length=data_receive?rx_total_length:16'd48;

////////udp发�?�和接收程序/////////////////// 
udp u1(
	.reset_n(reset_n),
	.e_rxc(e_rxc),
	.e_rxd(e_rxd),
   .e_rxdv(e_rxdv),
	.e_txen(e_txen),
	.e_txd(e_txd),
	.e_txer(e_txer),		
	
	.data_o_valid(data_o_valid),                    //数据接收有效信号,写入RAM/
	.ram_wr_data(ram_wr_data),                      //接收到的32bit数据写入RAM/	
	.rx_total_length(rx_total_length),              //接收IP包的总长�?/
	.rx_state(rx_state),                            //for chipscope test
	.rx_data_length(rx_data_length),                //接收IP包的数据长度/	
	.ram_wr_addr(ram_wr_addr),                      //ram写数据地�?
	.data_receive(data_receive),                    //接收到以太网数据包标�?

	.ram_rd_data(ram_rd_data),                      //RAM读出�?32bit数据/
	.tx_state(tx_state),                            //for chipscope test

	.tx_data_length(tx_data_length),                //发�?�IP包的数据长度/	
	.tx_total_length(tx_total_length),              //接发送IP包的总长�?/
	.ram_rd_addr(ram_rd_addr)                       //ram读数据地�?

	);

//////////ram用于存储以太网接收到的数据或测试数据///////////////////
dist_mem_gen_0 ram_inst (
    .a(addra),
    .d(dina),
    .dpra(ram_rd_addr),
    .clk(e_rxc),
    .we(wea),
    .dpo(ram_rd_data)
);

/********************************************/
//存储待发送的字符
/********************************************/
always @(*)
begin     //定义发�?�的字符
	udp_data[0]<={8'd72,8'd69,8'd76,8'd76};   //存储字符'H' 'E' 'L' 'L' 
	udp_data[1]<={8'd79,8'd32,8'd81,8'd77};   //存储字符'O' '空格' 'Q' 'M' 
    udp_data[2]<={8'd84,8'd69,8'd67,8'd72};   //存储字符'T' 'E' 'C' 'H'
	udp_data[3]<={8'd32,8'd66,8'd79,8'd65};   //存储字符'空格' 'B' 'O' 'A' 	 
	udp_data[4]<={8'd82,8'd68,8'd10,8'd13};   //存储字符'R' 'D' '换行�?' '回车�?'                            
end 

//////////RAM写入默认发�?�的数据//////////////////
always@(negedge e_rxc)
begin	
  if(reset_n==1'b0) begin
     ram_wr_finish<=1'b0;
	  ram_addr_i<=0;
	  ram_data_i<=0;
	  i<=0;
  end
  else begin
     if(i==5) begin
        ram_wr_finish<=1'b1;
        ram_wren_i<=1'b0;		  
     end
     else begin
        ram_wren_i<=1'b1;
		  ram_addr_i<=ram_addr_i+1'b1;
		  ram_data_i<=udp_data[i];
		  i<=i+1'b1;
	  end
  end 
end 

endmodule
