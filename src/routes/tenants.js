const express = require('express');
const { db } = require('../database/init');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Upgrade tenant to Pro plan
router.post('/:slug/upgrade', requireAdmin, (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  // Verify the tenant slug matches the user's tenant
  db.get(
    'SELECT * FROM tenants WHERE slug = ? AND id = ?',
    [slug, tenantId],
    (err, tenant) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!tenant) {
        return res.status(404).json({ error: 'Tenant not found or access denied' });
      }

      if (tenant.plan === 'pro') {
        return res.status(400).json({ error: 'Tenant is already on Pro plan' });
      }

      // Upgrade to Pro plan
      db.run(
        'UPDATE tenants SET plan = ? WHERE id = ?',
        ['pro', tenantId],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Failed to upgrade tenant' });
          }

          res.json({
            message: 'Tenant upgraded to Pro plan successfully',
            tenant: {
              id: tenant.id,
              slug: tenant.slug,
              name: tenant.name,
              plan: 'pro'
            }
          });
        }
      );
    }
  );
});

// Get tenant information
router.get('/:slug', (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  db.get(
    'SELECT * FROM tenants WHERE slug = ? AND id = ?',
    [slug, tenantId],
    (err, tenant) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!tenant) {
        return res.status(404).json({ error: 'Tenant not found or access denied' });
      }

      res.json(tenant);
    }
  );
});

// Get tenant statistics (for admin)
router.get('/:slug/stats', requireAdmin, (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  db.get(
    'SELECT * FROM tenants WHERE slug = ? AND id = ?',
    [slug, tenantId],
    (err, tenant) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!tenant) {
        return res.status(404).json({ error: 'Tenant not found or access denied' });
      }

      // Get note count
      db.get(
        'SELECT COUNT(*) as noteCount FROM notes WHERE tenant_id = ?',
        [tenantId],
        (err, noteStats) => {
          if (err) {
            return res.status(500).json({ error: 'Database error' });
          }

          // Get user count
          db.get(
            'SELECT COUNT(*) as userCount FROM users WHERE tenant_id = ?',
            [tenantId],
            (err, userStats) => {
              if (err) {
                return res.status(500).json({ error: 'Database error' });
              }

              res.json({
                tenant: {
                  id: tenant.id,
                  slug: tenant.slug,
                  name: tenant.name,
                  plan: tenant.plan
                },
                stats: {
                  noteCount: noteStats.noteCount,
                  userCount: userStats.userCount,
                  noteLimit: tenant.plan === 'free' ? 3 : 'unlimited'
                }
              });
            }
          );
        }
      );
    }
  );
});

module.exports = router;
