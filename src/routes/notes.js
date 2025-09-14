const express = require('express');
const { pool } = require('../database/init');
const { authenticateToken, requireMember } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);
router.use(requireMember);

// Create a note
router.post('/', async (req, res) => {
  const { title, content } = req.body;
  const { tenantId, tenantPlan } = req.user;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    // Check note limit for free plan
    if (tenantPlan === 'free') {
      const countResult = await pool.query(
        'SELECT COUNT(*) as count FROM notes WHERE tenant_id = $1',
        [tenantId]
      );

      if (parseInt(countResult.rows[0].count) >= 3) {
        return res.status(403).json({ 
          error: 'Note limit reached for free plan. Upgrade to Pro for unlimited notes.',
          upgradeRequired: true
        });
      }
    }

    // Create the note
    await createNote(req, res, title, content);
  } catch (error) {
    console.error('Create note error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

async function createNote(req, res, title, content) {
  const { tenantId, id: userId } = req.user;

  try {
    const result = await pool.query(
      'INSERT INTO notes (title, content, tenant_id, user_id) VALUES ($1, $2, $3, $4) RETURNING id, created_at',
      [title, content || '', tenantId, userId]
    );

    const note = result.rows[0];
    res.status(201).json({
      id: note.id,
      title,
      content: content || '',
      tenantId,
      userId,
      createdAt: note.created_at,
      updatedAt: note.created_at
    });
  } catch (error) {
    console.error('Create note error:', error);
    res.status(500).json({ error: 'Failed to create note' });
  }
}

// Get all notes for the current tenant
router.get('/', async (req, res) => {
  const { tenantId } = req.user;

  // Debug logging
  console.log(`GET /notes - User tenant ID: ${tenantId}, User: ${req.user.email}`);

  try {
    // Try with updated_by column first, fallback to basic query if column doesn't exist
    let result;
    try {
      result = await pool.query(
        `SELECT n.*, u.email as author_email, updater.email as updated_by_email
         FROM notes n 
         JOIN users u ON n.user_id = u.id 
         LEFT JOIN users updater ON n.updated_by = updater.id
         WHERE n.tenant_id = $1 
         ORDER BY n.created_at DESC`,
        [tenantId]
      );
    } catch (error) {
      // Fallback query if updated_by column doesn't exist yet
      console.log('Falling back to basic query (updated_by column may not exist yet)');
      result = await pool.query(
        `SELECT n.*, u.email as author_email 
         FROM notes n 
         JOIN users u ON n.user_id = u.id 
         WHERE n.tenant_id = $1 
         ORDER BY n.created_at DESC`,
        [tenantId]
      );
    }

    // Debug logging
    console.log(`GET /notes - Found ${result.rows.length} notes for tenant ${tenantId}`);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Get notes error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

// Get a specific note
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  const { tenantId } = req.user;

  try {
    // Try with updated_by column first, fallback to basic query if column doesn't exist
    let result;
    try {
      result = await pool.query(
        `SELECT n.*, u.email as author_email, updater.email as updated_by_email
         FROM notes n 
         JOIN users u ON n.user_id = u.id 
         LEFT JOIN users updater ON n.updated_by = updater.id
         WHERE n.id = $1 AND n.tenant_id = $2`,
        [id, tenantId]
      );
    } catch (error) {
      // Fallback query if updated_by column doesn't exist yet
      console.log('Falling back to basic query (updated_by column may not exist yet)');
      result = await pool.query(
        `SELECT n.*, u.email as author_email 
         FROM notes n 
         JOIN users u ON n.user_id = u.id 
         WHERE n.id = $1 AND n.tenant_id = $2`,
        [id, tenantId]
      );
    }

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get note error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

// Update a note
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { title, content } = req.body;
  const { tenantId, id: userId } = req.user;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    // Check if note exists and belongs to tenant
    const noteResult = await pool.query(
      'SELECT * FROM notes WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (noteResult.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }

    const note = noteResult.rows[0];

    // Update the note (try with updated_by column first)
    let updateResult;
    try {
      updateResult = await pool.query(
        'UPDATE notes SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP, updated_by = $5 WHERE id = $3 AND tenant_id = $4 RETURNING updated_at',
        [title, content || '', id, tenantId, userId]
      );
    } catch (error) {
      // Fallback query if updated_by column doesn't exist yet
      console.log('Falling back to basic update query (updated_by column may not exist yet)');
      updateResult = await pool.query(
        'UPDATE notes SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 AND tenant_id = $4 RETURNING updated_at',
        [title, content || '', id, tenantId]
      );
    }

    // Get updater information
    const updaterResult = await pool.query(
      'SELECT email FROM users WHERE id = $1',
      [userId]
    );
    const updaterEmail = updaterResult.rows[0]?.email || 'Unknown';

    res.json({
      id: parseInt(id),
      title,
      content: content || '',
      tenantId,
      userId,
      createdAt: note.created_at,
      updatedAt: updateResult.rows[0].updated_at,
      updatedBy: updaterEmail
    });
  } catch (error) {
    console.error('Update note error:', error);
    res.status(500).json({ error: 'Failed to update note' });
  }
});

// Delete a note
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const { tenantId } = req.user;

  try {
    // Check if note exists and belongs to tenant
    const noteResult = await pool.query(
      'SELECT * FROM notes WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    if (noteResult.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }

    // Delete the note
    await pool.query(
      'DELETE FROM notes WHERE id = $1 AND tenant_id = $2',
      [id, tenantId]
    );

    res.json({ message: 'Note deleted successfully' });
  } catch (error) {
    console.error('Delete note error:', error);
    res.status(500).json({ error: 'Failed to delete note' });
  }
});

module.exports = router;
