#!/bin/bash

# Local PostgreSQL Database Setup Script
# This script helps set up a local PostgreSQL database for development

echo "Setting up local PostgreSQL database for Multi-Tenant SaaS Notes Application..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Please install PostgreSQL first."
    echo "Visit: https://www.postgresql.org/download/"
    exit 1
fi

# Database configuration
DB_NAME="notes_app"
DB_USER="notes_user"
DB_PASSWORD="password123"  # Change this to a secure password

echo "Creating database: $DB_NAME"
echo "Creating user: $DB_USER"

# Create database and user (requires superuser privileges)
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "Database may already exist"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "User may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Run the setup script
echo "Setting up database schema..."
PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME -f scripts/setup-database.sql

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=development
PORT=3000

# PostgreSQL Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SSL=false
EOF
    echo ".env file created with generated JWT_SECRET"
else
    echo ".env file already exists. Please update DATABASE_URL manually if needed."
fi

echo ""
echo "✅ Database setup completed!"
echo ""
echo "Connection details:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  Connection String: postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
echo ""
echo "You can now start the application with: npm run dev"
echo ""
echo "Test accounts (password: password):"
echo "  admin@acme.test (Admin, Acme)"
echo "  user@acme.test (Member, Acme)"
echo "  admin@globex.test (Admin, Globex)"
echo "  user@globex.test (Member, Globex)"
