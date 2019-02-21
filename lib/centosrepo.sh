function checkout-basebranch()
{
    $arg_parse

    $requireargs version

    local branch=base/$version
    if ! git-branch-exists ; then
	local tag=$version
	info "Creating base branch $branch for tag $tag"
	echo git checkout -b $branch $tag 
	git checkout -b $branch $tag || fail "Creating branch"
    else
	info "Checking out base branch $branch"
	git checkout $branch || fail "Checking out branch"
    fi
    
}

help-add "make-tree: Make UPSTREAM/qemu-xen.git and create branches based on SOURCES/xen-queue.am"
function make-tree()
{
    . $TOPDIR/sources.cfg

    $arg_parse
    
    $requireargs QEMU_VERSION

    if [[ ! -d UPSTREAM ]] ; then
	info "Creating UPSTREAM/ to store upstream repositories..."
	mkdir UPSTREAM
    fi

    cd UPSTREAM

    if [[ ! -e qemu-xen.git ]] ; then
	$requireargs QEMU_URL
	info "Cloning qemu-xen.git..."
	git clone $QEMU_URL qemu-xen.git || fail "Cloning qemu-xen.git"
	info "done."
	
	cd qemu-xen.git
    else
	cd qemu-xen.git
	info "Fetching updates to qemu-xen.git..."
	git fetch
    fi

    checkout-basebranch version=$QEMU_VERSION
}

# Parse the special status string from gpg, depending on the key size
# see gpg --status-fd
function check-gpg-status() {
    $arg_parse
    $requireargs key

    local line fields
    local reason
    while read line; do
        if ! [[ "$line" =~ ^\[GNUPG:\]\  ]]; then
            continue
        fi
        IFS=' '
        fields=($line)
        unset IFS
        case "${fields[1]}" in
            NO_PUBKEY)
                reason="Public key missing"
                break
                ;;
            VALIDSIG)
                if [[ "${fields[2]}" != "$key" ]]; then
                    reason="Wrong key fingerprint"
                    break
                fi
                if [[ "${fields[10]}" != '00' ]]; then
                    reason="Wrong signature type"
                    break
                fi
                return 0
                ;;
        esac
    done
    fail "signature check failed ${what:+for }$what${reason:+: }$reason"
}

help-add "get-sources: Download and/or create tarballs for SOURCES based on sources.cfg"
function get-sources() {
    . $TOPDIR/sources.cfg

    $arg_parse
    $requireargs QEMU_VERSION QEMU_URL

    local tag=$QEMU_VERSION
    local spec_file="$TOPDIR/SPECS/qemu-xen.spec"

    # local nb_commit=$(perl -ne 'if(/^%define nb_commit ([0-9]+)$/) { print "$1\n";}' "$spec_file")
    # local cset_abbrev=${XEN_CSET:0:10}
    local nb_commit=0

    local qemu_file="$tag.tar.gz"

    if [[ ! -e "$TOPDIR/SOURCES/$qemu_file" ]] ; then
        pushd "$TOPDIR"

        make-tree

        cd "$TOPDIR/UPSTREAM/qemu-xen.git"

        # Have `git describe` always print the same string for a given commit
        git config core.abbrev 10

        # Extract the tag object and its signature in order to use gpgv and the
        # keyring included in the repo for verification
        local tag_obj=$(git cat-file tag "$tag")
        local tag_plaintext tag_asc do_pgp=false
        while read line; do
            if [[ "$line" =~ ^-----BEGIN\ PGP\  ]]; then
                do_pgp=true
            fi
            if $do_pgp; then
                tag_asc+="$line"$'\n'
            else
                tag_plaintext+="$line"$'\n'
            fi
        done <<<"$tag_obj"

        local gpg_status=$(gpgv --status-fd 1 --keyring "$TOPDIR/SOURCES/trustedkeys.gpg" <(echo -n "$tag_asc") <(echo -n "$tag_plaintext"))
        local what="qemu-xen git tag $tag"
        check-gpg-status key=${QEMU_KEYS[0]} <<<"$gpg_status"

        # By using merge --ff-only after checking out the tag, we make sure we
        # have at least the release tag of $XEN_VERSION in the history of
        # commit id $XEN_CSET.
        git checkout --detach $tag || fail "checkout"
        # git merge --ff-only "$QEMU_CSET" || fail "fast-forward merge"

        mkdir -p "$TOPDIR/SOURCES"
        scripts/archive-source.sh "$TOPDIR/SOURCES/$qemu_file" \
            || fail "archive-source failed"

        popd
    fi
}
