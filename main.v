//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    03:23:08 12/09/2023
// Design Name:
// Module Name:    parking_lot_top
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module parking_lot_top(
  input reset,
  input clock,
  input [15:0] license_plate,
  input in_mode,
  input out_mode,
  input leakage,
  input [2:0] leakage_floor,
  output reg [31:0] parked_1 = 0,
  output reg [31:0] parked_2 = 0,
  output reg [31:0] parked_3 = 0,
  output reg [31:0] parked_4 = 0,
  output reg [31:0] parked_5 = 0,
  output reg [31:0] parked_6 = 0,
  output reg [31:0] parked_7 = 0,
  output reg[2:0] current_floor = 0,
  output reg [15:0] moving = 0,
  output reg plate_type = 0,
  output reg [7:0] fee = 0,
  output wire [3:0] empty_suv,
  output wire [3:0] empty_sedan,
  output wire full_suv,
  output wire full_sedan
  );
 
  // parameter
  `define S0 3'b000
  `define S1 3'b001
  `define S2 3'b010
  `define S3 3'b011
  `define S4 3'b100
  `define S5 3'b101
  `define S6 3'b110
  `define S7 3'b111


  // register, wire
  reg [2:0] next_state_reg = 0;
  reg task_done = 0;
  reg going_back = 0;
  wire [395:0] task_list;
  wire [111:0] fee_list;
  wire [15:0] current_car;
  wire [13:0] parkstate_list;
  wire [3:0] task_num;
  wire [3:0] target_space;
  wire [3:0] original_space;
  wire [3:0] current_space;
  wire [2:0] state;
  wire [2:0] next_state;
  wire [2:0] target_floor;
  wire current_in, current_out, car_type;
  
  // new
  wire [223:0] early_parklist;


  // call module
  DFF state_reg(clock, reset, next_state, state, `S0);
  AddTaskList add_task_list(reset, in_mode, out_mode, license_plate, task_done, task_list, task_num, {parked_1, parked_2, parked_3, parked_4, parked_5, parked_6, parked_7}, leakage, leakage_floor, task_list, task_num);
  ReadTaskList read_task_list(state, task_list, {parked_1, parked_2, parked_3, parked_4, parked_5, parked_6, parked_7}, plate_type, moving, current_floor, going_back, leakage, leakage_floor, current_in, current_out, current_car, target_space, original_space, current_space, parkstate_list);
  UpdateEmptyFull update_emptyfull(reset, clock, in_mode, out_mode, license_plate, leakage_floor, early_parklist, empty_suv, empty_sedan, full_suv, full_sedan, early_parklist);
  GetCarType get_car_type(current_car, car_type);
  GetTargetFloor get_target_floor(target_space, target_floor);
  UpdateFee update_fee(reset, clock, task_done, fee_list, {parked_1, parked_2, parked_3, parked_4, parked_5, parked_6, parked_7}, original_space, current_space, current_car, target_space, next_state_reg, task_list, fee_list);

  // assign state
  always @* begin
    if(reset) begin
      next_state_reg = `S0; // parking space should be reset
    end
    else begin
      if(state == `S0) begin
        if(current_in && current_out) begin
          if(plate_type != car_type) next_state_reg = `S1;
          else next_state_reg = `S2;
        end
        else if(~current_in && ~current_out) next_state_reg = `S0;
        else if((current_in || current_out) && (plate_type != car_type)) next_state_reg = `S1;
        else if(current_out && (plate_type == car_type)) next_state_reg = `S2;
        else if(current_in && (plate_type == car_type)) next_state_reg = `S4;
      end
      else if(state == `S1) begin
        if(current_in && current_out) next_state_reg = `S2;
        else if(current_out) next_state_reg = `S2;
        else if(current_in) next_state_reg = `S4;
      end
      else if(state == `S2) begin
        if(current_in && current_out) begin
          if(current_floor != target_floor) next_state_reg = `S2;
          else next_state_reg = `S6;
        end
        else if(current_floor == target_floor && current_floor == 3'b000 && ~current_in && ~current_out) next_state_reg = `S0;
        else if(current_floor == target_floor && current_floor == 0 && (current_in || current_out) && plate_type != car_type) next_state_reg = `S1;
        else if(current_floor != target_floor) next_state_reg = `S2;
        else if(current_floor == target_floor && current_floor == 3'b000 && current_in && plate_type == car_type) next_state_reg = `S4;
        else if(current_floor == target_floor && current_floor != 3'b000 && current_out) next_state_reg = `S6;
      end
      else if(state == `S3) begin
        if(current_in && current_out) begin
          if(current_floor != target_floor) next_state_reg = `S3;
          else if(target_floor != 0) next_state_reg = `S7;
          else next_state_reg = `S5;
        end
        else if(current_floor != target_floor) next_state_reg = `S3;
        else if(current_floor == 3'b000 && moving != 0) begin
          next_state_reg = `S5;
        end
        else if(current_floor == target_floor && current_in) begin
          next_state_reg = `S7;
        end
      end
    else if(state == `S4) begin
      if(current_in) next_state_reg = `S3;
      end
      else if(state == `S5) begin
        if(current_in && current_out) begin
          if(plate_type != car_type) next_state_reg = `S1;
          else next_state_reg = `S2;
        end
        else if(~current_in && ~current_out) next_state_reg = `S0;
        else if((current_in || current_out) && plate_type != car_type) next_state_reg = `S1;
        else if(current_out && plate_type == car_type) next_state_reg = `S2;
        else if(current_in && plate_type == car_type) next_state_reg = `S4;
      end
      else if(state == `S6) begin
        if(current_in && current_out) next_state_reg = `S3;
        else if(current_out) next_state_reg = `S3;
      end
      else if(state == `S7) begin
        if(current_in & current_out) begin
          if(~(current_floor == target_floor && plate_type == car_type)) next_state_reg = `S2;
          else next_state_reg = `S6;
        end
        else if(~(current_floor == target_floor && current_out && plate_type == car_type)) next_state_reg = `S2;
        else next_state_reg = `S6;
      end
      // $display("next_state_reg: %d \n", next_state_reg);
    end
    // $display("task list check: %b", task_list[395:330]);
  end


  // assign output
  always@(posedge clock) begin
    // $display("reset: %d", reset);
    // $display("in mode: %d", in_mode);
    // $display("out mode: %d", out_mode);
    // $display("license plate: %d %d %d %d \n", license_plate[15:12], license_plate[11:8], license_plate[7:4], license_plate[3:0]);
    // $display("current floor: %d \n", current_floor);
    // $display("target floor: %d \n", target_floor);
    // $display("original space: %d \n", original_space);
    // $display("current in: %d \n", current_in);
    // $display("current out: %d \n", current_out);
    // $display("car: %d %d %d %d \n", current_car[15:12], current_car[11:8], current_car[7:4], current_car[3:0]);
    // $display("current state: %d \n", state);
    // $display("next state: %d \n", next_state);
    // $display("task num: %d \n", task_num);
    // $display("car type: %d \n", car_type);
    // $display("going back: %d \n", going_back);
    // $display("last task : %d | %d %d %d %d\n", task_list[(7-task_num+1) * 18 + 17 -: 2], task_list[(7-task_num+1) * 18 + 15 -: 4], task_list[(7-task_num+1) * 18 + 11 -: 4], task_list[(7-task_num+1) * 18 + 7 -: 4], task_list[(7-task_num+1) * 18 + 3 -: 4]);
    // $display("next task : %d | %d %d %d %d\n", task_list[377 : 376], task_list[375 : 372], task_list[371 : 368], task_list[367 : 364], task_list[363 : 360]);
    // $display("park state list: %b \n", parkstate_list);
    // $display("fee: %d %d %d %d %d %d %d %d %d %d %d %d %d %d \n", fee_list[111:104], fee_list[103:96], fee_list[95:88], fee_list[87:80], fee_list[79:72], fee_list[71:64], fee_list[63:56], fee_list[55:48], fee_list[47:40], fee_list[39:32], fee_list[31:24], fee_list[23:16], fee_list[15:8], fee_list[7:0]);
    if(reset) begin
      parked_1 = {32{1'b0}};
      parked_2 = {32{1'b0}};
      parked_3 = {32{1'b0}};
      parked_4 = {32{1'b0}};
      parked_5 = {32{1'b0}};
      parked_6 = {32{1'b0}};
      parked_7 = {32{1'b0}};
      current_floor = 0;
      moving = 0;
      plate_type = 0;
      fee = 0;
    end
    else begin
      task_done = 0;
      fee = 0;
      if(state == `S0) begin
        if(current_in && current_out) begin
          if(plate_type != car_type) plate_type = ~plate_type; // S1
        end
        else if(~current_in && ~current_out) ; //S0
        else if((current_in || current_out) && plate_type != car_type) begin //S1
          plate_type = ~plate_type;
        end
        else if(current_out && plate_type == car_type) begin ; //S2
          current_floor = current_floor + 1;
        end
        else if(current_in && plate_type == car_type) begin //S4
          moving = current_car;
        end
      end
      else if(state == `S1) begin
        if(current_in && current_out) current_floor = current_floor + 1; // S2
        else if(current_out) begin //S2
          current_floor = current_floor + 1;
        end
        else if(current_in) begin //S4
          moving = current_car;
        end
      end
      else if(state == `S2) begin
        if(current_in && current_out) begin
          if(current_floor != target_floor) begin // S2
            if(current_floor < target_floor) current_floor = current_floor + 1;
            else current_floor = current_floor - 1;
          end
          else begin // S6
            moving = current_car;
            case(target_space)
            4'b0000: parked_7[15:0] = {16{1'b0}};
            4'b0001: parked_7[31:16] = {16{1'b0}};
            4'b0010: parked_6[15:0] = {16{1'b0}};
            4'b0011: parked_6[31:16] = {16{1'b0}};
            4'b0100: parked_5[15:0] = {16{1'b0}};
            4'b0101: parked_5[31:16] = {16{1'b0}};
            4'b0110: parked_4[15:0] = {16{1'b0}};
            4'b0111: parked_4[31:16] = {16{1'b0}};
            4'b1000: parked_3[15:0] = {16{1'b0}};
            4'b1001: parked_3[31:16] = {16{1'b0}};
            4'b1010: parked_2[15:0] = {16{1'b0}};
            4'b1011: parked_2[31:16] = {16{1'b0}};
            4'b1100: parked_1[15:0] = {16{1'b0}};
            4'b1101: parked_1[31:16] = {16{1'b0}};
            endcase
          end
        end
        else if(current_floor == target_floor && current_floor == 3'b000 && ~current_in && ~current_out); //S0
        else if(current_floor == target_floor && current_floor == 0 && (current_in || current_out) && plate_type != car_type) begin //S1
          // $display("changing plate");
          plate_type = ~plate_type;
        end
        else if(current_floor != target_floor) begin //S2
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
          if(current_floor == 0 && going_back == 1) going_back = 0;
        end
        else if(current_floor == target_floor && current_floor == 3'b000 && current_in && plate_type == car_type) begin //S4
          moving = current_car;
        end
        else if(current_floor == target_floor && current_floor != 3'b000 && current_out) begin //S6
          moving = current_car;
          case(target_space)
          4'b0000: parked_7[15:0] = {16{1'b0}};
          4'b0001: parked_7[31:16] = {16{1'b0}};
          4'b0010: parked_6[15:0] = {16{1'b0}};
          4'b0011: parked_6[31:16] = {16{1'b0}};
          4'b0100: parked_5[15:0] = {16{1'b0}};
          4'b0101: parked_5[31:16] = {16{1'b0}};
          4'b0110: parked_4[15:0] = {16{1'b0}};
          4'b0111: parked_4[31:16] = {16{1'b0}};
          4'b1000: parked_3[15:0] = {16{1'b0}};
          4'b1001: parked_3[31:16] = {16{1'b0}};
          4'b1010: parked_2[15:0] = {16{1'b0}};
          4'b1011: parked_2[31:16] = {16{1'b0}};
          4'b1100: parked_1[15:0] = {16{1'b0}};
          4'b1101: parked_1[31:16] = {16{1'b0}};
          endcase
        end
      end
      else if(state == `S3) begin
        if(current_in && current_out) begin
          if(current_floor != target_floor) begin // S3
            if(current_floor < target_floor) current_floor = current_floor + 1;
            else current_floor = current_floor - 1;
          end
          else if(target_floor != 0) begin // S7
            {task_done, moving} = {1'b1, {16{1'b0}}};
            case(target_space)
            4'b0000: parked_7[15:0] = current_car;
            4'b0001: parked_7[31:16] = current_car;
            4'b0010: parked_6[15:0] = current_car;
            4'b0011: parked_6[31:16] = current_car;
            4'b0100: parked_5[15:0] = current_car;
            4'b0101: parked_5[31:16] = current_car;
            4'b0110: parked_4[15:0] = current_car;
            4'b0111: parked_4[31:16] = current_car;
            4'b1000: parked_3[15:0] = current_car;
            4'b1001: parked_3[31:16] = current_car;
            4'b1010: parked_2[15:0] = current_car;
            4'b1011: parked_2[31:16] = current_car;
            4'b1100: parked_1[15:0] = current_car;
            4'b1101: parked_1[31:16] = current_car;
            endcase
          end
          else begin // S5
            task_done = 1;
            moving = 0;
          end
        end
        else if(current_floor != target_floor) begin //S3
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
        end
        else if(current_floor == 3'b000 && moving != 0) begin //S5
          fee = fee_list[original_space * 8 + 7 -: 8];
          task_done = 1;
          moving = 0;      
        end
        else if(current_floor == target_floor && current_in) begin //S7
          // $display("now park\n");
          // $display("next task when done: %d \n", task_list[377:376]);
          if(task_list[377:376] == 0) going_back = 1;
          // $display("updated going back: %d \n", going_back);
          {task_done, moving} = {1'b1, {16{1'b0}}};
          case(target_space)
          4'b0000: parked_7[15:0] = current_car;
          4'b0001: parked_7[31:16] = current_car;
          4'b0010: parked_6[15:0] = current_car;
          4'b0011: parked_6[31:16] = current_car;
          4'b0100: parked_5[15:0] = current_car;
          4'b0101: parked_5[31:16] = current_car;
          4'b0110: parked_4[15:0] = current_car;
          4'b0111: parked_4[31:16] = current_car;
          4'b1000: parked_3[15:0] = current_car;
          4'b1001: parked_3[31:16] = current_car;
          4'b1010: parked_2[15:0] = current_car;
          4'b1011: parked_2[31:16] = current_car;
          4'b1100: parked_1[15:0] = current_car;
          4'b1101: parked_1[31:16] = current_car;
          endcase
        end
      end
      else if(state == `S4) begin
        if(current_in) begin //S3
          current_floor = current_floor + 1;
        end
      end
      else if(state == `S5) begin
        if(current_in && current_out) begin
          if(plate_type != car_type) plate_type = ~plate_type; // S1
          else begin // S2
            if(current_floor < target_floor) current_floor = current_floor + 1;
            else current_floor = current_floor - 1;
          end
        end
        else if(~current_in && ~current_out) ; //S0
        else if((current_in || current_out) && plate_type != car_type) begin //S1
          plate_type = ~plate_type;
        end
        else if(current_out && plate_type == car_type) begin //S2
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
        end
        else if(current_in && plate_type == car_type) begin //S4
          moving = current_car;
        end
      end
      else if(state == `S6) begin
        if(current_in && current_out) begin // S3
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
        end
        else if(current_out) begin //S3
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
        end
      end
      else if(state == `S7) begin
        if(current_in & current_out) begin
          if(~(current_floor == target_floor && plate_type == car_type)) begin // S2
            if(current_floor < target_floor) current_floor = current_floor + 1;
            else current_floor = current_floor - 1;
          end
          else begin // S6
            moving = current_car;
            case(target_space)
            4'b0000: parked_7[15:0] = {16{1'b0}};
            4'b0001: parked_7[31:16] = {16{1'b0}};
            4'b0010: parked_6[15:0] = {16{1'b0}};
            4'b0011: parked_6[31:16] = {16{1'b0}};
            4'b0100: parked_5[15:0] = {16{1'b0}};
            4'b0101: parked_5[31:16] = {16{1'b0}};
            4'b0110: parked_4[15:0] = {16{1'b0}};
            4'b0111: parked_4[31:16] = {16{1'b0}};
            4'b1000: parked_3[15:0] = {16{1'b0}};
            4'b1001: parked_3[31:16] = {16{1'b0}};
            4'b1010: parked_2[15:0] = {16{1'b0}};
            4'b1011: parked_2[31:16] = {16{1'b0}};
            4'b1100: parked_1[15:0] = {16{1'b0}};
            4'b1101: parked_1[31:16] = {16{1'b0}};
            endcase
          end
        end
        else if(~(current_floor == target_floor && current_out && plate_type == car_type)) begin //S2
          if(current_floor < target_floor) current_floor = current_floor + 1;
          else current_floor = current_floor - 1;
        end
        else begin //S6
          moving = current_car;
          case(target_space)
          4'b0000: parked_7[15:0] = {16{1'b0}};
          4'b0001: parked_7[31:16] = {16{1'b0}};
          4'b0010: parked_6[15:0] = {16{1'b0}};
          4'b0011: parked_6[31:16] = {16{1'b0}};
          4'b0100: parked_5[15:0] = {16{1'b0}};
          4'b0101: parked_5[31:16] = {16{1'b0}};
          4'b0110: parked_4[15:0] = {16{1'b0}};
          4'b0111: parked_4[31:16] = {16{1'b0}};
          4'b1000: parked_3[15:0] = {16{1'b0}};
          4'b1001: parked_3[31:16] = {16{1'b0}};
          4'b1010: parked_2[15:0] = {16{1'b0}};
          4'b1011: parked_2[31:16] = {16{1'b0}};
          4'b1100: parked_1[15:0] = {16{1'b0}};
          4'b1101: parked_1[31:16] = {16{1'b0}};
          endcase
        end
      end
    end
  end
  // update wire by register
  assign next_state = next_state_reg;
