module edge_detector #(
    parameter 
    POSEDGE = 1
)

(
    input sig,           
    input clk,            
    input reset_n,            
    output sig_edge,
    output reg out
);          

    wire isPOSEDGE = POSEDGE;
    wire sig_in = isPOSEDGE ? sig : !sig;
    reg sig_dly;                         

    always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sig_dly <= 0;
        end else begin
            sig_dly <= sig_in;
        end
    end

    assign sig_edge = sig_in & ~sig_dly;            

    always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            out <= 0;
        end else if (sig_edge) begin
            out <= ~out;
        end
    end
endmodule