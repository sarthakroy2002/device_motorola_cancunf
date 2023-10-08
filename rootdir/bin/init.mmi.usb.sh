#!/vendor/bin/sh
# Copyright (c) 2012, Code Aurora Forum. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of Code Aurora Forum, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Allow unique persistent serial numbers for devices connected via usb
# User needs to set unique usb serial number to persist.usb.serialno and
# if persistent serial number is not set then Update USB serial number if
# passed from command line
#
dbg_on=0
debug()
{
	echo "${0##*/}: $*"
	[ $dbg_on ] && echo "${0##*/}: $*" > /dev/kmsg
}

notice()
{
	echo "${0##*/}: $*"
	echo "${0##*/}: $*" > /dev/kmsg
}

target=`getprop ro.board.platform`
usb_action=`getprop vendor.usb.mmi-usb-sh.action`
notice "mmi-usb-sh: action = \"$usb_action\""
sys_usb_config=`getprop vendor.usb.config`
bootmode=`getprop ro.bootmode`

#factory cleanup
factory_cfg=`getprop persist.vendor.usb.mot-factory.config`
if [ "$bootmode" == "normal" ]; then
    if [[ "$factory_cfg" == *adb* ]]; then
       setprop persist.vendor.usb.mot-factory.config NULL
       setprop persist.vendor.usb.mot-factory.func NULL
       setprop persist.vendor.usb.config NULL
       setprop persist.vendor.mot.usb.config NULL
       setprop vendor.usb.config none
       notice "cleanup factory flg done"
    fi
fi

set_usb_secure_mode ()
{
    if [ "$#" == "1" ]
    then
        if [ -f /sys/class/android_usb/android0/secure ]
        then
            echo "$1" > /sys/class/android_usb/android0/secure
        else
            setprop vendor.usb.secure_mode $1
        fi
        notice "mmi-usb-sh: secure mode = $1"
    fi
}

tcmd_ctrl_adb ()
{
    ctrl_adb=`getprop vendor.tcmd.ctrl_adb`
    notice "mmi-usb-sh: vendor.tcmd.ctrl_adb = $ctrl_adb"
    case "$ctrl_adb" in
        "0")
            if [[ "$sys_usb_config" == *adb* ]]
            then
                # *** ALWAYS expecting adb at the end ***
                new_usb_config=${sys_usb_config/,adb/}
                notice "mmi-usb-sh: disabling adb ($new_usb_config)"
                setprop persist.vendor.usb.config $new_usb_config
                setprop vendor.usb.config $new_usb_config
                setprop persist.vendor.factory.allow_adb 0
            fi
        ;;
        "1")
            if [[ "$sys_usb_config" != *adb* ]]
            then
                # *** ALWAYS expecting adb at the end ***
                new_usb_config="$sys_usb_config,adb"
                notice "mmi-usb-sh: enabling adb ($new_usb_config)"
                setprop persist.vendor.usb.config $new_usb_config
                setprop vendor.usb.config $new_usb_config
                setprop persist.vendor.factory.allow_adb 1
            fi
        ;;
    esac

    exit 0
}

case "$usb_action" in
    "")
    ;;
    "vendor.tcmd.ctrl_adb")
        tcmd_ctrl_adb
    ;;
esac

case "$target" in
    "mt6879")
        setprop vendor.usb.controller "11201000.usb0"
        setprop vendor.usb.rndis.func.name mtk_rndis.gs4
     ;;
    "mt6789")
        setprop vendor.usb.controller "musb-hdrc"
        setprop vendor.usb.rndis.func.name mtk_rndis.gs4
     ;;
    "mt6855")
        setprop vendor.usb.controller "musb-hdrc"
        setprop vendor.usb.rndis.func.name mtk_rndis.gs4
     ;;
esac

## This is needed to switch to the qcom rndis driver.
diag_extra=`getprop persist.vendor.usb.config.extra`
if [ "$diag_extra" == "" ]; then
        setprop persist.vendor.usb.config.extra none
