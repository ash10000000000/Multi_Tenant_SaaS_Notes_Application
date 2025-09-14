const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../database/init');

const router = express.Router();

// Login endpoint
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    // Find user with tenant information
    const result = await pool.query(
      `SELECT u.*, t.slug as tenant_slug, t.plan as tenant_plan, t.name as tenant_name
       FROM users u 
       JOIN tenants t ON u.tenant_id = t.id 
       WHERE u.email = $1`,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    // Verify password
    const isMatch = await bcrypt.compare(password, user.password_hash);
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
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

// Register endpoint (for testing purposes)
router.post('/register', async (req, res) => {
  const { email, password, role = 'member', tenantSlug } = req.body;

  if (!email || !password || !tenantSlug) {
    return res.status(400).json({ error: 'Email, password, and tenant slug are required' });
  }

  try {
    // Check if tenant exists
    const tenantResult = await pool.query('SELECT id FROM tenants WHERE slug = $1', [tenantSlug]);
    if (tenantResult.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid tenant' });
    }

    const tenant = tenantResult.rows[0];

    // Check if user already exists
    const existingUserResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUserResult.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password and create user
    const hashedPassword = bcrypt.hashSync(password, 10);

    const userResult = await pool.query(
      'INSERT INTO users (email, password_hash, role, tenant_id) VALUES ($1, $2, $3, $4) RETURNING id',
      [email, hashedPassword, role, tenant.id]
    );

    res.status(201).json({
      message: 'User created successfully',
      userId: userResult.rows[0].id
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Invite user endpoint (Admin only)
router.post('/invite', async (req, res) => {
  const { email, role = 'member' } = req.body;
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    // Verify token and get user info
    const jwt = require('jsonwebtoken');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
    
    // Get user details from database
    const userResult = await pool.query(
      `SELECT u.*, t.slug as tenant_slug, t.plan as tenant_plan 
       FROM users u 
       JOIN tenants t ON u.tenant_id = t.id 
       WHERE u.id = $1`,
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(403).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];

    // Check if user is admin
    if (user.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can invite users' });
    }

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Check if user already exists
    const existingUserResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUserResult.rows.length > 0) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Generate a temporary password (in real app, send invitation email)
    const tempPassword = 'temp123';
    const hashedPassword = bcrypt.hashSync(tempPassword, 10);

    const userResult2 = await pool.query(
      'INSERT INTO users (email, password_hash, role, tenant_id) VALUES ($1, $2, $3, $4) RETURNING id',
      [email, hashedPassword, role, user.tenant_id]
    );

    res.status(201).json({
      message: 'User invited successfully',
      userId: userResult2.rows[0].id,
      tempPassword: tempPassword // In real app, this would be sent via email
    });
  } catch (error) {
    console.error('Invite user error:', error);
    res.status(500).json({ error: 'Failed to invite user' });
  }
});

module.exports = router;
