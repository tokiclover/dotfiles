#!/bin/sh
for i in $(seq $2 $3); do
  case $1 in
   -a|--add)
	   mknod -m0660 /dev/loop$i b 7 $i
	   chown root:disk /dev/loop$i
	   ;;
   -d|--del)
	   rm -f /dev/loop$i
	   ;;
  esac
done
