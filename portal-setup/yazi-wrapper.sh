#!/usr/bin/env bash
# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.

set -e

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

# Yazi arguments
yazi_args=()

if [ "$save" = "1" ]; then
    yazi_args=("--chooser-file=$out" "$path")
elif [ "$directory" = "1" ]; then
    yazi_args=("--chooser-file=$out" "--cwd-file=${out}.1" "$path")
elif [ "$multiple" = "1" ]; then
    yazi_args=("--chooser-file=$out" "$path")
else
    yazi_args=("--chooser-file=$out" "$path")
fi

# Create a temporary script to run in kitty
tmpscript=$(mktemp)
cat > "$tmpscript" << SCRIPT
#!/usr/bin/bash
# Source bashrc to get zoxide and other shell integrations
source ~/.bashrc 2>/dev/null || true
# Run yazi
exec /usr/bin/yazi $(printf '%q ' "${yazi_args[@]}")
SCRIPT
chmod +x "$tmpscript"

# Launch kitty with the script
/usr/bin/kitty --class termfilechooser --title "File Chooser" "$tmpscript"

# Cleanup
rm -f "$tmpscript"

# Handle directory selection
if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "${out}.1" ]; then
        cat "${out}.1" > "$out"
        rm "${out}.1"
    else
        rm -f "${out}.1"
    fi
fi
