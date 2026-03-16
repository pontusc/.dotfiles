# OpenVPN Shortcuts
# OpenVPN configuration is located at /etc/openvpn/client/alchemy.conf
alias vpn-up='sudo systemctl start openvpn-client@alchemy && echo "VPN Starting..." && sleep 2 && curl -s https://ifconfig.me && echo ""'
alias vpn-down='sudo systemctl stop openvpn-client@alchemy && echo "VPN Stopped."'
alias vpn-stat='systemctl status openvpn-client@alchemy'
