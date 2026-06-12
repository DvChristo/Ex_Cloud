#!/bin/bash
echo "🚀 Iniciando despliegue de Cafetería Pro (Base de Datos Local)..."

# 1. Actualización y dependencias
export NEEDRESTART_MODE=a
apt-get update && apt-get upgrade -y
apt-get install -y mariadb-server nginx python3-venv python3-pip

# 2. Encender MariaDB y esperar a que despierte (Evita el Error 500)
systemctl start mariadb
echo "⏳ Esperando a que el motor de base de datos inicie..."
sleep 5

# 3. Configurar Base de Datos MariaDB Local
echo "🗄️ Configurando esquema de base de datos..."
mysql -e "CREATE DATABASE IF NOT EXISTS cafeteria;"
mysql -e "CREATE USER IF NOT EXISTS 'cafeuser'@'localhost' IDENTIFIED BY 'ClaveLocal123';"
mysql -e "GRANT ALL PRIVILEGES ON cafeteria.* TO 'cafeuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "USE cafeteria; CREATE TABLE IF NOT EXISTS ventas (id INT AUTO_INCREMENT PRIMARY KEY, cliente VARCHAR(100) NOT NULL, tipo_cafe VARCHAR(50) NOT NULL, precio DECIMAL(6, 2) NOT NULL, fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 4. Crear estructura
mkdir -p /var/www/cafeteria/templates
cd /var/www/cafeteria

cat << EOF > requirements.txt
Flask==3.0.3
PyMySQL==1.1.0
gunicorn==21.2.0
EOF

# 5. Backend Python (Conectado a localhost)
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
        cursor.execute("SELECT * FROM ventas ORDER BY fecha DESC LIMIT 6")
        ventas = cursor.fetchall()
    conexion.close()
    return render_template('index.html', ventas=ventas)

@app.route('/registrar', methods=['POST'])
def registrar_venta():
    cliente = request.form['cliente']
    tipo_cafe = request.form['tipo_cafe']
    precio = float(request.form['precio'])
    
    conexion = conectar_db()
    try:
        with conexion.cursor() as cursor:
            cursor.execute("INSERT INTO ventas (cliente, tipo_cafe, precio) VALUES (%s, %s, %s)", (cliente, tipo_cafe, precio))
        conexion.commit()
        flash("Pedido procesado exitosamente en DB Local.", "success")
    except Exception as e:
        flash(f"Error en la base de datos: {str(e)}", "error")
    finally:
        conexion.close()
    return redirect('/')

if __name__ == '__main__':
    app.run()
EOF

# 6. Frontend Profesional
cat << 'EOF' > templates/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cafetería Pro | Local DB</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style> body { font-family: 'Inter', sans-serif; } </style>
</head>
<body class="bg-stone-100 text-stone-800 antialiased min-h-screen flex flex-col">

    <nav class="bg-stone-900 shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <div class="flex items-center gap-3">
                    <span class="text-2xl">☕</span>
                    <span class="font-bold text-xl text-white tracking-wider">AURORA <span class="text-amber-500">ROASTERS</span></span>
                </div>
                <div class="hidden md:block text-stone-400 text-sm font-medium">
                    Terminal Local (MariaDB)
                </div>
            </div>
        </div>
    </nav>

    <main class="flex-grow max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="mb-6 px-4 py-3 rounded-lg shadow-sm flex items-center gap-3 {% if category == 'success' %}bg-green-50 text-green-800 border-l-4 border-green-500{% else %}bg-red-50 text-red-800 border-l-4 border-red-500{% endif %}">
                        <span class="font-semibold">{{ '✓' if category == 'success' else '⚠' }}</span>
                        <p>{{ message }}</p>
                    </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div class="lg:col-span-5">
                <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-stone-200">
                    <div class="bg-amber-600 px-6 py-4">
                        <h2 class="text-lg font-bold text-white flex items-center gap-2"><span>📝</span> Nuevo Pedido</h2>
                    </div>
                    <form action="/registrar" method="POST" class="p-6 space-y-5">
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Nombre del Cliente</label>
                            <input type="text" name="cliente" required autocomplete="off" class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white" placeholder="Ej. María Pérez">
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Selección de Bebida</label>
                            <select name="tipo_cafe" required class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white cursor-pointer">
                                <option value="" disabled selected>Seleccione el café...</option>
                                <option value="Espresso Doble">☕ Espresso Doble</option>
                                <option value="Latte Macchiato">🥛 Latte Macchiato</option>
                                <option value="Cappuccino Vainilla">☁️ Cappuccino Vainilla</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Precio a Cobrar (USD)</label>
                            <input type="number" step="0.01" name="precio" required class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white" placeholder="3.50">
                        </div>
                        <button type="submit" class="w-full mt-4 bg-stone-900 hover:bg-amber-600 text-white font-bold py-3.5 px-4 rounded-lg transition-colors shadow-md">Procesar Pago ➔</button>
                    </form>
                </div>
            </div>

            <div class="lg:col-span-7">
                <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-stone-200 h-full flex flex-col">
                    <div class="px-6 py-5 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h2 class="text-lg font-bold text-stone-800 flex items-center gap-2">Monitor de Órdenes (Local)</h2>
                    </div>
                    <div class="p-6 flex-grow">
                        {% if ventas %}
                        <div class="space-y-4">
                            {% for venta in ventas %}
                            <div class="flex items-center justify-between p-4 rounded-xl border border-stone-100 hover:shadow-md transition-shadow bg-white">
                                <div class="flex items-center gap-4">
                                    <div class="bg-amber-100 text-amber-700 h-10 w-10 rounded-full flex items-center justify-center font-bold text-lg">
                                        {{ venta.cliente[0]|upper }}
                                    </div>
                                    <div>
                                        <p class="font-bold text-stone-800">{{ venta.cliente }}</p>
                                        <p class="text-sm text-stone-500">⏱ {{ venta.fecha.strftime('%H:%M') }} • <span class="font-medium text-amber-700">{{ venta.tipo_cafe }}</span></p>
                                    </div>
                                </div>
                                <div class="bg-green-50 text-green-700 font-bold px-4 py-1.5 rounded-lg border border-green-200">
                                    ${{ "%.2f"|format(venta.precio) }}
                                </div>
                            </div>
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="flex flex-col items-center justify-center h-full text-stone-400 space-y-3 py-12">
                            <span class="text-5xl">📭</span>
                            <p class="text-lg font-medium">Aún no hay ventas en la base local.</p>
                        </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </main>
</body>
</html>
EOF

# 7. Entorno Python
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# 8. Corrección de Permisos (Adiós Error 502)
chown -R www-data:www-data /var/www/cafeteria

# 9. Configuración del Servicio (Ejecutado como www-data)
cat << 'EOF' > /etc/systemd/system/cafeteria.service
[Unit]
Description=Gunicorn para Cafeteria Local Pro
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/cafeteria
Environment="PATH=/var/www/cafeteria/venv/bin"
ExecStart=/var/www/cafeteria/venv/bin/gunicorn --workers 2 --bind unix:cafeteria.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOF

# 10. Configuración Nginx
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

# 11. Reiniciar servicios
systemctl daemon-reload
systemctl restart mariadb
systemctl restart cafeteria
systemctl enable cafeteria
systemctl restart nginx

echo "✅ ¡Todo listo! Ingresa a la IP pública y presiona F5 o Ctrl+R."
