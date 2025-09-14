# Multi-Tenant SaaS Notes Application

A comprehensive multi-tenant SaaS Notes Application with strict tenant isolation, role-based access control, and subscription feature gating. Built with Node.js/Express backend and modern JavaScript frontend, deployed on Vercel.

## 🎯 Overview

This application demonstrates a complete multi-tenant SaaS architecture with:
- **JWT-based authentication** with role-based access control
- **Strict tenant isolation** ensuring data segregation
- **Subscription management** with Free/Pro plans
- **Full CRUD operations** for notes with real-time updates
- **Professional UI** with minimal, responsive design
- **Production-ready** security and error handling

## 🏗️ Architecture

### Multi-Tenancy Approach
This application uses **Shared Schema with Tenant ID** approach:
- Single database with tenant isolation through `tenant_id` foreign keys
- All tables include `tenant_id` column for data segregation
- Strict tenant isolation enforced at the application level
- Cost-effective and scalable for moderate tenant counts

### Technology Stack
- **Backend**: Node.js, Express.js, PostgreSQL, JWT
- **Frontend**: Vanilla JavaScript (HTML5, CSS3) - No frameworks required
- **Database**: PostgreSQL with connection pooling
- **Deployment**: Vercel (both backend and frontend)
- **Security**: Helmet.js, CORS, Rate limiting, bcrypt
- **Authentication**: JWT with 24-hour expiration
- **Password Security**: bcrypt with salt rounds

## 🚀 Features

### Multi-Tenancy
- ✅ Support for multiple tenants (Acme, Globex)
- ✅ Strict data isolation between tenants
- ✅ Tenant-specific user management
- ✅ Shared schema with tenant ID approach

### Authentication & Authorization
- ✅ JWT-based authentication
- ✅ Role-based access control (Admin/Member)
- ✅ Secure password hashing with bcrypt
- ✅ Token-based session management

### Subscription Management
- ✅ Free Plan: Limited to 3 notes per tenant
- ✅ Pro Plan: Unlimited notes
- ✅ Admin-only upgrade endpoint
- ✅ Real-time plan enforcement

### Notes Management
- ✅ Full CRUD operations for notes (Create, Read, Update, Delete)
- ✅ Tenant-isolated note storage with strict data segregation
- ✅ Role-based access control (Admin/Member permissions)
- ✅ Real-time note limits enforcement
- ✅ Author tracking (who created/updated each note)
- ✅ Inline editing with save/cancel functionality

### Frontend
- ✅ Modern vanilla JavaScript web application
- ✅ Responsive design with mobile support
- ✅ Real-time note management with instant updates
- ✅ Upgrade prompts for free plan users
- ✅ Professional, minimal UI design
- ✅ Plan status indicators and usage counters
- ✅ Error handling and user feedback

## 🔐 Test Accounts

All test accounts use password: `password`

| Email | Role | Tenant | Plan |
|-------|------|--------|------|
| admin@acme.test | Admin | Acme | Free |
| user@acme.test | Member | Acme | Free |
| admin@globex.test | Admin | Globex | Free |
| user@globex.test | Member | Globex | Free |

## 📡 API Endpoints

### Authentication
- `POST /auth/login` - User login with JWT token response
- `POST /auth/register` - User registration (for testing)
- `POST /auth/invite` - Invite new users (Admin only)

### Notes (Requires Authentication)
- `POST /notes` - Create a note (with tenant isolation and plan limits)
- `GET /notes` - List all notes for current tenant
- `GET /notes/:id` - Get specific note (tenant isolated)
- `PUT /notes/:id` - Update a note (with updater tracking)
- `DELETE /notes/:id` - Delete a note (tenant isolated)

### Tenants (Admin Only)
- `POST /tenants/:slug/upgrade` - Upgrade tenant to Pro plan
- `GET /tenants/:slug` - Get tenant info with plan status
- `GET /tenants/:slug/stats` - Get detailed tenant statistics

### System
- `GET /health` - Health check endpoint
- `GET /test` - Comprehensive test endpoint with all system data

## 🛠️ Local Development

### Prerequisites
- Node.js (v18 or higher)
- PostgreSQL database
- Git

### Backend Setup
```bash
# Clone the repository
git clone <repository-url>
cd Multi_Tenant_SaaS_Notes_Application

# Install dependencies
npm install

# Set up environment variables
cp env.example .env
# Edit .env with your configuration:
# JWT_SECRET=your-secure-jwt-secret
# DATABASE_URL=postgresql://user:password@localhost:5432/notes_db
# NODE_ENV=development

# Start development server
npm run dev
# Server will start on http://localhost:3000
```

### Frontend Setup
The frontend is a vanilla JavaScript application with no build process required:

```bash
# Navigate to frontend directory
cd frontend-js

# Open index.html in your browser
# Or serve it with a local server:
npx serve .
# Frontend will be available at http://localhost:3000
```

### Database Setup
The application will automatically:
- Create all required tables
- Insert default tenants (Acme, Globex)
- Create test user accounts
- Run database migrations

## 🚀 Deployment

