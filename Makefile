#
# Builds the control image which is read-only mounted
# in the aboriginal qemu environment and run there.
#
MKSQUASHFS          := $(shell which mksquashfs)
CONTROL_IMAGE_FILES := $(shell find $(CURDIR)/control)

ifndef MKSQUASHFS
    $(error "Unable to locate mksquashfs")
endif

all: control.sqf

clean:
	rm -f control.sqf

# Rebuild the control image if any files in the control
# image directory have changed.
control.sqf: $(CONTROL_IMAGE_FILES)
	$(MKSQUASHFS) $(CURDIR)/control $@ -noappend -all-root
