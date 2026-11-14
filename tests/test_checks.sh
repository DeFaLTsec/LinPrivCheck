#!/bin/sh
# Pruebas básicas sin dependencias (no usa bats para mantenerlo 100% portable).
set -u
SELF_DIR=$(cd "$(dirname "$0")/.." && pwd)
LPH_LIBDIR="$SELF_DIR/lib"
export LPH_LIBDIR
. "$LPH_LIBDIR/checks.sh"

fail=0
assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) echo "FALLÓ: se esperaba encontrar '$2' en: $1"; fail=1 ;;
    esac
}

# gtfo_lookup debe encontrar binarios conocidos
hit=$(gtfo_lookup "find")
[ -z "$hit" ] && { echo "FALLÓ: gtfo_lookup('find') vacío"; fail=1; }
assert_contains "$hit" "find|SUID"

hit_none=$(gtfo_lookup "binario_inexistente_xyz")
[ -n "$hit_none" ] && { echo "FALLÓ: gtfo_lookup de binario inexistente no debería tener match"; fail=1; }

# check_kernel_version siempre debe producir una línea INFO
out=$(check_kernel_version)
assert_contains "$out" "INFO|Kernel:"

if [ "$fail" -eq 0 ]; then
    echo "Todas las pruebas pasaron."
    exit 0
else
    echo "Hay pruebas fallidas."
    exit 1
fi
