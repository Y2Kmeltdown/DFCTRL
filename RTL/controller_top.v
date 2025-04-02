`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICNS
// Engineer: Adithya K
// 
// Create Date: 20.09.2024 02:54:13
// Design Name: 
// Module Name: controller_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller_top #(parameter WIDTH_INST_MEM = 80, WIDTH_ADDR_INST = 6, WIDTH_ADDR_PARAM = 12, WIDTH_ADDR_ACT = 11, WGT_TILE_WIDTH = 8, N_PEs = 16, N_PEsby4 = 4)(
input clk, resetn, en,
input [WIDTH_INST_MEM-1:0]inst,

output reg [WIDTH_ADDR_INST-1:0]base_addr_instmem_reg,stride_instmem_reg,
output reg rst_addr_instmem_reg,en_addr_instmem_reg,load_base_instmem_reg,
output reg [WIDTH_ADDR_ACT-1:0]base_addr_actmem_reg,stride_actmem_reg,
output reg rst_addr_actmem_reg,en_addr_actmem_reg,load_base_actmem_reg,wea_actmem_reg,
output reg [WIDTH_ADDR_PARAM-1:0]base_addr_parammem_reg,stride_parammem_reg,
output reg rst_addr_parammem_reg,en_addr_parammem_reg,load_base_parammem_reg,
output reg rst_pe_reg_reg,rst_pe_relu_reg_reg,shift_reg,load_bias_reg,load_psum_reg,sel_pe_reg_reg,ia_sign_reg,
output reg [N_PEs-1:0]wea_reg_reg1,wea_reg_reg2,
output reg done_reg,done_layer_reg,
output reg [1:0] sel_ppm_param_present
);

//**------PARAMETER DECLARATIONS-----**//

    localparam IDLE = 4'd0, // IDLE
    FETCH = 4'd1, // FETCH
    DECODE = 4'd2, // DECODE
    EXECUTE_FC = 4'd3, // EXECUTE_FC
    EXECUTE_FC_CONCAT = 4'd6, // EXECUTE_FC
    WB = 4'd4, // WRITE BACK 
    DONE = 4'd5; // DONE!!!!!!
    
    localparam 
    FC = 3'd0, // (FC: Fully Connected layer)
    FC_CONCAT = 3'd1,
    END = 3'd7;
    
    localparam BIAS_ALPHA_BETA_DEPTH_TILE = 3; // Depth of Bias + ALPHA + BETA stored in PARAM_MEM for a single M*N_PE tile.
    
//**------REG DECLARATIONS-----**//
    
reg [3:0]next_state,current_state;
reg [2:0]OPCODE_present,OPCODE_next;
reg done,done_layer;
reg [WIDTH_INST_MEM-1:0]instr_present,instr_next;
reg rst_addr_instmem,en_addr_instmem,load_base_instmem;
reg rst_addr_actmem,en_addr_actmem,load_base_actmem,wea_actmem;
reg rst_addr_parammem,en_addr_parammem,load_base_parammem;
reg [WIDTH_ADDR_INST-1:0]base_addr_instmem,stride_instmem;
reg [WIDTH_ADDR_ACT-1:0]base_addr_actmem,stride_actmem;
reg [WIDTH_ADDR_PARAM-1:0]base_addr_parammem,stride_parammem;
reg [11:0]counter_present,counter_next;
reg [3:0]counter_loop_present,counter_loop_next;
reg [WGT_TILE_WIDTH-1:0]wgt_tile_cnt_next,wgt_tile_cnt_present;
reg rst_pe_reg,rst_pe_relu_reg,shift,load_bias,load_psum,sel_pe_reg;
reg [N_PEs-1:0]wea_reg1,wea_reg2;
reg [WIDTH_ADDR_PARAM-1:0]WGT_base_addr_next,WGT_base_addr_present;
reg [WIDTH_ADDR_ACT-1:0]OA_base_addr_next,OA_base_addr_present;
reg [1:0]sel_ppm_param_next; //Change later
reg [8*20:0] ascii_state; // For storing ASCII state name

//**------WIRE DECLARATIONS-----**//

wire ia_sign;
wire [9:0]N,M;
wire [WIDTH_ADDR_ACT-1:0]OA_base_addr,IA_base_addr;
wire [WIDTH_ADDR_PARAM-1:0]WGT_base_addr;
wire act_fn;
wire [3:0]K;

//**------Debugging-----**//

always @(*) begin
    case(current_state)
        IDLE        : ascii_state = "IDLE";
        FETCH       : ascii_state = "FETCH";
        DECODE      : ascii_state = "DECODE";
        EXECUTE_FC  : ascii_state = "EXECUTE_FC";
        EXECUTE_FC_CONCAT : ascii_state = "EXECUTE_FC_CONCAT";
        WB          : ascii_state = "WB";
        DONE        : ascii_state = "DONE";
        default     : ascii_state = "UNKNOWN";
    endcase
end
    //**------FLIP FLOPS FOR TOP-LEVEL CONTROLLER-----**//

    always@(posedge clk or negedge resetn)
    begin
        if(!resetn)
            begin
                current_state <= IDLE;
                done_reg <= 1'b0;
                done_layer_reg <= 1'b0;
                OPCODE_present <= 0;
                counter_present <= 0;
                counter_loop_present <= 0;
                wgt_tile_cnt_present <= 0;
                instr_present <= 0;
                rst_pe_reg_reg <= 1'b0;
                rst_pe_relu_reg_reg <= 1'b0;
                wea_reg_reg1 <= 0;
                wea_reg_reg2 <= 0;
                shift_reg <= 1'b0;
                load_bias_reg <= 1'b0;
                load_psum_reg <= 1'b0;
                sel_pe_reg_reg <= 1'b0;
                rst_addr_instmem_reg <= 1'b0;
                en_addr_instmem_reg <= 1'b0;
                load_base_instmem_reg <= 1'b0;
                base_addr_instmem_reg <= 0;
                stride_instmem_reg <= 1;
                rst_addr_actmem_reg <= 1'b0;
                en_addr_actmem_reg <= 1'b0;
                load_base_actmem_reg <= 1'b0;
                base_addr_actmem_reg <= 0;
                stride_actmem_reg <= 1;
                rst_addr_parammem_reg <= 1'b0;
                en_addr_parammem_reg <= 1'b0;
                load_base_parammem_reg <= 1'b0;
                base_addr_parammem_reg <= 0;
                stride_parammem_reg <= 1;       
                ia_sign_reg <= 1'b0;  
                wea_actmem_reg <= 1'b0;
                WGT_base_addr_present <= 0;
                OA_base_addr_present <= 0;
                sel_ppm_param_present <= 0;
            end
        else
            begin
                current_state <= next_state;
                done_reg <= done;
                done_layer_reg <= done_layer;
                OPCODE_present <= OPCODE_next;
                counter_present <= counter_next;
                counter_loop_present <= counter_loop_next;
                wgt_tile_cnt_present <= wgt_tile_cnt_next;
                instr_present <= instr_next;
                rst_pe_reg_reg <= rst_pe_reg;
                rst_pe_relu_reg_reg <= rst_pe_relu_reg;
                wea_reg_reg1 <= wea_reg1;
                wea_reg_reg2 <= wea_reg2;
                shift_reg <= shift;
                load_bias_reg <= load_bias;
                load_psum_reg <= load_psum;
                sel_pe_reg_reg <= sel_pe_reg;
                rst_addr_instmem_reg <= rst_addr_instmem;
                en_addr_instmem_reg <= en_addr_instmem;
                load_base_instmem_reg <= load_base_instmem;
                base_addr_instmem_reg <= base_addr_instmem;
                stride_instmem_reg <= stride_instmem;
                rst_addr_actmem_reg <= rst_addr_actmem;
                en_addr_actmem_reg <= en_addr_actmem;
                load_base_actmem_reg <= load_base_actmem;
                base_addr_actmem_reg <= base_addr_actmem;
                stride_actmem_reg <= stride_actmem;
                rst_addr_parammem_reg <= rst_addr_parammem;
                en_addr_parammem_reg <= en_addr_parammem;
                load_base_parammem_reg <= load_base_parammem;
                base_addr_parammem_reg <= base_addr_parammem;
                stride_parammem_reg <= stride_parammem;     
                ia_sign_reg <= ia_sign;    
                wea_actmem_reg <= wea_actmem;         
                WGT_base_addr_present <= WGT_base_addr_next; 
                OA_base_addr_present <= OA_base_addr_next;
                sel_ppm_param_present <= sel_ppm_param_next;
            end
    end

    always@(*)
    begin
        next_state = current_state;
        OPCODE_next = OPCODE_present;
        instr_next = instr_present;
        done = 1'b0;
        done_layer = 1'b0;
        rst_pe_reg = 1'b1;
        rst_pe_relu_reg = 1'b1;
        wea_reg1 = 0;
        wea_reg2 = 0;
        shift = 1'b0;
        load_bias = 1'b0;
        load_psum = 1'b0;
        sel_pe_reg = 1'b0;
        rst_addr_instmem = 1'b1;
        en_addr_instmem = 1'b0;
        load_base_instmem = 1'b0;
        base_addr_instmem = 0;
        stride_instmem = 1;
        rst_addr_actmem = 1'b1;
        en_addr_actmem = 1'b0;
        load_base_actmem = 1'b0;
        base_addr_actmem = 0;
        stride_actmem = 1;
        rst_addr_parammem = 1'b1;
        en_addr_parammem = 1'b0;
        load_base_parammem = 1'b0;
        base_addr_parammem = base_addr_parammem_reg;
        stride_parammem = 1;         
        counter_next = counter_present;
        counter_loop_next = counter_loop_present;
        wgt_tile_cnt_next = wgt_tile_cnt_present;
        wea_actmem = 1'b0;
        WGT_base_addr_next = WGT_base_addr_present;
        OA_base_addr_next = OA_base_addr_present;
        sel_ppm_param_next = sel_ppm_param_present;
        case(current_state)
            //**------IDLE-----**//
            IDLE : begin
                rst_addr_instmem = 1'b0;
                if(en)
                    next_state = FETCH;
                else
                    next_state = IDLE;
            end
            //**------INSTRUCTION FETCH-----**//
            FETCH : begin
                // Add here later.
                en_addr_instmem = 1'b1;
                next_state = DECODE;
                OPCODE_next = inst[2:0];
                instr_next = inst;
            end
            //**------OPCODE DECODE-----**//     
            DECODE : begin
                if (OPCODE_present == FC)
                begin
                    next_state = EXECUTE_FC;
                end    
                else if (OPCODE_present == FC_CONCAT)
                    next_state = EXECUTE_FC_CONCAT;
                else if (OPCODE_present == END)
                    next_state = DONE;
                else
                    next_state = DECODE;
            end
            //**------EXECUTE FC-----**//  
            EXECUTE_FC : begin
                counter_next = counter_present+1;
                if (counter_present == 0)
                begin
                    load_base_parammem = 1'b1;
                    WGT_base_addr_next = WGT_base_addr_present + M + BIAS_ALPHA_BETA_DEPTH_TILE;
                    if(wgt_tile_cnt_present == 0)
                        base_addr_parammem = WGT_base_addr;                        
                    else 
                        base_addr_parammem = WGT_base_addr_present + WGT_base_addr;
                    rst_pe_reg = 1'b0;
                    en_addr_actmem = 1'b1;
                    load_base_actmem = 1'b1;
                    base_addr_actmem = IA_base_addr;
                end
                // Load Bias bottom half of PEs
                if(counter_present == 2)
                begin
                    load_bias = 1'b1;
                    wea_reg1 = 16'h00FF;
                end
                // Load Bias upper half of PEs 
                if(counter_present == 3)
                begin
                    load_bias = 1'b1;
                    wea_reg1 = 16'hFF00;
                end
                // IA*W
                if(counter_present >= 3 && counter_present <= M+2)
                begin
                    en_addr_actmem = 1'b1;
                end        
                if (counter_present >= 5 && counter_present <= M+4) 
                begin
                    wea_reg1 = 16'hFFFF;
                end          
                if (counter_present <= M+2)
                begin
                    en_addr_parammem = 1'b1;
                end
                //-------- State transition logic --------//      
                if(counter_present > M+4)
                begin
                    next_state = WB;
                    counter_next = 0;
                end
                else
                begin                     
                    next_state = EXECUTE_FC;
                end    
            end 
            //**------EXECUTE FC CONCATENATED-----**//  
            EXECUTE_FC_CONCAT : begin
                counter_next = counter_present+1;
                if (counter_present == 0)
                begin
                    load_base_parammem = 1'b1;
                end
                if (counter_present == 0 && counter_loop_present == 0)
                begin
                    WGT_base_addr_next = WGT_base_addr_present + M + BIAS_ALPHA_BETA_DEPTH_TILE;
                    if(wgt_tile_cnt_present == 0)
                        base_addr_parammem = WGT_base_addr;                        
                    else 
                        base_addr_parammem = WGT_base_addr_present + WGT_base_addr;
                    rst_pe_reg = 1'b0;
                    en_addr_actmem = 1'b1;
                    load_base_actmem = 1'b1;
                    base_addr_actmem = IA_base_addr;
                end
                // Load Bias bottom half of PEs
                if(counter_present == 2)
                begin
                    load_bias = 1'b1;
                    wea_reg1 = 16'h00FF;
                end
                // Load Bias upper half of PEs 
                if(counter_present == 3)
                begin
                    load_bias = 1'b1;
                    wea_reg1 = 16'hFF00;
                end
                // IA*W
                if(counter_present >= 3 && counter_present <= M+2)
                begin
                    en_addr_actmem = 1'b1;
                end        
                if (counter_present >= 5 && counter_present <= M+4) 
                begin
                    wea_reg1 = 16'hFFFF;
                end    
                if (counter_present == M+4)
                    rst_pe_relu_reg = 1'b0;
                if (counter_present == M+5)
                begin
                   load_psum = 1'b1;
                   wea_reg2 = 16'hFFFF; 
                   wea_reg1 = 16'hFFFF; 
                end        
                if (counter_present <= M+2)
                begin
                    en_addr_parammem = 1'b1;
                end
                //-------- State transition logic --------//      
                if(counter_present > M+5 && counter_loop_present >= K-1)
                begin
                    next_state = WB;
                    counter_next = 0;
                    counter_loop_next = 0;
                end
                else
                begin                     
                    next_state = EXECUTE_FC_CONCAT;
                    if(counter_present > M+5 )
                    begin
                        counter_loop_next = counter_loop_present+1;
                        counter_next = 0;
                    end                        
                end    
            end 
            //**------Write Back + Post-processing-----**// 
            WB : begin
                counter_next = counter_present+1;
                if(counter_present == 0)
                begin
                    en_addr_actmem = 1'b1;
                    load_base_actmem = 1'b1;
                    sel_ppm_param_next = 0;
                    if(wgt_tile_cnt_present == 0)
                    begin
                        base_addr_actmem = OA_base_addr; 
                        OA_base_addr_next = OA_base_addr_present + N_PEs;
                    end
                    else 
                    begin
                        base_addr_actmem = OA_base_addr_present + OA_base_addr;
                        OA_base_addr_next = OA_base_addr_present + N_PEs;
                    end     
                end
                //Flush the PSUM from PE array
                if(counter_present >= 1 && counter_present <= N_PEs)
                begin
                    shift = 1'b1;
                    wea_reg1 = 16'hFFFF;
                    //en_addr_parammem = counter_present[1] & counter_present[0];
                end
//                if(counter_present >= 2 && counter_present <= N_PEs+1)
//                begin
//                    sel_ppm_param_next = sel_ppm_param_present + 1; 
//                end
                if(counter_present >= 3 && counter_present <= N_PEs+2)
                begin
                    en_addr_actmem = 1'b1;
                    wea_actmem = 1'b1;
                end
                
                //-------- State transition logic --------// 
                if(counter_present >= N_PEs+2 & wgt_tile_cnt_present < N[9:4]-1)
                begin 
                    wgt_tile_cnt_next = wgt_tile_cnt_present + 1;
                    if(OPCODE_present == FC_CONCAT)
                        next_state = EXECUTE_FC_CONCAT;
                    else if (OPCODE_present == FC)
                        next_state = EXECUTE_FC;
                    counter_next = 0;
                    sel_ppm_param_next = 0;
                end
                else if(counter_present > N_PEs+2 && wgt_tile_cnt_next == N[9:4]-1) 
                begin
                    WGT_base_addr_next = 0;
                    OA_base_addr_next = 0;
                    wgt_tile_cnt_next = 0;
                    next_state = FETCH;
                    counter_next = 0;    
                    sel_ppm_param_next = 0;  
                    done_layer = 1'b1;              
                end    
                else
                begin                     
                    next_state = WB;
                end                   
            end
            //**------DONE-----**//  
            DONE : begin
                done = 1'b1;
                next_state = DONE;
            end
            default : next_state = IDLE;
        endcase
    end


//**------INSTRUCTION SLICING-----**//

assign M = instr_present[12:3];
assign N = instr_present[22:13];
assign IA_base_addr = instr_present[23+WIDTH_ADDR_ACT-1:23];
assign OA_base_addr = instr_present[39+WIDTH_ADDR_ACT-1:39];
assign WGT_base_addr = instr_present[55+WIDTH_ADDR_PARAM-1:55];
assign ia_sign = instr_present[71];
assign act_fn = instr_present[72];
assign K = instr_present[76:73];

endmodule
