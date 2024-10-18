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

    // set lines with delay
    for (int i=0; i<16; i++) {
		uint32_t address = (uint32_t)i << 1;
		uint32_t data = (uint32_t)memory[i] << 5;

		uint32_t output = data ^ address + 1;
        reg_la0_data = output;

		printf("%04b : %032b\n", i, reg_la0_data);
    }

	return 0;
}
