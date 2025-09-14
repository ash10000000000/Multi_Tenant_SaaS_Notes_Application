const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

// Create PostgreSQL connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test database connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('PostgreSQL connection error:', err);
});

const initializeDatabase = async () => {
  try {
    // Create tenants table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tenants (
        id SERIAL PRIMARY KEY,
        slug VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        plan VARCHAR(50) DEFAULT 'free' CHECK(plan IN ('free', 'pro')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'member' CHECK(role IN ('admin', 'member')),
        tenant_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    `);

    // Create notes table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT,
        tenant_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        updated_by INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
      )
    `);

    // Create indexes for better performance
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_notes_tenant_id ON notes(tenant_id)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id)`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);

    // Insert default tenants
    await pool.query(`
      INSERT INTO tenants (slug, name, plan) VALUES 
      ('acme', 'Acme Corporation', 'free'),
      ('globex', 'Globex Corporation', 'free')
      ON CONFLICT (slug) DO NOTHING
    `);

    // Get tenant IDs
    const tenantResult = await pool.query('SELECT id, slug FROM tenants');
    const tenantMap = {};
    tenantResult.rows.forEach(tenant => {
      tenantMap[tenant.slug] = tenant.id;
    });

    // Hash password for test accounts
    const hashedPassword = bcrypt.hashSync('password', 10);

    // Insert test users
    const testUsers = [
      { email: 'admin@acme.test', role: 'admin', tenant: 'acme' },
      { email: 'user@acme.test', role: 'member', tenant: 'acme' },
      { email: 'admin@globex.test', role: 'admin', tenant: 'globex' },
      { email: 'user@globex.test', role: 'member', tenant: 'globex' }
    ];

    for (const user of testUsers) {
      await pool.query(`
        INSERT INTO users (email, password_hash, role, tenant_id) 
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (email) DO NOTHING
      `, [user.email, hashedPassword, user.role, tenantMap[user.tenant]]);
    }

    console.log('PostgreSQL database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
    throw error;
  }
};

module.exports = { pool, initializeDatabase };
