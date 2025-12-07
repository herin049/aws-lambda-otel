# AWS Lambda OpenTelemetry

A Toy Python AWS Lambda project with OpenTelemetry instrumentation for distributed tracing and metrics collection.

## Overview

This project demonstrates how to set up observability for AWS Lambda functions using OpenTelemetry. It includes:

- An async Python Lambda handler using `uvloop` for high performance event loop management
- OpenTelemetry Collector and Python auto instrumentation via Lambda layers
- Infrastructure as Code using Terraform/OpenTofu

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

Supported environments: `dev`, `staging`, `prod`

## Configuration

### Lambda Configuration

Key variables in `iac/variables.tf`:

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS deployment region |
| `lambda_runtime` | `python3.14` | Python runtime version |
| `lambda_timeout` | `30` | Function timeout (seconds) |
| `lambda_memory_size` | `512` | Memory allocation (MB) |
| `lambda_handler` | `o11ylambda.entrypoints.aws_lambda.handler` | Handler path |

### OpenTelemetry Configuration

The Lambda is configured with these OpenTelemetry environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `AWS_LAMBDA_EXEC_WRAPPER` | `/opt/otel-instrument` | Enables auto-instrumentation |
| `OTEL_SERVICE_NAME` | `aws-lambda-otel-service-{env}` | Service identifier |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` | Collector endpoint |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | Export protocol |
| `OTEL_TRACES_SAMPLER` | `always_on` | Sampling strategy |

### Collector Configuration

The OpenTelemetry Collector (`resources/collector.yaml`) is configured with:

- **Receivers**: OTLP over gRPC (`:4317`) and HTTP (`:4318`)
- **Exporters**: Debug exporter (for development)
- **Pipelines**: Traces and metrics

To export to a production backend, modify the exporters section in `collector.yaml`.

## OpenTelemetry Lambda Layers

This project requires two Lambda layers:

1. **OpenTelemetry Collector Layer** - Runs the OTel Collector as a Lambda extension
2. **OpenTelemetry Python Layer** - Provides Python auto-instrumentation

Build these from the [opentelemetry-lambda](https://github.com/open-telemetry/opentelemetry-lambda) repository and update the paths in `iac/variables.tf` if necessary:

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