fi

#
# Allow USB enumeration with default PID/VID
#
usb_config=`getprop persist.vendor.usb.config`
mot_usb_config=`getprop persist.vendor.mot.usb.config`
buildtype=`getprop ro.build.type`
securehw=`getprop ro.boot.secure_hardware`
cid=`getprop ro.vendor.boot.cid`

notice "mmi-usb-sh: persist usb configs = \"$usb_config\", \"$mot_usb_config\""


phonelock_type=`getprop persist.sys.phonelock.mode`
usb_restricted=`getprop persist.sys.usb.policylocked`
if [ "$securehw" == "1" ] && [ "$buildtype" == "user" ] && [ "$(($cid))" != 0 ]
then
    if [ "$usb_restricted" == "1" ]
    then
        set_usb_secure_mode 1
    else
        case "$phonelock_type" in
            "1" )
                set_usb_secure_mode 1
            ;;
            * )
                set_usb_secure_mode 0
            ;;
        esac
    fi
fi


case "$bootmode" in
    "mot-factory" )
        if [ "$usb_config" != "adb" ]
        then
            setprop persist.vendor.usb.config adb
            setprop persist.vendor.usb.mot-factory.config adb
            setprop persist.vendor.usb.mot-factory.func adb
        fi
    ;;
    "charger" )
    ;;
    * )
        if [ "$buildtype" == "user" ] && [ "$phonelock_type" != "1" ] && [ "$usb_restricted" != "1" ]
        then
            set_usb_secure_mode 1
            notice "Disabling enumeration until bootup!"
        fi

        case "$usb_config" in
            "mtp,adb" | "mtp" | "adb")
            ;;
            *)
                case "$mot_usb_config" in
                    "mtp,adb" | "mtp" | "adb")
                        setprop persist.vendor.usb.config $mot_usb_config
                    ;;
                    *)
                        case "$securehw" in
                            "1" )
                                setprop persist.vendor.usb.config mtp
                            ;;
                            *)
                                setprop persist.vendor.usb.config adb
                            ;;
                        esac
                    ;;
                esac
            ;;
        esac

        adb_early=`getprop ro.boot.adb_early`
        if [ "$adb_early" == "1" ]; then
            set_usb_secure_mode 0
            notice "Enabling enumeration after bootup, count =  $count !"
            new_persist_usb_config=`getprop persist.vendor.usb.config`
            if [[ "$new_persist_usb_config" != *adb* ]]; then
                setprop persist.vendor.usb.config "adb"
                setprop vendor.usb.config "adb"
            else
                setprop vendor.usb.config $new_persist_usb_config
            fi
            exit 0
        fi
        if [ "$buildtype" == "user" ] && [ "$phonelock_type" != "1" ] && [ "$usb_restricted" != "1" ]
        then
            if [[ "$factory_cfg" == *adb* ]]; then
                new_persist_usb_config=`getprop persist.vendor.usb.config`
                if [ "$sys_usb_config" != "$new_persist_usb_config" ]; then
                    setprop vendor.usb.config $new_persist_usb_config
                    notice "mmi-usb-sh - factory to normal, reset the vendor usb config"
                fi
            fi
            count=0
            bootcomplete=`getprop vendor.boot_completed`
            notice "mmi-usb-sh - bootcomplete = $booted"
            while [ "$bootcomplete" != "1" ]; do
                debug "Sleeping till bootup!"
                sleep 1
                count=$((count+1))
                if [ $count -gt 90 ]
                then
                    notice "mmi-usb-sh - Timed out waiting for bootup"
                    break
                fi
                bootcomplete=`getprop vendor.boot_completed`
            done
            set_usb_secure_mode 0
            notice "Enabling enumeration after bootup, count =  $count !"
            exit 0
        fi
    ;;
esac

new_persist_usb_config=`getprop persist.vendor.usb.config`
if [ "$sys_usb_config" != "$new_persist_usb_config" ]; then
	setprop vendor.usb.config $new_persist_usb_config
fi
