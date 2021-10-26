module LBP ( clk, reset, gray_addr, gray_req, gray_data, lbp_addr, lbp_write, lbp_data, finish);
input   	clk;//本題採同步正緣觸發
input   	reset;//非同步重置信號
output  [5:0] 	gray_addr;//灰階圖像位址匯流排。LBP 端需透過此匯流排向Testbench 的 gray_mem 索取該位址的灰階影像資料。
output         	gray_req;//灰階圖像讀取致能訊號。高態觸發
input   [7:0] 	gray_data;//灰階圖像資料匯流排。Testbench 端利用此匯流排將gray_mem 的灰階圖像資料送到 LBP 端。
output  [5:0] 	lbp_addr;//局部二值模式位址匯流排。LBP 端利用此位址將經 LBP運算完成後之資料儲存至 lbp_mem 中。
output  	lbp_write;//局部二值模式資料寫入致能訊號。高態觸發
output  [7:0] 	lbp_data;//局部二值模式資料匯流排。LBP 端需透過此匯流排將LBP 運算結果傳送到 lbp_mem 中。
output  	finish;//交卷

//===========================================================================



reg [7:0] lbp_data;
reg [7:0] x, y, k, m;//x、y:判斷9宮格編碼到那個位置 k:紀錄這狀態是9宮格中哪一個 m:紀錄K這個clk的值(k的暫存)
reg [5:0] x_addr, y_addr;
reg [5:0] gray_addr, lbp_addr, gray_addr_tmp;//gray_addr_tmp暫存下一個gray_addr(見85、86行)
reg gray_req;
reg lbp_valid;//幫lbp_write致能 valid(adj.)有效的
reg finish;
reg [1:0] state;
parameter IDLE = 2'b00, LOAD = 2'b01, WRITE = 2'b11, COMP = 2'b10;//多工器，命名增加可讀性
//parameter用來定義一個標識符來代表一個常量，增加可讀性的好幫手
//IDLE 初始狀態 || LOAD 要資料到LBP || WRITE 寫資料到lbp || COMP LOAD轉WRITE的過渡狀態(因為要處理k=9的值，寫程式的邏輯)

reg [7:0] LBP_bin_1, LBP_bin_2, LBP_bin_3, LBP_bin_4, LBP_bin_5, LBP_bin_6, LBP_bin_7, LBP_bin_8, LBP_bin_9;

reg [7:0] LBP_value;

wire	lbp_write = lbp_valid & clk; //寫入權在lbp_valid、clk同時為1時啟動；為甚麼clk=1才能寫?

always@(posedge clk or posedge reset) begin
if ( reset ) begin
	state <= IDLE; gray_req <= 0; finish <= 0; x <= 2; y <= 2; k <= 1; lbp_valid <= 0;//x、y初始值放2是因為在編碼9宮格的中間
end
else begin
	case (state)
	IDLE : begin //
		state <=  LOAD;  
		gray_req <= 0; 
		x <= 2; y <= 2; k <= 1;
		lbp_valid <= 0;
		finish <= 0;
		end
	LOAD : begin //要求gray_mem給資料
		lbp_valid <= 0;
		gray_req <= 1;
		k <= k + 1;
		if (k == 9) begin state <= COMP;   gray_req <= 1;end//寫入第8狀態時k就會變成9，下一個狀態就會寫入完畢、所以進入COMP狀態
		else state <= LOAD;
		end
	COMP : begin //過渡狀態，關掉向gray_mem要資料的權限，開始進入寫入狀態
		state <= WRITE;
		gray_req <= 0;
		end
	WRITE : begin //一列一列讀，令x為列y為行，可稱為一列一列讀
		lbp_valid <= 1;
		if ((x==7)&(y==7)) begin state <= IDLE; finish <= 1; gray_req <= 0; end //若已經讀到x、y皆為7(8個資料)表示寫入完成，讓finish=1
		else if (x == 7) begin y <= y + 1; x <= 2; k<= 1; state<= LOAD; gray_req <= 0;end //若一列x讀完，換行繼續讀
		else begin x <= x + 1; k<= 1; state<= LOAD; gray_req <= 0;end//讀該列的x
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

always@(posedge clk) begin
		gray_addr = gray_addr_tmp;
end

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

always@(*) begin //計算LBP的數值(最終的2進位編碼)
 	LBP_value[0] = (LBP_bin_1 >= LBP_bin_5) ? 1 : 0;
	LBP_value[1] = (LBP_bin_2 >= LBP_bin_5) ? 1 : 0;
	LBP_value[2] = (LBP_bin_3 >= LBP_bin_5) ? 1 : 0;
	LBP_value[3] = (LBP_bin_4 >= LBP_bin_5) ? 1 : 0;
	LBP_value[4] = (LBP_bin_6 >= LBP_bin_5) ? 1 : 0;
	LBP_value[5] = (LBP_bin_7 >= LBP_bin_5) ? 1 : 0;
	LBP_value[6] = (LBP_bin_8 >= LBP_bin_5) ? 1 : 0;
	LBP_value[7] = (LBP_bin_9 >= LBP_bin_5) ? 1 : 0;
end

always@(posedge clk)  //為甚麼要-1 左移3格?
	lbp_addr <= ((y-1)<<3) + (x-1);

always@(posedge clk) //把LBP_value(編好的2進位碼)全丟出去
	lbp_data <= LBP_value;


endmodule
