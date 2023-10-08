#!/vendor/bin/sh

echo "Retrieve Modem RFS logs"

re='?(-)+([0-9.])'

if ! [[ $2 == $re ]] ; then
    echo "error: Not a number" >&2; exit 1
fi

__copy_logs()
{
    file1="${1}"
    file2="${2}"

    if [ ! -f "${file1}" ]; then
        echo -e "${file1} invalid"
        return
    fi

    /vendor/bin/chmod 666 "${file1}"
    /vendor/bin/cp "${file1}" "${file2}"
    /vendor/bin/chmod 640 "${file2}"
}

mdm_rfs_folder=/mnt/vendor/nvdata/md/
mdm_rfs_log0=mot_md_log_0.txt
mdm_rfs_log1=mot_md_log_1.txt

mdm_log_target_folder=/data/vendor/dontpanic

if [ "$1" == "loop" ]; then
    loop=1
else
    loop=0
fi

while true
do
    /vendor/bin/echo "1" > /data/vendor/radio/read_modem_efs
    /vendor/bin/sleep 1
    /vendor/bin/echo "0" > /data/vendor/radio/read_modem_efs

    __copy_logs $mdm_rfs_folder/$mdm_rfs_log0 $mdm_log_target_folder/$mdm_rfs_log0
    __copy_logs $mdm_rfs_folder/$mdm_rfs_log1 $mdm_log_target_folder/$mdm_rfs_log1

    if [ $loop -eq 1 ]
    then
        /vendor/bin/sleep $2
    else
        break
    fi
done

exit 0

