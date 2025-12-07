resource "aws_lambda_function" "this" {
  filename         = var.lambda_zip_path
  function_name    = "${var.lambda_function_name}-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler
  architectures    = ["x86_64"]
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  layers = [
    aws_lambda_layer_version.otel_collector.arn,
    aws_lambda_layer_version.otel_python.arn,
  ]

  environment {
    variables = {
      ENVIRONMENT = var.environment

      # OpenTelemetry Configuration
      AWS_LAMBDA_EXEC_WRAPPER            = "/opt/otel-instrument"
      OTEL_SERVICE_NAME                  = "${var.otel_service_name}-${var.environment}"
      OTEL_TRACES_SAMPLER                = "always_on"
      OTEL_PROPAGATORS                   = "tracecontext"
      OTEL_EXPORTER_OTLP_ENDPOINT        = "http://localhost:4318"
      OTEL_EXPORTER_OTLP_PROTOCOL        = "http/protobuf"
      OTEL_TRACES_EXPORTER               = "otlp"
      OTEL_METRICS_EXPORTER              = "otlp"
      OTEL_LOGS_EXPORTER                 = "none"
      OPENTELEMETRY_COLLECTOR_CONFIG_URI = "/var/task/resources/collector.yaml"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}-${var.environment}"
  retention_in_days = 3
}
