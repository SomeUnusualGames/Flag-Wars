# Main entry point of the game
MAIN_FILE = main.bas

# FreeBASIC compiler
FBC ?= fbc64

ifeq ($(OS),Windows_NT)
	OUTPUT_FILE = flag-wars.exe
	FBFLAGS ?= -x $(OUTPUT_FILE) -s gui -Wl --subsystem,windows
else
	FBC = fbc
	OUTPUT_FILE = flag-wars
	FBFLAGS ?= -x $(OUTPUT_FILE) -s gui
endif

main:
	$(FBC) $(MAIN_FILE) $(FBFLAGS)
