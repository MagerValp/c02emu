	.import __IO_START__

mmu			= $00

display_base		= __IO_START__ + $00
display_mode		= __IO_START__ + $03
display_irq_mask	= __IO_START__ + $04
display_irq_status	= __IO_START__ + $05

keyboard		= __IO_START__ + $0800
keyboard_queue		= keyboard + $00
keyboard_queue_size	= keyboard + $01

debug			= __IO_START__ + $0f00
debug_putchar		= debug + $00
debug_dump_regs		= debug + $02
debug_print_testnum	= debug + $03
debug_primm		= debug + $04
debug_trace_mask	= debug + $0b
debug_trace_cpu_on	= debug + $0c
debug_trace_cpu_off	= debug + $0d
debug_trace_ram_on	= debug + $0e
debug_trace_ram_off	= debug + $0f
DEBUG_TRACE_CPU 	= %00000001
DEBUG_TRACE_WRITE 	= %00000010
DEBUG_TRACE_READ 	= %00000100
