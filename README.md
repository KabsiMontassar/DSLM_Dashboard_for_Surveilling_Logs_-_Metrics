# DSLM: Dashboard for Surveilling Logs & Metrics

## Complete End-to-End Observability Stack

## Live Demo Features

**Centralized Logging** - Loki aggregates logs from all services with structured search  
**Metrics Collection** - Prometheus scrapes system and application metrics  
**Distributed Tracing** - Tempo collects OpenTelemetry traces with detailed spans  
**Unified Dashboards** - Grafana correlates logs, metrics & traces in one view  
**Alert Management** - Alertmanager routes notifications with deduplication  
**Sample Application** - Live Node.js app generating real observability data  
**Professional Demo Data** - Realistic microservices traces for demonstration

## Quick Start

### One-Command Setup

```bash
# Clone and setup everything
git clone https://github.com/KabsiMontassar/DSLM_Dashboard_for_Surveilling_Logs_-_Metrics.git
cd DSLM_Dashboard_for_Surveilling_Logs_-_Metrics
./setup.sh setup
```

### Manual Setup

```bash
# 1. Fix permissions (Linux/Mac)
chmod +x setup.sh fix-permissions.sh generate_demo_data.sh send_test_trace.sh

# 2. Start all services
docker compose up -d

# 3. Generate demo data (optional)
./generate_demo_data.sh
```

## Access Your Observability Stack

| Service          | URL                     | Credentials | Purpose                            |
| ---------------- | ----------------------- | ----------- | ---------------------------------- |
| **Grafana**      | <http://localhost:3000> | admin/admin | Unified dashboards & visualization |
| **Prometheus**   | <http://localhost:9090> | -           | Metrics collection & querying      |
| **Loki**         | <http://localhost:3100> | -           | Log aggregation & search           |
| **Tempo**        | <http://localhost:3200> | -           | Distributed tracing                |
| **Alertmanager** | <http://localhost:9093> | -           | Alert routing & management         |
| **Sample App**   | <http://localhost:3001> | -           | Demo application generating data   |

## Live Demo Scenarios

### 1. Logs Analysis (Loki)

```bash
# View application logs in Grafana → Explore → Loki
{app="dslm-sample-app"}
{app="dslm-sample-app"} |= "error"
{job="cadvisor"}
```

### 2. Metrics Monitoring (Prometheus)

```bash
# View metrics in Grafana → Explore → Prometheus
http_requests_total{job="sample-app"}
rate(http_requests_total[5m])
node_cpu_seconds_total
container_memory_usage_bytes
```

### 3. Distributed Tracing (Tempo)

```bash
# View traces in Grafana → Explore → Tempo
{service.name="dslm-sample-app"}
{service.name="payment-gateway"}
{http.status_code=500}
{cloud.region="us-east-1"}
{duration>100ms}
```

### 4. Generate Live Data

```bash
# Create application traces
curl http://localhost:3001/
curl http://localhost:3001/api/work
curl http://localhost:3001/api/error

# Generate professional demo data
./generate_demo_data.sh
```

### Alternative Setup

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Fix permissions (if needed)
./fix-permissions.sh

