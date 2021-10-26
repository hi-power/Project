module CIC(clk,reset,ready,busy,iaddr,idata,crd,cdata_rd,caddr_rd,cwr,cdata_wr,caddr_wr,csel);
input clk;
input reset;//非同步重置信號
input ready;//為1時灰階圖像準備完成
output busy;//=1時進行輸入灰階圖像資料索取
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

parameter NSEL = 3'b000, L0K0 = 3'b001,  L0K1 = 3'b010, L1K0 = 3'b011, L1K1 = 3'b100, L2F = 3'b001;//多工器，命名增加可讀性

always @(posedge clk or posedge reset ) begin
    if (reset) begin
        csel <= NSEL; ready <= 1; busy <= 0; crd <= 0; cwr <= 0;
    end

end