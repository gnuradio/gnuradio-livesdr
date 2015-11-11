. ./.config
. config/config-vars

printmsg=bin/print-msg

printinfo () {
    $printmsg info "$@"
}

printerror () {
    $printmsg error "$@"
}

printwarn () {
    $printmsg warn "$@"
}

printsuccess () {
    $printmsg success "$@"
}

die () {
    printerror $@
    exit 1
}

mkdir_or_fail () {
    mkdir -p $1 || die "Failed to create dir: " $1
}

test_iso_ro_mounted () {
    [ -f $ISOMNT_RO_SENTINEL ]
}

test_iso_rw_mounted () {
    [ -f $ISOMNT_RW_SENTINEL ]
}

require_iso_ro_mounted () {
    test_iso_ro_mounted || die Ubuntu ISO read-only mount not found!
}

require_iso_rw_mounted () {
    test_iso_rw_mounted || die Ubuntu ISO read-write overlay not found!
}

test_rootfs_ro_mounted () {
    [ -f $ROOTFSMNT_RO_SENTINEL ]
}

test_rootfs_rw_mounted () {
    [ -f $ROOTFSMNT_RW_SENTINEL ]
}

require_rootfs_rw_mounted () {
    test_rootfs_rw_mounted || die Ubuntu ISO read-write overlay mount not found!
}

test_chroot_mounted () {
    [ -f $CHROOT_MNT_SENTINEL ]
}

require_chroot_mounted () {
    test_chroot_mounted || die System mounts in chroot jail not found!
}

require_chroot_unmounted () {
    test_chroot_mounted && die System mounts in chroot still exist!
}
