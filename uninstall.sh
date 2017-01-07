#!/bin/bash
git reset ---hard
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed : $ret.EXIT"
	exit 1
fi

for file in $(ls ../.git/hooks/)
do
	if [ "${file##*.}"x != "bak"x ]; then
		continue
	fi
	cp "../.git/hooks/${file}" "../.git/hooks/${file%%.bak}" -Rvf
done
log_info "$0 $@ running success"
# read -n1 -p "Press any key to continue..."
exit 0 
