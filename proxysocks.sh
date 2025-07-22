#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables configurables
DEFAULT_SOCKS_PORT=1080
DEFAULT_HTTP_PORT=3128
SOCKS_PORT=""
HTTP_PORT=""
SOCKS_AUTH=""
HTTP_AUTH=""
IP_PUBLICA=$(curl -s ifconfig.me)

# @RealStrategy
# https://t.me/RealHackRWAM
# https://www.youtube.com/@zonatodoreal
# 170720251220AM

# Banner
mostrar_banner() {
    clear
    echo -e "${GREEN}"
    echo "  ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗"
    echo "  ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝"
    echo "  ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ "
    echo "  ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  "
    echo "  ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   "
    echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
    echo -e "${NC}"
}

# Menú principal
mostrar_menu_principal() {
    echo -e "${BLUE}=== MENÚ PRINCIPAL ==="
    echo -e "${NC}"
    echo -e "1. ${YELLOW}Instalar y configurar proxy automáticamente${NC}"
    echo -e "2. ${YELLOW}Instalación y configuración manual (seguro)${NC}"
    echo -e "3. ${YELLOW}Configurar puertos manualmente${NC}"
    echo -e "4. ${YELLOW}Ver información de conexión actual${NC}"
    echo -e "5. ${YELLOW}Reiniciar servicios proxy${NC}"
    echo -e "6. ${YELLOW}Desinstalar todo${NC}"
    echo -e "7. ${YELLOW}Salir${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo -n "Seleccione una opción [1-7]: "
}

# Submenú para instalación manual
mostrar_submenu_manual() {
    echo -e "${CYAN}=== INSTALACIÓN MANUAL ==="
    echo -e "${NC}"
    echo -e "1. ${YELLOW}Instalar proxy SOCKS5${NC}"
    echo -e "2. ${YELLOW}Instalar proxy HTTP${NC}"
    echo -e "3. ${YELLOW}Volver al menú principal${NC}"
    echo -e "${CYAN}=========================${NC}"
    echo -n "Seleccione una opción [1-3]: "
}

