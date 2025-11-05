#!/bin/bash
# ==============================================
# Crear usuario SSH "invitado" limitado a su home
# ==============================================

USER_NAME="invitado"
USER_HOME="/home/$USER_NAME"

# 1️⃣ Crear usuario sin contraseña y sin sudo
sudo adduser --disabled-password --gecos "" $USER_NAME
sudo deluser $USER_NAME sudo 2>/dev/null

# 2️⃣ Establecer shell restringido (rbash)
sudo usermod -s /bin/rbash $USER_NAME

# 3️⃣ Crear carpeta .ssh
sudo mkdir -p $USER_HOME/.ssh
sudo chmod 700 $USER_HOME/.ssh
sudo chown $USER_NAME:$USER_NAME $USER_HOME/.ssh

# 4️⃣ Pedir clave pública
echo "Por favor, pega la clave pública SSH del invitado y presiona ENTER:"
read CLAVE_PUBLICA

# 5️⃣ Guardar la clave pública
echo $CLAVE_PUBLICA | sudo tee $USER_HOME/.ssh/authorized_keys >/dev/null
sudo chmod 600 $USER_HOME/.ssh/authorized_keys
sudo chown $USER_NAME:$USER_NAME $USER_HOME/.ssh/authorized_keys

# 6️⃣ Limitar el home
# Crear enlaces simbólicos solo si necesita acceso a ciertos comandos, por ejemplo ls, cat
sudo mkdir -p $USER_HOME/bin
sudo chown $USER_NAME:$USER_NAME $USER_HOME/bin
# Agregar binarios que puede usar (opcional)
# cp /bin/ls $USER_HOME/bin/
# cp /bin/cat $USER_HOME/bin/

# 7️⃣ Cambiar PATH para usuario
echo 'PATH=$HOME/bin' | sudo tee -a $USER_HOME/.bash_profile >/dev/null
echo 'export PATH' | sudo tee -a $USER_HOME/.bash_profile >/dev/null

echo "✅ Usuario '$USER_NAME' creado con éxito."
echo "🔹 Acceso restringido a su home, sin sudo ni acceso a / ni /root."
echo "🔹 Conectarse vía SSH con su clave privada correspondiente:"
echo "ssh $USER_NAME@<IP_DEL_SERVIDOR>"
