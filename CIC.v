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
reg zeropedding;
reg readtestbench,writetestbench;
reg [65:0] x,y,k,m;//img位置判斷x從2~65是原圖片
reg [6:0] x_addr,y_addr;
reg [11:0] iaddr,iaddr_temp;


reg [2:0] csel;
reg [3:0] 0judge;

reg [19:0]  Block_1,Block_2,Block_3,Block_4, Block_5, Block_6, Block_7, Block_8, Block_9;
reg [19:0]  Block_1_K1,Block_2_K1,Block_3_K1,Block_4_K1, Block_5_K1, Block_6_K1, Block_7_K1, Block_8_K1, Block_9_K1;
reg [19:0]  Block_1_K0,Block_2_K0,Block_3_K0,Block_4_K0, Block_5_K0, Block_6_K0, Block_7_K0, Block_8_K0, Block_9_K0;
reg [19:0]  K0,K1;
reg [19:0]  L0_MEM0,L0_MEM1 ;

parameter NSEL = 3'b000, L0K0 = 3'b001,  L0K1 = 3'b010, L1K0 = 3'b011, L1K1 = 3'b100, L2F = 3'b101;//多工器，命名增加可讀性
parameter UL=4'b0000 ,UR=4'b0001,BL=4'b0010,BR=4'b0011,U=4'b0100,R=4'b0101,L=4'b0110,B=4'b0111,M=4'b1000;
parameter IDLE = 2'b00, LOAD = 2'b01, CHPIX = 2'b11, COMP = 2'b10;//多工器，命名增加可讀性

/*always @(posedge zeropedding) begin//9個zeropedding狀態判斷
    if (x==2 && y==2) begin//iaddr==0 x=2 y=2 iaddr==12'h000
        0judge <= UL;
    end
    else if(x==65 && y==2)begin//iaddr==63 x=65 y=2 iaddr==12'h03F
        0judge <= UR;
    end
    else if(x==2 && y==65)begin//iaddr==4031 x=2 y=65 iaddr==12'hFC0
        0judge <= BL;
    end
    else if(x==65 && y==65)begin//iaddr==4095 iaddr==12'hFFF x=65 y=65
        0judge <= BR;
    end
    else if(y==2)begin //iaddr<12'h03F
        0judge <= U;
    end
    else if(y==65)begin//iaddr>12'hFC0 && iaddr<12'hFFF
        0judge <= B;
    end
    else if(x==2)begin//iaddr%64==0 (iaddr<<6)==12'h000
        0judge <= L;
    end
    else if(x==65)begin//(iaddr+1)%64==0 (!iaddr<<6)==12'h000
        0judge <= R;
    end
end
//========實現zero pedding=======
always @(negedge clk) begin
    if(zeropedding==1)begin
        casez (0judge)
        UL: begin//左上
            Block_1 <= 20'h00000;
            Block_2 <= 20'h00000;
            Block_3 <= 20'h00000;
            Block_4 <= 20'h00000;
            Block_7 <= 20'h00000;
        end
        UR: begin//上
            Block_1 <= 20'h00000;
            Block_2 <= 20'h00000;
            Block_3 <= 20'h00000;
            Block_6 <= 20'h00000;
            Block_9 <= 20'h00000;            
        end
        BL: begin//右上
            Block_1 <= 20'h00000;
            Block_4 <= 20'h00000;
            Block_7 <= 20'h00000;
            Block_8 <= 20'h00000;
            Block_9 <= 20'h00000;
        end
        BR: begin//右
            Block_3 <= 20'h00000;
            Block_6 <= 20'h00000;
            Block_7 <= 20'h00000;
            Block_8 <= 20'h00000;
            Block_9 <= 20'h00000;
        end
        U: begin//右下
            Block_1 <= 20'h00000;
            Block_2 <= 20'h00000;
            Block_3 <= 20'h00000;
        end
        R: begin//下
            Block_3 <= 20'h00000;
            Block_6 <= 20'h00000;
            Block_9 <= 20'h00000;
        end
        L: begin//左下
            Block_1 <= 20'h00000;
            Block_4 <= 20'h00000;
            Block_7 <= 20'h00000;
        end
        B: begin//左
            Block_7 <= 20'h00000;
            Block_8 <= 20'h00000;
            Block_9 <= 20'h00000;
        end
        default: 
        zeropedding <= 0;
    endcase
    zeropedding <= 0;
    end
     

end*/
//===========================