# Función para mostrar resultados de configuración
mostrar_resultado_configuracion() {
    local tipo=$1
    local puerto=$2
    local auth=$3
    
    echo -e "\n${GREEN}✅ Configuración completada!${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo -e "${YELLOW}🔹 Configuración ${tipo}:${NC}"
    echo -e "   - IP PROXY: ${GREEN}$IP_PUBLICA${NC}"
    echo -e "   - PUERTO: ${GREEN}$puerto${NC}"
    
    if [[ -n "$auth" ]]; then
        echo -e "   - USUARIO: ${GREEN}$(echo $auth | cut -d: -f1)${NC}"
        echo -e "   - CONTRASEÑA: ${GREEN}$(echo $auth | cut -d: -f2)${NC}"
    else
        echo -e "   - AUTENTICACIÓN: ${RED}Desactivada${NC}"
    fi
    
    echo -e "${BLUE}====================================${NC}"
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

# Instalación de SOCKS5 con autenticación corregida
instalar_socks5() {
    echo -e "\n${GREEN}Instalando proxy SOCKS5...${NC}"
    
    # Preguntar por puerto
    read -p "Digite el puerto que va usar [por defecto $DEFAULT_SOCKS_PORT]: " SOCKS_PORT
    SOCKS_PORT=${SOCKS_PORT:-$DEFAULT_SOCKS_PORT}
    
    # Preguntar por autenticación
    read -p "¿Desea agregar usuario y contraseña? (y/n): " auth_choice
    if [[ $auth_choice =~ ^[Yy]$ ]]; then
        read -p "Ingrese el nombre de usuario: " username
        read -p "Ingrese la contraseña: " password
        SOCKS_AUTH="$username:$password"
    else
        SOCKS_AUTH=""
    fi
    
    # Actualizar sistema
    sudo apt update && sudo apt upgrade -y
    
    # Instalar Dante
    sudo apt install -y dante-server
    
    # Configurar Dante con sintaxis actualizada
    echo -e "${YELLOW}Configurando Dante en puerto $SOCKS_PORT...${NC}"
    cat <<EOF | sudo tee /etc/danted.conf
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = $SOCKS_PORT
external: $IP_PUBLICA
socksmethod: $( [[ -n "$SOCKS_AUTH" ]] && echo "username" || echo "none" )
clientmethod: none
EOF

    # Configuración de reglas con autenticación si es necesario
    if [[ -n "$SOCKS_AUTH" ]]; then
        cat <<EOF | sudo tee -a /etc/danted.conf
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    username: $(echo $SOCKS_AUTH | cut -d: -f1) password: $(echo $SOCKS_AUTH | cut -d: -f2)
}
EOF
    else
        cat <<EOF | sudo tee -a /etc/danted.conf
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
EOF
    fi

    # Reglas de paso
    cat <<EOF | sudo tee -a /etc/danted.conf
pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    protocol: tcp udp
}
EOF

    # Reiniciar Dante
    sudo systemctl restart danted && sudo systemctl enable danted
    sudo ufw allow $SOCKS_PORT/tcp
    
    # Verificar servicio
    if ! systemctl is-active --quiet danted; then
        echo -e "${RED}Error: Dante no se ha iniciado correctamente${NC}"
        journalctl -u danted -b | tail -n 20
        exit 1
    fi
    
    # Mostrar resultados
    mostrar_resultado_configuracion "SOCKS5" "$SOCKS_PORT" "$SOCKS_AUTH"
    
    # Probar conexión SOCKS5
    echo -e "\n${YELLOW}Probando conexión SOCKS5...${NC}"
    if [[ -n "$SOCKS_AUTH" ]]; then
        AUTH_PARAM="--socks5 127.0.0.1:$SOCKS_PORT --proxy-user $(echo $SOCKS_AUTH | cut -d: -f1):$(echo $SOCKS_AUTH | cut -d: -f2)"
    else
        AUTH_PARAM="--socks5 127.0.0.1:$SOCKS_PORT"
    fi
    
    if curl $AUTH_PARAM -I https://www.google.com --connect-timeout 10 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión SOCKS5 exitosa${NC}"
    else
        echo -e "${RED}✗ No se pudo establecer conexión SOCKS5${NC}"
        echo -e "${YELLOW}Revisa los logs con: journalctl -u danted -b${NC}"
    fi
}

