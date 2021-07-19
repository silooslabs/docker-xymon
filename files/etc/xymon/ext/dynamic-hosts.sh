#!/bin/sh

# Automatically add ghost hosts to hosts.cfg

list=/etc/xymon/ghostlist.cfg
tmp=$XYMONTMP/ghostlist.$$

trap 'rm $tmp' 0

cp $list $tmp
(
    $XYMON localhost ghostlist | awk -F\| '{print $2 " " $1 " # noconn nonongreen"}'
    cat $tmp
) | sort -u > $list

