# Courier & Package Tracking System Documentation

## Project Overview
A full-stack web application for managing courier services, package tracking, and delivery management using Flask and MySQL.

## Tech Stack
- **Backend**: Python 3.x with Flask framework
- **Database**: MySQL
- **Frontend**: Bootstrap 5 for responsive design
- **Authentication**: Flask Session and Werkzeug Security
- **Template Engine**: Jinja2

## Project Structure
```
courier_system/
├── app.py                 # Main Flask application
├── schema.sql            # Database schema and sample data
├── requirements.txt      # Project dependencies
├── static/              # Static assets
│   ├── css/
│   │   └── style.css    # Custom styling
│   └── js/
│       └── script.js    # Client-side functionality
├── templates/           # HTML templates
│   ├── base.html        # Base template with nav
│   ├── index.html       # Homepage
│   ├── login.html       # Customer login
│   ├── signup.html      # New customer registration
│   ├── dashboard.html   # Customer dashboard
│   ├── create_package.html  # Package creation form
│   ├── track.html       # Package tracking
│   ├── admin_login.html # Staff login
│   └── admin/          # Admin section templates
│       ├── packages.html
│       ├── update_status.html
│       └── confirm_delivery.html
└── tests/              # Testing utilities
    ├── test_queries.sql # SQL test queries
    └── test_http.py    # API endpoint tests
```

## Database Design

### Tables
1. **Customer**
   - Primary key: customer_id
   - Stores user details and login credentials
   - Fields: name, address, mobile_no, email, password

2. **Branch**
   - Primary key: branch_id
   - Stores courier branch information
   - Fields: branch_name, location, address, contact_no

3. **Staff**
   - Primary key: staff_id
   - Foreign key: branch_id references Branch
   - Stores staff details including role (Admin/DeliveryAgent)
   - Fields: name, role, contact_no, email, password

4. **Package**
   - Primary key: package_id
   - Foreign keys: customer_id, branch_id
   - Stores package details and current status
   - Fields: tracking_id, weight, cost, booking_date, delivery_date, status

5. **Tracking_Details**
   - Primary key: tracking_detail_id
   - Foreign key: package_id references Package
   - Stores package movement history
   - Fields: current_location, status, update_time

6. **Delivery**
   - Primary key: delivery_id
   - Foreign keys: package_id, staff_id
   - Stores delivery completion details
   - Fields: recipient_name, recipient_contact, delivery_date, delivery_status

### Database Features
1. **Stored Procedures**
   - `sp_create_package`: Generates tracking ID and creates package
   - `sp_update_status`: Updates package status and tracking history
   - `sp_confirm_delivery`: Records delivery completion

2. **Functions**
   - `compute_shipping_cost`: Calculates shipping cost based on weight and service type

3. **Triggers**
   - `trg_package_status_change`: Automatically logs status changes

## Application Workflow

### Customer Journey
1. **Registration & Login**
   - Customer signs up with email and password
   - Password is hashed using Werkzeug security
   - Session-based authentication maintains login state

2. **Creating Package**
   - Customer fills package details (weight, service type)
   - System generates unique tracking ID
   - Initial status set to 'Booked'
   - Cost calculated automatically

3. **Tracking Package**
   - Enter tracking ID to view:
     - Current status
     - Complete movement history
     - Delivery details if completed

### Staff Journey
1. **Staff Login**
   - Separate login portal for staff
   - Role-based access (Admin/DeliveryAgent)

2. **Package Management**
   - View all packages
   - Update package status
   - Record package location
   - Confirm deliveries

### Status Flow
Package goes through these states:
1. Booked
2. Picked Up
3. In Transit
4. Out for Delivery
5. Delivered

## Security Features
1. **Password Security**
   - Passwords hashed using Werkzeug
   - No plaintext passwords stored

2. **Session Management**
   - Flask session for user state
   - Role-based access control

3. **SQL Injection Prevention**
   - Parameterized queries
   - Input validation and sanitization

## Testing Tools

### SQL Tests (test_queries.sql)
- Verify database functionality
- Test stored procedures
- Generate reports
- Demonstration queries for review

### HTTP Tests (test_http.py)
- Automated API testing
- Tests all endpoints
- Verifies authentication
- Checks package operations

## Running the Project

1. **Setup Database**
```bash
mysql -u root -p < schema.sql
```

2. **Install Dependencies**
```bash
pip install -r requirements.txt
```

3. **Start Application**
```bash
python app.py
```

4. **Access Application**
- Main site: http://localhost:5000
- Customer login: http://localhost:5000/login
- Staff login: http://localhost:5000/admin_login

## Default Credentials

### Admin Login
- Email: admin
- Password: admin

### Test Customer
Create new account via signup page.

## Key Features
1. Real-time package tracking
2. Automated cost calculation
3. Complete tracking history
4. Role-based access control
5. Responsive design
6. Secure authentication
7. Email validation
8. Error handling and feedback

## Tools & Libraries Used
1. **Flask**: Web framework
2. **MySQL**: Database
3. **Bootstrap**: Frontend styling
4. **Werkzeug**: Security and utilities
5. **Flask-MySQLdb**: Database integration
6. **Jinja2**: Template engine
7. **Python dotenv**: Environment management

## Best Practices Implemented
1. Modular code structure
2. Secure password handling
3. Consistent error handling
4. Database connection management
5. Input validation
6. Proper session management
7. Responsive UI design
8. Clean code with comments

## Future Enhancements Possible
1. Email notifications
2. Payment integration
3. QR code for tracking
4. Mobile app interface
5. Route optimization
6. Analytics dashboard
7. Bulk package creation
8. API documentation

## Maintenance
- Regular database backups
- Log rotation
- Security updates
- Performance monitoring
- Error logging