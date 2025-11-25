#!/bin/bash
# CloseFriend Server Management - Quick Commands

function show_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         CloseFriend Server Management Console              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1)  Check Service Status"
    echo "2)  Restart Service"
    echo "3)  Stop Service"
    echo "4)  Start Service"
    echo "5)  View Live Logs"
    echo "6)  View Error Logs"
    echo "7)  View Access Logs"
    echo "8)  Test API Endpoint"
    echo "9)  Database Backup"
    echo "10) Update Application"
    echo "11) Check System Resources"
    echo "12) View Database Info"
    echo "13) Restart Nginx"
    echo "14) Edit Configuration"
    echo "15) View All Logs (last 50 lines)"
    echo "0)  Exit"
    echo ""
    echo -n "Enter choice: "
}

function press_enter() {
    echo ""
    echo -n "Press Enter to continue..."
    read
}

while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            echo ""
            sudo systemctl status closefriend
            press_enter
            ;;
        2)
            echo ""
            echo "Restarting service..."
            sudo systemctl restart closefriend
            echo "✓ Service restarted"
            sudo systemctl status closefriend --no-pager | head -10
            press_enter
            ;;
        3)
            echo ""
            echo "Stopping service..."
            sudo systemctl stop closefriend
            echo "✓ Service stopped"
            press_enter
            ;;
        4)
            echo ""
            echo "Starting service..."
            sudo systemctl start closefriend
            echo "✓ Service started"
            sudo systemctl status closefriend --no-pager | head -10
            press_enter
            ;;
        5)
            echo ""
            echo "Live logs (Ctrl+C to exit):"
            echo ""
            sudo journalctl -u closefriend -f
            ;;
        6)
            echo ""
            echo "Error logs (last 50 lines):"
            echo ""
            sudo tail -50 /var/log/closefriend/error.log
            press_enter
            ;;
        7)
            echo ""
            echo "Access logs (last 50 lines):"
            echo ""
            sudo tail -50 /var/log/closefriend/access.log
            press_enter
            ;;
        8)
            echo ""
            echo "Testing API endpoint..."
            curl -s http://localhost:8000/openapi.json | head -5
            echo ""
            echo ""
            if curl -s http://localhost:8000/openapi.json > /dev/null; then
                echo "✓ API is responding correctly"
            else
                echo "✗ API is not responding"
            fi
            press_enter
            ;;
        9)
            echo ""
            echo "Creating database backup..."
            if [ -f /usr/local/bin/backup-db.sh ]; then
                sudo /usr/local/bin/backup-db.sh
            elif [ -f /var/www/closefriend/backup-db.sh ]; then
                sudo /var/www/closefriend/backup-db.sh
            else
                echo "Backup script not found"
            fi
            press_enter
            ;;
        10)
            echo ""
            if [ -f /var/www/closefriend/update-server.sh ]; then
                /var/www/closefriend/update-server.sh
            else
                echo "Update script not found"
            fi
            press_enter
            ;;
        11)
            echo ""
            echo "=== System Resources ==="
            echo ""
            echo "CPU and Memory:"
            top -bn1 | head -20
            echo ""
            echo "Disk Usage:"
            df -h | grep -E '^/dev/'
            echo ""
            echo "Active Ports:"
            sudo netstat -tlnp | grep -E ':(80|443|8000|5432)'
            press_enter
            ;;
        12)
            echo ""
            echo "=== Database Information ==="
            echo ""
            if [ -f /var/www/closefriend/.credentials ]; then
                cat /var/www/closefriend/.credentials
            else
                echo "Database: closefriend"
                sudo -u postgres psql -c "\l" | grep closefriend
                echo ""
                sudo -u postgres psql -d closefriend -c "\dt"
            fi
            press_enter
            ;;
        13)
            echo ""
            echo "Testing Nginx configuration..."
            sudo nginx -t
            echo ""
            echo "Restarting Nginx..."
            sudo systemctl restart nginx
            echo "✓ Nginx restarted"
            press_enter
            ;;
        14)
            echo ""
            echo "Opening configuration file..."
            nano /var/www/closefriend/.env
            echo ""
            echo "Restarting service to apply changes..."
            sudo systemctl restart closefriend
            echo "✓ Changes applied"
            press_enter
            ;;
        15)
            echo ""
            echo "=== Application Logs (last 50 lines) ==="
            sudo journalctl -u closefriend -n 50 --no-pager
            press_enter
            ;;
        0)
            echo ""
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid option. Please try again."
            sleep 1
            ;;
    esac
done
