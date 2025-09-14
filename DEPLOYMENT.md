# Deployment Guide

This guide will help you deploy the Multi-Tenant SaaS Notes Application to Vercel.

## Prerequisites

1. A GitHub account
2. A Vercel account (free tier is sufficient)
3. A PostgreSQL database (local or cloud-hosted)
4. Git installed on your local machine

## PostgreSQL Database Setup

### Option 1: Local PostgreSQL
1. Install PostgreSQL on your local machine
2. Create a database:
```sql
CREATE DATABASE notes_app;
CREATE USER notes_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE notes_app TO notes_user;
```
3. Use connection string: `postgresql://notes_user:your_password@localhost:5432/notes_app`

### Option 2: Cloud PostgreSQL (Recommended for Production)
Popular options:
- **Neon** (free tier): https://neon.tech
- **Supabase** (free tier): https://supabase.com
- **Railway** (free tier): https://railway.app
- **Heroku Postgres** (paid): https://heroku.com/postgres
- **AWS RDS** (paid): https://aws.amazon.com/rds/postgresql/

Example connection string format:
```
postgresql://username:password@host:port/database?sslmode=require
```

## Step 1: Prepare the Repository

1. Initialize a Git repository in your project folder:
```bash
git init
git add .
git commit -m "Initial commit: Multi-tenant SaaS Notes Application"
```

2. Create a new repository on GitHub and push your code:
```bash
git remote add origin https://github.com/yourusername/multi-tenant-saas-notes.git
git branch -M main
git push -u origin main
```

## Step 2: Deploy Backend to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your GitHub repository
4. Configure the project:
   - **Framework Preset**: Other
   - **Root Directory**: Leave empty (root)
   - **Build Command**: `npm install`
   - **Output Directory**: Leave empty
   - **Install Command**: `npm install`

5. Set Environment Variables:
   - Go to Project Settings → Environment Variables
   - Add the following variables:
     - `JWT_SECRET`: Generate a secure random string (e.g., using `openssl rand -base64 32`)
     - `NODE_ENV`: `production`
     - `DATABASE_URL`: Your PostgreSQL connection string (see PostgreSQL setup below)
     - `DB_SSL`: `true` (for production PostgreSQL connections)

6. Deploy the backend
7. Note down the Vercel URL (e.g., `https://your-project-name.vercel.app`)

## Step 3: Update Frontend Configuration

1. Open `frontend-js/index.html`
2. Find the line: `this.apiBaseUrl = 'https://your-backend-url.vercel.app';`
3. Replace with your actual Vercel backend URL
4. Commit and push the changes:
```bash
git add frontend-js/index.html
git commit -m "Update frontend API URL"
git push
```

## Step 4: Deploy Frontend to Vercel

1. Create a new Vercel project for the frontend
2. Configure the project:
   - **Framework Preset**: Other
   - **Root Directory**: `frontend-js`
   - **Build Command**: Leave empty
   - **Output Directory**: Leave empty
   - **Install Command**: Leave empty

3. Deploy the frontend
4. Note down the frontend URL

## Step 5: Test the Application

1. Open your frontend URL in a browser
2. Test the login with the provided test accounts:
   - `admin@acme.test` / `password`
   - `user@acme.test` / `password`
   - `admin@globex.test` / `password`
   - `user@globex.test` / `password`

3. Test the following features:
   - Create notes
   - View notes
   - Delete notes
   - Test tenant isolation (login with different tenants)
   - Test note limits on free plan
   - Test upgrade functionality (admin users)

## Step 6: API Testing

You can test the API directly using curl or Postman:

### Health Check
```bash
curl https://your-backend-url.vercel.app/health
```

### Login
```bash
curl -X POST https://your-backend-url.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@acme.test","password":"password"}'
```

### Create Note (replace YOUR_TOKEN with actual token)
```bash
curl -X POST https://your-backend-url.vercel.app/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"Test Note","content":"This is a test note"}'
```

### List Notes
```bash
curl -X GET https://your-backend-url.vercel.app/notes \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### Common Issues

1. **CORS Errors**: Make sure CORS is enabled in the backend (it should be by default)
2. **Database Issues**: The PostgreSQL database tables are created automatically on first run. Ensure your DATABASE_URL is correct and accessible.
3. **Authentication Errors**: Check that JWT_SECRET is set correctly
4. **Frontend Not Loading**: Verify the API URL is correct in the frontend

### Environment Variables

Make sure these are set in Vercel:
- `JWT_SECRET`: A secure random string
- `NODE_ENV`: `production`
- `DATABASE_URL`: Your PostgreSQL connection string
- `DB_SSL`: `true` (for production PostgreSQL connections)

### Logs

Check Vercel function logs for any errors:
1. Go to your project dashboard
2. Click on "Functions" tab
3. Check the logs for any runtime errors

## Security Considerations

1. **JWT Secret**: Use a strong, random JWT secret
2. **CORS**: The current setup allows all origins for testing. In production, consider restricting to your frontend domain
3. **Rate Limiting**: The app includes rate limiting (100 requests per 15 minutes per IP)
4. **Database**: PostgreSQL is implemented with connection pooling for production scalability

## Scaling Considerations

For production use with many tenants:
1. ✅ PostgreSQL is already implemented with connection pooling
2. Consider adding caching layer (Redis) for frequently accessed data
3. Implement proper logging and monitoring
4. Add automated backups
5. Consider implementing database-per-tenant for better isolation at scale
6. Monitor database performance and add indexes as needed
7. Consider read replicas for better performance

## Support

If you encounter issues:
1. Check the Vercel function logs
2. Verify all environment variables are set
3. Test the API endpoints directly
4. Check the browser console for frontend errors
