#!/bin/bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and
# Prevent errors in a pipeline from being masked
set -euo pipefail

# Optional: Uncomment the next line for debugging purposes
# set -x

# Define the list of directories to create
DIRECTORIES=(
  ".github"
  ".github/workflows"
  "bin"
  "cache"
  "client"
  "config"
  "data"
  "docs"
  "docs/api"
  "docs/architecture"
  "docs/guides"
  "infra"
  "logs"
  "migrations"
  "monitoring"
  "monitoring/grafana"
  "monitoring/prometheus"
  "monitoring/grafana/grafana-data"
  "playground"
  "scripts"
  "seeds"
  "server"
  "shared"
  "tests"
  "workers"
)

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verify required commands are available
for cmd in mkdir npm cp rm; do
  if ! command_exists "$cmd"; then
    echo "Error: Required command '$cmd' is not installed." >&2
    exit 1
  fi
done

echo "Creating directories..."
# Create directories
mkdir -p "${DIRECTORIES[@]}"

echo "Initializing client with Vite..."
# Initialize client if package.json doesn't exist
if [ ! -f "client/package.json" ]; then
  pushd client > /dev/null
  npm create vite@latest . -- --template react-ts
  popd > /dev/null
else
  echo "Client already initialized. Skipping."
fi

echo "Initializing server..."
# Initialize server if package.json doesn't exist
if [ ! -f "server/package.json" ]; then
  pushd server > /dev/null
  npm init -y
  mkdir -p config  # Create config before src
  mkdir -p src
  pushd src > /dev/null
  mkdir -p controllers services models routes types
  popd > /dev/null
  popd > /dev/null
else
  echo "Server already initialized. Skipping."
fi

echo "Initializing shared..."
# Initialize shared if package.json doesn't exist
if [ ! -f "shared/package.json" ]; then
  pushd shared > /dev/null
  npm init -y
  mkdir -p config  # Create config before src
  mkdir -p src
  pushd src > /dev/null
  mkdir -p controllers services models routes types
  popd > /dev/null
  popd > /dev/null
else
  echo "Shared already initialized. Skipping."
fi

echo "Initializing workers..."
# Initialize workers if package.json doesn't exist
if [ ! -f "workers/package.json" ]; then
  pushd workers > /dev/null
  npm init -y
  mkdir -p src
  popd > /dev/null
else
  echo "Workers already initialized. Skipping."
fi

echo "Setting up configuration files..."
# Setup configuration files
mkdir -p config/docker
touch config/.env.development config/.env.staging config/.env.production config/.env.example

echo "Copying markdown files from templates..."

# Function to copy markdown files from templates
copy_guidelines() {
  local dir_name="$1"
  local template_file="templates/${dir_name}_README.md"
  local target_file="${dir_name}/GUIDELINES.md"

  if [ -f "$template_file" ]; then
    cp "$template_file" "$target_file"
    echo "Copied $template_file to $target_file"
  else
    # Provide a default GUIDELINES.md if template is missing
    echo "Warning: Template file $template_file not found. Creating default GUIDELINES.md for $dir_name."
    cat <<EOF > "$target_file"
# Guidelines for ${dir_name}

Provide project-specific guidelines here.
EOF
    echo "Created default GUIDELINES.md for $dir_name"
  fi
}

# Enable dotglob to include hidden files (like .github_README.md)
shopt -s nullglob dotglob

# Loop through all template files and copy to respective directories
if [ -d "templates" ]; then
  templates_found=false
  for template in templates/*_README.md; do
    templates_found=true
    # Extract the directory name by removing the suffix '_README.md'
    dir_name=$(basename "$template" "_README.md")

    # Call the function to rename README.md to GUIDELINES.md
    copy_guidelines "$dir_name"
  done

  if [ "$templates_found" = false ]; then
    echo "No template files found in templates/ directory."
  fi
else
  echo "Warning: templates/ directory does not exist. Skipping GUIDELINES.md creation."
fi

# Disable dotglob to restore default behavior
shopt -u nullglob dotglob

echo "Creating .gitignore..."
# Create .gitignore with specified content if it doesn't exist
if [ ! -f ".gitignore" ]; then
  cat <<EOF > .gitignore
# Root-level ignores
node_modules/
Dockerfile*
docker-compose.yml
.env.production
.env.staging
.env.development
dist/

# Ignore client-specific files
/client/node_modules/
/client/dist/

/server/node_modules/
/server/dist/
/server/.env*
EOF
  echo ".gitignore created."
else
  echo ".gitignore already exists. Skipping."
fi

echo "Deleting the templates folder..."
# Delete the templates folder if it exists
if [ -d "templates" ]; then
  rm -rf templates
  echo "templates/ folder deleted."
else
  echo "templates/ folder does not exist. Skipping deletion."
fi

echo "Project structure setup complete!"
