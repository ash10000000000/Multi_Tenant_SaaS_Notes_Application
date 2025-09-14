const express = require('express');
const { pool } = require('../database/init');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);

// Upgrade tenant to Pro plan
router.post('/:slug/upgrade', requireAdmin, async (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  try {
    // Verify the tenant slug matches the user's tenant
    const tenantResult = await pool.query(
      'SELECT * FROM tenants WHERE slug = $1 AND id = $2',
      [slug, tenantId]
    );

    if (tenantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Tenant not found or access denied' });
    }

    const tenant = tenantResult.rows[0];

    if (tenant.plan === 'pro') {
      return res.status(400).json({ error: 'Tenant is already on Pro plan' });
    }

    // Upgrade to Pro plan
    await pool.query(
      'UPDATE tenants SET plan = $1 WHERE id = $2',
      ['pro', tenantId]
    );

    // Get updated tenant info
    const updatedTenantResult = await pool.query(
      'SELECT * FROM tenants WHERE id = $1',
      [tenantId]
    );
    const updatedTenant = updatedTenantResult.rows[0];

    res.json({
      message: 'Tenant upgraded to Pro plan successfully',
      tenant: {
        id: updatedTenant.id,
        slug: updatedTenant.slug,
        name: updatedTenant.name,
        plan: updatedTenant.plan
      },
      noteLimit: 'unlimited',
      upgradeDate: new Date().toISOString()
    });
  } catch (error) {
    console.error('Upgrade tenant error:', error);
    res.status(500).json({ error: 'Failed to upgrade tenant' });
  }
});

// Get tenant information
router.get('/:slug', async (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  try {
    const result = await pool.query(
      'SELECT * FROM tenants WHERE slug = $1 AND id = $2',
      [slug, tenantId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tenant not found or access denied' });
    }

    const tenant = result.rows[0];
    
    // Get current note count
    const noteCountResult = await pool.query(
      'SELECT COUNT(*) as count FROM notes WHERE tenant_id = $1',
      [tenantId]
    );
    const noteCount = parseInt(noteCountResult.rows[0].count);

    res.json({
      ...tenant,
      noteCount,
      noteLimit: tenant.plan === 'free' ? 3 : 'unlimited',
      canCreateNote: tenant.plan === 'pro' || noteCount < 3
    });
  } catch (error) {
    console.error('Get tenant error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get tenant statistics (for admin)
router.get('/:slug/stats', requireAdmin, async (req, res) => {
  const { slug } = req.params;
  const { tenantId } = req.user;

  try {
    const tenantResult = await pool.query(
      'SELECT * FROM tenants WHERE slug = $1 AND id = $2',
      [slug, tenantId]
    );

    if (tenantResult.rows.length === 0) {
      return res.status(404).json({ error: 'Tenant not found or access denied' });
    }

    const tenant = tenantResult.rows[0];

    // Get note count
    const noteStatsResult = await pool.query(
      'SELECT COUNT(*) as noteCount FROM notes WHERE tenant_id = $1',
      [tenantId]
    );

    // Get user count
    const userStatsResult = await pool.query(
      'SELECT COUNT(*) as userCount FROM users WHERE tenant_id = $1',
      [tenantId]
    );

    res.json({
      tenant: {
        id: tenant.id,
        slug: tenant.slug,
        name: tenant.name,
        plan: tenant.plan
      },
      stats: {
        noteCount: parseInt(noteStatsResult.rows[0].notecount),
        userCount: parseInt(userStatsResult.rows[0].usercount),
        noteLimit: tenant.plan === 'free' ? 3 : 'unlimited'
      }
    });
  } catch (error) {
    console.error('Get tenant stats error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
