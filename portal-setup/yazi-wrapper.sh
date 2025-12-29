#!/usr/bin/env bash
# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
#
# For more information about input/output arguments read `xdg-desktop-portal-termfilechooser(5)`

# Debug logging
exec 2>> /tmp/yazi-wrapper-debug.log
echo "=== $(date) ===" >> /tmp/yazi-wrapper-debug.log
echo "Args: $@" >> /tmp/yazi-wrapper-debug.log
echo "TERMCMD: $TERMCMD" >> /tmp/yazi-wrapper-debug.log
echo "PATH: $PATH" >> /tmp/yazi-wrapper-debug.log

set -e

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

# Yazi arguments
yazi_args=()

if [ "$save" = "1" ]; then
    # save a file
    yazi_args=("--chooser-file=$out" "$path")
elif [ "$directory" = "1" ]; then
    # upload files from a directory
    yazi_args=("--chooser-file=$out" "--cwd-file=${out}.1" "$path")
elif [ "$multiple" = "1" ]; then
    # upload multiple files
    yazi_args=("--chooser-file=$out" "$path")
else
    # upload only 1 file
    yazi_args=("--chooser-file=$out" "$path")
fi

# Use TERMCMD from environment or default to kitty
echo "About to run: kitty with args: ${yazi_args[@]}" >> /tmp/yazi-wrapper-debug.log
/usr/bin/kitty --class termfilechooser --title "File Chooser" /usr/bin/yazi "${yazi_args[@]}"
exit_code=$?
echo "Kitty exited with code: $exit_code" >> /tmp/yazi-wrapper-debug.log

# Handle directory selection
if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "${out}.1" ]; then
        cat "${out}.1" > "$out"
        rm "${out}.1"
    else
        rm -f "${out}.1"
    fi
fi
