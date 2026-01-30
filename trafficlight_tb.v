`timescale 1ns / 1ps

module tb_trafficlight;

    //inputs
    reg clk;
    reg rst_n;
    reg ped_req_a;
    reg ped_req_b;
    reg emergency;

    //outputs
    wire [2:0] light_a;
    wire [2:0] light_b;
    wire [1:0] ped_light_a;
    wire [1:0] ped_light_b;

    trafficlight #(
        .SLOW_CLK_PERIOD(4)
    ) uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .ped_req_a(ped_req_a), 
        .ped_req_b(ped_req_b), 
        .emergency(emergency), 
        .light_a(light_a), 
        .light_b(light_b), 
        .ped_light_a(ped_light_a), 
        .ped_light_b(ped_light_b)
    );

    //clock
    always #5 clk = ~clk; //100MHz clock(10ns period)

    initial begin
        //initialize inputs
        clk = 0;
        rst_n = 0;
        ped_req_a = 0;
        ped_req_b = 0;
        emergency = 0;

        //reset system
        #20;
        rst_n = 1;

        //normal cycle (A Green -> A Yellow -> B Green)
        #2000; 

        //pedestrian A request
        $display("Triggering Pedestrian A Request");
        ped_req_a = 1;
        #20;
        ped_req_a = 0;
        //A Green -> Yellow -> Ped Walk -> Stop -> B Green
        #3000;

        //emergency
        $display("Triggering Emergency");
        emergency = 1;
        #500; //stays on emergency
        
        //release emergency
        $display("Releasing Emergency");
        emergency = 0;
        //system reset to A Green safely
        #1000;

        //pedestrian B request
        $display("Triggering Pedestrian B Request");
        ped_req_b = 1;
        #20;
        ped_req_b = 0;
        
        #5000;
        $finish;
    end
      
endmodule
