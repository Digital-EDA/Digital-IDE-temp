module syntax_error_example (
    input wire clock,
    input wire reset,
    input wire start,
    output reg [15:0] result
);

// Incorrect declaration type, should be 'reg' not 'integer' for synthesis compatibility
integer count;

// Undeclared identifier 'max_value', leading to a compilation error
always @(posedge clock)
begin
    if (reset) begin
        result <= 0;
        count <= 0;
    end
    else if (start && count < max_value) begin // 'max_value' is not declared anywhere
        count <= count + 1;
        result <= result + count;
    end
end

// Syntax error with misplaced semicolon, causing compilation failure
always @(posedge clock);
begin
    if (start) begin
        result <= result * 2;
    end
end

endmodule

