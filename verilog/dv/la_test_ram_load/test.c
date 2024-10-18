#include <stdio.h>
#include <stdint.h>

int main(void) {
    uint32_t memory[16] = {
            0x1f, // LDA 15
            0x90, // HLT
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0xff
    };

	uint32_t reg_la0_data = 1;

	uint32_t default_cpu_reset = 0x00000000;

    reg_la0_data = default_cpu_reset;

    // set lines with delay
    for (int i=0; i<16; i++) {

		uint32_t address = (uint32_t)i << 1;
		uint32_t data = (uint32_t)memory[i] << 5;

        reg_la0_data ^= data ^ address + 1;

		printf("%04b : %032b\n", i, reg_la0_data);

    	reg_la0_data = default_cpu_reset;
    }

	uint32_t default_cpu_running = 0x00001000;
	uint32_t clock = 0;
	for (int i=0; i<32; i++) {
		clock = (clock) ? 0 : 1;
		reg_la0_data = default_cpu_running ^ clock << 13;
		printf("%032b\n", reg_la0_data);
	}

	return 0;
}
