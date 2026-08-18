# 🟠 Proxmox Toolkit · MyScriptsBashs

> Colección de scripts Bash, aliases y dotfiles para administrar un nodo
> **Proxmox VE** desde una terminal Zsh personalizada.

![Proxmox VE](https://img.shields.io/badge/Proxmox%20VE-host%20toolkit-orange?logo=proxmox&logoColor=white)
![Shell](https://img.shields.io/badge/shell-Bash%20%2B%20Zsh-1f425f?logo=gnu-bash&logoColor=white)
![Estado](https://img.shields.io/badge/estado-activo-2ea44f)
![Licencia](https://img.shields.io/badge/licencia-personal-lightgrey)

> 🟠 **Importante:** el instalador está diseñado para un host Proxmox VE. No es
> un instalador genérico de Debian ni un instalador para Termux/Android.

---

## ⚡  // Inicio rápido \\

```bash
git clone https://github.com/ciprianotoor/MyScriptsBashs.git
cd MyScriptsBashs
./install-proxmox.sh
exec zsh
```

Después de instalar:

```bash
montar             # herramienta prioritaria de discos y montajes
aliases            # buscador visual de aliases con fzf
aliashelp          # ayuda organizada por categorías
aliasesrc          # editar aliases.sh y recargarlo al guardar
edit-readme        # editar y revisar README.md
TuneoNanoRoot      # copiar .nanorc tuneado al usuario root
TuneoBashRoot      # copiar .bashrc tuneado al usuario root
TuneoNanoUser      # aplicar .nanorc al usuario actual
TuneoBashUser      # aplicar .bashrc al usuario actual
consumo            # CPU, RAM y disco del nodo
r                  # reloj de terminal
push_my_scripts    # sincronizar cambios con GitHub
update-my-scripts  # descargar cambios desde GitHub
```

## 🧰 Qué instala `install-proxmox.sh`

El script verifica `/etc/pve/.version` o `pveversion` antes de continuar.
Después instala las dependencias usadas por `aliases.sh`:

```text
git zsh curl nano less lsd fzf bat tree tmux openssh-client
iproute2 iputils-ping procps util-linux hostname debianutils
gawk sed grep coreutils timeshift smartmontools tty-clock
```

También descarga o actualiza en `~/.zsh/`:

- Powerlevel10k
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions

Y crea una única fuente de configuración mediante enlaces simbólicos:

```text
~/.zshrc    -> <repositorio>/.zshrc
~/.p10k.zsh -> <repositorio>/.p10k.zsh
~/.nanorc   -> <repositorio>/.nanorc
```

Si ya existen archivos, el instalador los conserva como copias fechadas:
`*.backup-AAAAmmdd-HHMMSS`.

El instalador no sobrescribe `/root/.bashrc`, no cambia la red y no ejecuta
acciones sobre VMs o contenedores.

## 🗂️ Estructura del repositorio

```text
MyScriptsBashs/
├── install-proxmox.sh        # Instalación del entorno
├── aliases.sh                # Aliases y funciones de Zsh
├── edit-readme.sh            # Editor seguro del README
├── TuneoNanoRoot.sh           # Configura Nano para root mediante sudo
├── TuneoBashRoot.sh           # Configura Bash para root mediante sudo
├── TuneoNanoUser.sh           # Configura Nano del usuario actual
├── TuneoBashUser.sh           # Configura Bash del usuario actual
├── .zshrc / .p10k.zsh        # Zsh y Powerlevel10k
├── .nanorc                   # Configuración de Nano
├── push_my_scripts.sh        # Subir cambios a GitHub
├── update-my-scripts.sh      # Descargar cambios de GitHub
├── montar.sh                # Discos y montajes
├── lxc-admin.sh              # Contenedores LXC
├── administrarVMLXC.sh       # VMs y LXC
├── *proxmox*.sh / *zfs*.sh   # Administración del nodo
├── *backup*.sh               # Respaldos
├── archive/                  # Archivos antiguos, fuera del flujo principal
└── README.md
```

Los respaldos creados desde `AutoScripts.sh` no se guardan dentro del
repositorio. Se almacenan localmente en:

```text
~/.local/state/MyScriptsBashs/backups/
```

Esto evita subir archivos comprimidos antiguos a GitHub y mantiene separado el
backup de scripts del backup de la configuración del nodo Proxmox.

Al cargarse `aliases.sh`, cada archivo `*.sh` recibe un alias con su nombre y
se ejecuta mediante Bash. Esto permite utilizar scripts aunque no tengan el
bit ejecutable. `aliases.sh` no se incluye a sí mismo.

El flujo principal es: instalar → usar aliases y scripts → subir cambios con
`push_my_scripts` → descargar cambios con `update-my-scripts`. Los comandos
`qm`, `pct`, `pveversion`, `pvesm` y `pvecm` son propios de Proxmox VE; el
sistema Proxmox ya los proporciona.

## 🖥️ Aliases y configuración de terminal

```bash
aliases                  # Buscar aliases con fzf
aliashelp                # Ver nombres y funciones por categoría
aliasesrc                # Editar aliases.sh y recargar automáticamente
reload_alias             # Recargar aliases.sh sin abrir el editor
exec zsh                 # Reiniciar la sesión Zsh
consumo                  # Resumen de consumo del nodo
montar                   # Discos y montajes
r                        # Reloj tty-clock
```

`aliasesrc` utiliza `$EDITOR` si está definido y, de lo contrario, abre Nano.
Solo recarga la configuración si el editor termina correctamente.

Los nombres descriptivos (`listar_vms`, `vm_iniciar`, `listar_lxc`,
`ip_local`, `procesos_memoria`, `zfs_backup_v1`, etc.) son los recomendados.
Se conservan los nombres cortos antiguos (`vms`, `vmstart`, `cts`, `mip`,
`pvev`, etc.) para no romper hábitos ni scripts existentes.

Para tmux se recomienda esta secuencia lógica:

```bash
tmux_iniciar   # crea o conecta a la sesión trabajo
tmux_entrar    # entra a una sesión existente
tmux_listar    # lista las sesiones
tmux_cerrar    # cierra la sesión trabajo
```

## 🔐 Configurar SSH entre Proxmox y GitHub

Ejecuta estos pasos con el usuario propietario del repositorio:

```bash
sudo apt install -y git openssh-client
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "proxmox-git-$(hostname)" -f ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
cat ~/.ssh/id_ed25519.pub
```

En GitHub abre **Settings → SSH and GPG keys → New SSH key**, pega la clave
pública y guarda. Luego prueba:

```bash
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh -T git@github.com
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

La respuesta de GitHub puede indicar que no ofrece una shell interactiva; eso
es normal y confirma que la autenticación funcionó.

## 📤 Sincronizar con `push_my_scripts.sh`

El script calcula la carpeta real donde está instalado, añade cambios, crea un
commit fechado, actualiza `main` mediante rebase y hace push por SSH.

```bash
push_my_scripts
```

Cuando se ejecuta desde una terminal, muestra el resumen de cambios y pregunta
si deseas añadir un comentario personalizado al commit. Responder `n` o pulsar
Enter conserva el mensaje automático; en ejecuciones no interactivas utiliza
automáticamente ese mismo mensaje.

Para usarlo con otro repositorio:

```bash
export PUSH_SSH_KEY="$HOME/.ssh/id_ed25519"
export PUSH_REMOTE="git@github.com:TU_USUARIO/TU_REPOSITORIO.git"
export PUSH_BRANCH="main"
export PUSH_REPO_URL="https://github.com/TU_USUARIO/TU_REPOSITORIO"
push_my_scripts
```

La clave privada nunca debe subirse al repositorio; solo se registra en GitHub
el archivo `.pub`.

## 📥 Actualizar desde GitHub

`update-my-scripts.sh` comprueba primero que no existan cambios locales. Si el
repositorio está limpio, descarga la rama `main` con `git pull --ff-only`. Si
hay modificaciones locales, se detiene y muestra los archivos afectados para
evitar sobrescribir trabajo.

```bash
update-my-scripts
```

Después de una actualización, recarga Zsh:

```bash
exec zsh
```

## ⚠️ Seguridad y buenas prácticas

- Revisa cada script antes de ejecutarlo con `sudo`.
- Prueba con especial cuidado formateo, particionado, ZFS, restauración y apagado.
- No guardes claves, códigos 2FA ni contraseñas en el repositorio.
- Mantén la clave SSH con permisos restrictivos y passphrase.
- Haz un backup antes de modificar configuraciones del nodo.

## 📌 Información del proyecto

| Dato | Valor |
|---|---|
| **Autor** | Cipriano Javier Perez Garcia |
| **Proyecto** | MyScriptsBashs · Proxmox Toolkit |
| **Entorno objetivo** | Proxmox VE sobre Debian |
| **Última modificación** | 18 de agosto de 2026 |
| **Repositorio** | `github.com/ciprianotoor/MyScriptsBashs` |
| **Instalador** | `install-proxmox.sh` |
| **Sincronización** | `push_my_scripts.sh` mediante SSH |

## 🔗 Enlaces

- Repositorio: <https://github.com/ciprianotoor/MyScriptsBashs>
- GitHub SSH: <https://docs.github.com/en/authentication/connecting-to-github-with-ssh>

## ⚠️ Disclaimer

Estos scripts se proporcionan para uso personal y administrativo bajo tu
propia responsabilidad. Pueden requerir `sudo` y algunos modifican discos,
redes, servicios, máquinas virtuales, contenedores o configuraciones críticas
de Proxmox. El autor no garantiza que funcionen en todos los entornos ni se
hace responsable por pérdida de datos, interrupciones, daños en el sistema o
configuraciones incorrectas. Revisa el código, confirma los dispositivos y
realiza backups verificables antes de ejecutar operaciones sensibles.

## ❓ Preguntas frecuentes

### ¿Funciona fuera de Proxmox?

El instalador está diseñado para Proxmox VE. Algunos aliases y scripts Bash
pueden funcionar en Debian, pero no se garantiza compatibilidad fuera de un
host Proxmox.

### ¿Qué archivo debo editar para cambiar los aliases?

Usa `aliasesrc`. Abre `aliases.sh` con Nano o `$EDITOR` y recarga los cambios
automáticamente al cerrar el editor.

### ¿Cómo edito el README?

Ejecuta `edit-readme`. Usa `$EDITOR` o Nano, detecta marcadores de conflicto y
muestra si quedan cambios pendientes para `push_my_scripts`.

### ¿Cómo aplico el Nano RC a root?

Ejecuta `TuneoNanoRoot`. Pide sudo, respalda `/root/.nanorc` si existe y copia
la configuración versionada con permisos `600` y propietario `root:root`.

### ¿Cómo aplico el Bash RC tuneado a root?

Ejecuta `TuneoBashRoot`. Pide sudo, valida el `.bashrc`, respalda
`/root/.bashrc` si existe y copia la configuración versionada con permisos
`600` y propietario `root:root`. Los valores `MY_IP` y `MY_PORT` del archivo
deben personalizarse antes de usar los aliases SSH.

### ¿Cómo aplico los tuneos al usuario normal?

Ejecuta, sin `sudo`, `TuneoNanoUser` y `TuneoBashUser`. Ambos rechazan la
ejecución como root, respaldan los archivos existentes y aplican la
configuración al usuario actual con permisos `600`.

### ¿Cómo subo mis cambios?

Ejecuta `push_my_scripts`. El script muestra los cambios y permite añadir un
comentario al commit.

### ¿Cómo descargo cambios de GitHub?

Ejecuta `update-my-scripts`. Si hay cambios locales, se detiene para evitar
sobrescribirlos.

### ¿Dónde se guardan los backups de scripts?

En `~/.local/state/MyScriptsBashs/backups/`, fuera del repositorio.

### ¿Por qué `.zshrc`, `.p10k.zsh` y `.nanorc` son enlaces?

Para mantener una sola fuente de configuración dentro del repositorio y evitar
que el archivo activo y la copia versionada se desincronicen.

### ¿Qué hago si Git informa que hay cambios locales?

Revisa `git status`, guarda o confirma tus cambios y ejecuta
`update-my-scripts` nuevamente.
