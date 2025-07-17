#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables configurables
DEFAULT_SOCKS_PORT=8789
DEFAULT_HTTP_PORT=8118

# @RealStrategy
# https://t.me/RealHackRWAM
# https://www.youtube.com/@zonatodoreal
# 170720251220AM

mostrar_menu() {
    clear
    echo -e "${GREEN}"
    echo "  ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗"
    echo "  ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝"
    echo "  ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ "
    echo "  ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  "
    echo "  ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   "
    echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
    echo -e "${NC}"
    echo -e "${BLUE}=== MENÚ DE CONFIGURACIÓN DE PROXY ==="
    echo -e "${NC}"
    echo -e "1. ${YELLOW}Instalar y configurar proxy automáticamente${NC}"
    echo -e "2. ${YELLOW}Configurar puertos manualmente${NC}"
    echo -e "3. ${YELLOW}Ver información de conexión actual${NC}"
    echo -e "4. ${YELLOW}Reiniciar servicios proxy${NC}"
    echo -e "5. ${YELLOW}Desinstalar todo${NC}"
    echo -e "6. ${YELLOW}Salir${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -n "Seleccione una opción [1-6]: "
}

configurar_puertos() {
    echo -e "\n${GREEN}Configuración de puertos${NC}"
    echo -e "${YELLOW}--------------------------------${NC}"
    read -p "Introduzca el puerto SOCKS5 [por defecto $DEFAULT_SOCKS_PORT]: " SOCKS_PORT
    SOCKS_PORT=${SOCKS_PORT:-$DEFAULT_SOCKS_PORT}
    
    read -p "Introduzca el puerto HTTP [por defecto $DEFAULT_HTTP_PORT]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-$DEFAULT_HTTP_PORT}
    
    echo -e "\n${GREEN}Puertos configurados:${NC}"
    echo -e "SOCKS5: ${YELLOW}$SOCKS_PORT${NC}"
    echo -e "HTTP: ${YELLOW}$HTTP_PORT${NC}"
    echo -e "${YELLOW}--------------------------------${NC}"
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

instalar_proxy() {
    echo -e "\n${GREEN}Iniciando instalación...${NC}"
    
    # Actualizar sistema
    echo -e "${YELLOW}Actualizando paquetes del sistema...${NC}"
    sudo apt update && sudo apt upgrade -y
    
    # --- 1. Instalar Dante (SOCKS5) ---
    echo -e "${YELLOW}Instalando Dante (SOCKS5)...${NC}"
    sudo apt install -y dante-server
    
    # Configurar Dante
    echo -e "${YELLOW}Configurando Dante en puerto $SOCKS_PORT...${NC}"
    cat <<EOF | sudo tee /etc/danted.conf
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = $SOCKS_PORT
external: $(curl -s ifconfig.me)
method: none  # Sin autenticación
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
EOF
    
    # Reiniciar Dante
    sudo systemctl restart danted && sudo systemctl enable danted
    
    # --- 2. Instalar Privoxy (HTTP-to-SOCKS) ---
    echo -e "${YELLOW}Instalando Privoxy (HTTP-to-SOCKS)...${NC}"
    sudo apt install -y privoxy
    
    # Configurar Privoxy
    echo -e "${YELLOW}Configurando Privoxy en puerto $HTTP_PORT...${NC}"
    cat <<EOF | sudo tee /etc/privoxy/config
listen-address  0.0.0.0:$HTTP_PORT
forward-socks5 / 127.0.0.1:$SOCKS_PORT .
hide-incoming-headers     Proxy-Connection Keep-Alive
header-sanitize          Via X-Forwarded-For
EOF
    
    # Reiniciar Privoxy
    sudo systemctl restart privoxy && sudo systemctl enable privoxy
    
    # --- 3. Abrir puertos en el firewall ---
    echo -e "${YELLOW}Configurando firewall...${NC}"
    sudo ufw allow $HTTP_PORT/tcp   # Privoxy (HTTP)
    sudo ufw allow $SOCKS_PORT/tcp  # Dante (SOCKS5)
    sudo ufw --force enable
    
    mostrar_conexion
}

mostrar_conexion() {
    IP_PUBLICA=$(curl -s ifconfig.me)
    echo -e "\n${GREEN}✅ Proxy configurado correctamente!${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo -e "${YELLOW}🔹 Configuración para Windows:${NC}"
    echo -e "   - IP: ${GREEN}$IP_PUBLICA${NC}"
    echo -e "   - Puerto HTTP: ${GREEN}$HTTP_PORT${NC}"
    echo -e "   - Puerto SOCKS5: ${GREEN}$SOCKS_PORT${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo -e "${YELLOW}📌 Nota:${NC} Este proxy redirige tráfico HTTP/HTTPS a SOCKS5."
    echo -e "      Para usar SOCKS5 directamente (ej: en navegadores), usa el puerto ${GREEN}$SOCKS_PORT${NC}."
    echo -e "${BLUE}====================================${NC}"
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

reiniciar_servicios() {
    echo -e "\n${YELLOW}Reiniciando servicios proxy...${NC}"
    sudo systemctl restart danted
    sudo systemctl restart privoxy
    echo -e "${GREEN}Servicios reiniciados correctamente!${NC}"
    sleep 2
}

desinstalar_todo() {
    echo -e "\n${RED}⚠️ Advertencia: Esto desinstalará todos los componentes del proxy.${NC}"
    read -p "¿Está seguro que desea continuar? [s/N]: " confirmacion
    
    if [[ $confirmacion =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Desinstalando componentes...${NC}"
        
        # Detener y desinstalar Dante
        sudo systemctl stop danted
        sudo apt remove --purge -y dante-server
        
        # Detener y desinstalar Privoxy
        sudo systemctl stop privoxy
        sudo apt remove --purge -y privoxy
        
        # Eliminar configuraciones
        sudo rm -f /etc/danted.conf
        sudo rm -f /etc/privoxy/config
        
        # Cerrar puertos en el firewall
        sudo ufw delete allow $HTTP_PORT/tcp
        sudo ufw delete allow $SOCKS_PORT/tcp
        
        echo -e "${GREEN}Desinstalación completada.${NC}"
    else
        echo -e "${GREEN}Operación cancelada.${NC}"
    fi
    sleep 2
}

# Inicializar puertos con valores por defecto
SOCKS_PORT=$DEFAULT_SOCKS_PORT
HTTP_PORT=$DEFAULT_HTTP_PORT

# Menú principal
while true; do
    mostrar_menu
    read opcion
    
    case $opcion in
        1) 
            instalar_proxy
            ;;
        2) 
            configurar_puertos
            ;;
        3) 
            mostrar_conexion
            ;;
        4) 
            reiniciar_servicios
            ;;
        5) 
            desinstalar_todo
            ;;
        6) 
            echo -e "\n${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Opción inválida. Intente nuevamente.${NC}"
            sleep 2
            ;;
    esac
done
