#! /bin/bash
#
# sysinfo.sh - Graphical system information viewer
#
# Based on Victor Ananjevsky’s System informations
#   https://github.com/v1cont/yad/wiki/System-informations/
#
# Modifications in this file are © 2026 Bodhi Linux
#
# Licensed under GPLv3
#
# -----------------------------------------------------------------------------
# Description:
#   This script provides a tabbed graphical interface (using YAD) to display
#   various system and hardware information on Linux systems. It aggregates data
#   from standard command-line tools and presents it in an easy-to-read format.
#
#   Tabs include:
#     - CPU information        (lscpu)
#     - Memory usage           (/proc/meminfo)
#     - Disk usage             (df)
#     - PCI devices            (lspci)
#     - Loaded kernel modules  (/proc/modules, modinfo)
#     - Battery status         (acpi)
#
# Dependencies:
#   Required:
#     - bash
#     - yad              (GUI interface)
#     - pciutils         (provides `lspci`)
#     - acpi             (battery information)
#     - lsb-release      (OS version info)
#     - pkg-config       (used for EFL version detection)
#
#   Usually preinstalled:
#     - coreutils        (df, printf, etc.)
#     - util-linux       (lscpu)
#     - procps           (/proc access)
#     - grep, sed, awk
#
#   Optional:
#     - Moksha    (for `enlightenment_remote` version info)
#	  - inxi      (for 'copy report')
#	  - xclip     (also for 'copy report')
#
# Notes:
#   - Run `sudo sensors-detect` after installing lm-sensors for full sensor data.
#   - Some tabs (e.g., Battery) may be empty on unsupported hardware (e.g., desktops).
#   - If optional dependencies are missing, related fields will be blank or skipped.
#

KEY=$RANDOM

function show_mod_info {
TXT="\\n<span face='Monospace'>$(modinfo "$1" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</span>"
yad --title=$"Module information" --button="Close" --width=500 \
 --image="application-x-addon" --text="$TXT"
}
export -f show_mod_info

# CPU tab
lscpu | sed -r "s/:[ ]*/\n/" |\
yad --plug=$KEY --tabnum=1 --image=cpu --text=$"CPU information" \
--list --no-selection --column=$"Parameter" --column=$"Value" \
--button="Copy:bash -c 'xclip -selection clipboard < \"$CPU_INFO\"'" &

# GPU tab
(GPU=$(lspci | grep -Ei 'vga|3d|display' | head -n1 | cut -d' ' -f5-)

DRIVER=$(lspci -k | awk '
/VGA|3D|Display/ {f=1}
f && /Kernel driver in use/ {
    print $NF
    exit
}')

OPENGL=$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL renderer string/ {print $2}')

VERSION=$(glxinfo -B 2>/dev/null | awk -F': ' '/OpenGL version string/ {print $2}')

RES=$(xrandr 2>/dev/null | awk '/\*/ {print $1; exit}')

printf "%s\n%s\n" "GPU" "$GPU"
printf "%s\n%s\n" "Driver" "$DRIVER"
printf "%s\n%s\n" "Resolution" "$RES"
printf "%s\n%s\n" "Renderer" "$OPENGL"
printf "%s\n%s\n" "OpenGL" "$VERSION"
printf "%s\n%s\n" "Session" "$XDG_SESSION_TYPE"
)| \

yad --plug=$KEY --tabnum=2 --image=video-display --text=$"GPU information" \
--list --no-selection --fontname="Monospace 10" \
--column=$"Parameter":TEXT --column=$"Value":TEXT &

# Memory tab
sed -r "s/:[ ]*/\n/" /proc/meminfo |\
yad --plug=$KEY --tabnum=3 --image=memory --text=$"Memory usage information" \
--list --no-selection --column=$"Parameter" --column=$"Value" &
 
# Harddrive tab
df -T | tail -n +2 | awk '{printf "%s\n%s\n%s\n%s\n%s\n%s\n", $1,$7, $2, $3, $4, $6}' |\
yad --plug=$KEY --tabnum=4 --image=drive-harddisk --text=$"Disk space usage" \
--list --no-selection --column=$"Device" --column=$"Mountpoint" --column=$"Type" \
--column=$"Total:sz" --column=$"Free:sz" --column=$"Usage:bar" &

# PCI tab
lspci -vmm | sed 's/\&/\&amp;/g' | grep -E "^(Slot|Class|Vendor|Device|Rev):" | cut -f2 |\
yad --plug=$KEY --tabnum=5 --text=$"PCI bus devices" \
 --list --no-selection --column=$"ID" --column=$"Class" \
 --column=$"Vendor" --column=$"Device" --column=$"Rev" &

# Modules tab
awk '{printf "%s\n%s\n%s\n", $1, $3, $4}' /proc/modules | sed "s/[,-]$//" |\
yad --plug=$KEY --tabnum=6 --text=$"Loaded kernel modules" \
 --image="application-x-addon" --image-on-top \
 --list --dclick-action='bash -c "show_mod_info %s"' \
 --column=$"Name" --column=$"Used" --column=$"Depends" &
 
# Battery tab
 ( acpi -i ; acpi -a ) | sed -r "s/:[ ]*/\n/" | yad --plug=$KEY --tabnum=7 \
 --image=battery --text=$"Battery state" --list --no-selection \
 --column=$"Device" --column=$"Details" &

# Network tab
(echo "[ PCI: ]"
lspci -k | grep -A3 -Ei 'network|wireless|ethernet'
echo
echo "[ USB: ]"
lsusb | grep -Ei 'wireless|wifi|802|bluetooth'
) | \
sed 's/^/ /' | \
yad --plug=$KEY --tabnum=8 --image=network-wireless --text=$"Network information" \
--list --no-selection --fontname="Monospace 10" \
--column=$"Device" &

# Full report
REPORT=$(mktemp)

{
echo "SYSTEM:"
echo "======================================="
uname -a

echo
echo "CPU:"
echo "======================================="
inxi -C

echo
echo "GPU:"
echo "======================================="
inxi -G

echo
echo "MEMORY:"
echo "======================================="
free -h

echo
echo "STORAGE:"
echo "======================================="
df

echo
echo "NETWORK:"
echo "======================================="
inxi -N

} > "$REPORT"  
  
# main dialog
TXT=$"<b>Hardware system information</b>\\n\\n"
TXT+=$"\\tOS: $(lsb_release -ds) on $(hostname)\\n"
TXT+=$"\tEFL: $(pkg-config --modversion efl 2>/dev/null || echo 'Not installed')\\n"
command -v enlightenment_remote >/dev/null && \
  TXT+=$"\tMoskha: $(/usr/bin/enlightenment_remote -version)\n"
TXT+=$"\\tKernel: $(uname -sr)\\n\\n"

TXT+="\\t<i>$(uptime)</i>\\n\\n"

# shellcheck disable=SC2256  
yad --window-icon='dialog-information' --notebook --width=600 --height=450 \
  --title=$"System info" --text="$TXT" --button="Close" \
  --button="Copy report:bash -c 'xclip -selection clipboard < \"$REPORT\"'" \
  --key=$KEY --tab=$"CPU" --tab=$"GPU" --tab=$"Memory" --tab=$"Disks" --tab=$"PCI" \
  --tab=$"Modules" --tab=$"Battery" --tab=$"Network" --active-tab="${1:-1}"
  
