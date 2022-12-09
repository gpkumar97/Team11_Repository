//-----------------------------------------------------------------------------
// Title       : Cache Statistics
// Authors     : Naveen Babu Vanamala <>
//				 Pavan Kumar Govardhanam <>
//				 Sai Krishna Vallabhaneni <>
//				 Venkata Mohan Krishna Challa <ven4@pdx.edu>
//
// Description : Displays the statistics of the Cache like no_of_readss, no_of_writess, Hits, Misses, Cache_Ratio and also sends the types of commands to the Cache design.			 
//		 	
//-----------------------------------------------------------------------------

package cache_specs;


		
parameter cache_size			=	134217728;   		
parameter line_size				=	512;		
parameter ways					=	8;				
parameter address_bits				=	32;				
parameter bits_state				=	2;		
parameter true					=	1;		
parameter false					=	0;


parameter Byte_select_bits 		=	$clog2(line_size/8);
parameter sets				= 	cache_size/(ways*line_size);
parameter Set_bits			=	$clog2(sets);
parameter Tag_bits			=	address_bits - Set_bits - Byte_select_bits;
parameter PLRU_bits			=	7;

parameter Command_size			=	4;
parameter Address_size			=	32;

parameter CPU_read 			= 	0;
parameter CPU_write 			= 	1;

typedef enum bit[3:0]{CPU_data_read=0,CPU_data_write=1,CPU_instruction_read=2,SNOOP_invalidate=3,SNOOP_read=4,SNOOP_write=5,SNOOP_rdX=6,CLEAR=8,PRINT=9}command_type;


typedef enum bit[1:0] {NO_HIT, HIT, HIT_M}snp_rslt_t;
typedef enum bit[2:0] {READ, WRITE, INVALIDATE, RWIM}bus_op_t;


typedef enum bit[1:0] {M,E,S,I}state_t;

logic Normal_mode = 1 ;

endpackage : cache_specs

