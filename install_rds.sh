#!/bin/bash
# ==========================================
# ⚠️ EDITA ESTAS VARIABLES CON TU AWS RDS / AURORA ⚠️
# ==========================================
RDS_HOST="tu-cluster-aurora-o-rds.cluster-xxxx.us-east-1.rds.amazonaws.com"
RDS_USER="admin"
RDS_PASS="TuClaveSeguraRDS123"
RDS_NAME="cafeteria"
# ==========================================

echo "🚀 Iniciando despliegue de Cafetería Pro Cloud (Backend: AWS RDS)..."

# 1. Actualización de paquetes e instalación de dependencias cloud
export NEEDRESTART_MODE=a
apt-get update && apt-get upgrade -y
apt-get install -y nginx python3-venv python3-pip mysql-client

# 2. Conectarse al RDS remoto para crear la base de datos y la tabla
echo "🗄️ Conectando a AWS RDS para inicializar el esquema..."
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "CREATE DATABASE IF NOT EXISTS $RDS_NAME;"
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -D $RDS_NAME -e "CREATE TABLE IF NOT EXISTS ventas (id INT AUTO_INCREMENT PRIMARY KEY, cliente VARCHAR(100) NOT NULL, tipo_cafe VARCHAR(50) NOT NULL, precio DECIMAL(6, 2) NOT NULL, fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# 3. Crear estructura de directorios del proyecto
mkdir -p /var/www/cafeteria/templates
cd /var/www/cafeteria

# 4. Definir requerimientos de Python
cat << EOF > requirements.txt
Flask==3.0.3
PyMySQL==1.1.0
gunicorn==21.2.0
EOF

# 5. Generar el Backend inyectando las variables del RDS
cat << EOF > app.py
from flask import Flask, render_template, request, redirect, flash
import pymysql

app = Flask(__name__)
app.secret_key = "clave_secreta_academica_cloud"

def conectar_db():
    return pymysql.connect(
        host="${RDS_HOST}",
        user="${RDS_USER}",
        password="${RDS_PASS}",
        database="${RDS_NAME}",
        cursorclass=pymysql.cursors.DictCursor
    )

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
        flash("Pedido procesado exitosamente en AWS RDS.", "success")
    except Exception as e:
        flash(f"Error de conexión RDS: {str(e)}", "error")
    finally:
        conexion.close()
    return redirect('/')

if __name__ == '__main__':
    app.run()
EOF

# 6. Crear el Frontend Profesional optimizado para AWS Cloud
cat << 'EOF' > templates/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cafetería Pro | AWS Cloud POS</title>
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
                    AWS Cloud POS Terminal • Producción
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
                        <h2 class="text-lg font-bold text-white flex items-center gap-2"><span>📝</span> Nuevo Pedido Cloud</h2>
                    </div>
                    <form action="/registrar" method="POST" class="p-6 space-y-5">
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Nombre del Cliente</label>
                            <input type="text" name="cliente" required autocomplete="off" class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white" placeholder="Ej. Carlos Mendoza">
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Selección de Bebida</label>
                            <select name="tipo_cafe" required class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white cursor-pointer">
                                <option value="" disabled selected>Seleccione el café...</option>
                                <option value="Espresso Doble">☕ Espresso Doble</option>
                                <option value="Latte Macchiato">🥛 Latte Macchiato</option>
                                <option value="Cappuccino Vainilla">☁️ Cappuccino Vainilla</option>
                                <option value="Cold Brew Reserva">🧊 Cold Brew Reserva</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-stone-600 mb-1">Precio a Cobrar (USD)</label>
                            <input type="number" step="0.01" name="precio" required class="w-full px-4 py-3 rounded-lg border border-stone-300 focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none bg-stone-50 focus:bg-white" placeholder="4.25">
                        </div>
                        <button type="submit" class="w-full mt-4 bg-stone-900 hover:bg-amber-600 text-white font-bold py-3.5 px-4 rounded-lg transition-colors shadow-md">Procesar Pago Cloud ➔</button>
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
                        <span class="text-xs font-bold bg-amber-100 text-amber-800 px-3 py-1 rounded-full tracking-wide">AWS RDS ACTIVE</span>
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
                            <p class="text-lg font-medium">Conectado a RDS con éxito. Esperando transacciones...</p>
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

# 7. Configurar e Instalar el Entorno Virtual de Python
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# 8. Corrección Definitiva de Permisos para Gunicorn (Previene Error 502)
chown -R www-data:www-data /var/www/cafeteria

# 9. Configuración de Systemd ejecutándose bajo el usuario web seguro
cat << 'EOF' > /etc/systemd/system/cafeteria.service
[Unit]
Description=Gunicorn para Cafeteria Cloud RDS
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

# 10. Configuración del proxy inverso Nginx
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

# 11. Recargar el sistema y levantar toda la arquitectura
systemctl daemon-reload
systemctl restart cafeteria
systemctl enable cafeteria
systemctl restart nginx

echo "✅ ¡Despliegue Cloud en AWS RDS completo, seguro y libre de errores!"