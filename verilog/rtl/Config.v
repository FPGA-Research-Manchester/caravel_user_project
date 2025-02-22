// SPDX-FileCopyrightText:
// 2021 Nguyen Dao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

module Config (CLK, Rx, ComActive, ReceiveLED, s_clk, s_data, SelfWriteData, SelfWriteStrobe, ConfigWriteData, ConfigWriteStrobe, FrameAddressRegister, LongFrameStrobe, RowSelect);
	//parameter NumberOfRows = 16;
	parameter RowSelectWidth = 5;
	parameter FrameBitsPerRow = 32;
	//parameter desync_flag = 20;
	input CLK;
	// UART configuration port
	input Rx;
	output ComActive;
	output ReceiveLED;
	// BitBang configuration port
	input s_clk;
	input s_data;
	// CPU configuration port
	input [32-1:0] SelfWriteData; // configuration data write port
	input SelfWriteStrobe; // must decode address and write enable
	
	output [32-1:0] ConfigWriteData;
	output ConfigWriteStrobe;
	
	output [FrameBitsPerRow-1:0] FrameAddressRegister;
	output LongFrameStrobe;
	output [RowSelectWidth-1:0] RowSelect;

	wire [7:0] Command;
	wire [31:0] UART_WriteData;
	wire UART_WriteStrobe;
	wire [31:0] UART_WriteData_Mux;
	wire UART_WriteStrobe_Mux;
	wire UART_ComActive;
	wire UART_LED;

	wire [31:0] BitBangWriteData;
	wire BitBangWriteStrobe;
	wire [31:0] BitBangWriteData_Mux;
	wire BitBangWriteStrobe_Mux;
	wire BitBangActive;
	
	wire Reset;

	config_UART INST_config_UART (
	.CLK(CLK),
	.Rx(Rx),
	.WriteData(UART_WriteData),
	.ComActive(UART_ComActive),
	.WriteStrobe(UART_WriteStrobe),
	.Command(Command),
	.ReceiveLED(UART_LED)
	);
	
	//bitbang
	bitbang Inst_bitbang (
	.s_clk(s_clk),
	.s_data(s_data),
	.strobe(BitBangWriteStrobe),
	.data(BitBangWriteData),
	.active(BitBangActive),
	.clk(CLK)
	);
	
	// BitBangActive is used to switch between bitbang or internal configuration port (BitBang has therefore higher priority)
	assign BitBangWriteData_Mux = BitBangActive ? BitBangWriteData : SelfWriteData;
	assign BitBangWriteStrobe_Mux = BitBangActive ? BitBangWriteStrobe : SelfWriteStrobe;	

	// ComActive is used to switch between (bitbang+internal) port or UART (UART has therefore higher priority
	assign UART_WriteData_Mux = UART_ComActive ? UART_WriteData : BitBangWriteData_Mux;
	assign UART_WriteStrobe_Mux = UART_ComActive ? UART_WriteStrobe : BitBangWriteStrobe_Mux;	
	
	assign ConfigWriteData = UART_WriteData_Mux;
	assign ConfigWriteStrobe = UART_WriteStrobe_Mux;
	
	assign Reset = UART_ComActive || BitBangActive;

	assign ComActive = UART_ComActive;
	assign ReceiveLED = UART_LED^BitBangWriteStrobe;   
	
//	wire [FrameBitsPerRow-1:0] FrameAddressRegister;
//	wire LongFrameStrobe;
//	wire [RowSelectWidth-1:0] RowSelect;
	
	ConfigFSM ConfigFSM_inst (
	.CLK(CLK),
	.WriteData(UART_WriteData_Mux),
	.WriteStrobe(UART_WriteStrobe_Mux),
	.Reset(Reset),
	//outputs
	.FrameAddressRegister(FrameAddressRegister),
	.LongFrameStrobe(LongFrameStrobe),
	.RowSelect(RowSelect)
	);
	
endmodule
