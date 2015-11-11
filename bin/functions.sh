. ./.config

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
