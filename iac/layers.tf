resource "aws_lambda_layer_version" "otel_collector" {
  filename            = var.otel_collector_layer_path
  layer_name          = "${var.lambda_function_name}-otel-collector-${var.environment}"
  compatible_runtimes = [var.lambda_runtime]
  source_code_hash    = filebase64sha256(var.otel_collector_layer_path)

  description = "OpenTelemetry Collector Lambda Extension"
}

resource "aws_lambda_layer_version" "otel_python" {
  filename            = var.otel_python_layer_path
  layer_name          = "${var.lambda_function_name}-otel-python-${var.environment}"
  compatible_runtimes = [var.lambda_runtime]
  source_code_hash    = filebase64sha256(var.otel_python_layer_path)

  description = "OpenTelemetry Python Auto-instrumentation"
}