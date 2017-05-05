exec {fd}<$0

flock -w 1 -x $fd || {
    echo "duplicate process.">&2
    exit 1
}

