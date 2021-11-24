###################################################################
## This script will help you to monitor multiple websites SSL    ##
## certificates and trigger an email notifications when the SSL  ##
## will expire in 30 days, 15 days, 7 days or 1 day.             ## 
###################################################################

#!/bin/bash

#Email settings 
_sub="$website will expire within $DAYS (7 days)."
_from=FROM_EMAIL_ADDRESS
_to=TO_EMAIL_ADDRESS
_openssl="/usr/bin/openssl"

input=/home/ubuntu/websites

while IFS= read -r website; do
 certificate_file=$(mktemp)
 echo -n | openssl s_client -servername "$website" -connect "$website":443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $certificate_file
 date=$(openssl x509 -in $certificate_file -enddate -noout | sed "s/.=\(.\)/\1/")
 date_s=$(date -d "${date}" +%s)
 now_s=$(date -d now +%s)
 date_diff=$(( (date_s - now_s) / 86400 ))
 echo "$website will expire in $date_diff days"
 rm "$certificate_file"
 if [ $date_diff -le 30 -a $date_diff -ge 15 ]
 then
  echo "Reminder"
  echo "${_sub}"
  mail -s "$_sub" -r "$_from" "$_to" <<< "REMINDER: The TLS/SSL certificate ($website) will expire soon in $date_diff days"
 elif [ $date_diff -le 15 -a $date_diff -ge 7 ]
 then
  echo "Warning"
  echo "${_sub}"
  mail -s "$_sub" -r "$_from" "$_to" <<< "WARNING: The TLS/SSL certificate ($website) will expire soon in $date_diff days"
 elif [ $date_diff -le 7 -a $date_diff -ge 1 ]
 then
  echo "Critical"
  echo "${_sub}"
  mail -s "$_sub" -r "$_from" "$_to" <<< "CRITICAL: The TLS/SSL certificate ($website) will expire soon in $date_diff days"
 elif [ $date_diff -eq  1 ]
 then
  echo "Severe"
  echo "${_sub}"
  mail -s "$_sub" -r "$_from" "$_to" <<< "SEVERE: The TLS/SSL certificate ($website) will expire soon in $date_diff days"
 fi
done < $input
