#!/vendor/bin/sh

# Load all kernel modules listed in modules.load
modprobe -a -d /vendor/lib/modules $(cat /vendor/lib/modules/modules.load)

# Signal that all modules are loaded
setprop vendor.all.modules.ready 1
