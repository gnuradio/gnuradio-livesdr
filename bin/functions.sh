test_iso_ro_mounted () {
    [ -f $ISOMNT_RO_SENTINEL ]
}

test_iso_rw_mounted () {
    [ -f $ISOMNT_RW_SENTINEL ]
}

require_iso_ro_mounted () {
    test_iso_ro_mounted || {
        echo Ubuntu ISO read-only mount not found!
        exit 1
    }
}

require_iso_rw_mounted () {
    test_iso_rw_mounted || {
        echo Ubuntu ISO read-write overlay not found!
        exit 1
        }
}

test_rootfs_ro_mounted () {
    [ -f $ROOTFSMNT_RO_SENTINEL ]
}

test_rootfs_rw_mounted () {
    [ -f $ROOTFSMNT_RW_SENTINEL ]
}

require_rootfs_rw_mounted () {
    test_rootfs_rw_mounted || {
        echo Ubuntu ISO read-write overlay mount not found!
        exit 1
    }
}

test_chroot_mounted () {
    [ -f $CHROOT_MNT_SENTINEL ]
}

require_chroot_mounted () {
    test_chroot_mounted || {
        echo System mounts in chroot jail not found!
        exit 1
    }
}

require_chroot_unmounted () {
    test_chroot_mounted && {
        echo System mounts in chroot still exist!
        exit 1
    }
}

mkdir_or_fail () {
    mkdir -p $1 || {
        shift
        echo $@
        exit 1
    }
}
