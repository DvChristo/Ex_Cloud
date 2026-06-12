#!/bin/bash
# ==========================================
# ⚠️ EDITA ESTAS VARIABLES CON TU AWS AURORA/RDS ⚠️
# ==========================================
RDS_HOST="cafeteria-cluster.cluster-xxxx.us-east-1.rds.amazonaws.com"
RDS_USER="admin"
RDS_PASS="TuClaveRDS123"
RDS_NAME="cafeteria"
# ==========================================

echo "🚀 Iniciando despliegue de Cafetería Pro Cloud (Aurora/RDS)..."

# 1. Actualización y preparación del entorno
export NEEDRESTART_MODE=a
apt-get update && apt-get upgrade -y
apt-get install -y nginx python3-venv python3-pip mysql-client

# 2. Configurar la Base de Datos Remota
echo "🗄️ Conectando a AWS RDS/Aurora para preparar el esquema..."
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "CREATE DATABASE IF NOT EXISTS $RDS_NAME;"
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -D $RDS_NAME -e "CREATE TABLE IF NOT EXISTS ventas (id INT AUTO_INCREMENT PRIMARY KEY, cliente VARCHAR(100) NOT NULL, tipo_cafe VARCHAR(50) NOT NULL, precio DECIMAL(6, 2) NOT NULL, fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 3. Crear estructura de directorios
mkdir -p /var/www/cafeteria/templates
cd /var/www/cafeteria

# 4. Crear Dependencias
cat << EOF > requirements.txt
Flask==3.0.3
PyMySQL==1.1.0
gunicorn==21.2.0
EOF

# 5. Crear Backend en Python
cat << EOF > app.py
from flask import Flask, render_template, request, redirect, flash
import pymysql

app = Flask(__name__)
app.secret_key = "clave_secreta_academica"

def conectar_db():
    return pymysql.connect(host="${RDS_HOST}", user="${RDS_USER}", password="${RDS_PASS}", database="${RDS_NAME}", cursorclass=pymysql.cursors.DictCursor)

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
        flash("Pedido procesado exitosamente.", "success")
    except Exception as e:
        flash(f"Error en la base de datos: {str(e)}", "error")
    finally:
        conexion.close()
    return redirect('/')

if __name__ == '__main__':
    app.run()
EOF

