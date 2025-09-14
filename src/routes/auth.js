const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../database/init');

const router = express.Router();

// Login endpoint
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  // Find user with tenant information
  db.get(
    `SELECT u.*, t.slug as tenant_slug, t.plan as tenant_plan, t.name as tenant_name
     FROM users u 
     JOIN tenants t ON u.tenant_id = t.id 
     WHERE u.email = ?`,
    [email],
    (err, user) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Verify password
      bcrypt.compare(password, user.password_hash, (err, isMatch) => {
        if (err) {
          return res.status(500).json({ error: 'Password verification error' });
        }

        if (!isMatch) {
          return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate JWT token
        const token = jwt.sign(
          {
            userId: user.id,
            email: user.email,
            role: user.role,
            tenantId: user.tenant_id,
            tenantSlug: user.tenant_slug
          },
          process.env.JWT_SECRET || 'fallback-secret',
          { expiresIn: '24h' }
        );

        res.json({
          token,
          user: {
            id: user.id,
            email: user.email,
            role: user.role,
            tenant: {
              id: user.tenant_id,
              slug: user.tenant_slug,
              name: user.tenant_name,
              plan: user.tenant_plan
            }
          }
        });
      });
    }
  );
});

// Register endpoint (for testing purposes)
router.post('/register', (req, res) => {
  const { email, password, role = 'member', tenantSlug } = req.body;

  if (!email || !password || !tenantSlug) {
    return res.status(400).json({ error: 'Email, password, and tenant slug are required' });
  }

  // Check if tenant exists
  db.get('SELECT id FROM tenants WHERE slug = ?', [tenantSlug], (err, tenant) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }

    if (!tenant) {
      return res.status(400).json({ error: 'Invalid tenant' });
    }

    // Check if user already exists
    db.get('SELECT id FROM users WHERE email = ?', [email], (err, existingUser) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (existingUser) {
        return res.status(400).json({ error: 'User already exists' });
      }

      // Hash password and create user
      const hashedPassword = bcrypt.hashSync(password, 10);

      db.run(
        'INSERT INTO users (email, password_hash, role, tenant_id) VALUES (?, ?, ?, ?)',
        [email, hashedPassword, role, tenant.id],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Failed to create user' });
          }

          res.status(201).json({
            message: 'User created successfully',
            userId: this.lastID
          });
        }
      );
    });
  });
});

module.exports = router;
