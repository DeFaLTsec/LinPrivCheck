#!/bin/sh
# linprivhints - enumeración de escalada de privilegios en Linux, sin dependencias.
# Uso solo en sistemas con autorización expresa.
set -u

VERSION="0.1.0"
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
LPH_LIBDIR="$SELF_DIR/lib"
export LPH_LIBDIR

FORMAT="text"
QUIET=0

usage() {
    cat <<USAGE
linprivhints $VERSION - uso solo con autorización expresa

Uso: $0 [--json|--md] [--quiet] [-h]

  --json    salida en JSON
  --md      salida en Markdown (para informes)
  --quiet   evita checks que escriben en disco (histórico, etc.)
  -h        esta ayuda
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --json) FORMAT="json" ;;
        --md) FORMAT="md" ;;
        --quiet) QUIET=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; usage; exit 2 ;;
    esac
    shift
done

. "$LPH_LIBDIR/checks.sh"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

run_check() { "$1" >> "$TMP" 2>/dev/null; }

run_check check_suid
run_check check_sgid
run_check check_sudo
run_check check_capabilities
run_check check_cron
run_check check_writable_passwd
run_check check_docker_group
run_check check_nfs_no_root_squash
run_check check_kernel_version
[ "$QUIET" -eq 0 ] && run_check check_history_creds

sev_color() {
    case "$1" in
        CRITICAL) printf '\033[1;31m' ;;
        HIGH) printf '\033[0;31m' ;;
        MEDIUM) printf '\033[0;33m' ;;
        LOW) printf '\033[0;36m' ;;
        *) printf '\033[0;34m' ;;
    esac
}
RESET=$(printf '\033[0m')

sort_order() {
    awk -F'|' '{
        sev=$1
        if (sev=="CRITICAL") p=0
        else if (sev=="HIGH") p=1
        else if (sev=="MEDIUM") p=2
        else if (sev=="LOW") p=3
        else p=4
        print p"|"$0
    }' "$1" | sort -t'|' -k1,1n | cut -d'|' -f2-
}

case "$FORMAT" in
    json)
        echo "["
        first=1
        sort_order "$TMP" | while IFS='|' read -r sev title detail cmd; do
            [ "$first" -eq 1 ] && first=0 || printf ','
            printf '\n  {"severity":"%s","title":"%s","detail":"%s","command":"%s"}' \
                "$sev" "$(echo "$title" | sed 's/"/\\"/g')" \
                "$(echo "$detail" | sed 's/"/\\"/g')" \
                "$(echo "$cmd" | sed 's/"/\\"/g')"
        done
        echo "]"
        ;;
    md)
        echo "# linprivhints report"
        echo
        echo "| Sev | Hallazgo | Detalle | Comando |"
        echo "|---|---|---|---|"
        sort_order "$TMP" | while IFS='|' read -r sev title detail cmd; do
            printf '| %s | %s | %s | `%s` |\n' "$sev" "$title" "$detail" "$cmd"
        done
        ;;
    *)
        echo "linprivhints $VERSION - usar solo con autorización"
        echo "----------------------------------------------------"
        sort_order "$TMP" | while IFS='|' read -r sev title detail cmd; do
            color=$(sev_color "$sev")
            printf "%s[%s]%s %s\n" "$color" "$sev" "$RESET" "$title"
            printf "  -> %s\n" "$detail"
            printf "  \$ %s\n\n" "$cmd"
        done
        total=$(wc -l < "$TMP" | tr -d ' ')
        echo "Total de hallazgos: $total"
        ;;
esac