# 6. Crear Frontend Profesional (HTML + Tailwind CSS)
cat << 'EOF' > templates/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aurora Roasters | POS System</title>
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
                    AWS Cloud POS Terminal • En vivo
                </div>
            </div>
        </div>
    </nav>

    <main class="flex-grow max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
        
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="mb-6 px-4 py-3 rounded-lg shadow-sm flex items-center gap-3 {% if category == 'success' %}bg-green-50 text-green-800 border-l-4 border-green-500{% else %}bg-red-50 text-red-800 border-l-4 border-red-500{% endif %} animate-pulse">
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
                        <h2 class="text-lg font-bold text-white flex items-center gap-2">
                            <span>📝</span> Nuevo Pedido
                        </h2>
                    </div>
                    <form action="/registrar" method="POST" class="p-6 space-y-5">
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Nombre del Cliente</label>
                            <input type="text" name="cliente" required autocomplete="off" class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none bg-stone-50 focus:bg-white" placeholder="Ej. María Pérez">
                        </div>
                        
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Selección de Bebida</label>
                            <div class="relative">
                                <select name="tipo_cafe" required class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none appearance-none bg-stone-50 focus:bg-white cursor-pointer">
                                    <option value="" disabled selected>Seleccione el tipo de café...</option>
                                    <option value="Espresso Doble">☕ Espresso Doble</option>
                                    <option value="Latte Macchiato">🥛 Latte Macchiato</option>
                                    <option value="Cappuccino Vainilla">☁️ Cappuccino Vainilla</option>
                                    <option value="Flat White">🇦🇺 Flat White</option>
                                    <option value="Cold Brew">🧊 Cold Brew Reserva</option>
                                </select>
                                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-stone-500">
                                    ▼
                                </div>
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Precio a Cobrar (USD)</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                    <span class="text-stone-500 font-bold">$</span>
                                </div>
                                <input type="number" step="0.01" name="precio" required class="w-full pl-8 pr-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all outline-none bg-stone-50 focus:bg-white" placeholder="0.00">
                            </div>
                        </div>

                        <button type="submit" class="w-full mt-4 bg-stone-900 hover:bg-amber-600 text-white font-bold py-3.5 px-4 rounded-lg transition-colors duration-300 shadow-md flex justify-center items-center gap-2">
                            <span>Procesar Pago</span> <span>➔</span>
                        </button>
                    </form>
                </div>
            </div>

            <div class="lg:col-span-7">
                <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-stone-200 h-full flex flex-col">
                    <div class="px-6 py-5 border-b border-stone-100 flex justify-between items-center bg-stone-50">
                        <h2 class="text-lg font-bold text-stone-800 flex items-center gap-2">
                            <span class="relative flex h-3 w-3">
                              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                              <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                            </span>
                            Monitor de Órdenes Recientes
                        </h2>
                        <span class="text-xs font-semibold bg-stone-200 text-stone-600 px-3 py-1 rounded-full uppercase tracking-wide">Base de Datos: AWS RDS</span>
                    </div>
                    
                    <div class="p-6 flex-grow">
                        {% if ventas %}
                        <div class="space-y-4">
                            {% for venta in ventas %}
                            <div class="flex items-center justify-between p-4 rounded-xl border border-stone-100 hover:shadow-md transition-shadow bg-white group">
                                <div class="flex items-center gap-4">
                                    <div class="bg-amber-100 text-amber-700 h-10 w-10 rounded-full flex items-center justify-center font-bold text-lg group-hover:bg-amber-600 group-hover:text-white transition-colors">
                                        {{ venta.cliente[0]|upper }}
                                    </div>
                                    <div>
                                        <p class="font-bold text-stone-800">{{ venta.cliente }}</p>
                                        <p class="text-sm text-stone-500 flex items-center gap-1">
                                            <span>⏱ {{ venta.fecha.strftime('%H:%M') }}</span> • 
                                            <span class="font-medium text-amber-700">{{ venta.tipo_cafe }}</span>
                                        </p>
                                    </div>
                                </div>
                                <div class="bg-green-50 border border-green-200 text-green-700 font-bold px-4 py-1.5 rounded-lg">
                                    ${{ "%.2f"|format(venta.precio) }}
                                </div>
                            </div>
                            {% endfor %}
                        </div>
                        {% else %}
                        <div class="flex flex-col items-center justify-center h-full text-stone-400 space-y-3 py-12">
                            <span class="text-5xl">📭</span>
                            <p class="text-lg font-medium">El sistema está esperando la primera orden.</p>
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

# 7. Configurar Entorno Python
echo "🐍 Instalando entorno virtual Python..."
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# ==========================================
# 🛠️ CORRECCIÓN DEL ERROR 502 (PERMISOS)
# ==========================================
echo "🔒 Ajustando permisos de seguridad web..."
# Transferimos la propiedad completa de la carpeta al usuario web de Nginx
chown -R www-data:www-data /var/www/cafeteria

# 8. Crear servicio Systemd (Ahora ejecutándose como www-data)
cat << 'EOF' > /etc/systemd/system/cafeteria.service
[Unit]
Description=Gunicorn para Cafeteria Pro
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

# 9. Configurar Proxy Nginx
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

# 10. Iniciar la magia
systemctl daemon-reload
systemctl start cafeteria
systemctl enable cafeteria
systemctl restart nginx

echo "¡Despliegue Pro Completo y Libre de Errores! Ingresa a la IP pública del EC2."
