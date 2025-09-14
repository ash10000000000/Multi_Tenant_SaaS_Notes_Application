-- PostgreSQL Database Setup Script
-- Run this script to set up the database for the Multi-Tenant SaaS Notes Application

-- Create database (run this as superuser)
-- CREATE DATABASE notes_app;

-- Create user (run this as superuser)
-- CREATE USER notes_user WITH PASSWORD 'your_secure_password';

-- Grant privileges (run this as superuser)
-- GRANT ALL PRIVILEGES ON DATABASE notes_app TO notes_user;

-- Connect to the notes_app database and run the following:

-- Create tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  plan VARCHAR(50) DEFAULT 'free' CHECK(plan IN ('free', 'pro')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'member' CHECK(role IN ('admin', 'member')),
  tenant_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notes_tenant_id ON notes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Insert default tenants
INSERT INTO tenants (slug, name, plan) VALUES 
('acme', 'Acme Corporation', 'free'),
('globex', 'Globex Corporation', 'free')
ON CONFLICT (slug) DO NOTHING;

-- Note: Test users will be created automatically by the application
-- with hashed passwords when the server starts

-- Verify the setup
SELECT 'Database setup completed successfully!' as status;
SELECT COUNT(*) as tenant_count FROM tenants;
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as note_count FROM notes;