### Vercel Deployment (Recommended)
1. **Connect Repository**: Link your GitHub repository to Vercel
2. **Set Environment Variables** in Vercel dashboard:
   - `JWT_SECRET`: Your secure JWT secret key (32+ characters)
   - `NODE_ENV`: production
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `DB_SSL`: true
3. **Deploy Backend**: Vercel will automatically deploy the backend
4. **Deploy Frontend**: Deploy the `frontend-js` directory as a separate Vercel project
5. **Update API URL**: Update `apiBaseUrl` in `frontend-js/index.html` with your backend URL

### Alternative Deployment
- **Backend**: Any Node.js hosting (Heroku, Railway, DigitalOcean)
- **Frontend**: Any static hosting (Netlify, GitHub Pages, AWS S3)
- **Database**: PostgreSQL hosting (Supabase, Neon, AWS RDS)

### Production Checklist
- ✅ Environment variables configured
- ✅ Database connection established
- ✅ JWT secret is secure and random
- ✅ CORS configured for your frontend domain
- ✅ Rate limiting enabled
- ✅ SSL/HTTPS enabled

## 🔒 Security Features

- **CORS**: Enabled for cross-origin requests
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Helmet.js**: Security headers
- **JWT Tokens**: 24-hour expiration
- **Password Hashing**: bcrypt with salt rounds
- **SQL Injection Protection**: Parameterized queries with PostgreSQL
- **Tenant Isolation**: Strict data segregation

## 📊 Database Schema

### Tenants Table
```sql
CREATE TABLE tenants (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  plan VARCHAR(50) DEFAULT 'free' CHECK(plan IN ('free', 'pro')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'member' CHECK(role IN ('admin', 'member')),
  tenant_id INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
);
```

### Notes Table
```sql
CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  updated_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);
```

### Indexes
```sql
CREATE INDEX idx_notes_tenant_id ON notes(tenant_id);
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
```

## 🧪 Testing

### Quick Test
1. **Access the application** via your deployed frontend URL
2. **Login** with any test account (password: `password`)
3. **Create notes** to test CRUD functionality
4. **Test tenant isolation** by logging in with different tenant accounts
5. **Test plan limits** by creating 3+ notes on free plan
6. **Test upgrade** by using admin account to upgrade tenant

### Comprehensive Testing
1. **Authentication**: Verify JWT token generation and validation
2. **Tenant Isolation**: Create notes with different tenants, verify data segregation
3. **Role Testing**: Test admin vs member permissions (invite, upgrade)
4. **Plan Limits**: Test 3-note limit enforcement on free plan
5. **Upgrade Flow**: Test tenant upgrade to Pro plan and immediate effect
6. **CRUD Operations**: Test all note operations (create, read, update, delete)
7. **Error Handling**: Test invalid credentials, expired tokens, unauthorized access

### API Testing
Use tools like Postman, curl, or the included test script:

```bash
# Test health endpoint
curl https://your-backend.vercel.app/health

# Test comprehensive system data
curl https://your-backend.vercel.app/test

# Login and get token
curl -X POST https://your-backend.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@acme.test","password":"password"}'

# Create note (replace YOUR_TOKEN with actual token)
curl -X POST https://your-backend.vercel.app/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"Test Note","content":"This is a test note"}'

# Upgrade tenant (admin only)
curl -X POST https://your-backend.vercel.app/tenants/acme/upgrade \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Automated Testing
The application includes a PowerShell test script (`test-api.ps1`) for comprehensive API testing:

```powershell
# Run the test script
powershell -ExecutionPolicy Bypass -File .\test-api.ps1
```

## ✅ Evaluation Criteria Compliance

This application fully meets all evaluation requirements:

### **a. Health Endpoint Availability** ✅
- **Endpoint**: `GET /health` - Returns `{"status": "ok"}`
- **Purpose**: Automated testing and monitoring

### **b. Successful Login for All Predefined Accounts** ✅
- **4 Test Accounts** with password `password`:
  - `admin@acme.test` (Admin, Acme Corporation)
  - `user@acme.test` (Member, Acme Corporation)
  - `admin@globex.test` (Admin, Globex Corporation)
  - `user@globex.test` (Member, Globex Corporation)

### **c. Enforcement of Tenant Isolation** ✅
- **Strict data segregation** - Users only see their tenant's data
- **Database-level isolation** - All queries include `tenant_id` filtering
- **API-level enforcement** - All endpoints validate tenant ownership

### **d. Role-based Restrictions** ✅
- **Admin-only features**: Invite users, upgrade tenants, view statistics
- **Member restrictions**: Cannot invite users or upgrade plans
- **JWT-based authorization** with role validation

### **e. Free Plan Note Limit & Upgrade** ✅
- **Free Plan**: Maximum 3 notes per tenant
- **Pro Plan**: Unlimited notes
- **Upgrade endpoint**: `POST /tenants/:slug/upgrade` (Admin only)
- **Immediate effect**: Plan changes take effect instantly

### **f. Correct Functioning of All CRUD Endpoints** ✅
- **POST /notes** - Create notes with tenant isolation
- **GET /notes** - List tenant notes
- **GET /notes/:id** - Get specific note
- **PUT /notes/:id** - Update notes with updater tracking
- **DELETE /notes/:id** - Delete notes

### **g. Presence and Accessibility of Frontend** ✅
- **Professional UI** - Minimal, responsive design
- **Full functionality** - All CRUD operations available
- **Real-time updates** - Instant UI updates
- **Error handling** - User-friendly error messages

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For support or questions, please open an issue in the GitHub repository.
