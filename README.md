# Claude Code OpenTelemetry Monitoring

This repository provides a complete monitoring stack for Claude Code telemetry data using OpenTelemetry, Prometheus, and Grafana.

![Claude Code Metrics Dashboard](dashboard-screenshot.png)

## Features

✅ **Real-time Claude Code Metrics:**
- Active time tracking (CLI vs user time)
- Cost monitoring by model (Haiku, Sonnet, etc.)
- Token usage analysis (input/output/cache)
- Session count tracking

✅ **Pre-configured Dashboard:**
- Professional Grafana dashboard with time series charts and stat panels
- Anonymous access enabled (no login required)
- Set as homepage for immediate visibility

✅ **Production-ready Stack:**
- OpenTelemetry Collector for data collection
- Prometheus for metrics storage
- Grafana for visualization

## Architecture

The monitoring stack consists of three components:

- **OpenTelemetry Collector**: Receives telemetry data from Claude Code and exports metrics to Prometheus
- **Prometheus**: Scrapes and stores metrics from the OTEL Collector
- **Grafana**: Visualizes metrics with Prometheus as the data source

## Quick Start

### 1. Start the monitoring stack

```bash
git clone https://github.com/alileza/claude-otlp-example.git
cd claude-otlp-example
docker-compose up -d
```

This will start:
- OpenTelemetry Collector on ports 4317 (gRPC) and 4318 (HTTP)
- Prometheus on port 9099
- Grafana on port 3009

### 2. Configure Claude Code telemetry

Set the following environment variables to enable Claude Code to send telemetry to the OTEL Collector:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_SERVICE_NAME="claude-code"
export OTEL_RESOURCE_ATTRIBUTES="service.name=claude-code,service.version=1.0.0"
```

### 3. Start using Claude Code

Use Claude Code as normal - telemetry will automatically be collected and sent to the monitoring stack.

### 4. View the dashboard

Open **http://localhost:3009** in your browser - no login required! The Claude Code metrics dashboard will load immediately as the homepage.

## Available Metrics

The dashboard displays the following Claude Code telemetry:

- `claude_code_claude_code_active_time_seconds_total` - Time spent actively using Claude Code
- `claude_code_claude_code_cost_usage_USD_total` - Cost breakdown by model
- `claude_code_claude_code_session_count_total` - Number of CLI sessions started
- `claude_code_claude_code_token_usage_tokens_total` - Token usage by type (input/output/cache)

## Access Points

- **Grafana Dashboard**: http://localhost:3009 (no login required)
- **Prometheus**: http://localhost:9099
- **OTEL Collector metrics**: http://localhost:8889/metrics

## Environment Variables Explained

- `CLAUDE_CODE_ENABLE_TELEMETRY=1`: Enables telemetry collection in Claude Code
- `OTEL_METRICS_EXPORTER=otlp`: Configures OpenTelemetry to export metrics via OTLP protocol
- `OTEL_LOGS_EXPORTER=otlp`: Configures OpenTelemetry to export logs via OTLP protocol
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`: Uses gRPC protocol for OTLP communication
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`: Points to the OTEL Collector gRPC endpoint
- `OTEL_SERVICE_NAME="claude-code"`: Sets the service name for telemetry data
- `OTEL_RESOURCE_ATTRIBUTES`: Additional resource attributes for better metric identification

## Configuration Files

- `otel-collector.yml`: OpenTelemetry Collector configuration
- `prometheus.yml`: Prometheus scraping configuration
- `docker-compose.yml`: Container orchestration
- `grafana/provisioning/datasources/prometheus.yml`: Grafana datasource configuration

## Data Flow

1. Claude Code generates telemetry data when `CLAUDE_CODE_ENABLE_TELEMETRY=1` is set
2. Telemetry data is sent to OTEL Collector via gRPC (port 4317)
3. OTEL Collector processes the data and exposes metrics on port 8889
4. Prometheus scrapes metrics from OTEL Collector every 30 seconds
5. Grafana queries Prometheus to display metrics and create dashboards