export SCRIPT_BINDDIR=/root/live

. bin/functions.sh
. config/rootfs.vars

updated_rootfs () {
    touch $STAMPDIR/rootfs.stamp
}

exit_if_stamped () {
    [ -f $STAMPDIR/`basename "$1"`.stamp ] && exit 0
}

make_stamp () {
    touch $STAMPDIR/`basename "$1"`.stamp
}

refresh_or_install_file () {
    # $1 is absolute file path
    # $2 is output comment
    # $3 is owner, default root
    # $4 is group, default root
    # $5 is mode, default 644

    if [ ! -f "$1" ] || [ "$CUSTOMDIR/$1" -nt "$1" ] ; then
        printinfo "$2"
        mkdir_or_fail $(dirname $1)
        install \
            -o "${3:-root}" \
            -g "${4:-root}" \
            -m "${5:-0644}" \
            "$CUSTOMDIR/$1" \
            "$(dirname $1)" || die "Unable to install/update $1 !"

        updated_rootfs
    fi
}

refresh_or_install_files () {
    # $1 is absolute dir path
    # $2 is output comment
    # $3 is owner, default root
    # $4 is group, default root
    # $5 is mode, default 644
    local msgprinted
    msgprinted=no

    for file in $CUSTOMDIR/$1/*; do
        local base dest
        base=$(basename "$file")
        dest="$1/$base"

        if [ ! -f "$dest" ] || [ "$file" -nt "$dest" ] ; then
            if [ "$msgprinted" = "no" ] ; then
                printinfo $2
                msgprinted=yes
            fi
            mkdir_or_fail "$1"
            install \
                -o "${3:-root}" \
                -g "${4:-root}" \
                -m "${5:-0644}" \
                "$file" \
                "$1" || die "Unable to install/update $file !"

            updated_rootfs
        fi
    done
}

refresh_or_install_file_as () {
    # $1 is the source filename only
    # $2 is the absolute file path of final file name
    # $3 is output comment
    # $4 is owner, default root
    # $5 is group, default root
    # $6 is mode, default 644

    srcpath="$CUSTOMDIR/$(dirname $2)/$1"

    if [ ! -f "$2" ] || [ "$srcpath" -nt "$2" ] ; then
        printinfo $3
        mkdir_or_fail $(dirname $2)
        install -T \
            -o "${4:-root}" \
            -g "${5:-root}" \
            -m "${6:-0644}" \
            "$srcpath" \
            "$2" || die "Unable to install/update $2 !"

        updated_rootfs
    fi
}

prevent_services_running () {
    # Temporarily install policy file to prevent services from running
    refresh_or_install_file \
        /usr/sbin/policy-rc.d \
        "Installing temporary policy file to prevent services running..." \
        root root 755
}

allow_services_to_run () {
    rm -f /usr/sbin/policy-rc.d
}
