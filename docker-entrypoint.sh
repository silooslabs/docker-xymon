#!/bin/sh

if [ -n "$TZ" ] ; then
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
fi

test -f /var/lib/xymon/rrd || tar -C / -xf /root/xymon-data.tgz
test -f /etc/xymon/hosts.cfg || tar -C / -xf /root/xymon-config.tgz

env | grep SSMTP_ | cut -c 7- > /etc/ssmtp/ssmtp.conf

lighttpd -f /etc/lighttpd/lighttpd.conf

su-exec xymon xymonlaunch --no-daemon --config=etc/xymon/tasks.cfg
