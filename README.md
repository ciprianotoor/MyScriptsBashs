# MyScriptsBashs

## 👤 Autor
**Cipriano Javier Perez Garcia**

## 📅 Fecha
13 de junio de 2026  

## ⏰

Repositorio de scripts Bash desarrollados para **automatizar tareas en Proxmox** y facilitar la gestión de archivos y sincronización con GitHub.

## 📂 Contenido

* `MyScriptsBashs/`

  * Scripts de automatización de tareas.
  * Script principal: `push_my_scripts.sh` — detecta cambios, hace commit y push a GitHub automáticamente.
* `install-proxmox.sh` — instala el entorno en un host Proxmox VE y enlaza los dotfiles.

---

## ⚡ Funcionalidades principales

1. **`push_my_scripts.sh`**

   * Detecta cambios en la carpeta de scripts.
   * Hace commit automático con un timestamp.
   * Hace push al repositorio remoto en GitHub vía SSH.
   * Se puede ejecutar manualmente o integrarse como tarea de cron o VS Code.

2. **Gestión de scripts Bash**

   * Cualquier script agregado a la carpeta puede sincronizarse con GitHub.
   * Permite trabajar directamente en Proxmox vía SSH o VS Code remoto.

---

## 🚀 Requisitos

* Proxmox VE con acceso SSH.
* Git instalado.
* Clave SSH pública agregada a GitHub.
* Una cuenta de usuario con `sudo`.

## 🧰 Instalación en Proxmox

El instalador es específico para el host Proxmox y no se ejecuta en Debian genérico ni en Termux.
Realiza una copia fechada de los archivos existentes, instala Git/Zsh/Nano y los plugins de Zsh,
y enlaza `.zshrc`, `.p10k.zsh` y `.nanorc` desde el repositorio. Así, la configuración tuneada de
Nano y Powerlevel10k queda versionada en una sola ubicación.

```bash
git clone https://github.com/ciprianotoor/MyScriptsBashs.git
cd MyScriptsBashs
./install-proxmox.sh
exec zsh
```

---

## 💻 Uso

### Ejecutar el script de sincronización:

```bash
cd ~/MyScriptsBashs
./push_my_scripts.sh
```

* Detecta cambios, hace commit y push.
* Mensajes en terminal indican el estado: archivos agregados, commits y push exitoso.

### Integración opcional

* Ejecutar automáticamente al guardar archivos con **VS Code**.
* Configurar como tarea en **cron** para sincronización periódica.

---

## 📝 Buenas prácticas

* Guardar los scripts directamente en `/home/cipriano/MyScriptsBashs`.
* Probar scripts nuevos primero en un entorno de prueba.
* Mantener la clave SSH segura y con passphrase si es necesario.

---

## 🔗 Repositorio remoto

```text
git@github.com:ciprianotoor/MyScriptsBashs.git
```
