#! /bin/bash
echo -e "Please input your command to be broadcast, and ends with blank USER_CMD_LINE"
# PT1
IFS="" ; USER_CMD=()
while IFS="" read -r USER_CMD_LINE
do
    [[ "$USER_CMD_LINE" == "" ]] && break
    USER_CMD+=(`echo -en "$USER_CMD_LINE\n"`)
    # echo
    # echo -e "#"
    # echo -en "$USER_CMD_LINE\n"
    # echo -e "#"
    # for ((i = 0; i < ${#USER_CMD[@]}; i++)) ; do echo "${USER_CMD[$i]}" ; done
done

# # PT2
# USER_CMD=($(
# while IFS='$\n' read -r USER_CMD_LINE
# do
#     [[ "$USER_CMD_LINE" == "" ]] && break
#     echo -e "$USER_CMD_LINE\n" | awk '{print $0}'
# done
# ))

echo -e "Your command to be sent out is:"
# echo -e "${USER_CMD[*]}"
# echo ${USER_CMD[@]}
# printf '%s ' "${USER_CMD[@]}"

# echo -e "\n#"
# (IFS= ; echo -e "${USER_CMD[@]}\n")
#
# echo -e "\n##"
printf '%s\n' "${USER_CMD[@]}"

# echo -e "\n###"
# for ((i = 0; i < ${#USER_CMD[@]}; i++))
# do
#     echo "${USER_CMD[$i]}"
# done

# echo -e "####"
# for USER_CMD_LINE in ${USER_CMD[*]}
# do
#     echo -e "$USER_CMD_LINE"
# done
