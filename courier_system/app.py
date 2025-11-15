from flask import Flask, render_template, request, redirect, url_for, session, flash
try:
    from flask_mysqldb import MySQL
    _USE_FLASK_MYSQldb = True
except Exception:
    # If flask_mysqldb isn't available (common on some Windows setups),
    # we'll fall back to mysql-connector-python via a small shim below.
    MySQL = None
    _USE_FLASK_MYSQldb = False

from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import os

app = Flask(__name__)

# Database configuration
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'  # Change as needed
app.config['MYSQL_PASSWORD'] = 'root'   # Change as needed
app.config['MYSQL_DB'] = 'courier_db'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

# Secret key for session
app.secret_key = 'your_secret_key_here'  # Change this in production

if _USE_FLASK_MYSQldb:
    mysql = MySQL(app)
else:
    # Simple shim that provides a `connection` property similar to flask_mysqldb
    # but using mysql-connector-python. This avoids import errors and is easier
    # to install on Windows. You'll still need `mysql-connector-python`.
    class MySQLShim:
        def __init__(self, flask_app):
            self.config = flask_app.config

        @property
        def connection(self):
            import mysql.connector
            cfg = {
                'host': self.config.get('MYSQL_HOST', 'localhost'),
                'user': self.config.get('MYSQL_USER', 'root'),
                'password': self.config.get('MYSQL_PASSWORD', ''),
                'database': self.config.get('MYSQL_DB', None),
            }
            # create a new connection for each access to mimic flask_mysqldb behaviour
            raw_conn = mysql.connector.connect(**cfg)

            # Wrap the raw connection to provide cursor(dictionary=True) by default
            class ConnWrapper:
                def __init__(self, conn):
                    self._conn = conn

                def cursor(self):
                    return self._conn.cursor(dictionary=True)

                def commit(self):
                    return self._conn.commit()

                def rollback(self):
                    return self._conn.rollback()

                def close(self):
                    return self._conn.close()

            return ConnWrapper(raw_conn)

    mysql = MySQLShim(app)