# 3. Start services (use either command format)
docker compose up -d    # Newer format
# OR
docker-compose up -d    # Older format
```

## Setup Instructions

1. **Clone the repository**
2. **Configure Environment**: Edit `.env` with your settings
3. **Fix Permissions**: Run `./fix-permissions.sh` (Linux/Mac) or the manual commands
4. **Start Services**: Run `docker-compose up -d`
5. **Access Grafana**: <http://localhost:3000> (admin/admin)

## Environment Configuration

Sensitive data and configurable settings are managed through the `.env` file:

- **Grafana Credentials**: Admin username and password
- **SMTP Settings**: For email notifications from Alertmanager
- **Webhook URLs**: For external integrations (Slack, PagerDuty)
- **Service Ports**: Configurable to avoid conflicts
- **Integration Keys**: API keys for third-party services

**Important**: Never commit the `.env` file to version control. The repository includes a `.gitignore` file that excludes sensitive files.

## Port Configuration

Default ports are configured to avoid common conflicts, but can be customized in `.env`:

- Prometheus: 9090
- Grafana: 3000
- Loki: 3100
- Tempo: 3200/4317/4318
- Alertmanager: 9093
- Node Exporter: 9100
- cAdvisor: 8080
- Sample App: 3001

If you encounter port conflicts, update the corresponding variables in `.env`.

## Configuration

All configurations are in the `configs/` directory:

- `prometheus/`: Prometheus config and alert rules
- `loki/`: Loki config
- `tempo/`: Tempo config
- `alertmanager/`: Alertmanager config
- `grafana/`: Grafana provisioning and dashboards

Data is persisted in the `data/` directory.

## Automation Scripts

The project includes automation scripts to simplify setup and management:

### `setup.sh` - Complete Setup Script

```bash
./setup.sh setup     # Full automated setup
./setup.sh perms     # Fix permissions only
./setup.sh start     # Start services
./setup.sh stop      # Stop services
./setup.sh restart   # Restart services
./setup.sh status    # Check service status
./setup.sh logs      # Show logs
./setup.sh cleanup   # Remove containers and volumes
```

### `fix-permissions.sh` - Permission Fix Script

```bash
./fix-permissions.sh  # Fix all directory permissions
```

### Manual Permission Commands (Linux/Mac)

```bash
sudo chown -R 472:472 ./data/grafana       # Grafana
sudo chown -R 65534:65534 ./data/prometheus # Prometheus
sudo chown -R 10001:10001 ./data/loki       # Loki
sudo chown -R 10001:10001 ./data/tempo      # Tempo
chmod -R 755 ./data/
```

## Prerequisites

- **Docker** (version 20.10 or later)
- **Docker Compose** (plugin or standalone)
- **sudo access** (for directory creation and permissions)
- **Git** (for cloning the repository)

## Troubleshooting

### Permission Issues

If you encounter permission errors during setup:

```bash
# Option 1: Run setup as root
sudo ./setup.sh setup

# Option 2: Create directories manually first
sudo mkdir -p data/{prometheus,grafana,loki,tempo}
sudo mkdir -p data/grafana/{dashboards,plugins}
sudo chown -R $(whoami):$(whoami) data/

# Then run setup
./setup.sh setup
```

### Docker Compose Version Issues

The setup script automatically detects your Docker Compose version:

- `docker compose` (newer plugin format)
- `docker-compose` (older standalone format)

### Port Conflicts

If you get port binding errors, update the ports in your `.env` file:

```bash
PROMETHEUS_PORT=9091    # Instead of 9090
GRAFANA_PORT=3001       # Instead of 3000
# etc...
```

## Integration with Microservices

To integrate your microservices:

1. **Metrics**: Expose metrics on `/metrics` endpoint, Prometheus will scrape them.
2. **Logs**: Send logs to Loki via HTTP or use Promtail.
3. **Traces**: Use OpenTelemetry SDK to send traces to Tempo.

## Sample Application

The project includes a sample Node.js application that demonstrates the full observability stack in action. The sample app generates logs, metrics, and traces that are automatically collected and visualized in Grafana.

### Features Demonstrated

- **HTTP Request Logging**: All requests are logged with Winston and sent to Loki
- **Custom Metrics**: Prometheus metrics for request count, duration, and active connections
- **Distributed Tracing**: OpenTelemetry traces sent to Tempo with span attributes
- **Error Simulation**: Simulated errors for testing alert scenarios
- **Periodic Activity**: Background tasks that generate logs and traces every 30 seconds

### Sample App Endpoints

- `GET /` - Homepage with basic tracing
- `GET /api/health` - Health check endpoint
- `GET /api/work` - Simulated work with nested tracing
- `GET /api/error` - Simulated error for testing
- `GET /metrics` - Prometheus metrics endpoint

### Accessing the Sample App

Once services are running:

```bash
# Access the sample application
curl http://localhost:3001/

# View metrics
curl http://localhost:3001/metrics

# Check health
curl http://localhost:3001/api/health
```

### Viewing Data in Grafana

1. **Logs**: Go to Grafana → Explore → Select Loki datasource → Query: `{app="dslm-sample-app"}`
2. **Metrics**: Go to Grafana → Explore → Select Prometheus datasource → Query: `http_requests_total`
3. **Traces**: Go to Grafana → Explore → Select Tempo datasource → Search for traces

### Sample Dashboard

The included sample dashboard (`configs/grafana/dashboards/sample-dashboard.json`) shows:

- HTTP request metrics and trends
- Error rates and response times
- Log volume and patterns
- Trace spans and dependencies
