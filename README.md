# MyScriptsBashs
Auto:Cipriano Javier Perez Garcia
Fecha:02/11/2025
Repositorio de scripts Bash desarrollados para **automatizar tareas en Proxmox** y facilitar la gestión de archivos y sincronización con GitHub.

## 📂 Contenido

* `/home/cipriano/MyScriptsBashs/`

  * Scripts de automatización de tareas.
  * Script principal: `push_my_scripts.sh` — detecta cambios, hace commit y push a GitHub automáticamente.
* `.gitignore` (recomendado) para excluir backups, logs o archivos temporales.

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
* Carpeta de scripts: `/home/cipriano/MyScriptsBashs`.

---

## 💻 Uso

### Ejecutar el script de sincronización:

```bash
cd /home/cipriano/MyScriptsBashs
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

