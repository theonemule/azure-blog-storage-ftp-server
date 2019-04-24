#!/bin/bash

#The admin interface for OpenVPN

echo "Content-type: text/html"
echo ""
echo "<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Azure Blob Storage FTP Server</title>
</head>
<body>"

echo "<h1>Azure Blob Storage FTP Server</h1>"

eval `echo "${QUERY_STRING}"|tr '&' ';'`

eval `echo "${POST_DATA}"|tr '&' ';'`


case $option in
        "add") #Add a client
                ( echo ${password} ; echo ${password} ) | pure-pw useradd $username -f /ftp/ftp.passwd -u ftpuser -d /ftp/ftp-files/$username > /dev/null 2>&1
                mkdir /ftp/ftp-files/$username
                pure-pw mkdb  /ftp/ftp.pdb -f /ftp/ftp.passwd
                echo "<h3>Account created for <span style='color:red'>$username</span> added.</h3>"
        ;;
        "delete") #Revoke a client
                pure-pw userdel $username -f /ftp/ftp.passwd > /dev/null 2>&1
                pure-pw mkdb  /ftp/ftp.pdb -f /ftp/ftp.passwd
                echo "<h3>Account created for <span style='color:red'>$username</span> deleted.</h3>"
        ;;
        "edit") #Edit a client
                echo "New password for user <span style='color:red'>$username</span>: <form action='index.sh' method='get'><input type='hidden' name='option' value='change'><input type='hidden' name='username' value='$username'><input type='password' name='password'><input type='submit' value='Change'></form>"
        ;;
        "change") #Change a pasword
                ( echo ${password} ; echo ${password} ) | pure-pw passwd $username -f /ftp/ftp.passwd  > /dev/null 2>&1
                pure-pw mkdb  /ftp/ftp.pdb -f /ftp/ftp.passwd
                echo "<h3>Password changed for <span style='color:red'>$username</span>.</h3>"
        ;;


esac


FILE=/ftp/ftp.passwd
echo "<table border=1><tr><th>User</th><th>Folder</th><th></th><th></th></td>"
while read LINE; do
        IFS=':'; userInfo=($LINE); unset IFS;
        echo "<tr><td>${userInfo[0]}</td><td>${userInfo[5]}</td><td><a href='?option=delete&username=${userInfo[0]}'>Delete</a></td><td><a href='?option=edit&username=${userInfo[0]}'>Change Password</a></td></tr>"
done < $FILE
echo "</table>"

echo "<hr>"

echo "
<form action='index.sh' method='get'>
<input type='hidden' name='option' value='add'>
Username: <input type='text' name='username'><br/>
Password: <input type='password' name='password'><br/>
<input type='submit' value='Create'>
</form>
"

echo "</body></html>"
exit 0
