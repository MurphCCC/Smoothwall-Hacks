#!/bin/bash
# The idea is to write a script/program that will monitor our apache access files for every GET request for a pac file.  The pac file will have the same name as a username on our Smoothwall Proxy server.
# We will then take the name of the pac file along with the requesting IP address, some how tie those together either through an array or a combination of files.  We will then pass the IP address and the
# name of the pac file to a CURL command which will send a POST request to the login page of the proxy.  The pac file will be passed to the command as the username and the IP address will be passed as part
# of a header.  This will allow us to spoof the source address of the login attempt so that the proxy actually sees it as coming from the same IP address as the user who requested the pac file.
#
# If we can get this to work in semi real time, maybe run our script every 30 seconds or so, then we can essentially have an auto login system that requires absolutely no user interaction.

# The curl command goes something like this:
# curl --header "X-Forwarded-For: $IP" -d "USERNAME=$pacFile&PASSWORD=nobigdeal&submit=Login" http://192.168.8.21/ilogin
# No

cat /var/log/httpd/global_access_log | grep pac | awk '{print $1, $7}' | sort | uniq | sed 's/\///g; s/.pac//g' | sort | uniq > testarray

cat testarray | awk '{print $1}' > ip
cat testarray | awk '{print $2}' > name


declare -a ip_array=() # Declare an associative array, we will use this array to hold all of our IP addresses that we get from the log file.

declare -a name_array=() # Declare an array to hold the usernames that we get from the log file and send through the curl command

while read -r ip; do # Take each line in the file containing IP addresses and add it to our array.
        ip_array+=($ip)
done < ./ip

while read -r name; do # Take each line in the file containing usernames and add it to our array.
        name_array+=($name)
done < ./name

#echo ${ip_array[1]} ${name_array[1]}
#

length=`wc -l ip | sed "s/ip//g"`

echo $length

ITERATION=0
while [ $ITERATION -lt $length ]; do
echo 'curl --header "X-Forwarded-For: '${ip_array[$ITERATION]}'" -d "USERNAME='${name_array[$ITERATION]}'&PASSWORD=${PASSWORD}&submit=Login" http://192.168.8.21/ilogin"'
    let ITERATION=ITERATION+1
done
