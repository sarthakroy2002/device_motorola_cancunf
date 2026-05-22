#!/vendor/bin/sh

fps_id=$(cat /mnt/vendor/persist/fps/vendor_id)
fps_id=${fps_id:-none}

function load_module() {
	echo "Fingerprint ${1}: Load_Module" > /proc/bootprof
	modprobe -a -d /vendor/lib/modules "${1}"
}

function start_hal() {
	if [ "${fps_id}" == "chipone" ]; then
		load_module fpsensor_mtk_spi.ko
		sleep 1
		start chipone_fp_hal
		sleep 1
	elif [ "${fps_id}" == "goodix" ]; then
		load_module goodix_fps_tee.ko
		sleep 1
		start goodix_hal
		sleep 1
	elif [ "${fps_id}" == "none" ]; then
		/system/bin/log -t fingerprint "No valid fingerprint detected, gracefully exiting"
	fi
}

start_hal