/*always @(*) begin
    
     Block_1_K0 <= (Block_1*20'h0A89E-20'h01310 > 0)?Block_1*20'h0A89E-20'h01310:0;
     Block_2_K0 <= (Block_2*20'h092D5-20'h01310 > 0)?Block_2*20'h092D5-20'h01310:0;
     Block_3_K0 <= (Block_3*20'h06D43-20'h01310 > 0)?Block_3*20'h06D43-20'h01310:0;
     Block_4_K0 <= (Block_4*20'h0A004-20'h01310 > 0)?Block_4*20'h0A004-20'h01310:0;
     Block_5_K0 <= (Block_5*20'hF8F71-20'h01310 > 0)?Block_5*20'hF8F71-20'h01310:0;
     Block_6_K0 <= (Block_6*20'hF6E54-20'h01310 > 0)?Block_6*20'hF6E54-20'h01310:0;
     Block_7_K0 <= (Block_7*20'hFA6D7-20'h01310 > 0)?Block_7*20'hFA6D7-20'h01310:0;
     Block_8_K0 <= (Block_8*20'hFC834-20'h01310 > 0)?Block_8*20'hFC834-20'h01310:0;
     Block_9_K0 <= (Block_9*20'hFAC19-20'h01310 > 0)?Block_9*20'hFAC19-20'h01310:0;
    
     Block_1_K1 <= (Block_1*20'hFDB55-20'hF7295 >0)?Block_1*20'hFDB55-20'hF7295:0;
     Block_2_K1 <= (Block_2*20'h02992-20'hF7295 >0)?Block_2*20'h02992-20'hF7295:0;
     Block_3_K1 <= (Block_3*20'hFC994-20'hF7295 >0)?Block_3*20'hFC994-20'hF7295:0;
     Block_4_K1 <= (Block_4*20'h050FD-20'hF7295 >0)?Block_4*20'h050FD-20'hF7295:0;
     Block_5_K1 <= (Block_5*20'h02F20-20'hF7295 >0)?Block_5*20'h02F20-20'hF7295:0;
     Block_6_K1 <= (Block_6*20'h0202D-20'hF7295 >0)?Block_6*20'h0202D-20'hF7295:0;
     Block_7_K1 <= (Block_7*20'h03BD7-20'hF7295 >0)?Block_7*20'h03BD7-20'hF7295:0;
     Block_8_K1 <= (Block_8*20'hFD369-20'hF7295 >0)?Block_8*20'hFD369-20'hF7295:0;
     Block_9_K1 <= (Block_9*20'h05E68-20'hF7295 >0)?Block_9*20'h05E68-20'hF7295:0;
end//k=9時才能啟動*/

always @(posedge busy) begin
    ready <=0;
end
always @(negedge busy) begin
    ready <=1;
end

always @(posedge clk or posedge reset ) begin
    if (reset) begin
        csel <= NSEL; state <= IDLE; ready <= 0; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
        zeropedding <= 0;
    end
    else begin
        case (state)
	IDLE : begin //
        csel <= NSEL;
		state <=  LOAD;  
		ready <= 1; busy <= 0;
		x <= 2; y <= 2; k <= 1;
		crd <= 0; cwr <= 0;
		end
	LOAD : begin //要求testfixture給資料
		crd <= 0; cwr <= 0;
        busy <= 1;
		k <= k + 1;
		if (k == 9) {
        K0=Block_1_K0+Block_2_K0+Block_3_K0+Block_4_K0+Block_5_K0+Block_6_K0+Block_7_K0+Block_8_K0+Block_9_K0;
        K1=Block_1_K1+Block_2_K1+Block_3_K1+Block_4_K1+Block_5_K1+Block_6_K1+Block_7_K1+Block_8_K1+Block_9_K1;
        begin state <= COMP;  end//寫入第8狀態時k就會變成9，下一個狀態就會寫入完畢、所以進入COMP狀態
        }
		else state <= LOAD;
		end
	COMP : begin //關掉向testfixture讀寫資料的權限，算下一個像素
		state <= CHPIX;
        cwr <= 1;
		end
	CHPIX : begin //一列一列讀，令x為列y為行，可稱為一列一列讀
		
		if ((x==65)&(y==65)) begin state <= IDLE;  end //整張圖片(12byte)寫入完成
		else if (x == 65) begin y <= y + 1; x <= 2; k<= 1; state<= LOAD; end //若一列x讀完，換行繼續讀
		else begin x <= x + 1; k<= 1; state <= LOAD; end//讀該列的x
		end
	endcase
    end

end

