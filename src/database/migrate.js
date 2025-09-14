const { pool } = require('./init');

const migrateDatabase = async () => {
  try {
    console.log('Starting database migration...');
    
    // Check if updated_by column exists
    const columnCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notes' AND column_name = 'updated_by'
    `);
    
    if (columnCheck.rows.length === 0) {
      console.log('Adding updated_by column to notes table...');
      
      // Add the updated_by column
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN updated_by INTEGER,
        ADD CONSTRAINT fk_notes_updated_by 
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
      `);
      
      console.log('✅ Successfully added updated_by column');
    } else {
      console.log('✅ updated_by column already exists');
    }
    
    console.log('Database migration completed successfully!');
  } catch (error) {
    console.error('Migration error:', error);
    throw error;
  }
};

module.exports = { migrateDatabase };
