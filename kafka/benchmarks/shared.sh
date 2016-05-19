function drop_caches {
  sync
  echo 3 > /proc/sys/vm/drop_caches
}

function event_log {
  local message=$1
  echo $message | gawk '{print strftime("EVENT %Y:%m:%d %H:%M:%S,"), $0; fflush(); }'
}
