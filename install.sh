#!/bin/bash
git reset ---hard
ret=$?
if [ $ret -ne 0 ]; then
	log_error "${LINENO}:  failed : $ret.EXIT"
	exit 1
fi
uninstall.sh
for file in $(ls ./hooks/)
do
	if [[ -f "../.git/hooks/$file" ]]; then
		cp "../.git/hooks/$file" "../.git/hooks/${file}.bak" -Rvf
		ln -s -f "$file" "../.git/hooks/${file}"
	fi
done
log_info "$0 $@ running success"
# read -n1 -p "Press any key to continue..."
exit 0 
