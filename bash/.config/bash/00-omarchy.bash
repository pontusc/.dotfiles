# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# An existing gd alias breaks parsing of omarchy's gd() on re-source
unalias gd 2>/dev/null
source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"
