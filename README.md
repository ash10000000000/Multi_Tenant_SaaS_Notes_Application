# Multi-Tenant SaaS Notes Application

A comprehensive multi-tenant SaaS Notes Application with strict tenant isolation, role-based access control, and subscription feature gating. Built with Node.js/Express backend and Kotlin frontend, deployed on Vercel.

## 🏗️ Architecture

### Multi-Tenancy Approach
This application uses **Shared Schema with Tenant ID** approach:
- Single database with tenant isolation through `tenant_id` foreign keys
- All tables include `tenant_id` column for data segregation
- Strict tenant isolation enforced at the application level
- Cost-effective and scalable for moderate tenant counts

### Technology Stack
- **Backend**: Node.js, Express.js, PostgreSQL, JWT
- **Frontend**: JavaScript (HTML5, CSS3)
- **Database**: PostgreSQL with connection pooling
- **Deployment**: Vercel (both backend and frontend)
- **Security**: Helmet.js, CORS, Rate limiting, bcrypt

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
- ✅ Full CRUD operations for notes
- ✅ Tenant-isolated note storage
- ✅ Role-based access control
- ✅ Real-time note limits enforcement

### Frontend
- ✅ Modern JavaScript web application
- ✅ Responsive design
- ✅ Real-time note management
- ✅ Upgrade prompts for free plan users
- ✅ User-friendly interface

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
- `POST /auth/login` - User login
- `POST /auth/register` - User registration (testing)

### Notes (Requires Authentication)
- `POST /notes` - Create a note
- `GET /notes` - List all notes for tenant
- `GET /notes/:id` - Get specific note
- `PUT /notes/:id` - Update a note
- `DELETE /notes/:id` - Delete a note

### Tenants (Admin Only)
- `POST /tenants/:slug/upgrade` - Upgrade to Pro plan
- `GET /tenants/:slug` - Get tenant info
- `GET /tenants/:slug/stats` - Get tenant statistics

### System
- `GET /health` - Health check endpoint

## 🛠️ Local Development

### Backend Setup
```bash
# Install dependencies
npm install

# Set up environment variables
cp env.example .env
# Edit .env with your JWT_SECRET and DATABASE_URL

# Start development server
npm run dev
```

### Frontend Setup
The frontend is a simple JavaScript application in the `frontend-js` directory. No build process required - just deploy the `index.html` file to Vercel.

## 🚀 Deployment

### Backend Deployment (Vercel)
1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard:
   - `JWT_SECRET`: Your secure JWT secret key
   - `NODE_ENV`: production
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `DB_SSL`: true
3. Deploy the backend
4. Update the `apiBaseUrl` in `frontend-js/index.html` with your Vercel backend URL

### Frontend Deployment (Vercel)
1. Deploy the `frontend-js` directory to Vercel
2. Configure Vercel to serve the static files

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
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free' CHECK(plan IN ('free', 'pro')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Users Table
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'member')),
  tenant_id INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id)
);
```

### Notes Table
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants (id),
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

## 🧪 Testing

### Manual Testing
1. **Login Test**: Use test accounts to verify authentication
2. **Tenant Isolation**: Create notes with different tenants, verify isolation
3. **Role Testing**: Test admin vs member permissions
4. **Plan Limits**: Test 3-note limit on free plan
5. **Upgrade Flow**: Test tenant upgrade to Pro plan

### API Testing
Use tools like Postman or curl to test API endpoints:

```bash
# Login
curl -X POST https://your-backend.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@acme.test","password":"password"}'

# Create note (with token from login)
curl -X POST https://your-backend.vercel.app/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"Test Note","content":"This is a test note"}'
```

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request



For support or questions, please open an issue in the GitHub repository.
