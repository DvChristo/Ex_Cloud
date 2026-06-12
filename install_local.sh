#!/bin/bash
echo "🚀 Iniciando despliegue de Cafetería Cloud (Local)..."

# 1. Evitar bloqueos de Ubuntu y actualizar
export NEEDRESTART_MODE=a
apt-get update && apt-get upgrade -y

# 2. Instalar dependencias (Nginx, MariaDB, Python)
apt-get install -y mariadb-server nginx python3-venv python3-pip

# 3. Configurar Base de Datos MariaDB Local
echo "🗄️ Configurando base de datos..."
mysql -e "CREATE DATABASE IF NOT EXISTS cafeteria;"
mysql -e "CREATE USER IF NOT EXISTS 'cafeuser'@'localhost' IDENTIFIED BY 'ClaveLocal123';"
mysql -e "GRANT ALL PRIVILEGES ON cafeteria.* TO 'cafeuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "USE cafeteria; CREATE TABLE IF NOT EXISTS ventas (id INT AUTO_INCREMENT PRIMARY KEY, cliente VARCHAR(100) NOT NULL, tipo_cafe VARCHAR(50) NOT NULL, precio DECIMAL(6, 2) NOT NULL, fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 4. Crear estructura de la aplicación
echo "📂 Creando archivos de la aplicación..."
mkdir -p /var/www/cafeteria/templates
cd /var/www/cafeteria

# Crear requirements.txt
cat << 'EOF' > requirements.txt
Flask==3.0.3
PyMySQL==1.1.0
gunicorn==21.2.0
EOF

# Crear app.py (Configurado para localhost)
cat << 'EOF' > app.py
from flask import Flask, render_template, request, redirect, flash
import pymysql

app = Flask(__name__)
app.secret_key = "clave_secreta_academica"

def conectar_db():
    return pymysql.connect(host="localhost", user="cafeuser", password="ClaveLocal123", database="cafeteria", cursorclass=pymysql.cursors.DictCursor)

@app.route('/', methods=['GET'])
def index():
    conexion = conectar_db()
    with conexion.cursor() as cursor:
        cursor.execute("SELECT * FROM ventas ORDER BY fecha DESC LIMIT 5")
        ventas = cursor.fetchall()
    conexion.close()
    return render_template('index.html', ventas=ventas)

@app.route('/registrar', methods=['POST'])
def registrar_venta():
    cliente, tipo_cafe, precio = request.form['cliente'], request.form['tipo_cafe'], float(request.form['precio'])
    conexion = conectar_db()
    with conexion.cursor() as cursor:
        cursor.execute("INSERT INTO ventas (cliente, tipo_cafe, precio) VALUES (%s, %s, %s)", (cliente, tipo_cafe, precio))
    conexion.commit()
    conexion.close()
    return redirect('/')

if __name__ == '__main__':
    app.run()
EOF

# Crear index.html (Frontend Moderno)
cat << 'EOF' > templates/index.html
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Cafetería Local</title><script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-gray-100 min-h-screen p-8 font-sans">
    <div class="max-w-2xl mx-auto bg-white p-8 rounded-xl shadow-lg border-t-4 border-amber-600">
        <h1 class="text-3xl font-bold text-center text-amber-700 mb-6">☕ Cafetería (DB Local)</h1>
        <form action="/registrar" method="POST" class="space-y-4 mb-8">
            <input type="text" name="cliente" placeholder="Cliente" required class="w-full border p-2 rounded">
            <select name="tipo_cafe" required class="w-full border p-2 rounded"><option value="Latte">Latte</option><option value="Espresso">Espresso</option></select>
            <input type="number" step="0.01" name="precio" placeholder="Precio (Ej: 3.50)" required class="w-full border p-2 rounded">
            <button type="submit" class="w-full bg-amber-600 text-white font-bold py-2 rounded hover:bg-amber-700">Registrar Venta</button>
        </form>
        <h2 class="text-xl font-bold border-b pb-2 mb-4">Últimas Ventas</h2>
        <ul>{% for v in ventas %}<li class="flex justify-between border-b py-2"><span>{{v.cliente}} ({{v.tipo_cafe}})</span><span class="font-bold text-green-600">${{v.precio}}</span></li>{% endfor %}</ul>
    </div>
</body></html>
EOF

# 5. Configurar Entorno Virtual
echo "🐍 Instalando dependencias de Python..."
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# 6. Crear servicio Systemd para Gunicorn
cat << 'EOF' > /etc/systemd/system/cafeteria.service
[Unit]
Description=Gunicorn para Cafeteria
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/cafeteria
Environment="PATH=/var/www/cafeteria/venv/bin"
ExecStart=/var/www/cafeteria/venv/bin/gunicorn --workers 2 --bind unix:cafeteria.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOF

# 7. Configurar Nginx
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;
    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/cafeteria/cafeteria.sock;
    }
}
EOF

# 8. Reiniciar y encender servicios
systemctl daemon-reload
systemctl start cafeteria
systemctl enable cafeteria
systemctl restart nginx

echo "✅ ¡Despliegue Local Completo! Ingresa a la IP pública de tu EC2."