always @(posedge clk) begin
    case (csel)
           NSEL : begin//沒有選擇記憶體
                crd <= 0; cwr <= 0;
           end
           L0K0 : begin//寫入/讀取 Layer 0，Kernel 0 執行 Convolutional 的結果。
            L0_MEM0=(K0-20'h01310 > 0)?(K0-20'h01310):0;    
               
           end
           L0K1 : begin//寫入/讀取 Layer 0，Kernel 1 執行 Convolutional 的結果。
            L0_MEM1=(K1-20'hF7295 > 0)?(K1-20'hF7295):0;   
           end
           L1K0 : begin//寫入/讀取 Layer 1，將 Kernel 0 執行 Convolutional後再進行 Max-pooling 運算的結果。
               
           end
           L1K1 : begin//寫入/讀取 Layer 1，將 Kernel 1 執行 Convolutional後再進行 Max-pooling 運算的結果。
               
           end
           L2F :  begin//表示寫入/讀取 Layer 2，Flatten 層的運算結果。
               
           end
            default: begin
                csel <= NSEL; ready <= 1; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
            end
    endcase
end
/*

*/

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
        if(y_addr==1 || x_addr==1 || y_addr==66 || x_addr==66)begin
            zeropedding <= 1;
            case (k)//收texfixture給的img pixal資料(共9格的資料)
        	    1: begin
                    Block_1 <= 20'h00000 ;
                    Block_1_K0 <= Block_1*20'h0A89E;
                    Block_1_K1 <= Block_1*20'hFDB55;
                   end
        	    2: begin
                    Block_2 <= 20'h00000 ;
                    Block_2_K0 <= Block_2*20'h092D5;
                    Block_2_K1 <= Block_2*20'h02992;
                   end
	            3: begin
                    Block_3 <= 20'h00000 ;
                    Block_3_K0 <= Block_3*20'h06D43;
                    Block_3_K1 <= Block_3*20'hFC994;
                   end
                   end
	            4: begin
                    Block_4 <= 20'h00000 ;
                    Block_4_K0 <= Block_4*20'h0A004;
                    Block_4_K1 <= Block_4*20'h050FD;
                   end
	            5:begin
                    Block_5 <= 20'h00000 ;
                    Block_5_K0 <= Block_5*20'hF8F71;
                    Block_5_K1 <= Block_5*20'h02F20;
                   end
	            6: begin
                    Block_6 <= 20'h00000 ;
                    Block_6_K0 <= Block_6*20'hF6E54;
                    Block_6_K1 <= Block_6*20'h0202D;
                   end
	            7: begin
                    Block_7 <= 20'h00000 ;
                   Block_7_K0 <= Block_7*20'hFA6D7;
                   Block_7_K1 <= Block_7*20'h03BD7;
                   end
	            8: begin
                    Block_8 <= 20'h00000 ;
                    Block_8_K0 <= Block_8*20'hFC834;
                    Block_8_K1 <= Block_8*20'hFD369;
                   end
	            9: begin
                    Block_9 <= 20'h00000 ;
                    Block_9_K0 <= Block_9*20'hFAC19;
                    Block_9_K1 <= Block_9*20'h05E68;
                   end
            endcase

        end
         else begin
	    	iaddr_tmp = ((y_addr-2)<<6 ) + (x_addr-2);
        end
        
end
always @(posedge clk) begin
       iaddr <= iaddr_tmp
end

//============================================
always@(negedge clk) begin
    if(zeropedding==0)begin
        
        case (m)//收texfixture給的img pixal資料(共9格的資料)
        	1:begin
               Block_1 <= idata ;
               Block_1_K0 <= Block_1*20'h0A89E;//每一個bin都是20bit
               Block_1_K1 <= Block_1*20'hFDB55;
              end
        	2: begin
               Block_2 <= idata ;
               Block_2_K0 <= Block_2*20'h092D5;
               Block_2_K1 <= Block_2*20'h02992;
               end
	        3: begin
               Block_3 <= idata ;
               Block_3_K0 <= Block_3*20'h06D43;
               Block_3_K1 <= Block_3*20'hFC994;
               end
	        4: begin
               Block_4 <= idata ;
               Block_4_K0 <= Block_4*20'h0A004;
               Block_4_K1 <= Block_4*20'h050FD;
               end
	        5: begin
               Block_5 <= idata ;
               Block_5_K0 <= Block_5*20'hF8F71;
               Block_5_K1 <= Block_5*20'h02F20;
               end
	        6: begin
               Block_6 <= idata ;
               Block_6_K0 <= Block_6*20'hF6E54;
               Block_6_K1 <= Block_6*20'h0202D;
               end
	        7: begin
               Block_7 <= idata ;
               Block_7_K0 <= Block_7*20'hFA6D7;
               Block_7_K1 <= Block_7*20'h03BD7;
               end
	        8: begin
               Block_8 <= idata ;
               Block_8_K0 <= Block_8*20'hFC834;
               Block_8_K1 <= Block_8*20'hFD369;
               end
	        9: begin
               Block_9 <= idata ;
               Block_9_K0 <= Block_9*20'hFAC19;
               Block_9_K1 <= Block_9*20'h05E68;
               end
            
        endcase
    end
end

endmodule
