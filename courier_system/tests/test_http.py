import requests
import json

BASE_URL = 'http://localhost:5000'

def test_signup():
    data = {
        'name': 'Test User',
        'email': 'test@example.com',
        'mobile': '9999999999',
        'address': 'Test Address',
        'password': 'testpass123'
    }
    response = requests.post(f'{BASE_URL}/signup', data=data)
    print('Signup Test:', response.status_code)
    return response.cookies

def test_login():
    data = {
        'email': 'test@example.com',
        'password': 'testpass123'
    }
    response = requests.post(f'{BASE_URL}/login', data=data)
    print('Login Test:', response.status_code)
    return response.cookies

def test_create_package(cookies):
    data = {
        'weight': '2.5',
        'branch_id': '1',
        'service_type': 'Express'
    }
    response = requests.post(f'{BASE_URL}/create_package', data=data, cookies=cookies)
    print('Create Package Test:', response.status_code)
    return response.text

def test_track_package(tracking_id):
    data = {'tracking_id': tracking_id}
    response = requests.post(f'{BASE_URL}/track', data=data)
    print('Track Package Test:', response.status_code)
    return response.text

def test_admin_login():
    data = {
        'email': 'admin@courier.com',
        'password': 'hashed_admin_pass'
    }
    response = requests.post(f'{BASE_URL}/admin_login', data=data)
    print('Admin Login Test:', response.status_code)
    return response.cookies

def test_update_status(cookies, tracking_id):
    data = {
        'tracking_id': tracking_id,
        'status': 'In Transit',
        'location': 'Test Location'
    }
    response = requests.post(f'{BASE_URL}/admin/update_status', data=data, cookies=cookies)
    print('Update Status Test:', response.status_code)

def test_confirm_delivery(cookies, tracking_id):
    data = {
        'tracking_id': tracking_id,
        'recipient_name': 'Test Recipient',
        'recipient_contact': '8888888888'
    }
    response = requests.post(f'{BASE_URL}/admin/confirm_delivery', data=data, cookies=cookies)
    print('Confirm Delivery Test:', response.status_code)

def run_all_tests():
    print("Starting tests...")
    
    # Test customer flow
    cookies = test_signup()
    if not cookies:
        cookies = test_login()
    
    # Create package
    result = test_create_package(cookies)
    tracking_id = None
    if 'Tracking ID:' in result:
        tracking_id = result.split('Tracking ID:')[1].strip()
    
    if tracking_id:
        # Track package
        test_track_package(tracking_id)
        
        # Test admin flow
        admin_cookies = test_admin_login()
        if admin_cookies:
            test_update_status(admin_cookies, tracking_id)
            test_confirm_delivery(admin_cookies, tracking_id)
    
    print("Tests completed!")

if __name__ == '__main__':
    run_all_tests()