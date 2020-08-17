#!/usr/bin/env bash
# like https://github.com/syntaqx/git-hooks/blob/master/hooks/shellcheck.sh
# but with docker

set -eu

# https://www.shellcheck.net/

# Filter out non-shell files, if we can.
if command -v file >/dev/null 2>&1; then
    new_args="$(
        for arg in "$@"; do
            if [ -f "${arg}" ]; then
                case "$(file --brief --mime-type "${arg}")" in
                    *shellscript) printf "%s\n" "${arg}" ;;
                esac
            else
                # Pass non-file args through unchanged
                printf "%s\n" "${arg}"
                continue
            fi
        done
    )"

    _NL='
'
    # Mute shellcheck complaint about missing quotes.
    # shellcheck disable=SC2086
    IFS="$_NL" set -- ${new_args}

    unset new_args arg _NL
fi

version="0.7.1"
if command -v shellcheck >/dev/null 2>/dev/null && [ "$(shellcheck --version | grep '^version:' | awk '{print $2}')" = "$version" ]; then
    shellcheck "$@"
else
    docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:v$version "$@"
fi
