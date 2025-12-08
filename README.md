# AWS Lambda OpenTelemetry

A Toy Python AWS Lambda project with OpenTelemetry instrumentation for distributed tracing and metrics collection.

## Overview

This project demonstrates how to set up observability for AWS Lambda functions using OpenTelemetry. It includes:

  - An async Python Lambda handler using `uvloop` for high performance event loop management.
  - OpenTelemetry Collector and Python auto instrumentation via Lambda layers.
  - **Grafana Cloud Integration**: Configured to export traces, metrics, and logs directly to Grafana Cloud via OTLP.
  - Infrastructure as Code using Terraform/OpenTofu.

## Prerequisites

  - Python 3.14 
  - [uv](https://docs.astral.sh/uv/) - Python package manager 
  - [just](https://github.com/casey/just) - Command runner 
  - [OpenTofu](https://opentofu.org/) or Terraform 1.0+ 
  - AWS CLI configured with appropriate credentials
  - OpenTelemetry Lambda layers (see [opentelemetry-lambda](https://github.com/open-telemetry/opentelemetry-lambda))

## Installation

Install development dependencies:

```bash
just install
```

This runs `uv sync --all-extras --dev` to set up your local environment.

## Development

### Running Tests

```bash
# Run tests
just test

# Run tests with coverage
just test-cov
```



### Code Quality

```bash
# Format code with ruff
just fmt

# Lint code with ruff
just lint

# Type check with pyrefly
just typecheck
```



## Building & Deployment

### Package the Lambda

Create a deployment zip containing the Lambda code and dependencies:

```bash
just package
```

This creates `dist/lambda.zip` with all dependencies bundled.

### Inspect Package Contents

```bash
just inspect
```



### Infrastructure Management

The project uses OpenTofu (or Terraform) for infrastructure management:

```bash
# Initialize Terraform
just init [env]        # default: dev

# Preview changes
just plan [env]

# Apply changes
just apply [env]

# Destroy infrastructure
just destroy [env]
```

Supported environments: `dev`, `staging`, `prod`.

## Configuration

### Lambda Configuration

Key variables in `iac/variables.tf`:

| Variable                | Default                                     | Description                                                  |
|-------------------------|---------------------------------------------|--------------------------------------------------------------|
| `aws_region`            | `us-east-1`                                 | AWS deployment region                                        |
| `lambda_runtime`        | `python3.14`                                | Python runtime version                                       |
| `lambda_timeout`        | `30`                                        | Function timeout (seconds)                                   |
| `lambda_memory_size`    | `512`                                       | Memory allocation (MB)                                       |
| `lambda_handler`        | `o11ylambda.entrypoints.aws_lambda.handler` | Handler path                                                 |
| `otel_service_name`     | `aws-lambda-otel-service`                   | OpenTelemetry service name                                   |
| `grafana_auth_token`    | N/A                                         | Grafana Cloud OTLP auth token (set in `secrets.auto.tfvars`) |
| `grafana_otlp_endpoint` | N/A                                         | Grafana Cloud OTLP endpoint (set in `secrets.auto.tfvars`)   |


### OpenTelemetry Configuration

The Lambda is configured with these OpenTelemetry environment variables:

| Variable                              | Value                                | Description                   |
|---------------------------------------|--------------------------------------|-------------------------------|
| `AWS_LAMBDA_EXEC_WRAPPER`             | `/opt/otel-instrument`               | Enables auto-instrumentation  |
| `OTEL_SERVICE_NAME`                   | `{otel_service_name}-{env}`          | Service identifier            |
| `OTEL_EXPORTER_OTLP_ENDPOINT`         | `http://localhost:4318`              | Collector endpoint            |
| `OTEL_EXPORTER_OTLP_PROTOCOL`         | `http/protobuf`                      | Export protocol               |
| `OTEL_TRACES_SAMPLER`                 | `always_on`                          | Sampling strategy             |
| `OTEL_PROPAGATORS`                    | `tracecontext,baggage,b3`            | Context propagation formats   |
| `OTEL_TRACES_EXPORTER`                | `otlp`                               | Trace exporter                |
| `OTEL_METRICS_EXPORTER`               | `otlp`                               | Metrics exporter              |
| `OTEL_LOGS_EXPORTER`                  | `otlp`                               | Logs exporter                 |
| `OPENTELEMETRY_COLLECTOR_CONFIG_FILE` | `/var/task/resources/collector.yaml` | Collector config file path    |
| `GRAFANA_OTLP_ENDPOINT`               | see secrets                          | Grafana Cloud OTLP endpoint   |
| `GRAFANA_AUTH_TOKEN`                  | see secrets                          | Grafana Cloud OTLP auth token |

### Grafana Cloud & Collector Configuration

The OpenTelemetry Collector (`resources/collector.yaml`) is configured to export telemetry to **Grafana Cloud**.

To enable this, you must provide the following secrets in a file named `iac/secrets.auto.tfvars`:

```hcl
# iac/secrets.auto.tfvars
grafana_otlp_endpoint = "https://otlp-gateway-prod-us-east-0.grafana.net/otlp"
grafana_auth_token    = "Basic <YOUR_BASE64_ENCODED_TOKEN>"
```

The collector pipeline is configured as follows:

  - **Receivers**:
      - `otlp`: gRPC (`:4317`) and HTTP (`:4318`)
      - `telemetryapi`: Captures AWS Lambda Platform events.
  - **Exporters**:
      - `otlphttp/grafana`: Sends data to the endpoint defined in your secrets.
      - `debug`: Detailed logging for troubleshooting.

## OpenTelemetry Lambda Layers

This project requires two Lambda layers:

1.  **OpenTelemetry Collector Layer** - Runs the OTel Collector as a Lambda extension 
2.  **OpenTelemetry Python Layer** - Provides Python auto-instrumentation 

Build these from the [opentelemetry-lambda](https://github.com/open-telemetry/opentelemetry-lambda) submodule and update the paths in `iac/variables.tf` if necessary:

```hcl
variable "otel_collector_layer_path" {
  default = "../opentelemetry-lambda/collector/build/opentelemetry-collector-layer-amd64.zip"
}

variable "otel_python_layer_path" {
  default = "../opentelemetry-lambda/python/src/build/opentelemetry-python-layer.zip"
}
```

## Handler Details

The Lambda handler (`src/o11ylambda/entrypoints/aws_lambda.py`) features basic scaffolding with:

  - **uvloop**: High-performance event loop for async operations
  - **Cached event loop**: Reuses the event loop across warm invocations
  - **Graceful shutdown**: Handles `SIGINT` and `SIGTERM` signals

## Clean Up

Remove build artifacts:

```bash
just clean
```



## License

Apache 2.0