const jwt = require('jsonwebtoken');
const { db } = require('../database/init');

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }

    // Get user details from database
    db.get(
      `SELECT u.*, t.slug as tenant_slug, t.plan as tenant_plan 
       FROM users u 
       JOIN tenants t ON u.tenant_id = t.id 
       WHERE u.id = ?`,
      [user.userId],
      (err, userDetails) => {
        if (err) {
          return res.status(500).json({ error: 'Database error' });
        }

        if (!userDetails) {
          return res.status(403).json({ error: 'User not found' });
        }

        req.user = {
          id: userDetails.id,
          email: userDetails.email,
          role: userDetails.role,
          tenantId: userDetails.tenant_id,
          tenantSlug: userDetails.tenant_slug,
          tenantPlan: userDetails.tenant_plan
        };

        next();
      }
    );
  });
};

const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
};

const requireAdmin = requireRole(['admin']);
const requireMember = requireRole(['admin', 'member']);

module.exports = {
  authenticateToken,
  requireRole,
  requireAdmin,
  requireMember
};
