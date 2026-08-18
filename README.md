# MyScriptsBashs

Colección de scripts Bash y configuración de terminal para administrar un host
**Proxmox VE**. El repositorio también incluye un instalador reproducible para
que otro usuario pueda clonar el proyecto y obtener el mismo entorno de Zsh,
Powerlevel10k, aliases y Nano.

## Qué instala `install-proxmox.sh`

El instalador solo continúa si detecta Proxmox VE (`/etc/pve/.version` o
`pveversion`). Ejecutado desde el usuario que usará la terminal, realiza estas
acciones:

1. Instala con APT las dependencias usadas por `aliases.sh`:

   `git`, `zsh`, `curl`, `nano`, `less`, `lsd`, `fzf`, `bat`, `tree`, `tmux`,
   `openssh-client`, `iproute2`, `iputils-ping`, `procps`, `util-linux`,
   `hostname`, `debianutils`, `gawk`, `sed`, `grep`, `coreutils`, `timeshift` y
   `smartmontools` y `tty-clock`.

2. Descarga o actualiza estos plugins en `~/.zsh/`:

   - Powerlevel10k
   - zsh-autosuggestions
   - zsh-syntax-highlighting
   - zsh-completions

3. Enlaza los archivos versionados del repositorio:

   ```text
   ~/.zshrc    -> <repositorio>/.zshrc
   ~/.p10k.zsh -> <repositorio>/.p10k.zsh
   ~/.nanorc   -> <repositorio>/.nanorc
   ```

   De esta forma no hay dos configuraciones activas. Los archivos existentes
   se conservan como `*.backup-AAAAmmdd-HHMMSS` antes de crear los enlaces.

El instalador no sobrescribe `/root/.bashrc`, no cambia la configuración de
red y no ejecuta acciones sobre máquinas virtuales o contenedores.

## Instalación

Requisitos: Proxmox VE, una cuenta con `sudo` y acceso a Internet para APT y
GitHub.

```bash
git clone https://github.com/ciprianotoor/MyScriptsBashs.git
cd MyScriptsBashs
./install-proxmox.sh
exec zsh
```

El script puede ejecutarse desde cualquier ruta; no presupone que el repositorio
esté en `~/MyScriptsBashs`. Para usar `push_my_scripts.sh`, la cuenta debe tener
una clave SSH autorizada para el repositorio de GitHub.

## Configurar SSH entre Proxmox y GitHub

Estos pasos permiten que `push_my_scripts.sh` haga `commit` y `push` sin pedir
contraseña de GitHub. Ejecútalos con el usuario propietario del repositorio,
no necesariamente como `root`.

### 1. Crear una clave en Proxmox

```bash
sudo apt install -y git openssh-client
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "proxmox-git-$(hostname)" -f ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

Se recomienda proteger la clave con una passphrase.

### 2. Añadir la clave pública a GitHub

```bash
cat ~/.ssh/id_ed25519.pub
```

En GitHub abre **Settings → SSH and GPG keys → New SSH key**, pega el contenido
completo y guarda la clave.

### 3. Probar la conexión

```bash
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh -T git@github.com
```

GitHub confirmará la autenticación, pero indicará que no ofrece una shell
interactiva; ese resultado es normal.

### 4. Configurar el remoto y el agente SSH

```bash
git remote set-url origin git@github.com:TU_USUARIO/TU_REPOSITORIO.git
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
git config --global user.name "Tu nombre"
git config --global user.email "tu-correo@example.com"
```

Para usar `push_my_scripts.sh` con otro repositorio sin editar el script:

```bash
export PUSH_SSH_KEY="$HOME/.ssh/id_ed25519"
export PUSH_REMOTE="git@github.com:TU_USUARIO/TU_REPOSITORIO.git"
export PUSH_BRANCH="main"
export PUSH_REPO_URL="https://github.com/TU_USUARIO/TU_REPOSITORIO"
push_my_scripts
```

La clave privada nunca debe subirse al repositorio; solo se registra en GitHub
el archivo `.pub`.

## Estructura

```text
MyScriptsBashs/
├── install-proxmox.sh          # Instalador del entorno Proxmox
├── push_my_scripts.sh          # Commit y push automático por SSH
├── aliases.sh                  # Alias y funciones cargados por Zsh
├── .zshrc                      # Configuración principal de Zsh
├── .p10k.zsh                   # Tema y segmentos de Powerlevel10k
├── .nanorc                     # Configuración personalizada de Nano
├── lxc-admin.sh                # Administración de contenedores LXC
├── administrarVMLXC.sh         # Menú de VMs y contenedores
├── AuditoriaProxmoxVE.sh       # Auditoría del nodo
├── proxmox_security_audit.sh   # Revisión de seguridad
├── *backup*.sh                 # Respaldos de configuración
├── *zfs*.sh                    # Herramientas para ZFS
├── *PersistentImg*.sh          # Imágenes persistentes
└── README.md
```

Los demás scripts se pueden ejecutar directamente desde el repositorio. Al
cargar `aliases.sh`, se genera automáticamente un alias para cada archivo
`*.sh` de esta carpeta; cada alias ejecuta el script mediante Bash, incluso si
el archivo no tiene el bit ejecutable.
Los comandos `qm`, `pct`, `pveversion`, `pvesm` y `pvecm` son propios de
Proxmox VE y no se instalan mediante APT adicional.

## Uso diario

Después de instalar:

```bash
exec zsh                 # recargar la configuración
aliases                  # buscar aliases con fzf
aliasesrc                # editar aliases.sh y recargarlo al guardar
reload_alias             # recargar aliases.sh sin abrir el editor
consumo                  # resumen de CPU, RAM y disco
montar                   # herramienta prioritaria de discos y montajes
r                       # reloj de terminal (tty-clock)
push_my_scripts          # sincronizar cambios con GitHub
```

También están disponibles los aliases para VMs/LXC, red, SSH, logs, APT,
tmux, Timeshift, Git, `r.sh` (reloj de terminal) y herramientas de diagnóstico.

`aliasesrc` usa la variable `$EDITOR` si está definida; de lo contrario abre
Nano. Solo recarga la configuración si el editor termina correctamente.

## Sincronización con GitHub

`push_my_scripts.sh` calcula automáticamente la carpeta donde está instalado,
añade todos los cambios, crea un commit con fecha, actualiza `main` mediante
rebase y hace push al remoto SSH:

```text
git@github.com:ciprianotoor/MyScriptsBashs.git
```

Si el rebase encuentra conflictos, el script se detiene para que se resuelvan
manualmente; no oculta el error.

## Notas de seguridad

- Revisa cada script antes de ejecutarlo con `sudo`.
- No guardes claves, códigos 2FA ni contraseñas en el repositorio.
- Mantén la clave SSH con permisos restrictivos y, preferiblemente, passphrase.
- Prueba scripts de discos, ZFS, backups y apagado en un entorno controlado.
