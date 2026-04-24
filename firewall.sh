#!/bin/bash

# ─────────────────────────────────────────────
#  Firewall Manager — UFW Interactive Tool
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Run as root: sudo bash firewall.sh${RESET}"
        exit 1
    fi
}

header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════╗"
    echo "║        🔥 Firewall Port Manager          ║"
    echo "║              UFW Controller              ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${RESET}"
    STATUS=$(ufw status | head -1)
    if echo "$STATUS" | grep -q "active"; then
        echo -e "  Firewall: ${GREEN}● ACTIVE${RESET}"
    else
        echo -e "  Firewall: ${RED}● INACTIVE${RESET}"
    fi
    echo ""
}

pause() {
    echo ""
    read -rp "  Press Enter to continue..."
}

show_status() {
    header
    echo -e "${BOLD}  Current Firewall Rules:${RESET}"
    echo "  ──────────────────────────────────────────"
    ufw status verbose 2>/dev/null | sed 's/^/  /'
    pause
}

open_port() {
    header
    echo -e "${BOLD}  Open a Port${RESET}"
    echo "  ──────────────────────────────────────────"
    echo ""
    read -rp "  Port number (e.g. 8080) or range (e.g. 8000:8100): " PORT
    [[ -z "$PORT" ]] && echo -e "${RED}  No port entered.${RESET}" && pause && return

    echo ""
    echo -e "  Protocol:"
    echo "    1) TCP"
    echo "    2) UDP"
    echo "    3) Both (TCP+UDP)"
    read -rp "  Choose [1-3, default=1]: " PROTO_CHOICE

    case "$PROTO_CHOICE" in
        2) PROTO="udp" ;;
        3) PROTO="any" ;;
        *) PROTO="tcp" ;;
    esac

    echo ""
    echo -e "  Allow from:"
    echo "    1) Any IP (0.0.0.0/0)"
    echo "    2) Specific IP"
    echo "    3) IP Range / Subnet (e.g. 192.168.1.0/24)"
    read -rp "  Choose [1-3, default=1]: " SRC_CHOICE

    case "$SRC_CHOICE" in
        2)
            read -rp "  Enter IP address: " SRC_IP
            [[ -z "$SRC_IP" ]] && echo -e "${RED}  No IP entered.${RESET}" && pause && return
            ;;
        3)
            read -rp "  Enter subnet (e.g. 192.168.1.0/24): " SRC_IP
            [[ -z "$SRC_IP" ]] && echo -e "${RED}  No subnet entered.${RESET}" && pause && return
            ;;
        *)
            SRC_IP="any"
            ;;
    esac

    echo ""
    # Build and run the rule
    if [[ "$SRC_IP" == "any" ]]; then
        if [[ "$PROTO" == "any" ]]; then
            ufw allow "$PORT"
        else
            ufw allow "$PORT/$PROTO"
        fi
    else
        if [[ "$PROTO" == "any" ]]; then
            ufw allow from "$SRC_IP" to any port "${PORT%%:*}"
            [[ "$PORT" == *:* ]] && echo -e "${YELLOW}  Note: IP-specific rules use single ports. For ranges, add rules per port.${RESET}"
        else
            ufw allow from "$SRC_IP" to any port "${PORT%%:*}" proto "$PROTO"
        fi
    fi

    echo -e "\n  ${GREEN}✔ Rule added: Port $PORT ($PROTO) from ${SRC_IP}${RESET}"
    pause
}

close_port() {
    header
    echo -e "${BOLD}  Close / Delete a Port Rule${RESET}"
    echo "  ──────────────────────────────────────────"
    echo ""
    echo -e "${YELLOW}  Current rules (numbered):${RESET}"
    ufw status numbered 2>/dev/null | grep -E "^\[" | sed 's/^/  /'
    echo ""
    read -rp "  Enter rule number to DELETE (or press Enter to cancel): " RULE_NUM
    [[ -z "$RULE_NUM" ]] && return

    if ! [[ "$RULE_NUM" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}  Invalid number.${RESET}"
        pause
        return
    fi

    echo ""
    read -rp "  Confirm delete rule #$RULE_NUM? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
        yes | ufw delete "$RULE_NUM" 2>/dev/null
        echo -e "\n  ${GREEN}✔ Rule #$RULE_NUM deleted.${RESET}"
    else
        echo -e "  ${YELLOW}Cancelled.${RESET}"
    fi
    pause
}

block_ip() {
    header
    echo -e "${BOLD}  Block an IP / Subnet${RESET}"
    echo "  ──────────────────────────────────────────"
    echo ""
    read -rp "  Enter IP or subnet to BLOCK (e.g. 1.2.3.4 or 10.0.0.0/8): " BLOCK_IP
    [[ -z "$BLOCK_IP" ]] && echo -e "${RED}  No IP entered.${RESET}" && pause && return

    echo ""
    echo "  Direction:"
    echo "    1) Block INBOUND (incoming)"
    echo "    2) Block OUTBOUND (outgoing)"
    echo "    3) Block BOTH"
    read -rp "  Choose [1-3, default=1]: " DIR_CHOICE

    case "$DIR_CHOICE" in
        2)
            ufw deny out from any to "$BLOCK_IP"
            echo -e "\n  ${GREEN}✔ Blocked outbound to $BLOCK_IP${RESET}"
            ;;
        3)
            ufw deny in from "$BLOCK_IP"
            ufw deny out from any to "$BLOCK_IP"
            echo -e "\n  ${GREEN}✔ Blocked inbound and outbound for $BLOCK_IP${RESET}"
            ;;
        *)
            ufw deny in from "$BLOCK_IP"
            echo -e "\n  ${GREEN}✔ Blocked inbound from $BLOCK_IP${RESET}"
            ;;
    esac
    pause
}

