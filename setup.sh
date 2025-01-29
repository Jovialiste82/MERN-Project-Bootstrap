#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the list of directories to create
DIRECTORIES=(
  ".github"
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

echo "Creating directories..."
# Create directories
mkdir -p "${DIRECTORIES[@]}"

echo "Initializing client with Vite..."
# Initialize client
cd client
npm create vite@latest . -- --template react-ts
cd ..

echo "Initializing server..."
# Initialize server
cd server
npm init -y
mkdir src config
cd ..

echo "Initializing workers..."
# Initialize workers
cd workers
npm init -y
mkdir src
cd ..

echo "Setting up configuration files..."
# Setup configuration files
cd config
mkdir docker
touch .env.development .env.staging .env.production .env.example
cd ..

# Dynamic GUIDELINES.md creation using templates
echo "Copying markdown files from templates..."

# Function to copy markdown files from templates
copy_guidelines() {
  local dir_name="$1"
  local template_file="templates/${dir_name}_README.md"
  local target_file=""

  # Skip copying root README.md (to prevent overwriting the main README)
  if [ "$dir_name" == "root" ]; then
    echo "Skipping root README.md to prevent overwriting."
    return
  fi

  # Change README.md to GUIDELINES.md in subdirectories
  target_file="${dir_name}/GUIDELINES.md"

  if [ -f "$template_file" ]; then
    cp "$template_file" "$target_file"
    echo "Copied $template_file to $target_file"
  else
    echo "Warning: Template file $template_file not found. Skipping markdown file for $dir_name."
  fi
}

# Loop through all template files and copy to respective directories
for template in templates/*_README.md; do
  # Extract the directory name by removing the suffix '_README.md'
  dir_name=$(basename "$template" "_README.md")
  
  # Call the function to rename README.md to GUIDELINES.md
  copy_guidelines "$dir_name"
done

echo "Creating .gitignore..."
# Create .gitignore with specified content
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

# Ignore server-specific files
/server/node_modules/
/server/dist/
/server/.env*
EOF

echo "Deleting the templates folder..."
# Delete the templates folder
rm -rf templates

echo "Project structure setup complete!"
