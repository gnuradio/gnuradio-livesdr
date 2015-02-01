include config/config-vars

all: config-test binary

deps:
	@bin/install-deps

# Test required binaries are installed and executable
config-test:
	@bin/config-test

##################
# Initialization #
##################

# Download stock Ubuntu ISO image if needed
${UBUNTU_ISO_FILE}:
	@bin/get-stock-iso

stock: ${UBUNTU_ISO_FILE}

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

# Install custom files
stamps/install-custom.stamp:
	@bin/install-custom
	@touch stamps/install-custom.stamp

custom: mount stamps/install-custom.stamp

# Remove, update, and install custom packages
stamps/packages.stamp:
	@bin/run-in-chroot /root/live/bin/chroot-uninstall-pkgs
ifeq (${UPGRADE_PKGS},YES)
	@bin/run-in-chroot /root/live/bin/chroot-upgrade-pkgs
endif
	@bin/run-in-chroot /root/live/bin/chroot-install-pkgs
	@touch stamps/packages.stamp

packages: mount stamps/packages.stamp

# Create new initrd from rootfs contents (and with cryptsetup)
${CHROOT_INITRD}:
	@bin/run-in-chroot /root/live/bin/chroot-initramfs

${ISO_INITRD}: ${CHROOT_INITRD}
	@bin/copy-initrd

initrd: mount ${ISO_INITRD}

# Target for entire custom content generation
content: custom packages initrd

###############
# Remastering #
###############

# Remove files from root filesystem not destined for image
clean-rootfs: mount-rootfs
	@bin/clean-rootfs

# Make updated squashfs file from overlay
rootfs: clean-rootfs unmount-chroot
	@bin/make-rootfs

luks: rootfs
	@bin/make-luks

# Make remastered image from overlay
master: mount-iso
	@bin/make-master

# Build a new master image based on current overlays
ifeq (${ENCRYPT},YES)
binary: content luks master unmount
else
binary: content rootfs master unmount
endif

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
	@rm -f stamps/*.stamp
	@sudo rm -rf ${RWMNT}/iso
	@sudo rm -rf ${RWMNT}/rootfs

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
