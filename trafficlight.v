module trafficlight #(
    parameter integer SLOW_CLK_PERIOD = 50_000_000 //testbench can override this value
)(
    input  wire       clk, //clock
    input  wire       rst_n, //reset
    input  wire       ped_req_a, //pedestrian button A
    input  wire       ped_req_b, //pedestrian button B
    input  wire       emergency, //emergency switch

    output wire [2:0] light_a, //traffic light A (red, yellow, green)
    output wire [2:0] light_b, //traffic light B (red, yellow, green)
    output wire [1:0] ped_light_a, //pedestrian light A (green, red)
    output wire [1:0] ped_light_b //pedestrian light B (green, red)
);

    localparam RED       = 3'b001;
    localparam YELLOW    = 3'b010;
    localparam GREEN     = 3'b100;

    localparam DONT_WALK = 2'b01;
    localparam WALK      = 2'b10;

//FSM STATES

//sequence for A

    localparam [2:0] S_A_GREEN    = 3'b000;
    localparam [2:0] S_A_YELLOW   = 3'b001;
    localparam [2:0] S_A_PED_WALK = 3'b010;
    localparam [2:0] S_A_PED_STOP = 3'b011;

//sequence for B

    localparam [2:0] S_B_GREEN    = 3'b100;
    localparam [2:0] S_B_YELLOW   = 3'b101;
    localparam [2:0] S_B_PED_WALK = 3'b110;
    localparam [2:0] S_B_PED_STOP = 3'b111;

//timing in clock ticks

    localparam GREEN_TIME    = 10;
    localparam YELLOW_TIME   = 3;
    localparam PED_WALK_TIME = 5;
    localparam PED_STOP_TIME = 2;

    reg [2:0] state, next_state; //current and next state of FSM
    reg [7:0] timer; //timer for state duration
    
    reg ped_a_latch, ped_b_latch; //stores button presses
    reg [25:0] clk_counter;  //creates a slow pulse
    wire slow_clk_enable; //pulse which enables state transition

//CLOCK DIVIDER

    assign slow_clk_enable = (clk_counter == SLOW_CLK_PERIOD - 1); //pulse generator

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
        end else if (slow_clk_enable) begin
            clk_counter <= 0;
        end else begin
            clk_counter <= clk_counter + 1;
        end
    end

//PEDESTRIAN REQUEST FUNCTION

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_a_latch <= 1'b0;
            ped_b_latch <= 1'b0;
        end else begin 
            if (ped_req_a) ped_a_latch <= 1'b1; //latch A is set on button press and stays till state enters WALK
            else if (state == S_A_PED_WALK) ped_a_latch <= 1'b0;

            if (ped_req_b) ped_b_latch <= 1'b1; //latch A is set on button press and stays till state enters WALK
            else if (state == S_B_PED_WALK) ped_b_latch <= 1'b0;
        end
    end

//SEQUENTIAL STATE AND TIMER

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_A_GREEN;
            timer <= GREEN_TIME;
        end 

//EMERGENCY OVERRIDE FUNCTION

        else if (emergency) begin
            state <= S_A_GREEN; //forces signal A to green and resets the timer
            timer <= GREEN_TIME;
        end
        else if (slow_clk_enable) begin //resumes signal
            if (timer == 0) begin
                state <= next_state; //loads timer for new specific state
                case (next_state)
                    S_A_GREEN:    timer <= GREEN_TIME;
                    S_A_YELLOW:   timer <= YELLOW_TIME;
                    S_A_PED_WALK: timer <= PED_WALK_TIME;
                    S_A_PED_STOP: timer <= PED_STOP_TIME;
                    S_B_GREEN:    timer <= GREEN_TIME;
                    S_B_YELLOW:   timer <= YELLOW_TIME;
                    S_B_PED_WALK: timer <= PED_WALK_TIME;
                    S_B_PED_STOP: timer <= PED_STOP_TIME;
                    default:      timer <= GREEN_TIME;
                endcase
            end else begin
                timer <= timer - 1;
            end
        end
    end

//COMBINATIONAL STATE LOGIC

    always @(*) begin
        next_state = state; //prevents accidental latches
        if (timer == 0) begin //evaluates transition only if timer has expired
            case (state)
                S_A_GREEN:    next_state = S_A_YELLOW; 
                S_A_YELLOW: begin 
                    if (ped_a_latch) next_state = S_A_PED_WALK; //if pedestrian A is waiting then ped A turned green 
                    else             next_state = S_B_GREEN; //otherwise B signal turned green
                end
                S_A_PED_WALK: next_state = S_A_PED_STOP;
                S_A_PED_STOP: next_state = S_B_GREEN;
                S_B_GREEN:    next_state = S_B_YELLOW;
                S_B_YELLOW: begin
                    if (ped_b_latch) next_state = S_B_PED_WALK; //if pedestrian B is waiting then ped A turned green
                    else             next_state = S_A_GREEN; //otherwise A signal turned green
                end
                S_B_PED_WALK: next_state = S_B_PED_STOP;
                S_B_PED_STOP: next_state = S_A_GREEN;
                default:      next_state = S_A_GREEN;
            endcase
        end
    end

//OUTPUT

    reg [2:0] light_a_fsm;
    reg [2:0] light_b_fsm;
    reg [1:0] ped_light_a_fsm;
    reg [1:0] ped_light_b_fsm;

    always @(*) begin //by default all lights are red
        light_a_fsm     = RED;
        light_b_fsm     = RED;
        ped_light_a_fsm = DONT_WALK;
        ped_light_b_fsm = DONT_WALK;

        case (state)
            S_A_GREEN:    light_a_fsm = GREEN;
            S_A_YELLOW:   light_a_fsm = YELLOW;
            S_A_PED_WALK: ped_light_a_fsm = WALK;
            S_B_GREEN:    light_b_fsm = GREEN;
            S_B_YELLOW:   light_b_fsm = YELLOW;
            S_B_PED_WALK: ped_light_b_fsm = WALK;
        endcase
    end

//FINAL OUTPUT ASSIGNMENT
    
    assign light_a     = (emergency) ? RED : light_a_fsm;
    assign light_b     = (emergency) ? RED : light_b_fsm;
    assign ped_light_a = (emergency) ? DONT_WALK : ped_light_a_fsm;
    assign ped_light_b = (emergency) ? DONT_WALK : ped_light_b_fsm;

endmodule
