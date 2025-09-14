@echo off
REM Local PostgreSQL Database Setup Script for Windows
REM This script helps set up a local PostgreSQL database for development

echo Setting up local PostgreSQL database for Multi-Tenant SaaS Notes Application...

REM Check if PostgreSQL is installed
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo PostgreSQL is not installed or not in PATH. Please install PostgreSQL first.
    echo Visit: https://www.postgresql.org/download/windows/
    pause
    exit /b 1
)

REM Database configuration
set DB_NAME=notes_app
set DB_USER=notes_user
set DB_PASSWORD=password123

echo Creating database: %DB_NAME%
echo Creating user: %DB_USER%

REM Create database and user (requires superuser privileges)
psql -U postgres -c "CREATE DATABASE %DB_NAME%;" 2>nul || echo Database may already exist
psql -U postgres -c "CREATE USER %DB_USER% WITH PASSWORD '%DB_PASSWORD%';" 2>nul || echo User may already exist
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %DB_USER%;"

REM Run the setup script
echo Setting up database schema...
set PGPASSWORD=%DB_PASSWORD%
psql -h localhost -U %DB_USER% -d %DB_NAME% -f scripts/setup-database.sql

REM Create .env file if it doesn't exist
if not exist .env (
    echo Creating .env file...
    (
        echo JWT_SECRET=your-super-secret-jwt-key-here-change-this
        echo NODE_ENV=development
        echo PORT=3000
        echo.
        echo # PostgreSQL Database Configuration
        echo DATABASE_URL=postgresql://%DB_USER%:%DB_PASSWORD%@localhost:5432/%DB_NAME%
        echo DB_HOST=localhost
        echo DB_PORT=5432
        echo DB_NAME=%DB_NAME%
        echo DB_USER=%DB_USER%
        echo DB_PASSWORD=%DB_PASSWORD%
        echo DB_SSL=false
    ) > .env
    echo .env file created. Please update JWT_SECRET with a secure random string.
) else (
    echo .env file already exists. Please update DATABASE_URL manually if needed.
)

echo.
echo ✅ Database setup completed!
echo.
echo Connection details:
echo   Database: %DB_NAME%
echo   User: %DB_USER%
echo   Password: %DB_PASSWORD%
echo   Connection String: postgresql://%DB_USER%:%DB_PASSWORD%@localhost:5432/%DB_NAME%
echo.
echo You can now start the application with: npm run dev
echo.
echo Test accounts (password: password):
echo   admin@acme.test (Admin, Acme)
echo   user@acme.test (Member, Acme)
echo   admin@globex.test (Admin, Globex)
echo   user@globex.test (Member, Globex)
echo.
pause