endmodule








// flip-flop
module DFF(clk, rst, next, state, initial_state);
  input clk;
  input rst;
  input [2:0] initial_state;
  input [2:0] next;
  output [2:0] state;
  reg [2:0] state;
 
  always@(posedge clk) begin
    if(rst)
      state <= initial_state;
    else
      state <= next;
  end
endmodule







// get car_type
module GetCarType(input [15:0] license_plate, output reg car_type);
  always @(license_plate) begin
    // $display("------------------------------------------------------------ INPUT TEST (GetCarType) -----------------------------------------------------------");
    // $display("license_plate: %d %d %d %d\n", license_plate[15:12], license_plate[11:8], license_plate[7:4], license_plate[3:0]);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
   
    car_type = license_plate[0] == 0 ? 1'b0 : 1'b1;
   
    // $display("----------------------------------------------------------- OUTPUT TEST (GetCarType) -----------------------------------------------------------");
    // $display("car type: %d\n", car_type);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
  end
endmodule








// get target floor
module GetTargetFloor(input [3:0] target, output [2:0] floor);
  assign floor = 3'b111 - target[3:1];
endmodule








// update empty and full
module UpdateEmptyFull(
  input rst,
  input clk,
  input in_mode,
  input out_mode,
  input [15:0] license_plate,
  input [2:0] leakage_floor,
  input [223:0] early_list,
  output reg [3:0] empty_suv,
  output reg [3:0] empty_sedan,
  output reg full_suv,
  output reg full_sedan,
  output reg [223:0] updated_early_list
  );
  integer i, idx;
  reg is_disable, disable_floor, car_type, parkedin_sedan, parkedin_suv;
  reg [13:0] early_statelist = 0;
  reg [15:0] current_car;
  reg [3:0] target_space;
  reg [23:0] concat_updown;
  reg [11:0] even_updown = {4'b0110, 4'b0100, 4'b0010};
  reg [11:0] odd_updown = {4'b0101, 4'b0011, 4'b0001};
  reg [3:0] current_space;
  reg [3:0] new_floor;
  reg [2:0] original_floor;


  always @(rst, in_mode, out_mode, license_plate, leakage_floor) begin
    if(rst) begin
      empty_suv = 7;
      empty_sedan = 5;
      full_suv = 0;
      full_sedan = 0;
      is_disable = 0;
      updated_early_list = 0;
    end
    // $display("------------------------------------------------------------ INPUT TEST (UpdateEmptyFull) -----------------------------------------------------------");
    // $display("park state list: %b\n",  parkstate_list);
    // $display("leakge_floor: %d\n", leakage_floor);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
    else begin
      // new *********************************************************
      empty_suv = 7;
      empty_sedan = 5;
      full_suv = 0;
      full_sedan = 0;
      updated_early_list = early_list;
      for(i = 13; i >= 0; i = i - 1) begin
        early_statelist[i] = updated_early_list[i * 16 + 15 -: 16] != 0;
      end
      current_car = license_plate;
      is_disable = current_car[15:12] == 4'b1001;
      car_type = current_car[0]; //`sedan : `suv
      target_space = 4'b1110;
      // in
      if({out_mode, in_mode} == 2'b01) begin
        if(is_disable) begin
          // sedan
          if(car_type == 0) begin
            // $display("finding space for disabled sedan");
            if(early_statelist[11] == 0) target_space = 4'd11;
            else if(early_statelist[13] == 0) target_space = 4'd13;
            else if(early_statelist[10] == 0) target_space = 4'd10;
            else if(early_statelist[7] == 0) target_space = 4'd7;
            else if(early_statelist[6] == 0) target_space = 4'd6;
            else if(early_statelist[3] == 0) target_space = 4'd3;
            else if(early_statelist[2] == 0) target_space = 4'd2;
            else if(early_statelist[12] == 0) target_space = 4'd12;
            else if(early_statelist[9] == 0) target_space = 4'd9;
            else if(early_statelist[8] == 0) target_space = 4'd8;
            else if(early_statelist[5] == 0) target_space = 4'd5;
            else if(early_statelist[4] == 0) target_space = 4'd4;
            else if(early_statelist[1] == 0) target_space = 4'd1;
            else if(early_statelist[0] == 0) target_space = 4'd0;
            else target_space = 4'b1110;
          end
          // suv
          else begin
            // $display("finding space for disabled suv");
            if(early_statelist[13] == 0) target_space = 4'd13;
            else if(early_statelist[12] == 0) target_space = 4'd12;
            else if(early_statelist[9] == 0) target_space = 4'd9;
            else if(early_statelist[8] == 0) target_space = 4'd8;
            else if(early_statelist[5] == 0) target_space = 4'd5;
            else if(early_statelist[4] == 0) target_space = 4'd4;
            else if(early_statelist[1] == 0) target_space = 4'd1;
            else if(early_statelist[0] == 0) target_space = 4'd0;
          end
        end
        // not disable
        else begin
          // sedan
          if(car_type == 0) begin
            // $display("finding space for normal sedan");
            if(early_statelist[10] == 0) target_space = 4'd10;
            else if(early_statelist[7] == 0) target_space = 4'd7;
            else if(early_statelist[6] == 0) target_space = 4'd6;
            else if(early_statelist[3] == 0) target_space = 4'd3;
            else if(early_statelist[2] == 0) target_space = 4'd2;
            else if(early_statelist[12] == 0) target_space = 4'd12;
            else if(early_statelist[9] == 0) target_space = 4'd9;
            else if(early_statelist[8] == 0) target_space = 4'd8;
            else if(early_statelist[5] == 0) target_space = 4'd5;
            else if(early_statelist[4] == 0) target_space = 4'd4;
            else if(early_statelist[1] == 0) target_space = 4'd1;
            else if(early_statelist[0] == 0) target_space = 4'd0;
          end
          // suv
          else begin
            // $display("finding space for normal suv");
            if(early_statelist[12] == 0) target_space = 4'd12;
            else if(early_statelist[9] == 0) target_space = 4'd9;
            else if(early_statelist[8] == 0) target_space = 4'd8;
            else if(early_statelist[5] == 0) target_space = 4'd5;
            else if(early_statelist[4] == 0) target_space = 4'd4;
            else if(early_statelist[1] == 0) target_space = 4'd1;
            else if(early_statelist[0] == 0) target_space = 4'd0;
          end
        end
        if(target_space[3:1] == (3'b111 - leakage_floor)) begin
          parkedin_sedan = (target_space[1:0] == 2 || target_space[1:0] == 3);
          parkedin_suv = (target_space[1:0] == 0 || target_space[1:0] == 1);
          original_floor = {1'b0, target_space[3:1]};
          if(current_car[15:12] == 4'b1001) begin
            // disable sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
            // disable suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          else begin
            // sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
            // suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
        end
        // $display("founded target for in when updating empty: %d \n", target_space);
        idx = target_space;
        early_statelist[idx] = 1;
        updated_early_list[16 * idx + 15 -: 16] = license_plate;
      end
      // out
      else if({out_mode, in_mode} == 2'b10) begin
        for(i = 0; i < 14; i = i + 1) begin
          if(updated_early_list[i * 16 + 15 -: 16] == current_car) idx = i;
        end
        early_statelist[idx] = 0;
        updated_early_list[16 * idx + 15 -: 16] = 0;
      end
      // move
      if(leakage_floor != 0) begin
        if(early_statelist[{(3'b111 - leakage_floor), 1'b0}] != 0) begin
          idx = {(3'b111 - leakage_floor), 1'b0};
          current_car = updated_early_list[16 * idx + 15 -: 16];
          early_statelist[idx] = 0;
          updated_early_list[16 * idx + 15 -: 16] = 0;
          current_space = idx;
          original_floor = current_space[3:1];
          parkedin_sedan = (current_space[1:0] == 2 || current_space[1:0] == 3);
          parkedin_suv = (current_space[1:0] == 0 || current_space[1:0] == 1);
          // $display("state before leakage: %b \n", early_statelist);
          if(current_car[15:12] == 4'b1001) begin
            // disable sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
            // disable suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          else begin
            // sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
            // suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          idx = target_space;
          // $display("found new for leakage in early: %d \n", target_space);
          early_statelist[idx] = 1;
          updated_early_list[16 * idx + 15 -: 16] = current_car;
          // $display("early park state list after moving : %b \n", early_statelist);
        end
        if(early_statelist[{3'b111 - leakage_floor, 1'b1}] != 0) begin
          idx = {(3'b111 - leakage_floor), 1'b1};
          current_car = updated_early_list[16 * idx + 15 -: 16];
          early_statelist[idx] = 0;
          updated_early_list[16 * idx + 15 -: 16] = 0;
          current_space = idx;
          original_floor = current_space[3:1];
          parkedin_sedan = (current_space[1:0] == 2 || current_space[1:0] == 3);
          parkedin_suv = (current_space[1:0] == 0 || current_space[1:0] == 1);
          // $display("state before leakage: %b \n", early_statelist);
          if(current_car[15:12] == 4'b1001) begin
            // disable sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
            // disable suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          else begin
            // sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
            // suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(early_statelist[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(early_statelist[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          idx = target_space;
          // $display("found new for leakage in early: %d \n", target_space);
          early_statelist[idx] = 1;
          updated_early_list[16 * idx + 15 -: 16] = current_car;
          // $display("early park state list after moving : %b \n", early_statelist);
        end
      end
      for(i = 13; i >= 0; i = i - 1) begin
        early_statelist[i] = updated_early_list[i * 16 + 15 -: 16] != 0;
      end
      // $display("early park state list after everything : %b \n", early_statelist);
      // count cars
      for (i = 0; i < 14; i = i + 1) begin 
        if (i != 11 && i != 13) begin 
          if (i[1:0] == 2 || i[1:0] == 3) begin // sedan
            if (early_statelist[i] != 0) empty_sedan = empty_sedan - 1; // car exists
          end
          else begin
            if (early_statelist[i] != 0) empty_suv = empty_suv - 1; // car exists
          end 
        end
      end
      // leakage floor 
      if(leakage_floor != 0) begin
        // $display("empty before %d %d \n", empty_sedan, empty_suv);
        disable_floor = (leakage_floor == 1) | (leakage_floor == 2);
        if(leakage_floor[0] == 0) empty_sedan = empty_sedan - (disable_floor ? 1 : 2);
        else empty_suv = empty_suv - (disable_floor ? 1 : 2);
        // $display("empty after %d %d \n", empty_sedan, empty_suv);
      end
      full_suv = (empty_suv == 0);
      full_sedan = (empty_sedan == 0);
    end
    // $display("----------------------------------------------------------- OUTPUT TEST (UpdateEmptyFull) -----------------------------------------------------------");
    // $display("empty_suv: %d\n",  empty_suv);
    // $display("empty_sedan: %d\n",  empty_sedan);
    // $display("full_suv: %d\n",  full_suv);
    // $display("full_suv: %d\n",  full_suv);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
  end


  always @(posedge clk) begin
    // $display("leakage_floor: %d\n", leakage_floor);
    // $display("empty_suv: %d\n",  empty_suv);
    // $display("empty_sedan: %d\n",  empty_sedan);
    // $display("full_suv: %d\n",  full_suv);
    // $display("full_suv: %d\n",  full_suv);
    // $display("early park state list : %b \n", early_statelist);
  end
endmodule








// update task list
module AddTaskList(
  input reset,
  input in_mode,
  input out_mode,
  input [15:0] license_plate,
  input done,
  input [395:0] task_list,
  input [3:0] task_num,
  input [223:0] park_list,
  input leakage,
  input [2:0] leakage_floor,
  output reg [395:0] updated_task_list,
  output reg [3:0] updated_task_num
  );
  integer idx;




  always @(posedge done) begin
    if(done) begin
      // $display("task done");
      updated_task_num = task_num;
      updated_task_list = task_list;
      updated_task_list = updated_task_list << 5'b10010;
      updated_task_num = updated_task_num - 1'b1;
    end
  end


  always @(reset, in_mode, out_mode, license_plate, leakage) begin // modified
    if(reset) begin
      // $display("reset");
      updated_task_num = 0;
      updated_task_list = 0;
    end
    else begin
      // $display("------------------------------------------------------------ INPUT TEST (AddTaskList) -----------------------------------------------------------");
      // $display("reset: %d\n", reset);
      // $display("in_mode: %d\n", in_mode);
      // $display("out_mode: %d\n", out_mode);
      // $display("license_plate: %d %d %d %d\n", license_plate[15:12], license_plate[11:8], license_plate[7:4], license_plate[3:0]);
      // $display("done: %d\n", done);
      // $display("task_list (first 3 tasks): \n");
      // $display(" %d | %d %d %d %d \n", task_list[395-:2], task_list[393-:4], task_list[389-:4], task_list[385-:4], task_list[381-:4]);
      // $display(" %d | %d %d %d %d \n", task_list[377-:2], task_list[375-:4], task_list[371-:4], task_list[367-:4], task_list[363-:4]);
      // $display(" %d | %d %d %d %d \n", task_list[359-:2], task_list[357-:4], task_list[353-:4], task_list[349-:4], task_list[345-:4]);
      // $display("task_num: %d\n", task_num);
      // $display("park_list:\n");
      // $display("%d %d %d %d | %d %d %d %d", park_list[31-:4], park_list[27-:4], park_list[23-:4], park_list[19-:4], park_list[15-:4], park_list[11-:4], park_list[7-:4], park_list[3-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[63-:4], park_list[59-:4], park_list[55-:4], park_list[51-:4], park_list[47-:4], park_list[43-:4], park_list[39-:4], park_list[35-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[95-:4], park_list[91-:4], park_list[87-:4], park_list[83-:4], park_list[79-:4], park_list[75-:4], park_list[71-:4], park_list[67-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[127-:4], park_list[123-:4], park_list[119-:4], park_list[115-:4], park_list[111-:4], park_list[107-:4], park_list[103-:4], park_list[99-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[159-:4], park_list[155-:4], park_list[151-:4], park_list[147-:4], park_list[143-:4], park_list[139-:4], park_list[135-:4], park_list[131-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[191-:4], park_list[187-:4], park_list[183-:4], park_list[179-:4], park_list[175-:4], park_list[171-:4], park_list[167-:4], park_list[163-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[223-:4], park_list[219-:4], park_list[215-:4], park_list[211-:4], park_list[207-:4], park_list[203-:4], park_list[199-:4], park_list[195-:4]);
      // $display("leakge: %d\n", leakage);
      // $display("leakge_floor: %d\n", leakage_floor);
      // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
      updated_task_num = task_num;
      updated_task_list = task_list;
      if(leakage) begin
        idx = {(3'b111 - leakage_floor), 1'b0};
        if(park_list[idx * 16 + 15 -: 16] != 0 && (task_num == 0 || (task_num > 0 && updated_task_list[(22 - task_num) * 18 + 17 -: 18] != {2'b11, park_list[idx * 16 + 15 -: 16]}))) begin
          if(updated_task_num > 0) updated_task_list = {updated_task_list[395:378], {2'b11, park_list[idx * 16 + 15 -: 16]}, updated_task_list[377:18]};
          else updated_task_list[395:378] = {2'b11, park_list[idx * 16 + 15 -: 16]};
          updated_task_num = updated_task_num + 1;
        end
        idx = {(3'b111 - leakage_floor), 1'b1};
        if(park_list[idx * 16 + 15 -: 16] != 0 && (task_num == 0 || (task_num > 0 && updated_task_list[(22 - task_num) * 18 + 17 -: 18] != {2'b11, park_list[idx * 16 + 15 -: 16]}))) begin
          if(updated_task_num > 0) updated_task_list = {updated_task_list[395:378], {2'b11, park_list[idx * 16 + 15 -: 16]}, updated_task_list[377:18]};
          else updated_task_list[395:378] = {2'b11, park_list[idx * 16 + 15 -: 16]};
          updated_task_num = updated_task_num + 1;
        end
      end
      idx = 21 - updated_task_num;
      if((task_num > 0 && updated_task_list[(idx + 1) * 18 + 17 -: 18] != {((in_mode) ? 2'b01 : 2'b10), license_plate} && license_plate != 0 && (in_mode ^ out_mode)) || task_num == 0) begin
        // $display("previous %b, now: %b, truth %d\n", updated_task_list[(idx + 1) * 18 + 17 -: 18], {((in_mode) ? 2'b01 : 2'b10), license_plate}, updated_task_list[(idx + 1) * 18 + 17 -: 18] != {((in_mode) ? 2'b01 : 2'b10), license_plate});
        if(in_mode == 1) begin
          updated_task_list[idx * 18 + 17 -: 18] = {2'b01, license_plate};
          updated_task_num = updated_task_num + 1;
        end
        else if(out_mode == 1) begin
          updated_task_list[idx * 18 + 17 -: 18] = {2'b10, license_plate};
          updated_task_num = updated_task_num + 1;
        end
      end
      // $display("----------------------------------------------------------- OUTPUT TEST (AddTaskList) -----------------------------------------------------------");
      // $display("updated task_list (first 3 tasks): \n");
      // $display(" %d | %d %d %d %d \n", updated_task_list[395-:2], updated_task_list[393-:4], updated_task_list[389-:4], updated_task_list[385-:4], updated_task_list[381-:4]);
      // $display(" %d | %d %d %d %d \n", updated_task_list[377-:2], updated_task_list[375-:4], updated_task_list[371-:4], updated_task_list[367-:4], updated_task_list[363-:4]);
      // $display(" %d | %d %d %d %d \n", updated_task_list[359-:2], updated_task_list[357-:4], updated_task_list[353-:4], updated_task_list[349-:4], updated_task_list[345-:4]);
      // $display("update task_num: %d\n", updated_task_num);
      // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
    end
  end
endmodule








// read task list
module ReadTaskList(
  input [2:0] cur_state,
  input [395:0] task_list,
  input [223:0] park_list,
  input plate_type,
  input [15:0] moving,
  input [2:0] current_floor,
  input going_back,
  input leakage,
  input [2:0] leakage_floor,

  output reg current_in,
  output reg current_out,
  output reg [15:0] current_car,
  output reg [3:0] target_space,
  output reg [3:0] original_space,
  output reg [3:0] current_space,
  output reg [13:0] parkstate_list
  );
  integer i, idx;
  reg [23:0] concat_updown;
  reg [11:0] even_updown = {4'b0110, 4'b0100, 4'b0010};
  reg [11:0] odd_updown = {4'b0101, 4'b0011, 4'b0001};
  reg [3:0] original_floor;
  reg [3:0] new_floor;
  reg is_disable, car_type, check_location, parkedin_sedan, parkedin_suv;  


  always @(cur_state, task_list, plate_type, moving, leakage) begin
    // $display("------------------------------------------------------------ INPUT TEST (ReadTaskList) -----------------------------------------------------------");
    // $display("cur_state: %d\n", cur_state);
    // $display("task_list (first 3 tasks): \n");
    // $display(" %d | %d %d %d %d \n", task_list[395-:2], task_list[393-:4], task_list[389-:4], task_list[385-:4], task_list[381-:4]);
    // $display(" %d | %d %d %d %d \n", task_list[377-:2], task_list[375-:4], task_list[371-:4], task_list[367-:4], task_list[363-:4]);
    // $display(" %d | %d %d %d %d \n", task_list[359-:2], task_list[357-:4], task_list[353-:4], task_list[349-:4], task_list[345-:4]);
    // $display("park_list:\n");
    // $display("%d %d %d %d | %d %d %d %d", park_list[31-:4], park_list[27-:4], park_list[23-:4], park_list[19-:4], park_list[15-:4], park_list[11-:4], park_list[7-:4], park_list[3-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[63-:4], park_list[59-:4], park_list[55-:4], park_list[51-:4], park_list[47-:4], park_list[43-:4], park_list[39-:4], park_list[35-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[95-:4], park_list[91-:4], park_list[87-:4], park_list[83-:4], park_list[79-:4], park_list[75-:4], park_list[71-:4], park_list[67-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[127-:4], park_list[123-:4], park_list[119-:4], park_list[115-:4], park_list[111-:4], park_list[107-:4], park_list[103-:4], park_list[99-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[159-:4], park_list[155-:4], park_list[151-:4], park_list[147-:4], park_list[143-:4], park_list[139-:4], park_list[135-:4], park_list[131-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[191-:4], park_list[187-:4], park_list[183-:4], park_list[179-:4], park_list[175-:4], park_list[171-:4], park_list[167-:4], park_list[163-:4]);
    // $display("%d %d %d %d | %d %d %d %d", park_list[223-:4], park_list[219-:4], park_list[215-:4], park_list[211-:4], park_list[207-:4], park_list[203-:4], park_list[199-:4], park_list[195-:4]);
    // $display("plate type: %d\n", plate_type);
    // $display("moving: %d %d %d %d\n", moving[15-:4], moving[11-:4], moving[7-:4], moving[3-:4]);
    // $display("current_floor: %d\n", current_floor);
    // $display("leakage: %d\n", leakage);
    // $display("leakage_floor: %d\n", leakage_floor);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
    for(i = 13; i >= 0; i = i - 1) begin
      parkstate_list[i] = park_list[i * 16 + 15 -: 16] != 0;
    end
    current_in = 0;
    current_out = 0;
    current_car = task_list[393:378];
    is_disable = current_car[15:12] == 4'b1001;
    car_type = current_car[0]; //`sedan : `suv
    target_space = 4'b1110;
    // in
    if(task_list[395:394] == 2'b01) begin
      current_in = 1;
      if(cur_state != `S2) begin
        if(is_disable) begin
          // sedan
          if(car_type == 0) begin
            // $display("finding space for disabled sedan");
            if(parkstate_list[11] == 0) target_space = 4'd11;
            else if(parkstate_list[13] == 0) target_space = 4'd13;
            else if(parkstate_list[10] == 0) target_space = 4'd10;
            else if(parkstate_list[7] == 0) target_space = 4'd7;
            else if(parkstate_list[6] == 0) target_space = 4'd6;
            else if(parkstate_list[3] == 0) target_space = 4'd3;
            else if(parkstate_list[2] == 0) target_space = 4'd2;
            else if(parkstate_list[12] == 0) target_space = 4'd12;
            else if(parkstate_list[9] == 0) target_space = 4'd9;
            else if(parkstate_list[8] == 0) target_space = 4'd8;
            else if(parkstate_list[5] == 0) target_space = 4'd5;
            else if(parkstate_list[4] == 0) target_space = 4'd4;
            else if(parkstate_list[1] == 0) target_space = 4'd1;
            else if(parkstate_list[0] == 0) target_space = 4'd0;
            else target_space = 4'b1110;
          end
          // suv
          else begin
            // $display("finding space for disabled suv");
            if(parkstate_list[13] == 0) target_space = 4'd13;
            else if(parkstate_list[12] == 0) target_space = 4'd12;
            else if(parkstate_list[9] == 0) target_space = 4'd9;
            else if(parkstate_list[8] == 0) target_space = 4'd8;
            else if(parkstate_list[5] == 0) target_space = 4'd5;
            else if(parkstate_list[4] == 0) target_space = 4'd4;
            else if(parkstate_list[1] == 0) target_space = 4'd1;
            else if(parkstate_list[0] == 0) target_space = 4'd0;
          end
        end
        // not disable
        else begin
          // sedan
          if(car_type == 0) begin
            // $display("finding space for normal sedan");
            if(parkstate_list[10] == 0) target_space = 4'd10;
            else if(parkstate_list[7] == 0) target_space = 4'd7;
            else if(parkstate_list[6] == 0) target_space = 4'd6;
            else if(parkstate_list[3] == 0) target_space = 4'd3;
            else if(parkstate_list[2] == 0) target_space = 4'd2;
            else if(parkstate_list[12] == 0) target_space = 4'd12;
            else if(parkstate_list[9] == 0) target_space = 4'd9;
            else if(parkstate_list[8] == 0) target_space = 4'd8;
            else if(parkstate_list[5] == 0) target_space = 4'd5;
            else if(parkstate_list[4] == 0) target_space = 4'd4;
            else if(parkstate_list[1] == 0) target_space = 4'd1;
            else if(parkstate_list[0] == 0) target_space = 4'd0;
          end
          // suv
          else begin
            // $display("finding space for normal suv");
            if(parkstate_list[12] == 0) target_space = 4'd12;
            else if(parkstate_list[9] == 0) target_space = 4'd9;
            else if(parkstate_list[8] == 0) target_space = 4'd8;
            else if(parkstate_list[5] == 0) target_space = 4'd5;
            else if(parkstate_list[4] == 0) target_space = 4'd4;
            else if(parkstate_list[1] == 0) target_space = 4'd1;
            else if(parkstate_list[0] == 0) target_space = 4'd0;
          end
        end
        if(target_space[3:1] == (3'b111 - leakage_floor)) begin
          parkedin_sedan = (target_space[1:0] == 2 || target_space[1:0] == 3);
          parkedin_suv = (target_space[1:0] == 0 || target_space[1:0] == 1);
          original_floor = {1'b0, target_space[3:1]};
          if(current_car[15:12] == 4'b1001) begin
            // disable sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
            // disable suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          else begin
            // sedan
            if(current_car[0] == 0) begin
              if(parkedin_suv) concat_updown = {odd_updown, even_updown};
              else concat_updown = {odd_updown, even_updown};
              for(i = 5; i >= 0; i = i - 1) begin
                new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
            // suv
            else begin
              for(i = 2; i >= 0; i = i - 1) begin
                new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
                new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
                if(new_floor <= 6  && new_floor >= 0) begin
                  if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
                  if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
                end
              end
            end
          end
          idx = target_space;
          parkstate_list[idx] = 1;
          // $display("alternative target for in: %d \n", target_space);
        end
        idx = target_space;
        parkstate_list[idx] = 1;
      end
    end
    // out
    else if(task_list[395:394] == 2'b10) begin
      if(~going_back) begin
        original_space = 0;
        current_out = 1;
        for(i = 0; i < 14; i = i + 1) begin
          if(park_list[i * 16 + 15 -: 16] == current_car) idx = i;
        end
        // $display("CHECK THIS: %d \n\n\n",idx);
        if(moving == 0) target_space = idx;
        else target_space = 4'b1110;
        parkstate_list[idx] = 0;
        original_space = idx;
      end
    end
    // move
    else if(task_list[395:394] == 2'b11) begin
      current_in = 1;
      current_out = 1;
      idx = 15;
      for(i = 0; i < 14; i = i + 1) begin
        if(park_list[i * 16 + 15 -: 16] == current_car) idx = i;
      end
      idx = (idx == 15) ? current_space : idx;
      parkstate_list[idx] = 0;
      current_space = idx;
      original_floor = current_space[3:1];
      parkedin_sedan = (current_space[1:0] == 2 || current_space[1:0] == 3);
      parkedin_suv = (current_space[1:0] == 0 || current_space[1:0] == 1);
      if(current_car[15:12] == 4'b1001) begin
        // disable sedan
        if(current_car[0] == 0) begin
          if(parkedin_suv) concat_updown = {odd_updown, even_updown};
          else concat_updown = {odd_updown, even_updown};
          for(i = 5; i >= 0; i = i - 1) begin
            new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
            end
            new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
            end
          end
        end
        // disable suv
        else begin
          for(i = 2; i >= 0; i = i - 1) begin
            new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
            end
            new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0) target_space = {new_floor, 1'b1};
            end
          end
        end
      end
      else begin
        // sedan
        if(current_car[0] == 0) begin
          if(parkedin_suv) concat_updown = {odd_updown, even_updown};
          else concat_updown = {odd_updown, even_updown};
          for(i = 5; i >= 0; i = i - 1) begin
            new_floor = original_floor + concat_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
            end
            new_floor = original_floor - concat_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 11 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
            end
          end
        end
        // suv
        else begin
          for(i = 2; i >= 0; i = i - 1) begin
            new_floor = original_floor + even_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
            end
            new_floor = original_floor - even_updown[i * 4 + 3 -: 4];
            if(new_floor <= 6  && new_floor >= 0) begin
              if(parkstate_list[{new_floor, 1'b0}] == 0) target_space = {new_floor, 1'b0};
              if(parkstate_list[{new_floor, 1'b1}] == 0 && {new_floor, 1'b1} != 13) target_space = {new_floor, 1'b1};
            end
          end
        end
      end
      idx = target_space;
      parkstate_list[idx] = 1;
      // $display("alternative target for moving: %d \n", target_space);
      if(moving == 0) target_space = current_space;
    end
    // in or out, always 0 if plate type different
    if(plate_type != car_type || (current_in && ~current_out && moving == 0 && current_floor != 0)) target_space = 4'b1110;
    // $display("----------------------------------------------------------- OUTPUT TEST (ReadTaskList) -----------------------------------------------------------");
    // $display("current_in: %d\n", current_in);
    // $display("current_out: %d\n", current_out);
    // $display("current_car: %d %d %d %d\n", current_car[15-:4], current_car[11-:4], current_car[7-:4], current_car[3-:4]);
    // $display("target_space: %d\n", target_space);
    // $display("original_space: %d\n", original_space);
    // $display("current_space: %d\n", current_space);
    // $display("parkstate_list: %b\n", parkstate_list);
    // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
  end
endmodule


// update fee
module UpdateFee(
  input reset,
  input clk,
  input done,
  input [111:0] fee,
  input [223:0] park_list,
  input [3:0] original_space,
  input [3:0] current_space,
  input [15:0] car,
  input [3:0] target_space,
  input [2:0] state,
  input [395:0] task_list,
  output reg [111:0] updated_fee
  );
  integer i, j;
  reg [17:0] task_check;
  reg [15:0] current_car;
  reg [7:0] save_fee = 0;
  reg [3:0] origin_temp = 0;
  reg check = 0;

  always @(posedge clk or reset) begin
    if (reset) begin
      updated_fee = 0;
      task_check = 0;
      current_car = 0;
      save_fee = 0;
      origin_temp = 0;
      check = 0;
    end
    else begin
      // $display("------------------------------------------------------------ INPUT TEST (Update Fee) -----------------------------------------------------------");
      // $display("reset: %d\n", reset);
      // $display("done: %d\n", done);
      // $display("fee:\n");
      // $display("%d | %d", fee[15-:8], fee[7-:8]);
      // $display("%d | %d", fee[31-:8], fee[23-:8]);
      // $display("%d | %d", fee[47-:8], fee[39-:8]);
      // $display("%d | %d", fee[63-:8], fee[55-:8]);
      // $display("%d | %d", fee[79-:8], fee[71-:8]);
      // $display("%d | %d", fee[95-:8], fee[87-:8]);
      // $display("%d | %d", fee[111-:8], fee[103-:8]);
      // $display("park_list:\n");
      // $display("%d %d %d %d | %d %d %d %d", park_list[31-:4], park_list[27-:4], park_list[23-:4], park_list[19-:4], park_list[15-:4], park_list[11-:4], park_list[7-:4], park_list[3-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[63-:4], park_list[59-:4], park_list[55-:4], park_list[51-:4], park_list[47-:4], park_list[43-:4], park_list[39-:4], park_list[35-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[95-:4], park_list[91-:4], park_list[87-:4], park_list[83-:4], park_list[79-:4], park_list[75-:4], park_list[71-:4], park_list[67-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[127-:4], park_list[123-:4], park_list[119-:4], park_list[115-:4], park_list[111-:4], park_list[107-:4], park_list[103-:4], park_list[99-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[159-:4], park_list[155-:4], park_list[151-:4], park_list[147-:4], park_list[143-:4], park_list[139-:4], park_list[135-:4], park_list[131-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[191-:4], park_list[187-:4], park_list[183-:4], park_list[179-:4], park_list[175-:4], park_list[171-:4], park_list[167-:4], park_list[163-:4]);
      // $display("%d %d %d %d | %d %d %d %d", park_list[223-:4], park_list[219-:4], park_list[215-:4], park_list[211-:4], park_list[207-:4], park_list[203-:4], park_list[199-:4], park_list[195-:4]);
      // $display("original_space: %d\n", original_space);
      // $display("current_space: %d\n", current_space);
      // $display("car: %d %d %d %d\n", car[15-:4], car[11-:4], car[7-:4], car[3-:4]);
      // $display("target_space: %d\n", target_space);
      // $display("state: %d\n", state);
      // $display("task_list (first 3 tasks): \n");
      // $display(" %d | %d %d %d %d \n", task_list[395-:2], task_list[393-:4], task_list[389-:4], task_list[385-:4], task_list[381-:4]);
      // $display(" %d | %d %d %d %d \n", task_list[377-:2], task_list[375-:4], task_list[371-:4], task_list[367-:4], task_list[363-:4]);
      // $display(" %d | %d %d %d %d \n", task_list[359-:2], task_list[357-:4], task_list[353-:4], task_list[349-:4], task_list[345-:4]);
      // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
      updated_fee = fee;
      if(task_list[395:394] == 2'b11 && state != 3'b010) begin
        if(state == 3'b110) begin // S6
          // $display("moving phase 1");
          // $display("current space: %d \n", current_space);
          // $display("target space: %d \n", target_space);
          // $display("saved fee: %d \n", save_fee);
          // $display("original fee: %d \n", updated_fee[current_space * 8 + 7 -: 8]);
          save_fee = updated_fee[current_space * 8 + 7 -: 8];
          updated_fee[current_space * 8 + 7 -: 8] = 0;
          if(car[15:12] == 4'b1000) save_fee = save_fee + 1;
          else if(car[15:12] != 4'b1001 && car[15:12] != 0) save_fee = save_fee + 2;
        end
        else if(state == 3'b011) begin // S3
          // $display("moving phase 2");
          if(car[15:12] == 4'b1000) save_fee = save_fee + 1;
          else if(car[15:12] != 4'b1001 && car[15:12] != 0) save_fee = save_fee + 2;
          updated_fee[current_space * 8 + 7 -: 8] = 0;
        end
        else if(state == 3'b111) begin // S7
          // $display("moving phase 3");
          if(car[15:12] == 4'b1000) save_fee = save_fee + 1;
          else if(car[15:12] != 4'b1001 && car[15:12] != 0) save_fee = save_fee + 2;
          updated_fee[target_space * 8 + 7 -: 8] = save_fee;
          save_fee = 0;
        end
      end
      if(done && park_list[origin_temp * 16 + 15-: 16] == 4'b0000) begin
        updated_fee[origin_temp * 8 + 7 -: 8] = 0;
      end
      else begin
        for(i = 0; i < 14; i = i + 1) begin
          current_car = park_list[i * 16 + 15 -: 16];
          check = 0;
          for (j = 0; j < 22; j = j+1) begin
            task_check = task_list[18*j+17-:18];
            if (task_check[17:16] == 2'b10 && task_check[15:0] == current_car) check = 1;
          end
          if (!check) begin
            if(current_car[15:12] == 4'b1000) updated_fee[i * 8 + 7 -: 8] = updated_fee[i * 8 + 7 -: 8] + 1;
            else if(current_car[15:12] != 4'b1001 && current_car[15:12] != 0) updated_fee[i * 8 + 7 -: 8] = updated_fee[i * 8 + 7 -: 8] + 2;
          end
        end
      end
      // $display("----------------------------------------------------------- OUTPUT TEST (Update Fee) -----------------------------------------------------------");
      // $display("updated_fee:\n");
      // $display("%d | %d", updated_fee[15-:8], updated_fee[7-:8]);
      // $display("%d | %d", updated_fee[31-:8], updated_fee[23-:8]);
      // $display("%d | %d", updated_fee[47-:8], updated_fee[39-:8]);
      // $display("%d | %d", updated_fee[63-:8], updated_fee[55-:8]);
      // $display("%d | %d", updated_fee[79-:8], updated_fee[71-:8]);
      // $display("%d | %d", updated_fee[95-:8], updated_fee[87-:8]);
      // $display("%d | %d", updated_fee[111-:8], updated_fee[103-:8]);
      // $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
    end
    check = 0;
  end


  always @(posedge clk or reset) begin
    if (reset) origin_temp = 0;
    else origin_temp = original_space;
  end


endmodule

