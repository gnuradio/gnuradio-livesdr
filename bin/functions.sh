. ./.config

printmsg=$SCRIPT_BINDDIR/bin/print-msg

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

exit_if_not_configured () {
    local opt
    set +u
    eval opt=\$$1
    set -u

    [ "$opt" = "y" ] || exit 0
}
