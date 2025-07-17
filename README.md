# ProxySocks 🧦🔐

Script en Bash para instalar, configurar y administrar automáticamente servidores proxy **SOCKS5** (Dante) y **HTTP** (Privoxy) en sistemas **Ubuntu**. Diseñado para facilitar la creación de un proxy funcional con redirección de tráfico, menú interactivo y control total desde la terminal.

---

## 🧰 Características

- ✅ Instalación automática de Dante (SOCKS5) y Privoxy (HTTP-to-SOCKS)
- ⚙️ Configuración personalizada de puertos
- 🔁 Reinicio de servicios desde el menú
- 🔒 Reglas de firewall gestionadas automáticamente
- 🧹 Desinstalación completa con un clic
- 📋 Menú visual amigable en la terminal
- 🌐 Muestra tu IP pública y puertos activos

---

## 📸 Vista del menú

```bash
  ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
  ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
  ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
  ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
  ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

=== MENÚ DE CONFIGURACIÓN DE PROXY ===

1. Instalar y configurar proxy automáticamente
2. Configurar puertos manualmente
3. Ver información de conexión actual
4. Reiniciar servicios proxy
5. Desinstalar todo
6. Salir 
```

## 🚀 Instalación
- git clone https://github.com/tuusuario/ProxySocks.git
- cd ProxySocks
- chmod +x proxysocks.sh
- ./proxysocks.sh

⚠️ Ejecuta con privilegios de sudo. Compatible con sistemas Ubuntu y derivados.

## 🌐 Detalles técnicos
- Dante SOCKS5: Red de proxy sin autenticación por defecto
- Privoxy: Redirecciona tráfico HTTP/HTTPS al puerto SOCKS5 local (127.0.0.1)
- Firewall (ufw): Abre automáticamente los puertos necesarios configurados por el usuario

## 🔧 Requisitos
- Ubuntu 18.04 / 20.04 / 22.04+
- Acceso sudo
- Herramientas básicas: curl, ufw, apt

## 📤 Desinstalación
Desde el menú, elige la opción 5. 
Desinstalar todo para eliminar:
- Servicios: Dante y Privoxy
- Configuraciones en /etc/
- Reglas de firewall abiertas
- Limpieza total del sistema proxy

## 👤 Autor
@RealStrategy
- 📨 Telegram: [@RealHackRWAM](https://t.me/RealHackRWAM)
- 📺 YouTube: [@zonatodoreal](https://www.youtube.com/@zonatodoreal)


