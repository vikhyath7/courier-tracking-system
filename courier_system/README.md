# Courier & Package Tracking System

A complete courier management and tracking system built with Flask and MySQL.

## Features

- Customer registration and login
- Package creation and tracking
- Staff management and admin interface
- Real-time status updates
- Delivery confirmation system
- Comprehensive tracking history

## Project Structure

```
courier_system/
├── app.py               # Main Flask application
├── schema.sql          # Database schema and sample data
├── requirements.txt    # Project dependencies
├── static/
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── script.js
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── login.html
│   ├── signup.html
│   ├── dashboard.html
│   ├── create_package.html
│   ├── track.html
│   ├── admin_login.html
│   └── admin/
│       ├── packages.html
│       ├── update_status.html
│       └── confirm_delivery.html
└── tests/
    ├── test_queries.sql
    └── test_http.py
```

## Setup Instructions

1. Create a MySQL database:
   ```bash
   mysql -u root -p < schema.sql
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure database connection in app.py:
   ```python
   app.config['MYSQL_HOST'] = 'localhost'
   app.config['MYSQL_USER'] = 'your_username'
   app.config['MYSQL_PASSWORD'] = 'your_password'
   app.config['MYSQL_DB'] = 'courier_db'
   ```

4. Run the application:
   ```bash
   python app.py
   ```

## Test Cases & Sample Flows

### Customer Flow
1. Sign up with email and password
2. Login with credentials
3. Create new package
4. Track package status
5. View package history

### Admin/Staff Flow
1. Login with staff credentials
2. View all packages
3. Update package status
4. Confirm deliveries

### SQL Test Queries (tests/test_queries.sql)
1. Nested Query: Find customers with pending deliveries
2. Join Query: Package details with customer and branch info
3. Aggregate Query: Daily shipment statistics
4. Trigger Test: Status update tracking
5. Procedure Tests: Package creation, status updates, delivery confirmation

## Review-2 Screenshots Required

1. Database Creation:
   - schema.sql execution output
   - Sample data insertion results

2. Basic Functionality:
   - Customer registration page
   - Login page
   - Package creation form
   - Package tracking results

3. SQL Demonstrations:
   - Trigger execution
   - Stored procedure calls
   - Complex query results

## Review-3 Screenshots Required

1. Complete System Flow:
   - Customer dashboard with packages
   - Admin package management
   - Status update interface
   - Delivery confirmation form

2. Advanced Features:
   - Tracking history timeline
   - Branch-wise reports
   - Status update notifications

3. Code Quality:
   - Database schema with constraints
   - Stored procedures and triggers
   - Error handling examples

## Implementation Notes

### ER to Schema Mapping
- Customer table maps to Customer entity with attributes
- Package table includes foreign keys to Customer and Branch
- Tracking_Details provides history through package_id reference
- Staff table connects to Branch through branch_id

### Stored Procedures & Triggers
- compute_shipping_cost: Calculates shipping cost based on weight and service type
- sp_create_package: Generates tracking ID and initializes package
- sp_update_status: Updates status and maintains tracking history
- trg_package_status_change: Automatically logs status changes

### Security Measures
- Password hashing using Werkzeug
- Session-based authentication
- Input validation and sanitization
- Parameterized SQL queries

## Testing

Run the automated tests:
```bash
cd tests
python test_http.py
```

For SQL tests:
```bash
mysql -u root -p courier_db < test_queries.sql
```

## Common Issues & Solutions

1. MySQL Connection:
   - Verify credentials in app.py
   - Ensure MySQL service is running
   - Check database name and permissions

2. Package Creation:
   - Validate weight and cost calculations
   - Verify branch existence
   - Check tracking ID generation

3. Status Updates:
   - Confirm staff authorization
   - Verify tracking history entries
   - Check trigger execution

## Future Enhancements

1. Email notifications for status updates
2. QR code generation for tracking
3. Payment integration
4. Mobile app interface
5. Route optimization for deliveries

## Contributors

- [Your Name]
- Course: UE23CS351A
- [University Name]