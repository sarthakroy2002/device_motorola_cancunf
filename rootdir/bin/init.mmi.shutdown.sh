#!/vendor/bin/sh

PATH=/sbin:/vendor/sbin:/vendor/bin:/vendor/xbin
export PATH

scriptname=${0##*/}

debug()
{
	echo "$*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

get_history_value()
{
	local __result=$1
	local history_count=0
	local value=""
	local IFS=$2

	shift 2
	for arg in ${@}; do
		value=$value"$IFS$arg"
		history_count=$(($history_count + 1))
		if [ $history_count -eq 3 ]; then
			break
		fi
	done
	eval $__result="$value"
	debug "value:$value history_count:$history_count"
}

set_reboot_bootseq_history()
{
	BOOTSEQ_HISTORY_PROP=persist.vendor.reboot.bootseq.history
	#get current boot sequence
	if [ ! -f /proc/bootinfo ]; then
		notice "Error:/proc/bootinfo is not ready"
		return
	fi
	boot_seq_line=`grep BOOT_SEQ /proc/bootinfo | sed 's/ //g'`
	boot_seq=${boot_seq_line##*:}
	notice "BOOT_SEQ is $boot_seq"
	shutdown_time=`date +%s`

	#get previous value of bootseq history
	bootseq_history=`getprop $BOOTSEQ_HISTORY_PROP`
	debug "booseq_history is $bootseq_history"
	get_history_value valid_history_value , $bootseq_history
	setprop $BOOTSEQ_HISTORY_PROP "$boot_seq.$shutdown_time$valid_history_value"
	new_bootseq_history=`getprop $BOOTSEQ_HISTORY_PROP`
	notice "set $BOOTSEQ_HISTORY_PROP $new_bootseq_history"

	#update reboot command history
	REBOOTCMD_HISTORY_PROP=persist.vendor.reboot.command.history

	reboot_cmds=`getprop log.powerctrl.reboot.command`
	notice "reboot_cmds is [$reboot_cmds]"

	#get previous value of command history
	rebootcmd_history=`getprop $REBOOTCMD_HISTORY_PROP`
	debug "reboot command history is $rebootcmd_history"
	get_history_value valid_cmd_history_value - $rebootcmd_history

	setprop $REBOOTCMD_HISTORY_PROP "$boot_seq.$reboot_cmds${valid_cmd_history_value}"
	new_bootseq_history=`getprop $REBOOTCMD_HISTORY_PROP`
	notice "set $REBOOTCMD_HISTORY_PROP $new_bootseq_history"
}

set_reboot_bootseq_history
