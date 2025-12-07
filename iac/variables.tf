variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "aws-lambda-otel"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 512
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package zip file"
  type        = string
  default     = "../dist/lambda.zip"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.14"
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "o11ylambda.entrypoints.aws_lambda.handler"
}

variable "otel_collector_layer_path" {
  description = "Path to the OpenTelemetry Collector Lambda layer zip file"
  type        = string
  default     = "../opentelemetry-lambda/collector/build/opentelemetry-collector-layer-amd64.zip"
}

variable "otel_python_layer_path" {
  description = "Path to the OpenTelemetry Python Lambda layer zip file"
  type        = string
  default     = "../opentelemetry-lambda/python/src/build/opentelemetry-python-layer.zip"
}

variable "otel_service_name" {
  description = "Service name for OpenTelemetry instrumentation"
  type        = string
  default     = "aws-lambda-otel-service"
}

variable "otel_exporter_endpoint" {
  description = "OpenTelemetry exporter endpoint"
  type        = string
  default     = ""
}
