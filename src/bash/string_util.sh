if [ "$STRING_UTIL_H" ]; then
    return
fi

export STRING_UTIL_H="string_util.sh"
echo "include $STRING_UTIL_H"

. log_util.sh

# trim(str)
# remove blank space in both side
trim()
{
    echo $*
}

# remove the suffix and get short name
# @param in filename
get_short_name()
{
    local expected_params_in_num=1
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$0 expects $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi

    local full_file_name=$1
    local file_name=$(basename "$full_file_name") 
    echo "$file_name" | sed 's/\.\w*$//'
}