# Instalación de HTTP Proxy
instalar_http_proxy() {
    echo -e "\n${GREEN}Instalando proxy HTTP...${NC}"
    
    # Verificar si SOCKS5 está configurado
    if [[ -z "$SOCKS_PORT" ]]; then
        echo -e "${YELLOW}Advertencia: No se encontró configuración SOCKS5 previa.${NC}"
        read -p "¿Desea configurar un puerto SOCKS5 para el proxy HTTP? (y/n): " setup_socks
        if [[ $setup_socks =~ ^[Yy]$ ]]; then
            instalar_socks5
        else
            DEFAULT_SOCKS_FOR_HTTP=1080
            read -p "Ingrese el puerto SOCKS5 al que se conectará [por defecto $DEFAULT_SOCKS_FOR_HTTP]: " SOCKS_PORT
            SOCKS_PORT=${SOCKS_PORT:-$DEFAULT_SOCKS_FOR_HTTP}
        fi
    fi
    
    # Preguntar por puerto HTTP
    read -p "Digite el puerto que va usar [por defecto $DEFAULT_HTTP_PORT]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-$DEFAULT_HTTP_PORT}
    
    # Preguntar por autenticación
    read -p "¿Desea agregar usuario y contraseña? (y/n): " auth_choice
    if [[ $auth_choice =~ ^[Yy]$ ]]; then
        read -p "Ingrese el nombre de usuario: " username
        read -p "Ingrese la contraseña: " password
        HTTP_AUTH="$username:$password"
    else
        HTTP_AUTH=""
    fi
    
    # Actualizar sistema
    sudo apt update && sudo apt upgrade -y
    
    # Instalar Privoxy
    sudo apt install -y privoxy
    
    # Detener servicio primero
    sudo systemctl stop privoxy
    
    # Configurar Privoxy
    echo -e "${YELLOW}Configurando Privoxy en puerto $HTTP_PORT...${NC}"
    cat <<EOF | sudo tee /etc/privoxy/config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address  0.0.0.0:$HTTP_PORT
toggle  1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
forward-socks5 / 127.0.0.1:$SOCKS_PORT .
forwarded-connect-retries  0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 300
socket-timeout 300
permit-access  0.0.0.0/0
EOF

    # Configurar autenticación si es necesario
    if [[ -n "$HTTP_AUTH" ]]; then
        echo "admin-address 0.0.0.0:$((HTTP_PORT+10000))" | sudo tee -a /etc/privoxy/config
        echo "user-manual $HTTP_AUTH" | sudo tee -a /etc/privoxy/config
    fi

    # Configuración adicional importante
    echo "forward / ." | sudo tee -a /etc/privoxy/config
    
    # Reiniciar Privoxy
    sudo systemctl daemon-reload
    sudo systemctl restart privoxy
    sudo systemctl enable privoxy
    
    # Configurar firewall
    sudo ufw allow $HTTP_PORT/tcp
    
    # Verificar servicio
    if ! systemctl is-active --quiet privoxy; then
        echo -e "${RED}Error: Privoxy no se ha iniciado correctamente${NC}"
        journalctl -u privoxy -b | tail -n 20
        exit 1
    fi
    
    # Mostrar resultados
    mostrar_resultado_configuracion "HTTP" "$HTTP_PORT" "$HTTP_AUTH"
    
    # Probar conexión HTTP
    echo -e "\n${YELLOW}Probando conexión HTTP...${NC}"
    if [[ -n "$HTTP_AUTH" ]]; then
        AUTH_PARAM="-x http://127.0.0.1:$HTTP_PORT -U $(echo $HTTP_AUTH | cut -d: -f1):$(echo $HTTP_AUTH | cut -d: -f2)"
    else
        AUTH_PARAM="-x http://127.0.0.1:$HTTP_PORT"
    fi
    
    if curl $AUTH_PARAM -I https://www.google.com --connect-timeout 10 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión HTTP exitosa${NC}"
    else
        echo -e "${RED}✗ No se pudo establecer conexión HTTP${NC}"
        echo -e "${YELLOW}Revisa los logs con: journalctl -u privoxy -b${NC}"
    fi
}

