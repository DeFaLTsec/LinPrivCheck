# 🐧 linprivhints

Script de **enumeración de escalada de privilegios en Linux**, 100% Bash/sh,
**sin dependencias**: corre hasta en las cajas más mínimas. A diferencia de
linPEAS/LinEnum, no solo lista — **interpreta** cada hallazgo y te da el
comando de explotación, usando una base de datos de GTFOBins embebida (offline).

> ⚠️ **Uso legal**: ejecútalo únicamente en sistemas propios o con
> autorización expresa y por escrito (pentest, CTF, laboratorio propio).

## Características
- Binarios **SUID/SGID**, **capabilities**, **sudo -l**, **cron**, permisos
  de `/etc/passwd` y `/etc/shadow`, grupo `docker`, NFS `no_root_squash`,
  versión de kernel y credenciales en el historial de shell.
- Cada hallazgo trae **severidad**, **por qué importa** y **comando listo**.
- Base de datos de GTFOBins embebida (`lib/gtfobins.db`) — sin internet.
- Salida en texto con colores, **JSON** (`--json`) y **Markdown** (`--md`)
  para pegar directo en el informe.
- Modo `--quiet` que evita tocar archivos de usuario (historial, etc.).
- Sin dependencias: ni Python, ni curl, ni bash obligatorio (usa `sh`).

## Uso
```bash
chmod +x linprivhints.sh
./linprivhints.sh                 # salida en texto con colores
./linprivhints.sh --json > out.json
./linprivhints.sh --md > informe.md
./linprivhints.sh --quiet         # no toca archivos de usuario
```

Subirlo a un objetivo en un solo comando (útil si solo tienes acceso remoto):
```bash
curl -s https://raw.githubusercontent.com/<tu-usuario>/linprivhints/main/linprivhints.sh | sh
```
*(nota: esta forma no incluye `lib/gtfobins.db`, así que los hallazgos SUID
no tendrán el comando exacto — transfiere la carpeta completa si lo necesitas)*

Ejemplo de salida: [`examples/sample_output.txt`](examples/sample_output.txt)

## Probarlo en un laboratorio
```bash
docker build -t linprivhints-lab .
docker run --rm -it linprivhints-lab
```

## Tests
```bash
sh tests/test_checks.sh
```

## Añadir binarios a la base de GTFOBins
Edita `lib/gtfobins.db`, formato `binario|técnica|comando`.

## Roadmap
- [ ] Chequeo de PATH hijacking
- [ ] Detección de contenedores (LXC/LXD)
- [ ] Exportar a SARIF para CI

## Licencia
MIT
