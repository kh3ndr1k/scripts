#!/usr/bin/bash
# -------------------------------------------------
# ANSI 256 Color Palette
# Auto-detect shell or force via argument
# Usage:
#  ./ansi-palette.sh        auto-detect
#  ./ansi-palette.sh bash   force bash palette
#  ./ansi-palette.sh zsh    force zsh palette
# -------------------------------------------------

MODE="$1"

detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    else
        echo "bash"
    fi
}

palette_bash() {
    for i in {0..255}; do
        printf " \e[48;5;%sm  \e[0m\e[38;5;%sm:%03d\e[0m  " "$i" "$i" "$i"
        (( (i + 1) % 10 == 0 )) && echo
    done
    echo
}

palette_zsh() {
    zsh -c '
        for i in {0..255}; do
            print -Pn " %K{$i}  %k:%F{$i}${(l:3::0:)i}%f  "
            (( (i + 1) % 10 == 0 )) && print
        done
        print
    '
}


if [[ -z "$MODE" ]]; then
    MODE="$(detect_shell)"
fi

case "${MODE,,}" in
    bash)
        palette_bash
        ;;
    zsh)
        command -v zsh >/dev/null || {
            echo "zsh not found"
            exit 1
        }
        palette_zsh
        ;;
    *)
        echo "Usage: ${0##*/} [bash|zsh]"
        exit 1
        ;;
esac