# Configuración manual de puertos
configurar_puertos_manual() {
    echo -e "\n${GREEN}Configuración manual de puertos${NC}"
    echo -e "${YELLOW}--------------------------------${NC}"
    
    # Configurar puerto SOCKS5
    read -p "Introduzca el puerto SOCKS5 [por defecto $DEFAULT_SOCKS_PORT]: " SOCKS_PORT
    SOCKS_PORT=${SOCKS_PORT:-$DEFAULT_SOCKS_PORT}
    
    # Configurar puerto HTTP
    read -p "Introduzca el puerto HTTP [por defecto $DEFAULT_HTTP_PORT]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-$DEFAULT_HTTP_PORT}
    
    echo -e "\n${GREEN}Puertos configurados:${NC}"
    echo -e "SOCKS5: ${YELLOW}$SOCKS_PORT${NC}"
    echo -e "HTTP: ${YELLOW}$HTTP_PORT${NC}"
    echo -e "${YELLOW}--------------------------------${NC}"
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

# Mostrar información de conexión
mostrar_conexion() {
    echo -e "\n${GREEN}Información de conexión actual${NC}"
    echo -e "${BLUE}====================================${NC}"
    
    if [[ -n "$SOCKS_PORT" ]]; then
        echo -e "${CYAN}Proxy SOCKS5:${NC}"
        echo -e "   - IP: ${GREEN}$IP_PUBLICA${NC}"
        echo -e "   - Puerto: ${GREEN}$SOCKS_PORT${NC}"
        if [[ -n "$SOCKS_AUTH" ]]; then
            echo -e "   - Usuario: ${GREEN}$(echo $SOCKS_AUTH | cut -d: -f1)${NC}"
            echo -e "   - Contraseña: ${GREEN}$(echo $SOCKS_AUTH | cut -d: -f2)${NC}"
        else
            echo -e "   - Autenticación: ${RED}Desactivada${NC}"
        fi
        echo -e "${BLUE}--------------------------------${NC}"
    fi
    
    if [[ -n "$HTTP_PORT" ]]; then
        echo -e "${CYAN}Proxy HTTP:${NC}"
        echo -e "   - IP: ${GREEN}$IP_PUBLICA${NC}"
        echo -e "   - Puerto: ${GREEN}$HTTP_PORT${NC}"
        if [[ -n "$HTTP_AUTH" ]]; then
            echo -e "   - Usuario: ${GREEN}$(echo $HTTP_AUTH | cut -d: -f1)${NC}"
            echo -e "   - Contraseña: ${GREEN}$(echo $HTTP_AUTH | cut -d: -f2)${NC}"
        else
            echo -e "   - Autenticación: ${RED}Desactivada${NC}"
        fi
        echo -e "${BLUE}--------------------------------${NC}"
    fi
    
    if [[ -z "$SOCKS_PORT" && -z "$HTTP_PORT" ]]; then
        echo -e "${RED}No hay proxies configurados actualmente.${NC}"
    fi
    
    echo -e "${BLUE}====================================${NC}"
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

# Reiniciar servicios
reiniciar_servicios() {
    echo -e "\n${YELLOW}Reiniciando servicios proxy...${NC}"
    
    if [[ -n "$SOCKS_PORT" ]]; then
        sudo systemctl restart danted
        echo -e "SOCKS5 reiniciado en puerto ${GREEN}$SOCKS_PORT${NC}"
    fi
    
    if [[ -n "$HTTP_PORT" ]]; then
        sudo systemctl restart privoxy
        echo -e "HTTP Proxy reiniciado en puerto ${GREEN}$HTTP_PORT${NC}"
    fi
    
    echo -e "${GREEN}Servicios reiniciados correctamente!${NC}"
    sleep 2
}

# Desinstalar todo
desinstalar_todo() {
    echo -e "\n${RED}⚠️ Advertencia: Esto desinstalará todos los componentes del proxy.${NC}"
    read -p "¿Está seguro que desea continuar? [s/N]: " confirmacion
    
    if [[ $confirmacion =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Desinstalando componentes...${NC}"
        
        # Detener y desinstalar Dante
        if [[ -n "$SOCKS_PORT" ]]; then
            sudo systemctl stop danted
            sudo systemctl disable danted
            sudo ufw delete allow $SOCKS_PORT/tcp
        fi
        sudo apt remove --purge -y dante-server
        
        # Detener y desinstalar Privoxy
        if [[ -n "$HTTP_PORT" ]]; then
            sudo systemctl stop privoxy
            sudo systemctl disable privoxy
            sudo ufw delete allow $HTTP_PORT/tcp
        fi
        sudo apt remove --purge -y privoxy
        
        # Limpiar configuraciones
        sudo rm -f /etc/danted.conf
        sudo rm -f /etc/privoxy/config
        SOCKS_PORT=""
        HTTP_PORT=""
        SOCKS_AUTH=""
        HTTP_AUTH=""
        
        echo -e "${GREEN}Desinstalación completada.${NC}"
    else
        echo -e "${GREEN}Operación cancelada.${NC}"
    fi
    sleep 2
}

# Instalación automática
instalar_automatico() {
    echo -e "\n${GREEN}Iniciando instalación automática...${NC}"
    
    # Configurar puertos por defecto
    SOCKS_PORT=$DEFAULT_SOCKS_PORT
    HTTP_PORT=$DEFAULT_HTTP_PORT
    
    # Actualizar sistema
    sudo apt update && sudo apt upgrade -y
    
    # Instalar Dante (SOCKS5)
    sudo apt install -y dante-server
    
    # Configurar Dante
    cat <<EOF | sudo tee /etc/danted.conf
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = $SOCKS_PORT
external: $IP_PUBLICA
socksmethod: none
clientmethod: none
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    protocol: tcp udp
}
EOF
    
    sudo systemctl restart danted && sudo systemctl enable danted
    sudo ufw allow $SOCKS_PORT/tcp
    
    # Instalar Privoxy (HTTP)
    sudo apt install -y privoxy
    
    # Configurar Privoxy
    cat <<EOF | sudo tee /etc/privoxy/config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address  0.0.0.0:$HTTP_PORT
toggle  1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
forward-socks5 / 127.0.0.1:$SOCKS_PORT .
forwarded-connect-retries  0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 300
socket-timeout 300
permit-access  0.0.0.0/0
forward / .
EOF
    
    sudo systemctl restart privoxy && sudo systemctl enable privoxy
    sudo ufw allow $HTTP_PORT/tcp
    
    # Mostrar resultados
    echo -e "\n${GREEN}✅ Configuración automática completada!${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo -e "${CYAN}Proxy SOCKS5:${NC}"
    echo -e "   - IP: ${GREEN}$IP_PUBLICA${NC}"
    echo -e "   - Puerto: ${GREEN}$SOCKS_PORT${NC}"
    echo -e "   - Autenticación: ${RED}Desactivada${NC}"
    echo -e "${BLUE}--------------------------------${NC}"
    echo -e "${CYAN}Proxy HTTP:${NC}"
    echo -e "   - IP: ${GREEN}$IP_PUBLICA${NC}"
    echo -e "   - Puerto: ${GREEN}$HTTP_PORT${NC}"
    echo -e "   - Autenticación: ${RED}Desactivada${NC}"
    echo -e "${BLUE}====================================${NC}"
    
    # Probar conexiones
    echo -e "\n${YELLOW}Probando conexiones...${NC}"
    
    # Probar SOCKS5
    if curl --socks5 127.0.0.1:$SOCKS_PORT -I https://www.google.com --connect-timeout 10 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión SOCKS5 exitosa${NC}"
    else
        echo -e "${RED}✗ Falló conexión SOCKS5${NC}"
    fi
    
    # Probar HTTP
    if curl -x http://127.0.0.1:$HTTP_PORT -I https://www.google.com --connect-timeout 10 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexión HTTP proxy exitosa${NC}"
    else
        echo -e "${RED}✗ Falló conexión HTTP proxy${NC}"
    fi
    
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
}

# Menú principal
while true; do
    mostrar_banner
    mostrar_menu_principal
    read opcion_principal
    
    case $opcion_principal in
        1) 
            instalar_automatico
            ;;
        2) 
            while true; do
                mostrar_banner
                mostrar_submenu_manual
                read opcion_manual
                
                case $opcion_manual in
                    1) 
                        instalar_socks5
                        ;;
                    2) 
                        instalar_http_proxy
                        ;;
                    3) 
                        break
                        ;;
                    *) 
                        echo -e "\n${RED}Opción inválida. Intente nuevamente.${NC}"
                        sleep 2
                        ;;
                esac
            done
            ;;
        3) 
            configurar_puertos_manual
            ;;
        4) 
            mostrar_conexion
            ;;
        5) 
            reiniciar_servicios
            ;;
        6) 
            desinstalar_todo
            ;;
        7) 
            echo -e "\n${GREEN}Saliendo...${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Opción inválida. Intente nuevamente.${NC}"
            sleep 2
            ;;
    esac
done
