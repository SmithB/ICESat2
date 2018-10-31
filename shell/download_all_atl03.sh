#! /usr/bin/env bash

# From Ben Smith:
# put your scf user name in place of scf_user_name
# this will grab all the ATL03 files in your outgoing directory.

echo "open sftp://scf_user_name:DUMMY@gs615-scf1.gsfc.nasa.gov; ls outgoing" > lftp_script
for j in `lftp  -c " open sftp://scf_user_name:DUMMY@gs615-scf1.gsfc.nasa.gov; ls outgoing" | awk '/.h5/ {print $NF}'` ; do
    [ -f $j ] ||  echo "pget -n 30 outgoing/$j" >> lftp_script

done

lftp -f lftp_script
