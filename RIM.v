module RIM(
    input clk,rst_n,in_valid,
    input [7:0] maze,
    output reg out_valid,
    output reg [2:0] out_row,out_col
);
reg [79:0] map;
reg [3:0] count_rat;
reg [2:0] count_maze;
reg [2:0] col,row;
reg [2:0] ans_col [0:14];
reg [2:0] ans_row [0:14];
reg [3:0] path_num;
wire [3:0] stack_path_num;
wire [2:0] stack_row,stack_col;
wire down_right;
wire [6:0] project_p,project_p_d,project_p_r;

assign project_p = (row<<3)+row+col;
assign project_p_d = project_p+9;
assign project_p_r = project_p+1;
wire dead_path;
/************* input maze *************/
wire [6:0] map_l;
// assign map_h = {(count_maze+1),3'b000}-1+count_maze;
assign map_l = {count_maze,count_maze};
wire complete_ans;
assign complete_ans = (path_num==15 && count_rat!=15)? 1'b1:1'b0;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        count_maze <= 3'd0;
        col <= 3'd0;
        row <= 3'd0;
        map <= 80'd0;
        path_num <= 0;
    end else begin
        if(in_valid)begin
            map[map_l]   <= maze[0];
            map[map_l+1] <= maze[1];
            map[map_l+2] <= maze[2];
            map[map_l+3] <= maze[3];
            map[map_l+4] <= maze[4];
            map[map_l+5] <= maze[5];
            map[map_l+6] <= maze[6];
            map[map_l+7] <= maze[7];
            map[79] <= 1'b1;
            count_maze <= count_maze+1;
            col<=3'd0;
            row<=3'd0;
            path_num <= 4'd0;
        end else begin
            map[project_p] <= 1'b0;
            if (!complete_ans) begin
                if(dead_path) begin
                    row <= stack_row;
                    col <= stack_col;
                    path_num <= stack_path_num;
                end else begin
                    ans_row[path_num] <= row;
                    ans_col[path_num] <= col;
                    if(down_right)
                        col<=col+1;
                    else
                        row<=row+1;
                    path_num <= path_num+1;
                end
            end 
        end
    end
end
wire stack_w_en;
corner now_corner(
    .down_p(map[project_p_d]),
    .right_p(map[project_p_r]),
    .down_right(down_right),
    .dead_path(dead_path),
    .is_corner_out(stack_w_en)
);
stack my_stack(
    .clk(clk),
    .rst_n(rst_n),
    .w_en(stack_w_en),
    .pop(dead_path),
    .clr(in_valid),
    .row_in(row),
    .col_in(col),
    .path_num_in(path_num),
    .row_out(stack_row),
    .col_out(stack_col),
    .path_num_out(stack_path_num)
);
/************* input maze *************/

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        count_rat<=0;
        out_col<=0;
        out_row<=0;
    end else begin
        if(complete_ans)begin
            out_col <=ans_col[count_rat];
            out_row <=ans_row[count_rat];
            count_rat <= count_rat+1;
        end else begin
            count_rat<=0;
            out_col<=0;
            out_row<=0;
        end

    end
end
always@(posedge clk,negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;
    end else begin
        if(complete_ans)
            out_valid <= 1;
        else 
            out_valid <= 0;
    end
end
endmodule


module corner(
    input down_p,right_p,
    output down_right,dead_path,
    output is_corner_out
);
assign is_corner_out = down_p & right_p;
assign down_right = right_p ^ is_corner_out;
assign dead_path = ~(right_p | down_p);

endmodule

module stack(
    input clk,rst_n,w_en,pop,clr,
    input [2:0] row_in,col_in,
    input [3:0] path_num_in,
    output [2:0] row_out,col_out,
    output [3:0] path_num_out
);
reg [2:0] count;
reg [2:0] stack_row [0:6];
reg [2:0] stack_col [0:6];
reg [3:0] stack_path_num [0:6];
assign row_out=stack_row[count-1];
assign col_out=stack_col[count-1];
assign path_num_out=stack_path_num[count-1];
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        count<=0;
    end else begin
        if(clr)
            count<=0;
        else if(w_en)begin
            stack_row[count] <= row_in;
            stack_col[count] <= col_in;
            stack_path_num[count] <= path_num_in;
            count <= count + 1;
        end else if(pop)
            count <= count - 1; 
    end
end

endmodule
