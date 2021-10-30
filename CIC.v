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
reg [65:0] x,y,k,m;//img位置判斷x從2~65是原圖片
reg [6:0] x_addr,y_addr;
reg [11:0] iaddr,iaddr_temp;

reg [2:0] csel;
reg [3:0] 0judge;

parameter NSEL = 3'b000, L0K0 = 3'b001,  L0K1 = 3'b010, L1K0 = 3'b011, L1K1 = 3'b100, L2F = 3'b101;//多工器，命名增加可讀性
parameter UL=4'b0000 ,UR=4'b0001,BL=4'b0010,BR=4'b0011,U=4'b0100,R=4'b0101,L=4'b0110,B=4'b0111,M=4'b1000;
parameter IDLE = 2'b00, LOAD = 2'b01, WRITE = 2'b11, COMP = 2'b10;//多工器，命名增加可讀性

always @(posedge clk) begin//9個zeropedding狀態判斷
    if (iaddr==12'h000) begin//iaddr==0 x=1 y=1
        0judge <= UL;
    end
    else if(iaddr==12'h03F)begin//iaddr==63 x=64 y=1
        0judge <= UR;
    end
    else if(iaddr==12'hFC0)begin//iaddr==4031 x=1 y=64
        0judge <= BL;
    end
    else if(iaddr==12'hFFF)begin//iaddr==4095 x=64 y=64
        0judge <= BR;
    end
    else if(iaddr<12'h03F)begin
        0judge <= U;
    end
    else if(iaddr>12'hFC0 && iaddr<12'hFFF)begin
        0judge <= B;
    end
    else if((iaddr<<6)==12'h000)begin//iaddr%64==0
        0judge <= L;
    end
    else if((!iaddr<<6)==12'h000)begin//(iaddr+1)%64==0
        0judge <= R;
    end
    else begin
        0judge <= M;
    end
end
//========實現zero pedding=======
always @(posedge clk) begin
     casez (0judge)
        UL: begin//左上
            
        end
        UR: begin//上
            
        end
        BL: begin//右上
            
        end
        BR: begin//右
            
        end
        U: begin//右下
            
        end
        R: begin//下
            
        end
        L: begin//左下
            
        end
        B: begin//左
            
        end
        M: begin//左
            
        end
        default: 
        reset <= 1;
    endcase

end
//===========================


always @(posedge clk or posedge reset ) begin
    if (reset) begin
        csel <= NSEL; state <= IDLE; ready <= 0; busy <= 0; crd <= 0; cwr <= 0; x <= 2; y <= 2; k <= 1;
    end
    else begin
        case (state)
	IDLE : begin //
        csel <= NSEL;
		state <=  LOAD;  
		ready <= 1; 
		x <= 2; y <= 2; k <= 1;
		crd <= 0; cwr <= 0;
		end
	LOAD : begin //要求testfixture給資料
		crd <= 0; cwr <= 0;
		ready <= 1;
        busy <= 1;
		k <= k + 1;
		if (k == 9) begin state <= COMP;   ready <= 1;end//寫入第8狀態時k就會變成9，下一個狀態就會寫入完畢、所以進入COMP狀態
		else state <= LOAD;
		end
	COMP : begin //過渡狀態，關掉向testfixture要資料的權限，開始進入寫入狀態
		state <= WRITE;
		ready <= 0;
        busy <= 0;
		end
	WRITE : begin //一列一列讀，令x為列y為行，可稱為一列一列讀
		lbp_valid <= 1;
		if ((x==65)&(y==65)) begin state <= IDLE; finish <= 1; ready <= 0; end //若已經讀到x、y皆為7(8個資料)表示寫入完成，讓finish=1
		else if (x == 65) begin y <= y + 1; x <= 2; k<= 1; state<= LOAD; ready <= 0;end //若一列x讀完，換行繼續讀
		else begin x <= x + 1; k<= 1; state<= LOAD; ready <= 0;end//讀該列的x
		end
	endcase
    end

end

/*
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
		iaddr_tmp = ((y_addr-2)<<6 ) + (x_addr-2);
end
always @(posedge clk) begin
       iaddr <= iaddr_tmp
end

//============================================
always@(posedge clk) begin
 case (m)//收gray_meme給的資料(共9格的資料)
 	1: LBP_bin_1 <= idata;//每一個bin都是8bit
	2: LBP_bin_2 <= idata;
	3: LBP_bin_3 <= idata;
	4: LBP_bin_4 <= idata;
	5: LBP_bin_5 <= idata;
	6: LBP_bin_6 <= idata;
	7: LBP_bin_7 <= idata;
	8: LBP_bin_8 <= idata;
	9: LBP_bin_9 <= idata;
 endcase
end

endmodule
