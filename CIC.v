module CIC(clk,reset,ready,busy,iaddr,idata,crd,cdata_rd,caddr_rd,cwr,cdata_wr,caddr_wr,csel);
input clk;
input reset;//非同步重置信號
input ready;//為1時灰階圖像準備完成
output busy;//=1時進行輸入灰階圖像資料索取(索取致能)
output [11:0] iaddr;//輸入灰階圖像位址訊號
input [19:0] idata;//輸入灰階圖像像素資料訊號

output crd;//CONV 運算輸出記憶體讀取致能訊號
input  [19:0] cdata_rd;//CONV 運算結果記憶體讀取訊號
output [11:0] caddr_rd;//CONV 運算結果記憶體讀取位址

output cwr;//CONV 運算輸出記憶體寫入致能訊號
output [19:0] cdata_wr;//CONV 運算結果記憶體寫出訊號
output [11:0] caddr_wr;//CONV 運算結果記憶體寫入位址
output [2:0] csel;//CONV 運算處理結果寫入/讀取記憶體選擇訊號。
//===========================================================================


reg ready;//
reg busy;
reg [63:0] x,y,k,m;//img位置判斷
reg [8:0] z ;
reg [11:0] iaddr;
reg [61:0] x_addr, y_addr;//test
reg [2:0] csel;
reg [63:0] LBP_bin_1, LBP_bin_2, LBP_bin_3, LBP_bin_4, LBP_bin_5, LBP_bin_6, LBP_bin_7, LBP_bin_8, LBP_bin_9;

reg [4095:0] i_mem ,
parameter NSEL = 3'b000, L0K0 = 3'b001,  L0K1 = 3'b010, L1K0 = 3'b011, L1K1 = 3'b100, L2F = 3'b101;//多工器，命名增加可讀性

//========zero pedding=======
always @(posedge clk) begin
    
end
//===========================

always @(posedge clk or posedge reset ) begin
    if (reset) begin
        csel <= NSEL; ready <= 1; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
    end
    else begin
        case (csel)
           NSEL : begin//沒有選擇記憶體
               ready <= 1; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
           end
           L0K0 : begin//寫入/讀取 Layer 0，Kernel 0 執行 Convolutional 的結果。

               
           end
           L0K1 : begin//寫入/讀取 Layer 0，Kernel 1 執行 Convolutional 的結果。
               
           end
           L1K0 : begin//寫入/讀取 Layer 1，將 Kernel 0 執行 Convolutional後再進行 Max-pooling 運算的結果。
               
           end
           L1K1 : begin//寫入/讀取 Layer 1，將 Kernel 1 執行 Convolutional後再進行 Max-pooling 運算的結果。
               
           end
           L2F : begin//表示寫入/讀取 Layer 2，Flatten 層的運算結果。
               
           end
            default: begin
                csel <= NSEL; ready <= 1; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
            end
        endcase
    end

end

always@(posedge clk)
	m <= k;
    always@(*) begin
        case (k)//LBP的位置
		1 : begin y_addr = y - 1; x_addr = x - 1; end
		2 : begin y_addr = y - 1; x_addr = x    ; end  
		3 : begin y_addr = y - 1; x_addr = x + 1; end
		4 : begin y_addr = y    ; x_addr = x - 1; end
		5 : begin y_addr = y    ; x_addr = x    ; end
		6 : begin y_addr = y    ; x_addr = x + 1; end
		7 : begin y_addr = y + 1; x_addr = x - 1; end
		8 : begin y_addr = y + 1; x_addr = x    ; end
		9 : begin y_addr = y + 1; x_addr = x + 1; end
		endcase
		gray_addr_tmp = ((y_addr-1)<<3 ) + (x_addr-1);
		
end
 always@(posedge clk)
     always@(*) begin
         case (z)
         1 : if y_addr = 1 and x_addr < 3
         LBP_bin_1,LBP_bin_2,LBP_bin_3,LBP_bin_4,LBP_bin_7 <= 0; 
         2 : if y_addr = 1 and x_addr >3
         LBP_bin_1,LBP_bin_2,LBP_bin_3 <= 0 ;
         3 : if y_addr = 1 and x_addr > 61
         LBP_bin_1,LBP_bin_2,LBP_bin_3,LBP_bin_6,LBP_bin_9 <= 0; 
         4 : if y_addr > 3 and x_addr < 3
         LBP_bin_1,LBP_bin_4,LBP_bin_7 <= 0 ;
         5 : if y_addr > 3 and x_addr > 3 
         LBP_bin_1 <= gray_data;
         6 : if y_addr > 3 and x_addr >61
         LBP_bin_3,LBP_bin_6,LBP_bin_9 <= 0 ; 
         7 : if y_addr >61 and x_addr <3
         LBP_bin_1,LBP_bin_4,LBP_bin_7,LBP_bin_8,LBP_bin_9 <= 0; 
         8 : if y_addr >61 and x_addr >3
        LBP_bin_7,LBP_bin_8,LBP_bin_9 <= 0 ;
         9 : if y_addr >61 and x_addr >61
         LBP_bin_3,LBP_bin_6,LBP_bin_7,LBP_bin_8,LBP_bin_9 <= 0; 

         endcase
end
//============================================
always@(posedge clk) begin
 case (m)//收gray_meme給的資料(共9格的資料)
 	1: LBP_bin_1 <= gray_data;//每一個bin都是8bit
	2: LBP_bin_2 <= gray_data;
	3: LBP_bin_3 <= gray_data;
	4: LBP_bin_4 <= gray_data;
	5: LBP_bin_5 <= gray_data;
	6: LBP_bin_6 <= gray_data;
	7: LBP_bin_7 <= gray_data;
	8: LBP_bin_8 <= gray_data;
	9: LBP_bin_9 <= gray_data;
 endcase
end


endmodule


endmodule