allow_ip_range() {
    header
    echo -e "${BOLD}  Allow IP Range / Subnet for a Port${RESET}"
    echo "  ──────────────────────────────────────────"
    echo ""
    read -rp "  Enter subnet (e.g. 192.168.1.0/24 or 10.0.0.0/8): " SUBNET
    [[ -z "$SUBNET" ]] && echo -e "${RED}  No subnet entered.${RESET}" && pause && return

    read -rp "  Port number: " PORT
    [[ -z "$PORT" ]] && echo -e "${RED}  No port entered.${RESET}" && pause && return

    echo ""
    echo "  Protocol: 1) TCP  2) UDP  3) Both"
    read -rp "  Choose [1-3, default=1]: " PROTO_CHOICE
    case "$PROTO_CHOICE" in
        2) PROTO="udp" ;;
        3)
            ufw allow from "$SUBNET" to any port "$PORT" proto tcp
            ufw allow from "$SUBNET" to any port "$PORT" proto udp
            echo -e "\n  ${GREEN}✔ Allowed $SUBNET → port $PORT (TCP+UDP)${RESET}"
            pause
            return
            ;;
        *) PROTO="tcp" ;;
    esac

    ufw allow from "$SUBNET" to any port "$PORT" proto "$PROTO"
    echo -e "\n  ${GREEN}✔ Allowed $SUBNET → port $PORT ($PROTO)${RESET}"
    pause
}

toggle_firewall() {
    header
    STATUS=$(ufw status | head -1)
    if echo "$STATUS" | grep -q "active"; then
        echo -e "  Firewall is currently ${GREEN}ACTIVE${RESET}"
        read -rp "  Disable firewall? [y/N]: " CONFIRM
        if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
            ufw disable
            echo -e "\n  ${YELLOW}⚠ Firewall DISABLED${RESET}"
        fi
    else
        echo -e "  Firewall is currently ${RED}INACTIVE${RESET}"
        read -rp "  Enable firewall? [y/N]: " CONFIRM
        if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
            ufw --force enable
            echo -e "\n  ${GREEN}✔ Firewall ENABLED${RESET}"
        fi
    fi
    pause
}

reset_all() {
    header
    echo -e "${RED}${BOLD}  ⚠  RESET ALL RULES${RESET}"
    echo "  This will delete ALL firewall rules and disable UFW."
    echo "  SSH (port 22) will be re-added automatically."
    echo ""
    read -rp "  Type 'RESET' to confirm: " CONFIRM
    if [[ "$CONFIRM" == "RESET" ]]; then
        ufw --force reset
        ufw allow ssh
        ufw --force enable
        echo -e "\n  ${GREEN}✔ Reset complete. SSH (22) re-allowed. Firewall enabled.${RESET}"
    else
        echo -e "  ${YELLOW}Cancelled.${RESET}"
    fi
    pause
}

quick_open() {
    header
    echo -e "${BOLD}  Quick Open Common Ports${RESET}"
    echo "  ──────────────────────────────────────────"
    echo ""
    echo "    1)  22   — SSH"
    echo "    2)  80   — HTTP"
    echo "    3)  443  — HTTPS"
    echo "    4)  3306 — MySQL"
    echo "    5)  5432 — PostgreSQL"
    echo "    6)  6379 — Redis"
    echo "    7)  27017— MongoDB"
    echo "    8)  3000 — Node.js / React"
    echo "    9)  4000 — Custom App"
    echo "   10)  8080 — Alt HTTP"
    echo ""
    read -rp "  Choose [1-10]: " Q

    declare -A PORTS=(
        [1]="22/tcp" [2]="80/tcp" [3]="443/tcp"
        [4]="3306/tcp" [5]="5432/tcp" [6]="6379/tcp"
        [7]="27017/tcp" [8]="3000/tcp" [9]="4000/tcp" [10]="8080/tcp"
    )

    if [[ -n "${PORTS[$Q]}" ]]; then
        ufw allow "${PORTS[$Q]}"
        echo -e "\n  ${GREEN}✔ Opened port ${PORTS[$Q]}${RESET}"
    else
        echo -e "  ${RED}Invalid choice.${RESET}"
    fi
    pause
}

# ─── Main Menu ───────────────────────────────
check_root

while true; do
    header
    echo -e "  ${BOLD}Main Menu${RESET}"
    echo "  ──────────────────────────────────────────"
    echo "   1)  Show current rules & status"
    echo "   2)  Open a port"
    echo "   3)  Close / delete a rule"
    echo "   4)  Block an IP or subnet"
    echo "   5)  Allow IP range for a port"
    echo "   6)  Quick open common ports"
    echo "   7)  Enable / Disable firewall"
    echo "   8)  Reset ALL rules"
    echo "   9)  Exit"
    echo ""
    read -rp "  Choose [1-9]: " CHOICE

    case "$CHOICE" in
        1) show_status ;;
        2) open_port ;;
        3) close_port ;;
        4) block_ip ;;
        5) allow_ip_range ;;
        6) quick_open ;;
        7) toggle_firewall ;;
        8) reset_all ;;
        9) echo -e "\n  ${CYAN}Goodbye!${RESET}\n"; exit 0 ;;
        *) echo -e "\n  ${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
done
