###############################################################################
#
# PIC compile makefile for use with SDCC and GPUTILS
# You can find an dummy projects at http://szokesandor.hu/sdcc
#
# C2006.12.02. [EMAIL PROTECTED]
# C2008.03.22. [EMAIL PROTECTED]
#
# Please send bug reports or comments to the author.
# If you improved this makefile, please send the updates back to the author!
#
# Licensed under the GNU GPL V2 or later
#
#
#----------------------------------------------------------------------------
# Name of the .hex file without extention
#
PRJ	  = firmware
#
#-----------------------------------------------------------------------------
# Used modules, the first should contain the main() function
# Assembly modules should have extention ".S", because the current clean up!
#
SRCS_C       := main.c
SRCS_ASM     := fuses.asm
SRCS_H		 := main.h
#
#----------------------------------------------------------------------------
# Type of the used cpu
#
#CPU	  = 12f683
CPU	  = 16f88
#
#----------------------------------------------------------------------------
# Type of the architecture eg. -mpic14 or -mpic16
#
ARCH	 = -mpic14
#
#----------------------------------------------------------------------------
# Adjust to sdcc data dir and to gputils dir.
# Normally they are installed into /usr/share
# In my case I have built sdcc under my home.
#
SDCCDIR      = /usr/local/share/sdcc
GPUTILSDIR   = /opt/local/share/gputils
#
#----------------------------------------------------------------------------
# Adjust according to architecture 14bit (pic) or 16bit (pic16)
#
INCLUDEDIR   = $(SDCCDIR)/include/pic
LIBDIR       = $(SDCCDIR)/lib/pic

#INCLUDEDIR   = $(SDCCDIR)/include/pic16
#LIBDIR       = $(SDCCDIR)/lib/pic16
#
#----------------------------------------------------------------------------
# Defining the tools, you may have several version installed
# for different reasons (testing, production, etc.)
#
SDCC	 = /usr/local/bin/sdcc
GPASM	= /opt/local/bin/gpasm
GPDASM       = /opt/local/bin/gpdasm
GPLINK       = /opt/local/bin/gplink
PK2CMD		 = PATH=$(PATH):/opt/local/bin /opt/local/bin/pk2cmd
#
#----------------------------------------------------------------------------
# We should link against these libraries.
# If custom startup code is used crt0i.o should be removed and
# the new crt module should be added to the SRCS_ASM line.
#
#LIBS	 = crt0i.o libsdcc.lib pic$(CPU).lib
LIBS	 = libsdcc.lib pic$(CPU).lib
#
#----------------------------------------------------------------------------
# Flags sdcc:
#   -c :compile only
#   -S :stop after assembly
#   -V : show actual command line the compiler executing
#   --verbose: Shows the various actions the compiler is performing
#
# Flags for gplink:
#   -c :
#   -m :
#   -w :
#   -r :
#   -I dir:
#   -s file: the linker file
SDCC_FLAGS   = --peep-file peep.rules -S $(ARCH) -p$(CPU) --std-sdcc99 -I $(SDCCDIR)/include/pic -I $(SDCCDIR)/non-free/include/pic -c
GPASM_FLAGS  =
GPLINK_FLAGS = -c -m -w -r -I $(LIBDIR) -I $(SDCCDIR)/non-free/lib/pic -s $(GPUTILSDIR)/lkr/$(CPU).lkr
#
###############################################################################
#
# NO USER SERVICABLE SETTING BELOW THIS LINE!
#
# Changes hereafter can totally break your build process.
# Modify only, if you know what are you doing!
# If you improved this makefile, please send the updates back to the author!
#
DEPDIR       = .deps
DEPFILES     = $(DEPDIR)/$(*F)
OBJS_C       := $(SRCS_C:.c=.o)
OBJS_ASM     = $(SRCS_ASM:.asm=.o)
OBJS	 = $(OBJS_C) $(OBJS_ASM)
#
#----------------------------------------------------------------------------
# Only the generated asm files will be deleted
#
CLEAN_ASMS   = $(SRCS_C:.c=.asm)
#
#----------------------------------------------------------------------------
# Current datetime for creating archive
#
DATETIME     = $(shell date +%Y_%m_%d_%H%M%S)
#
#----------------------------------------------------------------------------
# Redefine the compiler
#
CC	   = $(SDCC)
SIMCC  = /usr/gcc-4.7.1/bin/gcc-4.7
#
#----------------------------------------------------------------------------
# For dependancy, we use makedepend a bit sligthly modified
#
MAKEDEPEND   = touch $(DEPFILES).d && /opt/local/bin/makedepend -I$(INCLUDEDIR) -Dpic$(CPU) -f $(DEPFILES).d $<
#
##############################################################################
# Main target
#
all: $(PRJ).hex
Debug: clean all
Release: clean all install
test:
	$(SIMCC) -std=gnu99 -I/usr/local/share/sdcc/non-free/include/pic/ -o watchtest sim.c
#
##############################################################################
# Install to device
#
install: $(PRJ).hex
	$(PK2CMD) -X -PPIC$(CPU) -JN -F$(PRJ).HEX -M
##############################################################################
# Linking the modules alltogether
#
$(PRJ).hex: $(OBJS)
	$(GPLINK) $(GPLINK_FLAGS) -o $(PRJ).hex $(OBJS) $(LIBS)
	$(GPDASM) -p$(CPU) $(PRJ).hex > $(PRJ).dasm
	@echo "*** Linking finished."
#
##############################################################################
# Compiling and assembling the modules, with dependencies to its include files
#
# fixme: use only pipe for creating dependancy files
# compile through asm
#
%.o: %.c peep.rules %.h
	@mkdir -p $(DEPDIR)
	@$(MAKEDEPEND); \
	cp $(DEPFILES).d $(DEPFILES).dep; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	    -e '/^$$/ d' -e 's/$$/ :/' < $(DEPFILES).d >> $(DEPFILES).dep; \
	rm -f $(DEPFILES).d $(DEPFILES).d.bak
	$(CC) $(SDCC_FLAGS) $<
	$(GPASM) $(GPASM_FLAGS) -c $*.asm
##############################################################################
# compiling standalone asm files into object file if needed
#
%.o: %.asm
	$(GPASM) $(GPASM_FLAGS) -c $<
#----------------------------------------------------------------------------
# Include generated dependancy to depend on.
#
-include $(SRCS:%.c=$(DEPDIR)/%.dep)
#
#----------------------------------------------------------------------------
# Cleaning the folder, deleting all the files that can be regenerated
#
clean:
	-rm -f *.o $(CLEAN_ASMS) *.lst *.p *.d *.cod *.hex *.c~ *.asm~ *.map \
	*.cof *.dasm *.dump* $(DEPFILES)*
	-rmdir $(DEPDIR)
	@echo "*** Project directory cleaned."
#
#----------------------------------------------------------------------------
# Creating a snapshot of the current state of the project,in the upper folder.
# Can be useful for archiving earlier versions of the project.
#
dist:
	@pwd=$$(pwd); cd ..; tar cjf $$pwd-$(DATETIME).tar.bz2 $$(basename $$pwd);\
	echo "*** Dist created: $$pwd-$(DATETIME).tar.bz2"
#
.PHONY: all clean dist
#
# end of makefile 
###############################################################################