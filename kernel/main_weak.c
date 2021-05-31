#include <kernel_internal.h>

void __weak main(void)
{
	/* NOP default main() if the application does not provide one. */
	arch_nop();
}
