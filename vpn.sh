#!/bin/bash

# Function to install OpenVPN
install_vpn() {
    pkg update && pkg upgrade -y # Update and upgrade Termux packages
    
    pkg install openvpn easy-rsa -y # Install OpenVPN and Easy-RSA
    
    easyrsa init-pki # Initialize the Easy-RSA directory structure
    
    echo "Building CA certificate..." # Build the Certificate Authority (CA) certificate
    easyrsa build-ca
    
    echo "Creating server certificate and key..." # Create a server certificate and key
    easyrsa gen-req server nopass
    easyrsa sign-req server server
    
    echo "Generating Diffie-Hellman parameters..." # Generate Diffie-Hellman parameters
    easyrsa gen-dh
    
    echo "Generating shared secret key..." # Generate a shared secret key for authentication
    openvpn --genkey --secret keys/ta.key
    
    echo "Creating OpenVPN configuration file..." # Create a sample OpenVPN configuration file
    cat > /etc/openvpn/server.conf << EOF
    port 1194
    proto udp
    dev tun
    ca ca.crt
    cert server.crt
    key server.key
    dh dh.pem
    server 10.8.0.0 255.255.255.0
    ifconfig-pool-persist ipp.txt
    push "redirect-gateway def1 bypass-dhcp"
    push "dhcp-option DNS 208.67.222.222"
    push "dhcp-option DNS 208.67.220.220"
    keepalive 10 120
    cipher AES-256-CBC
    user nobody
    group nogroup
    persist-key
    persist-tun
    status openvpn-status.log
    verb 3
EOF
    echo "Starting OpenVPN server..."   # Start the OpenVPN server
    openvpn --config /etc/openvpn/server.conf --daemon
    pkg install screen -y
echo "VPN setup completed. Please check the logs for any issues."
echo "Please re-run"
exit

}






# Function to display connection stats
display_stats() {
    screen -dmS vpn_stats bash -c "tail -f /var/log/openvpn/openvpn-status.log"
}

# Function to start the VPN
start_vpn() {
    openvpn --config /etc/openvpn/server.conf --daemon
}

# Function to stop the VPN
stop_vpn() {
    killall openvpn
}

# Main menu
while true; do
    clear
    echo "Menu"
    echo " "
    echo "1. Install VPN"
    echo "2. Start VPN"
    echo "3. Stop VPN"
    echo "5. Exit"
    echo " "
    read -p "Make Number Selection: " choice

    case $choice in
        1)
            echo "Installing VPN..."
            install_vpn
            ;;
        2)
            echo "Starting VPN..."
            start_vpn
            display_stats
            ;;
        3)
            echo "Stopping VPN..."
            stop_vpn
            ;;
        5)
            exit 0
            ;;
        *)
            echo "Invalid selection. Please try again."
            ;;
    esac
done
