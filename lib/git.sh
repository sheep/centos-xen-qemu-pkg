function git-branch-exists
{
    $arg_parse

    $requireargs branch
    
    git rev-parse --verify $branch >& /dev/null
}

function git-get-branch
{
    $arg_parse
    
    local _branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)

    report-result "$_branch"
}

# return 1 if git is older than the version specified by git_ver
function git-check-version() {
    $arg_parse
    $requireargs git_ver

    local v=$(git --version)
    v=${v#git version }

    # Compare digit of a version one-by-one
    while [ -n "$git_ver" ]; do
        [ -z "$v" ] && return 1
        [ ${v%%.*} -lt ${git_ver%%.*} ] && return 1
        [ ${v%%.*} -gt ${git_ver%%.*} ] && return 0
        if [ "$v" != "${v#*.}" ]; then
            v=${v#*.}
        else
            v=""
        fi
        if [ "$git_ver" != "${git_ver#*.}" ]; then
            git_ver=${git_ver#*.}
        else
            git_ver=""
        fi
    done
}
