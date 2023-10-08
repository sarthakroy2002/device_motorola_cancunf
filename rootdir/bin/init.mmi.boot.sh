#!/vendor/bin/sh

PATH=/sbin:/vendor/sbin:/vendor/bin:/vendor/xbin
export PATH

scriptname=${0##*/}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

# reload UTAGS
utag_status=$(cat /proc/config/reload)
if [ "$utag_status" == "2" ]; then
	notice "Utags are not ready, reloading"
	echo 1 > /proc/config/reload
	utag_status=$(cat /proc/config/reload)
	[ "$utag_status" != "0" ] && notice "Utags failed to reload"
fi

# Export these for factory validation purposes
iccid=$(cat /proc/config/iccid/ascii 2>/dev/null)
if [ ! -z "$iccid" ]; then
	setprop ro.vendor.mot.iccid $iccid
fi
unset iccid

# Get FTI data and catch old units with incorrect/missing UTAG_FTI
pds_fti=/mnt/vendor/persist/factory/fti
if [ -r $pds_fti ]; then
	set -A fti $(od -A n -t x1 $pds_fti 2>/dev/null | tr '[A-F]' '[a-f]')
else
	notice "Can not read FTI data in persist"
fi

# If UTAG_FTI is readable, compare checksums
# and if they mismatch, assume PDS is valid and overwrite UTAG
utag_fti=/proc/config/fti
if [ -r $utag_fti/ascii ]; then
	set -A fti_utag $(cat ${utag_fti}/raw | sed 's/../& /g' | tr '[A-F]' '[a-f]')
	# Byte 128 is total cksum, if nothing there, PDS data is invalid/missing
	if [ ! -z "${fti[127]}" ]; then
		# Make sure fti in UTAG is the same as in persist. Checksum comparison
		if [ "${fti[126]}" != "${fti_utag[126]}" -o "${fti[127]}" != "${fti_utag[127]}" ]; then
			notice "Copying FTI data from persist"
			cat $pds_fti > ${utag_fti}/raw
		fi
	else
		# If PDS data is invalid, take UTAG and hope it is correct
		notice "Will use FTI from UTAG"
		set -A fti $(od -A n -t x1 ${utag_fti}/ascii 2>/dev/null)
	fi
else
	notice "Missing FTI UTAG; copying from persist"
	echo fti > /proc/config/all/new
	cat $pds_fti > ${utag_fti}/raw
fi

# Read HW version from FTI data
hw_v1="\x${fti[35]}"
hw_v2="\x${fti[36]}"
hw_v3="\x${fti[37]}"
if [ "$hw_v3" == "\x30" ]; then
	hw_v3=""
fi
hw_v4="\x${fti[38]}"
if [ "$hw_v4" == "\x30" ]; then
	hw_v4=""
fi
setprop ro.vendor.hw.boardversion $(printf "$hw_v1$hw_v2$hw_v3$hw_v4")

# Now we have set fti var either from PDS or UTAG
# Get Last Test Station stamp from FTI
# and convert to user-friendly date, US format
# Real offsets for year/month/day are 63/64/65
# If the month/date look reasonable, data is probably OK.
mdate="Unknown"
y=0x${fti[63]}
m=0x${fti[64]}
d=0x${fti[65]}
let year=$y month=$m day=$d
# Invalid data will often have bogus month/date values
if [ $month -le 12 -a $day -le 31 -a $year -ge 12 ]; then
	mdate=$month/$day/20$year
else
	notice "Corrupt FTI data"
fi
setprop ro.vendor.manufacturedate $mdate
unset fti y m d year month day utag_fti pds_fti fti_utag mdate

t=$(getprop ro.build.tags)
if [[ "$t" != *release* ]]; then
	for p in $(cat /proc/cmdline); do
		if [ ${p%%:*} = "@" ]; then
			v=${p#@:}; a=${v%=*}; b=${v#*=}
			${a%%:*} ${a##*:} $b
	fi
	done
fi
unset p v a b t

# Cleanup stale/incorrect programmed model value
# Real values will never contain substrings matching "internal" device name
product=$(getprop ro.vendor.hw.device)
model=$(cat /proc/config/model/ascii 2>/dev/null)
if [ $? -eq 0 ]; then
	if [ "${model#*_}" == "$product" -o "${model%_*}" == "$product" ]; then
		notice "Clearing stale model value"
		echo "" > /proc/config/model/raw
	fi
fi
unset model product



# Export the RKP csr state which should be done in factory
rkp_complete_file="/mnt/vendor/persist/rkp_complete"
rkp_csr_state="not uploaded"
if [ -f "$rkp_complete_file" ]; then
	setprop ro.vendor.mot.hw.rkp_csr_uploaded 1
	rkp_csr_state="already uploaded"
else
	setprop ro.vendor.mot.hw.rkp_csr_uploaded 0
fi
notice "RKP CSR file on device is: $rkp_csr_state"
unset $rkp_complete_file
unset $rkp_csr_state

get_history_value()
{
	local __result=$1
	local history_count=0
	local value=""
	local IFS=','

	shift 1
	for arg in ${@}; do
		value=$value",$arg"
		history_count=$(($history_count + 1))
		if [ $history_count -eq 3 ]; then
			break
		fi
	done
	eval $__result="$value"
	debug "value:$value history_count:$history_count"
}

set_boot_bootseq_history()
{
	#get current boot sequence
	if [ ! -f /proc/bootinfo ]; then
		notice "Error:/proc/bootinfo is not ready"
		return
	fi
	boot_seq_line=`grep BOOT_SEQ /proc/bootinfo | sed 's/ //g'`
	boot_seq=${boot_seq_line##*:}
	notice "BOOT_SEQ is $boot_seq"
	setprop ro.vendor.boot_seq $boot_seq
	boot_time=`date +%s`

	#get previous value of bootseq history
	bootseq_history=`getprop persist.vendor.boot.bootseq.history`
	notice "booseq_history is $bootseq_history"
	get_history_value valid_history_value $bootseq_history
	setprop persist.vendor.boot.bootseq.history "$boot_seq.$boot_time$valid_history_value"
	new_bootseq_history=`getprop persist.vendor.boot.bootseq.history`
	notice "set persist.vendor.boot.bootseq.history $new_bootseq_history"
}

set_boot_bootseq_history
