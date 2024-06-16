//Can replace all instances of CHANGENAME to appropriate name
`timescale 1ns/1ns
`include "sobolrng.v"
//`include "" //input file here
`define TESTAMOUNT 10 //change for number of bitstreams tested

class errorcheck;
    real uResult;
    real eResult;
    real num;
    real cntA;
    real cntB;
    real denom;
    real sum;
    real mse;
    real rmse;

    function new(real iA, iB, denom, num, sum);
        cntA = iA;
        cntB = iB;
        this.denom = denom;
        this.num = num;
        this.sum = sum;

    endfunction 

    function fSUM(sum);
        uResult = (num/denom);
        //eResult = change equation here;

        $display("uResult = %f", uResult);
        //$display("eResult = %f", eResult); //uncomment when eResult changed 

        this.sum = sum + ((uResult - eResult) * (uResult - eResult));
        return sum + ((uResult - eResult) * (uResult - eResult));
    endfunction

    function fMSE();
        mse = sum / `TESTAMOUNT;
        $display("mse: %f", mse);
    endfunction

    function fRMSE();
        rmse = $sqrt(mse);
        $display("rmse: %f", rmse);
    endfunction

endclass

module CHANGENAME();
    parameter BITWIDTH = 8;
    
    logic iClk;
    logic iRstN;
    logic iA;
    logic iB;
    logic iClr;
    logic loadB;
    logic oC;
    
    
    errorcheck error;
    real num; //counts output's 1s
    real cntA; //counts As
    real cntB; //counts Bs
    real denom; //denominator
    real sum; //used for mse and rmse

    //calculates end result
    always@(posedge iClk or negedge iRstN) begin
        if(~iRstN) begin
            num <= 0;
        end else begin
            if(~iClr) begin 
                num <= num + oC;
            end else begin
                num <= 0;
            end
        end
    end

    //calculates denominator
    always@(posedge iClk or negedge iRstN) begin
        if(~iRstN) begin
            denom <= 0;
        end else begin
            if(~iClr) begin 
                denom <= denom + 1;
            end else begin
                denom <= 0;
            end
        end
    end

    //Counts 1 in As and Bs
    always@(posedge iClk or negedge iRstN) begin
        if(~iRstN) begin
            cntA <= 0;
        end else begin
            if(~iClr) begin 
                cntA <= cntA + iA;
            end else begin 
                cntA <= 0;
            end
        end
    end
    always@(posedge iClk or negedge iRstN) begin
        if(~iRstN) begin
            cntA <= 0;
        end else begin
            if(~iClr) begin 
                    cntB <= cntB + iB;
            end else begin 
                cntB <= 0;
            end
        end
    end

    //used for bitstream generation
    logic [BITWIDTH-1:0] sobolseq_tbA;
    logic [BITWIDTH-1:0] sobolseq_tbB;
    logic [BITWIDTH-1:0] rand_A;
    logic [BITWIDTH-1:0] rand_B;

    sobolrng #(
        .BITWIDTH(BITWIDTH)
    ) u_sobolrng_tbA (
        .iClk(iClk),
        .iRstN(iRstN),
        .iEn(1),
        .iClr(iClr),
        .sobolseq(sobolseq_tbA)
    );

    reg [BITWIDTH-1:0] iB_buff;

    always@(posedge iClk or negedge iRstN) begin
        if(~iRstN) begin
            iB_buff <= 0;
        end else begin
            if(loadB) begin
                iB_buff <= rand_B;
            end else begin
                iB_buff <= iB_buff;
            end
            
        end
    end

    sobolrng #(
        .BITWIDTH(BITWIDTH)
    ) u_sobolrng_tbB (
        .iClk(iClk),
        .iRstN(iRstN),
        .iEn(1),
        .iClr(iClr),
        .sobolseq(sobolseq_tbB)
    );

    always #5 iClk = ~iClk; //defines the clock


    initial begin 
        $dumpfile("CHANGENAME.vcd"); $dumpvars;

        iClk = 1;
        iB = 0;
        iA = 0;
        rand_A = 0;
        rand_B = 0;
        iRstN = 0;
        iClr = 0;
        loadB = 1;
        sum = 0;

        #10;
        iRstN = 1;

        //specified cycles of unary bitstreams
        repeat(`TESTAMOUNT) begin
            rand_A = $urandom_range(255);
            rand_B = $urandom_range(255);

            repeat(256) begin
                #10;
                iA = (rand_A > sobolseq_tbA);
                iB = (iB_buff > sobolseq_tbB);
            end

            error = new(iA, iB, denom, num, sum);
            sum = error.fSUM(sum);
        end

        error.fMSE();
        error.fRMSE();

        iClr = 1;
        iA = 0;
        iB = 0;
        #400;

        $finish;
    end 

endmodule