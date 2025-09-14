const express = require('express');
const { db } = require('../database/init');
const { authenticateToken, requireMember } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticateToken);
router.use(requireMember);

// Create a note
router.post('/', (req, res) => {
  const { title, content } = req.body;
  const { tenantId, tenantPlan } = req.user;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  // Check note limit for free plan
  if (tenantPlan === 'free') {
    db.get(
      'SELECT COUNT(*) as count FROM notes WHERE tenant_id = ?',
      [tenantId],
      (err, result) => {
        if (err) {
          return res.status(500).json({ error: 'Database error' });
        }

        if (result.count >= 3) {
          return res.status(403).json({ 
            error: 'Note limit reached for free plan. Upgrade to Pro for unlimited notes.',
            upgradeRequired: true
          });
        }

        // Create the note
        createNote(req, res, title, content);
      }
    );
  } else {
    // Pro plan - unlimited notes
    createNote(req, res, title, content);
  }
});

function createNote(req, res, title, content) {
  const { tenantId, id: userId } = req.user;

  db.run(
    'INSERT INTO notes (title, content, tenant_id, user_id) VALUES (?, ?, ?, ?)',
    [title, content || '', tenantId, userId],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to create note' });
      }

      res.status(201).json({
        id: this.lastID,
        title,
        content: content || '',
        tenantId,
        userId,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    }
  );
}

// Get all notes for the current tenant
router.get('/', (req, res) => {
  const { tenantId } = req.user;

  db.all(
    `SELECT n.*, u.email as author_email 
     FROM notes n 
     JOIN users u ON n.user_id = u.id 
     WHERE n.tenant_id = ? 
     ORDER BY n.created_at DESC`,
    [tenantId],
    (err, notes) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      res.json(notes);
    }
  );
});

// Get a specific note
router.get('/:id', (req, res) => {
  const { id } = req.params;
  const { tenantId } = req.user;

  db.get(
    `SELECT n.*, u.email as author_email 
     FROM notes n 
     JOIN users u ON n.user_id = u.id 
     WHERE n.id = ? AND n.tenant_id = ?`,
    [id, tenantId],
    (err, note) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!note) {
        return res.status(404).json({ error: 'Note not found' });
      }

      res.json(note);
    }
  );
});

// Update a note
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { title, content } = req.body;
  const { tenantId, id: userId } = req.user;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  // Check if note exists and belongs to tenant
  db.get(
    'SELECT * FROM notes WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, note) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!note) {
        return res.status(404).json({ error: 'Note not found' });
      }

      // Update the note
      db.run(
        'UPDATE notes SET title = ?, content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND tenant_id = ?',
        [title, content || '', id, tenantId],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Failed to update note' });
          }

          res.json({
            id: parseInt(id),
            title,
            content: content || '',
            tenantId,
            userId,
            createdAt: note.created_at,
            updatedAt: new Date().toISOString()
          });
        }
      );
    }
  );
});

// Delete a note
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const { tenantId } = req.user;

  // Check if note exists and belongs to tenant
  db.get(
    'SELECT * FROM notes WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, note) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!note) {
        return res.status(404).json({ error: 'Note not found' });
      }

      // Delete the note
      db.run(
        'DELETE FROM notes WHERE id = ? AND tenant_id = ?',
        [id, tenantId],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Failed to delete note' });
          }

          res.json({ message: 'Note deleted successfully' });
        }
      );
    }
  );
});

module.exports = router;
