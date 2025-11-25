#!/bin/bash
# Docker container monitoring script
# Detects abnormal CPU/Memory usage (crypto mining indicators)

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Thresholds
CPU_THRESHOLD=60  # Alert if CPU > 60%
MEM_THRESHOLD=80  # Alert if Memory > 80%
DURATION=10       # Monitor duration in seconds

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Docker Container Security Monitor                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi

# Function to get container stats
get_stats() {
    local container=$1
    docker stats --no-stream --format "{{.CPUPerc}},{{.MemPerc}},{{.MemUsage}}" $container
}

# Monitor all running containers
echo "Monitoring containers for $DURATION seconds..."
echo ""

containers=$(docker ps --format "{{.Names}}")

if [ -z "$containers" ]; then
    echo -e "${YELLOW}No running containers found${NC}"
    exit 0
fi

# Initial stats
for container in $containers; do
    stats=$(get_stats $container)
    cpu=$(echo $stats | cut -d',' -f1 | sed 's/%//')
    mem=$(echo $stats | cut -d',' -f2 | sed 's/%//')
    mem_usage=$(echo $stats | cut -d',' -f3)
    
    echo "Container: $container"
    echo "  CPU: ${cpu}%"
    echo "  Memory: ${mem}% ($mem_usage)"
    
    # Check for abnormal usage
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
        echo -e "  ${RED}⚠️  WARNING: High CPU usage! Possible crypto mining!${NC}"
        echo "  Checking processes..."
        docker top $container
        echo ""
    fi
    
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
        echo -e "  ${YELLOW}⚠️  WARNING: High memory usage!${NC}"
    fi
    
    echo ""
done

# Monitor over time
echo "Continuous monitoring (${DURATION}s)..."
echo ""

high_cpu_count=0

for i in $(seq 1 $DURATION); do
    for container in $containers; do
        stats=$(get_stats $container)
        cpu=$(echo $stats | cut -d',' -f1 | sed 's/%//')
        
        if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
            high_cpu_count=$((high_cpu_count + 1))
            echo -e "${RED}[$(date +%H:%M:%S)] $container: CPU ${cpu}% - ALERT!${NC}"
        fi
    done
    sleep 1
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Monitoring Summary                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ $high_cpu_count -gt $((DURATION / 2)) ]; then
    echo -e "${RED}⚠️  CRITICAL: Persistent high CPU detected!${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Stop suspicious containers:"
    echo "     docker stop <container-name>"
    echo ""
    echo "  2. Inspect container processes:"
    echo "     docker top <container-name>"
    echo ""
    echo "  3. Check container logs:"
    echo "     docker logs <container-name>"
    echo ""
    echo "  4. Scan for malware:"
    echo "     docker exec <container-name> ps aux"
    echo ""
    echo "  5. Rebuild with secure Dockerfile:"
    echo "     docker compose down"
    echo "     docker compose build --no-cache"
    echo "     docker compose up -d"
    echo ""
else
    echo -e "${GREEN}✓ No suspicious activity detected${NC}"
fi

# Show network connections
echo ""
echo "Network connections:"
for container in $containers; do
    echo ""
    echo "Container: $container"
    docker exec $container sh -c "netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo 'No netstat/ss available'" | head -10
done

# Show running processes
echo ""
echo "Running processes in containers:"
for container in $containers; do
    echo ""
    echo "Container: $container"
    docker top $container | head -10
done

echo ""
echo "Monitor complete. Run './docker-monitor.sh' again to re-check."