# Login decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'customer_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def staff_login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'staff_id' not in session:
            return redirect(url_for('admin_login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        name = request.form['name']
        address = request.form['address']
        mobile = request.form['mobile']
        email = request.form['email']
        password = request.form['password']
        hashed_password = generate_password_hash(password)
        
        cur = mysql.connection.cursor()
        try:
            cur.execute("""
                INSERT INTO Customer (name, address, mobile_no, email, password)
                VALUES (%s, %s, %s, %s, %s)
            """, (name, address, mobile, email, hashed_password))
            mysql.connection.commit()
            flash('Registration successful! Please login.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            flash('An error occurred. Email might already be registered.', 'error')
        finally:
            cur.close()
    
    return render_template('signup.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        cur = mysql.connection.cursor()
        cur.execute('SELECT * FROM Customer WHERE email = %s', (email,))
        user = cur.fetchone()
        cur.close()
        
        if user and check_password_hash(user['password'], password):
            session['customer_id'] = user['customer_id']
            session['name'] = user['name']
            return redirect(url_for('dashboard'))
        
        flash('Invalid email or password', 'error')
    
    return render_template('login.html')

@app.route('/dashboard')
@login_required
def dashboard():
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT p.*, b.branch_name, 
               (SELECT status FROM Tracking_Details WHERE package_id = p.package_id 
                ORDER BY update_time DESC LIMIT 1) as latest_status
        FROM Package p
        JOIN Branch b ON p.branch_id = b.branch_id
        WHERE p.customer_id = %s
        ORDER BY p.booking_date DESC
    """, (session['customer_id'],))
    packages = cur.fetchall()
    cur.close()
    
    return render_template('dashboard.html', packages=packages)

@app.route('/create_package', methods=['GET', 'POST'])
@login_required
def create_package():
    if request.method == 'POST':
        weight = float(request.form['weight'])
        branch_id = int(request.form['branch_id'])
        service_type = request.form['service_type']
        
        cur = mysql.connection.cursor()
        try:
            cur.execute("CALL sp_create_package(%s, %s, %s, %s, @tracking_id)",
                       (session['customer_id'], branch_id, weight, service_type))
            cur.execute("SELECT @tracking_id as tracking_id")
            result = cur.fetchone()
            mysql.connection.commit()
            
            if result and result['tracking_id']:
                flash(f'Package created successfully! Tracking ID: {result["tracking_id"]}', 'success')
                return redirect(url_for('dashboard'))
        except Exception as e:
            flash('An error occurred while creating the package.', 'error')
        finally:
            cur.close()
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM Branch")
    branches = cur.fetchall()
    cur.close()
    
    return render_template('create_package.html', branches=branches)

@app.route('/track', methods=['GET', 'POST'])
def track():
    if request.method == 'POST':
        tracking_id = request.form['tracking_id']
        
        cur = mysql.connection.cursor()
        cur.execute("""
            SELECT p.*, c.name as customer_name, b.branch_name,
                   (SELECT status FROM Tracking_Details WHERE package_id = p.package_id 
                    ORDER BY update_time DESC LIMIT 1) as latest_status
            FROM Package p
            JOIN Customer c ON p.customer_id = c.customer_id
            JOIN Branch b ON p.branch_id = b.branch_id
            WHERE p.tracking_id = %s
        """, (tracking_id,))
        package = cur.fetchone()
        
        tracking_history = None
        if package:
            cur.execute("""
                SELECT * FROM Tracking_Details
                WHERE package_id = %s
                ORDER BY update_time DESC
            """, (package['package_id'],))
            tracking_history = cur.fetchall()
        
        cur.close()
        return render_template('track.html', package=package, tracking_history=tracking_history)
    
    return render_template('track.html')

@app.route('/admin_login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        cur = mysql.connection.cursor()
        cur.execute('SELECT * FROM Staff WHERE email = %s', (email,))
        staff = cur.fetchone()
        cur.close()
        
        # Allow either a stored hashed password (recommended) or a plaintext
        # password stored in the DB (convenience for testing). In production
        # always store hashed passwords.
        if staff:
            stored_pw = staff.get('password')
            pw_ok = False
            try:
                if stored_pw and check_password_hash(stored_pw, password):
                    pw_ok = True
            except Exception:
                # If stored_pw is not a valid hash, check plaintext equality
                pw_ok = (stored_pw == password)

            if not pw_ok and stored_pw == password:
                pw_ok = True

            if pw_ok:
                session['staff_id'] = staff['staff_id']
                session['is_admin'] = staff['role'] == 'Admin'
                session['staff_name'] = staff['name']
                return redirect(url_for('admin_packages'))
        
        flash('Invalid email or password', 'error')
    
    return render_template('admin_login.html')

@app.route('/admin/packages')
@staff_login_required
def admin_packages():
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT p.*, c.name as customer_name, b.branch_name,
               (SELECT status FROM Tracking_Details WHERE package_id = p.package_id 
                ORDER BY update_time DESC LIMIT 1) as latest_status
        FROM Package p
        JOIN Customer c ON p.customer_id = c.customer_id
        JOIN Branch b ON p.branch_id = b.branch_id
        ORDER BY p.booking_date DESC
    """)
    packages = cur.fetchall()
    cur.close()
    
    return render_template('admin/packages.html', packages=packages)

@app.route('/admin/update_status', methods=['GET', 'POST'])
@staff_login_required
def update_status():
    if request.method == 'POST':
        tracking_id = request.form['tracking_id']
        status = request.form['status']
        location = request.form['location']
        
        cur = mysql.connection.cursor()
        try:
            cur.execute("CALL sp_update_status(%s, %s, %s, %s)",
                       (tracking_id, location, status, session['staff_id']))
            mysql.connection.commit()
            flash('Status updated successfully!', 'success')
        except Exception as e:
            flash('An error occurred while updating status.', 'error')
        finally:
            cur.close()
        
        return redirect(url_for('admin_packages'))
    
    return render_template('admin/update_status.html')

@app.route('/admin/confirm_delivery', methods=['GET', 'POST'])
@staff_login_required
def confirm_delivery():
    if request.method == 'POST':
        tracking_id = request.form['tracking_id']
        recipient_name = request.form['recipient_name']
        recipient_contact = request.form['recipient_contact']
        
        cur = mysql.connection.cursor()
        try:
            cur.execute("CALL sp_confirm_delivery(%s, %s, %s, %s)",
                       (tracking_id, recipient_name, recipient_contact, session['staff_id']))
            mysql.connection.commit()
            flash('Delivery confirmed successfully!', 'success')
        except Exception as e:
            flash('An error occurred while confirming delivery.', 'error')
        finally:
            cur.close()
        
        return redirect(url_for('admin_packages'))
    
    return render_template('admin/confirm_delivery.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)