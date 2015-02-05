mkdir_or_fail () {
    mkdir -p $1 || {
        shift
        $PRINTERROR $@
        exit 1
    }
}
