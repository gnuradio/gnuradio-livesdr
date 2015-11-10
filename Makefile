-include ./.config
include config/config-vars

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
	@bin/run-in-chroot

# Run pre-chroot job queue
stamps/pre-chroot.stamp:
	@bin/pre-chroot-run-parts
	@touch stamps/pre-chroot.stamp

pre-chroot: mount stamps/pre-chroot.stamp

stamps/chroot-ops.stamp:
	@bin/run-in-chroot /root/live/bin/chroot-run-parts
	@touch stamps/chroot-ops.stamp

chroot-ops: mount stamps/chroot-ops.stamp

${ISO_INITRD}: stamps/chroot-ops.stamp $(wildcard ${CHROOT_INITRD})
	@bin/copy-initrd

initrd: mount ${ISO_INITRD}

# Target for entire custom content generation
content: pre-chroot chroot-ops initrd

###############
# Remastering #
###############

stamps/remaster.stamp:
	@bin/remaster-run-parts
	@touch stamps/remaster.stamp

remaster: unmount-chroot stamps/remaster.stamp

# Make updated squashfs file from overlay
rootfs: unmount-chroot
	@bin/make-rootfs

luks: rootfs
	@bin/make-luks

# Make remastered image from overlay
master: mount-iso
	@bin/make-master

# Build a new master image based on current overlays
binary: content remaster unmount

###########
# Cleanup #
###########

# Misc. cleanup of repository
clean:
	@find bin/ -type f -name *~ -delete
	@find config/ -type f -name *~ -delete

dist-clean: unmount clean
	@rm -f ${ISO_DIR}/${REMASTER_NAME}
	@rm -f ${ISO_DIR}/${UBUNTU_ISO_BASE}.tmp
	@rm -f ${ISO_DIR}/SHA256SUM*
	@rm -f ${ISO_DIR}/*.torrent
	@rm -f ${ISO_DIR}/md5sums
	@rm -f ${ISO_DIR}/sha256sums
	@rm -f stamps/*.stamp
	@sudo rm -rf ${RWMNT}/iso
	@sudo rm -rf ${RWMNT}/rootfs
	@sudo rm -rf tmp/*

really-clean: dist-clean
	@sudo rm -rf ccache/*
	@sudo rm -rf gitcache/*

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
