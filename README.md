# 🟠 Proxmox Toolkit · MyScriptsBashs

> Colección de scripts Bash, aliases y dotfiles para administrar un nodo
> **Proxmox VE** desde una terminal Zsh personalizada.

![Proxmox VE](https://img.shields.io/badge/Proxmox%20VE-host%20toolkit-orange?logo=proxmox&logoColor=white)
![Shell](https://img.shields.io/badge/shell-Bash%20%2B%20Zsh-1f425f?logo=gnu-bash&logoColor=white)
![Estado](https://img.shields.io/badge/estado-activo-2ea44f)
![Licencia](https://img.shields.io/badge/licencia-personal-lightgrey)

> 🟠 **Importante:** el instalador está diseñado para un host Proxmox VE. No es
> un instalador genérico de Debian ni un instalador para Termux/Android.

<<<<<<< HEAD
## ⚡  ## Inicio rápido
=======
<br>

## ⚡&nbsp;&nbsp;Inicio rápido
>>>>>>> ac0f276 (Auto-commit Proxmox admin: 2026-08-18 15:56:57)

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
aliasesrc          # editar aliases.sh y recargarlo al guardar
consumo            # CPU, RAM y disco del nodo
r                  # reloj de terminal
push_my_scripts    # sincronizar cambios con GitHub
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
├── install-proxmox.sh          # Instala el entorno completo
├── push_my_scripts.sh          # Commit, rebase y push por SSH
├── aliases.sh                  # Aliases y funciones cargados por Zsh
├── .zshrc                      # Configuración principal de Zsh
├── .p10k.zsh                   # Tema y segmentos Powerlevel10k
├── .nanorc                     # Configuración personalizada de Nano
├── montar.sh                   # Gestión de discos y montajes
├── r.sh                        # Reloj tty-clock
├── lxc-admin.sh                # Administración LXC
├── administrarVMLXC.sh         # Menú de VMs y contenedores
├── AuditoriaProxmoxVE.sh       # Auditoría del nodo
├── proxmox_security_audit.sh   # Revisión de seguridad
├── *backup*.sh                 # Respaldos de configuración
├── *zfs*.sh                    # Herramientas ZFS
├── *PersistentImg*.sh          # Imágenes persistentes
├── archive/                    # Archivos antiguos conservados
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

Los comandos `qm`, `pct`, `pveversion`, `pvesm` y `pvecm` son propios de
Proxmox VE; el sistema Proxmox ya los proporciona.

## 🖥️ Aliases y configuración de terminal

```bash
aliases                  # Buscar aliases con fzf
aliasesrc                # Editar aliases.sh y recargar automáticamente
reload_alias             # Recargar aliases.sh sin abrir el editor
exec zsh                 # Reiniciar la sesión Zsh
consumo                  # Resumen de consumo del nodo
montar                   # Discos y montajes
r                        # Reloj tty-clock
```

`aliasesrc` utiliza `$EDITOR` si está definido y, de lo contrario, abre Nano.
Solo recarga la configuración si el editor termina correctamente.

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
