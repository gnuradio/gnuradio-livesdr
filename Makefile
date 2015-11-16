-include ./.config
include config/config.vars

# Get rid of Kconfig quoted strings
UBUNTU_ISO_FILE_UNQ=$(shell echo $(UBUNTU_ISO_FILE))

all: config-test binary

deps:
	@bin/install-deps

# Test required binaries are installed and executable
config-test:
	@bin/config-test

##################
# Initialization #
##################

# Configuration
.PHONY: config

config:
	kconfig-mconf config/Kconfig

# Download stock Ubuntu ISO image if needed
${UBUNTU_ISO_FILE_UNQ}:
	@echo ${UBUNTU_ISO_FILE_UNQ}
	@bin/get-stock-iso

stock: ${UBUNTU_ISO_FILE_UNQ}

# Mount stock Ubuntu ISO image and overlay
${ISOMNT_RO_SENTINEL}:
	@bin/mount-iso

mount-iso: stock ${ISOMNT_RO_SENTINEL}

# Mount squashfs-based root filesystem and overlay
${ROOTFSMNT_RO_SENTINEL}:
	@bin/mount-rootfs

mount-rootfs: mount-iso ${ROOTFSMNT_RO_SENTINEL}

${CHROOT_MNT_SENTINEL}:
	@bin/mount-chroot

# Mount chroot system mounts
mount-chroot: mount-rootfs ${CHROOT_MNT_SENTINEL}

# Mount everything
mount: mount-chroot

#################
# Customization #
#################

# Interactive chroot for misc. tasks
chroot: mount
	@bin/run-in-rootfs

# Run prepare job queue
prep: mount
	@bin/prep.d-run-parts

# Run rootfs job queue
rootfs:
	@bin/run-in-rootfs /root/live/bin/rootfs.d-run-parts

# Target for entire custom content generation
content: prep rootfs

###############
# Remastering #
###############

isofs: unmount-chroot
	@bin/isofs.d-run-parts

# Build a new master image based on current overlays
binary: content isofs unmount

###########
# Cleanup #
###########

# Misc. cleanup of repository
clean:
	@find bin/ -type f -name *~ -delete
	@find config/ -type f -name *~ -delete

dist-clean: unmount clean
	@rm -f config/install-pkgs.d/linux-tools
	@rm -f ${ISO_DIR}/${REMASTER_NAME}
	@rm -f ${ISO_DIR}/${UBUNTU_ISO_BASE}.tmp
	@rm -f ${ISO_DIR}/SHA256SUM*
	@rm -f ${ISO_DIR}/md5sums
	@rm -f ${ISO_DIR}/sha256sums
	@rm -f stamps/*.stamp
	@sudo rm -rf ${RWMNT}/iso
	@sudo rm -rf ${RWMNT}/rootfs

really-clean: dist-clean
	@sudo rm -rf ccache/*

# Unmount chroot jail mounts
unmount-chroot:
	@bin/unmount-chroot

# Unmount root filesystem image
unmount-rootfs: unmount-chroot
	@bin/unmount-rootfs

# Unmount Ubuntu ISO image
unmount-iso: unmount-rootfs
	@bin/unmount-iso

# Unmount everything
unmount: unmount-iso

###########
# Testing #
###########

kvm:
	@bin/run-in-kvm
