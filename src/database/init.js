const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const bcrypt = require('bcryptjs');

const dbPath = path.join(__dirname, 'notes.db');
const db = new sqlite3.Database(dbPath);

const initializeDatabase = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Create tenants table
      db.run(`
        CREATE TABLE IF NOT EXISTS tenants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          slug TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          plan TEXT DEFAULT 'free' CHECK(plan IN ('free', 'pro')),
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Create users table
      db.run(`
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'member')),
          tenant_id INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (tenant_id) REFERENCES tenants (id)
        )
      `);

      // Create notes table
      db.run(`
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          tenant_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (tenant_id) REFERENCES tenants (id),
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      `);

      // Create indexes for better performance
      db.run(`CREATE INDEX IF NOT EXISTS idx_notes_tenant_id ON notes(tenant_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id)`);
      db.run(`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`);

      // Insert default tenants
      db.run(`
        INSERT OR IGNORE INTO tenants (slug, name, plan) VALUES 
        ('acme', 'Acme Corporation', 'free'),
        ('globex', 'Globex Corporation', 'free')
      `, (err) => {
        if (err) {
          console.error('Error inserting tenants:', err);
          reject(err);
          return;
        }

        // Get tenant IDs
        db.all('SELECT id, slug FROM tenants', (err, tenants) => {
          if (err) {
            reject(err);
            return;
          }

          const tenantMap = {};
          tenants.forEach(tenant => {
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

          const insertUser = db.prepare(`
            INSERT OR IGNORE INTO users (email, password_hash, role, tenant_id) 
            VALUES (?, ?, ?, ?)
          `);

          testUsers.forEach(user => {
            insertUser.run(user.email, hashedPassword, user.role, tenantMap[user.tenant]);
          });

          insertUser.finalize((err) => {
            if (err) {
              reject(err);
              return;
            }
            console.log('Database initialized successfully');
            resolve();
          });
        });
      });
    });
  });
};

module.exports = { db, initializeDatabase };
