# Configuration variables
python_version := "3.14"
package_dir := "package"
dist_dir := "dist"
iac_dir := "iac"
zip_name := "lambda.zip"
terraform_bin := "tofu"

# Load environment variables from .env file
set dotenv-load := true

# Default recipe to display available commands
default:
    @just --list

# Package the Lambda deployment zip
package:
    #!/usr/bin/env bash
    set -e
    echo "Cleaning previous builds..."
    rm -rf {{package_dir}} {{dist_dir}}

    echo "Creating directories..."
    mkdir -p {{package_dir}} {{dist_dir}}

    echo "Installing dependencies..."
    uv pip install \
        --target {{package_dir}} \
        --python-version {{python_version}} \
        --no-deps \
        -r <(uv pip compile pyproject.toml)

    echo "Installing package..."
    uv pip install \
        --target {{package_dir}} \
        --python-version {{python_version}} \
        --no-deps \
        .

    echo "Creating deployment package..."
    cd {{package_dir}} && zip -r ../{{dist_dir}}/{{zip_name}} . -x '*.pyc' -x '*/__pycache__/*' && cd ..

    echo "Deployment package created: {{dist_dir}}/{{zip_name}}"
    echo "Size: $(du -h {{dist_dir}}/{{zip_name}} | cut -f1)"

# Initialize infrastructure
init env="dev":
    @echo "Initializing infrastructure for environment: {{env}}"
    cd {{iac_dir}} && {{terraform_bin}} init -var="environment={{env}}"

# Plan infrastructure changes
plan env="dev":
    @echo "Planning infrastructure for environment: {{env}}"
    cd {{iac_dir}} && {{terraform_bin}} plan -var="environment={{env}}"

# Apply infrastructure changes
apply env="dev":
    @echo "Applying infrastructure changes for environment: {{env}}"
    cd {{iac_dir}} && {{terraform_bin}} apply -var="environment={{env}}"

# Destroy infrastructure
destroy env="dev":
    @echo "Destroying infrastructure for environment: {{env}}"
    cd {{iac_dir}} && {{terraform_bin}} destroy -var="environment={{env}}"

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    rm -rf {{package_dir}} {{dist_dir}}
    @echo "Clean complete!"

# Package and show package contents
inspect: package
    @echo "Package contents:"
    unzip -l {{dist_dir}}/{{zip_name}} | head -20

# Run tests
test:
    uv run pytest

# Run tests with coverage
test-cov:
    uv run pytest --cov=my_project --cov-report=html --cov-report=term

# Install development dependencies
install:
    uv sync --all-extras --dev

# Format code
fmt:
    uv run ruff format src tests

# Lint code
lint:
    uv run ruff check src tests

# Type check
typecheck:
    uv run pyrefly check src