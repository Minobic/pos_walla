from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from flask_cors import CORS
import hashlib
import re

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:mayank@localhost/pos_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

CORS(app)

db = SQLAlchemy(app)

# User Table
class User(db.Model):
    __tablename__ = 'User'
    user_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_name = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)  # Hashed password will be stored here
    role = db.Column(db.Enum('cashier', 'manager', 'admin'), nullable=False)
    status = db.Column(db.Enum('active', 'pending', 'rejected', 'inactive'), nullable=False, default='pending')
    first_name = db.Column(db.String(255), nullable=False)
    last_name = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    phone = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Category Table
class Category(db.Model):
    __tablename__ = 'Category'
    cat_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    cat_name = db.Column(db.String(255), unique=True, nullable=False)
    cat_description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Product Table
class Product(db.Model):
    __tablename__ = 'Product'
    product_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_name = db.Column(db.String(255), nullable=False)
    product_description = db.Column(db.Text)
    sale_price = db.Column(db.Numeric(10, 2), nullable=False)
    mrp_price = db.Column(db.Numeric(10, 2), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('Category.cat_id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Product Batch Table
class ProductBatch(db.Model):
    __tablename__ = 'ProductBatch'
    p_batch_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    p_batch_name = db.Column(db.String(255), nullable=False)
    p_id = db.Column(db.Integer, db.ForeignKey('Product.product_id'), nullable=False)
    p_batch_exp = db.Column(db.Date, nullable=False)
    p_batch_mfg = db.Column(db.Date, nullable=False)
    p_batch_created_at = db.Column(db.DateTime, default=datetime.utcnow)
    p_batch_updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Barcode Generator Table
class BarcodeGenerator(db.Model):
    __tablename__ = 'BarcodeGenerator'
    barcode_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    product_name = db.Column(db.String(255), nullable=False)  # New field
    barcode_header = db.Column(db.String(255), nullable=False)  # New field
    barcode_number = db.Column(db.String(255), unique=True, nullable=False)  # Renamed from barcode_value
    line_1 = db.Column(db.String(255))  # New field
    line_2 = db.Column(db.String(255))  # New field
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Inventory Table
class Inventory(db.Model):
    __tablename__ = 'Inventory'
    inventory_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    p_id = db.Column(db.Integer, db.ForeignKey('Product.product_id'), nullable=False)
    p_batch_id = db.Column(db.Integer, db.ForeignKey('ProductBatch.p_batch_id'), nullable=False)
    stock_level = db.Column(db.Enum('high', 'low', 'medium'), nullable=False)
    p_batch_quantity = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Customer Table
class Customer(db.Model):
    __tablename__ = 'Customer'
    customer_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_name = db.Column(db.String(255), nullable=False)
    customer_mobile = db.Column(db.String(255), unique=True, nullable=False)

# Invoice Table
class Invoice(db.Model):
    __tablename__ = 'Invoice'
    invoice_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('User.user_id'), nullable=False)
    customer_id = db.Column(db.Integer, db.ForeignKey('Customer.customer_id'), nullable=False)
    total_amount = db.Column(db.Numeric(10, 2), nullable=False)
    sub_total = db.Column(db.Numeric(10, 2), nullable=False)
    discount_id = db.Column(db.Integer, db.ForeignKey('Coupon.coupon_id'))
    discount_amount = db.Column(db.Numeric(10, 2))
    tax_id = db.Column(db.Integer, db.ForeignKey('Tax.tax_id'))
    tax_amount = db.Column(db.Numeric(10, 2))
    loyalty_points = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# InvoiceItem Table
class InvoiceItem(db.Model):
    __tablename__ = 'InvoiceItem'
    invoice_item_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    invoice_id = db.Column(db.Integer, db.ForeignKey('Invoice.invoice_id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('Product.product_id'), nullable=False)
    p_batch_id = db.Column(db.Integer, db.ForeignKey('ProductBatch.p_batch_id'), nullable=True)
    quantity = db.Column(db.Integer, nullable=False)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# InvoicePayment Table
class InvoicePayment(db.Model):
    __tablename__ = 'InvoicePayment'
    payment_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    invoice_id = db.Column(db.Integer, db.ForeignKey('Invoice.invoice_id'), nullable=False)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    payment_method = db.Column(db.Enum('cash', 'credit_card', 'debit_card', 'mobile_payment'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Coupon Table
class Coupon(db.Model):
    __tablename__ = 'Coupon'
    coupon_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    coupon_code = db.Column(db.String(255), unique=True, nullable=False)
    discount_type = db.Column(db.Enum('percentage', 'fixed'), nullable=False)
    value = db.Column(db.Numeric(10, 2), nullable=False)
    start_date = db.Column(db.DateTime, nullable=False)
    end_date = db.Column(db.DateTime, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Tax Table
class Tax(db.Model):
    __tablename__ = 'Tax'
    tax_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tax_name = db.Column(db.String(255), nullable=False)
    tax_rate = db.Column(db.Numeric(5, 2), nullable=False)
    gst = db.Column(db.Numeric(5, 2), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Loyalty Points Table
class LoyaltyPoints(db.Model):
    __tablename__ = 'LoyaltyPoints'
    loyalty_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('Customer.customer_id'), nullable=False)
    points = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Registration Endpoint
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    # Validate input data
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    required_fields = ['username', 'firstName', 'lastName', 'email', 'phone', 'password', 'confirmPassword', 'role']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400

    if data['password'] != data['confirmPassword']:
        return jsonify({'error': 'Passwords do not match'}), 400

    if not re.match(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$', data['email']):
        return jsonify({'error': 'Invalid email format'}), 400

    # Check if username or email already exists
    if User.query.filter_by(user_name=data['username']).first():
        return jsonify({'error': 'Username already exists'}), 400

    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already exists'}), 400

    # Hash the password using SHA-256
    hashed_password = hashlib.sha256(data['password'].encode('utf-8')).hexdigest()

    # Create new user
    new_user = User(
        user_name=data['username'],
        password=hashed_password,  # Store the hashed password
        role=data['role'],
        first_name=data['firstName'],
        last_name=data['lastName'],
        email=data['email'],
        phone=data['phone']
    )

    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'User registered successfully', 'user_id': new_user.user_id}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    # Hash the password using SHA-256
    hashed_password = hashlib.sha256(password.encode('utf-8')).hexdigest()

    user = User.query.filter_by(email=email).first()
    if user and user.password == hashed_password:  # Compare the hashed password
        return jsonify({
            'name': f"{user.first_name} {user.last_name}",  # Combine first and last name
            'role': user.role,
            'user_id': user.user_id,
            # Add any other fields you want to return
        }), 200
    else:
        return jsonify({'error': 'Invalid email or password'}), 401

@app.route('/categories', methods=['GET'])
def get_categories():
    categories = Category.query.all()
    categories_list = []
    for category in categories:
        categories_list.append({
            'cat_id': category.cat_id,
            'cat_name': category.cat_name,
            'cat_description': category.cat_description,
            'created_at': category.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': category.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    return jsonify(categories_list), 200

@app.route('/categories', methods=['POST'])
def add_category():
    data = request.get_json()

    # Validate input data
    if not data or 'cat_name' not in data or 'cat_description' not in data:
        return jsonify({'error': 'cat_name and cat_description are required'}), 400

    # Create new category
    new_category = Category(
        cat_name=data['cat_name'],
        cat_description=data['cat_description']
    )

    db.session.add(new_category)
    db.session.commit()

    return jsonify({
        'cat_id': new_category.cat_id,
        'cat_name': new_category.cat_name,
        'cat_description': new_category.cat_description,
        'created_at': new_category.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': new_category.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 201

@app.route('/categories/<int:cat_id>', methods=['PUT'])
def update_category(cat_id):
    data = request.get_json()

    # Validate input data
    if not data or 'cat_name' not in data or 'cat_description' not in data:
        return jsonify({'error': 'cat_name and cat_description are required'}), 400

    category = Category.query.get(cat_id)
    if not category:
        return jsonify({'error': 'Category not found'}), 404

    category.cat_name = data['cat_name']
    category.cat_description = data['cat_description']
    db.session.commit()

    return jsonify({
        'cat_id': category.cat_id,
        'cat_name': category.cat_name,
        'cat_description': category.cat_description,
        'created_at': category.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': category.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 200

@app.route('/categories/<int:cat_id>', methods=['DELETE'])
def delete_category(cat_id):
    category = Category.query.get(cat_id)
    if not category:
        return jsonify({'error': 'Category not found'}), 404

    db.session.delete(category)
    db.session.commit()

    return jsonify({'message': 'Category deleted successfully'}), 200

# Product Endpoints
@app.route('/products', methods=['GET'])
def get_products():
    products = db.session.query(Product, Category.cat_name).join(Category).all()
    products_list = []
    for product, category_name in products:
        products_list.append({
            'product_id': product.product_id,
            'product_name': product.product_name,
            'product_description': product.product_description,
            'sale_price': float(product.sale_price),
            'mrp_price': float(product.mrp_price),
            'quantity': product.quantity,
            'category_id': product.category_id,
            'category_name': category_name,  # Include category name
            'created_at': product.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': product.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    return jsonify(products_list), 200

@app.route('/products', methods=['POST'])
def add_product():
    data = request.get_json()

    if not data or 'product_name' not in data or 'sale_price' not in data or 'mrp_price' not in data or 'quantity' not in data or 'category_id' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    new_product = Product(
        product_name=data['product_name'],
        product_description=data.get('product_description', ''),
        sale_price=data['sale_price'],
        mrp_price=data['mrp_price'],
        quantity=data['quantity'],
        category_id=data['category_id']
    )

    db.session.add(new_product)
    db.session.commit()

    return jsonify({
        'product_id': new_product.product_id,
        'product_name': new_product.product_name,
        'product_description': new_product.product_description,
        'sale_price': float(new_product.sale_price),
        'mrp_price': float(new_product.mrp_price),
        'quantity': new_product.quantity,
        'category_id': new_product.category_id,
        'created_at': new_product.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': new_product.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 201

@app.route('/products/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    data = request.get_json()

    if not data or 'product_name' not in data or 'sale_price' not in data or 'mrp_price' not in data or 'quantity' not in data or 'category_id' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    product = Product.query.get(product_id)
    if not product:
        return jsonify({'error': 'Product not found'}), 404

    product.product_name = data['product_name']
    product.product_description = data.get('product_description', product.product_description)
    product.sale_price = data['sale_price']
    product.mrp_price = data['mrp_price']
    product.quantity = data['quantity']
    product.category_id = data['category_id']
    db.session.commit()

    return jsonify({
        'product_id': product.product_id,
        'product_name': product.product_name,
        'product_description': product.product_description,
        'sale_price': float(product.sale_price),
        'mrp_price': float(product.mrp_price),
        'quantity': product.quantity,
        'category_id': product.category_id,
        'created_at': product.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': product.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 200

@app.route('/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Product.query.get(product_id)
    if not product:
        return jsonify({'error': 'Product not found'}), 404

    db.session.delete(product)
    db.session.commit()

    return jsonify({'message': 'Product deleted successfully'}), 200

# Product Batch Endpoints

# Product Batch Endpoints

@app.route('/product_batches', methods=['GET'])
def get_product_batches():
    product_batches = db.session.query(ProductBatch, Product.product_name).join(Product).all()
    product_batches_list = []
    for batch, product_name in product_batches:
        product_batches_list.append({
            'p_batch_id': batch.p_batch_id,
            'p_batch_name': batch.p_batch_name,
            'p_batch_mfg': batch.p_batch_mfg.strftime('%Y-%m-%d'),  # Format date
            'p_batch_exp': batch.p_batch_exp.strftime('%Y-%m-%d'),  # Format date
            'p_id': batch.p_id,
            'product_name': product_name,  # Include product name
            'created_at': batch.p_batch_created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': batch.p_batch_updated_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    return jsonify(product_batches_list), 200

@app.route('/product_batches', methods=['POST'])
def add_product_batch():
    data = request.get_json()

    # Validate input data
    if not data or 'p_batch_name' not in data or 'p_batch_mfg' not in data or 'p_batch_exp' not in data or 'p_id' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    # Create new product batch
    new_batch = ProductBatch(
        p_batch_name=data['p_batch_name'],
        p_batch_mfg=datetime.strptime(data['p_batch_mfg'], '%Y-%m-%d').date(),
        p_batch_exp=datetime.strptime(data['p_batch_exp'], '%Y-%m-%d').date(),
        p_id=data['p_id']
    )

    db.session.add(new_batch)
    db.session.commit()

    return jsonify({
        'p_batch_id': new_batch.p_batch_id,
        'p_batch_name': new_batch.p_batch_name,
        'p_batch_mfg': new_batch.p_batch_mfg.strftime('%Y-%m-%d'),
        'p_batch_exp': new_batch.p_batch_exp.strftime('%Y-%m-%d'),
        'p_id': new_batch.p_id,
        'created_at': new_batch.p_batch_created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': new_batch.p_batch_updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 201

@app.route('/product_batches/<int:batch_id>', methods=['PUT'])
def update_product_batch(batch_id):
    data = request.get_json()

    # Validate input data
    if not data or 'p_batch_name' not in data or 'p_batch_mfg' not in data or 'p_batch_exp' not in data or 'p_id' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    batch = ProductBatch.query.get(batch_id)
    if not batch:
        return jsonify({'error': 'Product batch not found'}), 404

    batch.p_batch_name = data['p_batch_name']
    batch.p_batch_mfg = datetime.strptime(data['p_batch_mfg'], '%Y-%m-%d').date()
    batch.p_batch_exp = datetime.strptime(data['p_batch_exp'], '%Y-%m-%d').date()
    batch.p_id = data['p_id']
    db.session.commit()

    return jsonify({
        'p_batch_id': batch.p_batch_id,
        'p_batch_name': batch.p_batch_name,
        'p_batch_mfg': batch.p_batch_mfg.strftime('%Y-%m-%d'),
        'p_batch_exp': batch.p_batch_exp.strftime('%Y-%m-%d'),
        'p_id': batch.p_id,
        'created_at': batch.p_batch_created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': batch.p_batch_updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 200

@app.route('/product_batches/<int:batch_id>', methods=['DELETE'])
def delete_product_batch(batch_id):
    batch = ProductBatch.query.get(batch_id)
    if not batch:
        return jsonify({'error': 'Product batch not found'}), 404

    db.session.delete(batch)
    db.session.commit()

    return jsonify({'message': 'Product batch deleted successfully'}), 200

@app.route('/inventories', methods=['GET'])
def get_inventories():
    inventories = (
        db.session.query(Inventory, Product.product_name, ProductBatch.p_batch_name)
        .select_from(Inventory)  # Explicitly set the starting point
        .join(Product, Inventory.p_id == Product.product_id)  # Specify the join condition
        .join(ProductBatch, Inventory.p_batch_id == ProductBatch.p_batch_id)  # Specify the join condition
        .all()
    )
    inventories_list = []
    for inventory, product_name, batch_name in inventories:
        inventories_list.append({
            'inventory_id': inventory.inventory_id,
            'p_id': inventory.p_id,
            'p_batch_id': inventory.p_batch_id,
            'stock_level': inventory.stock_level,
            'p_batch_quantity': inventory.p_batch_quantity,
            'product_name': product_name,  # Include product name
            'p_batch_name': batch_name,     # Include product batch name
            'created_at': inventory.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': inventory.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
        })
    return jsonify(inventories_list), 200

# Add a new inventory
@app.route('/inventories', methods=['POST'])
def add_inventory():
    data = request.get_json()

    if not data or 'p_id' not in data or 'p_batch_id' not in data or 'stock_level' not in data or 'p_batch_quantity' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    new_inventory = Inventory(
        p_id=data['p_id'],
        p_batch_id=data['p_batch_id'],
        stock_level=data['stock_level'],
        p_batch_quantity=data['p_batch_quantity']
    )

    db.session.add(new_inventory)
    db.session.commit()

    return jsonify({
        'inventory_id': new_inventory.inventory_id,
        'p_id': new_inventory.p_id,
        'p_batch_id': new_inventory.p_batch_id,
        'stock_level': new_inventory.stock_level,
        'p_batch_quantity': new_inventory.p_batch_quantity,
        'created_at': new_inventory.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': new_inventory.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 201

# Update an existing inventory
@app.route('/inventories/<int:inventory_id>', methods=['PUT'])
def update_inventory(inventory_id):
    data = request.get_json()

    if not data or 'p_id' not in data or 'p_batch_id' not in data or 'stock_level' not in data or 'p_batch_quantity' not in data:
        return jsonify({'error': 'Missing required fields'}), 400

    inventory = Inventory.query.get(inventory_id)
    if not inventory:
        return jsonify({'error': 'Inventory not found'}), 404

    inventory.p_id = data['p_id']
    inventory.p_batch_id = data['p_batch_id']
    inventory.stock_level = data['stock_level']
    inventory.p_batch_quantity = data['p_batch_quantity']
    db.session.commit()

    return jsonify({
        'inventory_id': inventory.inventory_id,
        'p_id': inventory.p_id,
        'p_batch_id': inventory.p_batch_id,
        'stock_level': inventory.stock_level,
        'p_batch_quantity': inventory.p_batch_quantity,
        'created_at': inventory.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': inventory.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 200

# Delete an inventory
@app.route('/inventories/<int:inventory_id>', methods=['DELETE'])
def delete_inventory(inventory_id):
    inventory = Inventory.query.get(inventory_id)
    if not inventory:
        return jsonify({'error': 'Inventory not found'}), 404

    db.session.delete(inventory)
    db.session.commit()

    return jsonify({'message': 'Inventory deleted successfully'}), 200

@app.route('/barcodes', methods=['GET'])
def get_barcodes():
    barcodes = BarcodeGenerator.query.all()
    barcodes_list = []
    for barcode in barcodes:
        barcodes_list.append({
            'barcode_id': barcode.barcode_id,
            'product_name': barcode.product_name,
            'barcode_header': barcode.barcode_header,
            'barcode_number': barcode.barcode_number,
            'line_1': barcode.line_1,
            'line_2': barcode.line_2,
            'created_at': barcode.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': barcode.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
        })
    return jsonify(barcodes_list), 200

@app.route('/barcodes', methods=['POST'])
def add_barcode():
    data = request.get_json()

    # Validate input data
    if not data or 'product_name' not in data or 'barcode_header' not in data or 'barcode_number' not in data:
        return jsonify({'error': 'product_name, barcode_header, and barcode_number are required'}), 400

    # Check if the barcode number already exists
    if BarcodeGenerator.query.filter_by(barcode_number=data['barcode_number']).first():
        return jsonify({'error': 'Barcode number already exists'}), 400

    # Create new barcode
    new_barcode = BarcodeGenerator(
        product_name=data['product_name'],
        barcode_header=data['barcode_header'],
        barcode_number=data['barcode_number'],
        line_1=data.get('line_1', ''),
        line_2=data.get('line_2', ''),
    )

    db.session.add(new_barcode)
    db.session.commit()

    return jsonify({
        'barcode_id': new_barcode.barcode_id,
        'product_name': new_barcode.product_name,
        'barcode_header': new_barcode.barcode_header,
        'barcode_number': new_barcode.barcode_number,
        'line_1': new_barcode.line_1,
        'line_2': new_barcode.line_2,
        'created_at': new_barcode.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': new_barcode.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
    }), 201

@app.route('/barcodes/<int:barcode_id>', methods=['PUT'])
def update_barcode(barcode_id):
    data = request.get_json()

    # Validate input data
    if not data or 'barcode_number' not in data:
        return jsonify({'error': 'barcode_number is required'}), 400

    barcode = BarcodeGenerator.query.get(barcode_id)
    if not barcode:
        return jsonify({'error': 'Barcode not found'}), 404

    # Update barcode fields
    barcode.product_name = data.get('product_name', barcode.product_name)
    barcode.barcode_header = data.get('barcode_header', barcode.barcode_header)
    barcode.barcode_number = data['barcode_number']
    barcode.line_1 = data.get('line_1', barcode.line_1)
    barcode.line_2 = data.get('line_2', barcode.line_2)
    db.session.commit()

    return jsonify({
        'barcode_id': barcode.barcode_id,
        'product_name': barcode.product_name,
        'barcode_header': barcode.barcode_header,
        'barcode_number': barcode.barcode_number,
        'line_1': barcode.line_1,
        'line_2': barcode.line_2,
        'created_at': barcode.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'updated_at': barcode.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
    }), 200

@app.route('/barcodes/<int:barcode_id>', methods=['DELETE'])
def delete_barcode(barcode_id):
    barcode = BarcodeGenerator.query.get(barcode_id)
    if not barcode:
        return jsonify({'error': 'Barcode not found'}), 404

    db.session.delete(barcode)
    db.session.commit()

    return jsonify({'message': 'Barcode deleted successfully'}), 200

@app.route('/barcodes/<string:barcode>', methods=['GET'])
def get_product_by_barcode(barcode):
    barcode_entry = BarcodeGenerator.query.filter_by(barcode_number=barcode).first()
    if barcode_entry:
        product_details = Product.query.filter_by(product_name=barcode_entry.product_name).first()
        if product_details:
            return jsonify({
                'product_id': product_details.product_id,
                'product_name': product_details.product_name,
                'mrp_price': float(product_details.mrp_price),
                'sale_price': float(product_details.sale_price),
            }), 200
    return jsonify({'error': 'Product not found'}), 404

@app.route('/promocode/<string:promo_code>', methods=['GET'])
def apply_promo_code(promo_code):
    coupon = Coupon.query.filter_by(coupon_code=promo_code).first()
    if coupon:
        current_date = datetime.utcnow()
        if coupon.start_date <= current_date <= coupon.end_date:
            discount_amount = float(coupon.value) if coupon.discount_type == 'fixed' else float(coupon.value) / 100
            return jsonify({'discount_amount': discount_amount}), 200
    return jsonify({'error': 'Invalid promo code'}), 404

@app.route('/invoices', methods=['POST'])
def create_invoice():
    data = request.get_json()

    # Validate input data
    required_fields = ['user_id', 'customer_name', 'customer_mobile', 'total_amount', 'sub_total', 'items', 'payment_method']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400

    # Check if customer exists, if not, create a new customer
    customer = Customer.query.filter_by(customer_mobile=data['customer_mobile']).first()
    if not customer:
        customer = Customer(customer_name=data['customer_name'], customer_mobile=data['customer_mobile'])
        db.session.add(customer)
        db.session.commit()
    else:
        # Update the customer name if it exists
        customer.customer_name = data['customer_name']
        db.session.commit()

    # Create invoice
    new_invoice = Invoice(
        user_id=data['user_id'],
        customer_id=customer.customer_id,
        total_amount=data['total_amount'],
        sub_total=data['sub_total'],
        discount_amount=data.get('discount_amount', 0.0),
        tax_amount=data.get('tax_amount', 0.0),
    )
    db.session.add(new_invoice)
    db.session.commit()

    # Create invoice items
    for item in data['items']:
        invoice_item = InvoiceItem(
            invoice_id=new_invoice.invoice_id,
            product_id=item['product_id'],
            p_batch_id=item['p_batch_id'] if item['p_batch_id'] is not None else None,
            quantity=item['quantity'],
            price=item['sale_price'],
        )
        db.session.add(invoice_item)

    # Create invoice payment
    invoice_payment = InvoicePayment(
        invoice_id=new_invoice.invoice_id,
        amount=data['total_amount'],
        payment_method=data['payment_method'],
    )
    db.session.add(invoice_payment)
    db.session.commit()

    # Update loyalty points
    loyalty_points = LoyaltyPoints.query.filter_by(customer_id=customer.customer_id).first()
    if not loyalty_points:
        loyalty_points = LoyaltyPoints(customer_id=customer.customer_id, points=0)
        db.session.add(loyalty_points)

    # Assuming 1 point for every 100 rupees spent
    points_to_add = int(data['total_amount'] / 100)
    loyalty_points.points += points_to_add
    db.session.commit()

    return jsonify({'message': 'Invoice created successfully', 'invoice_id': new_invoice.invoice_id}), 201



@app.route('/payment_methods', methods=['GET'])
def get_payment_methods():
    payment_methods = ['cash', 'credit_card', 'debit_card', 'mobile_payment']
    return jsonify(payment_methods), 200

if __name__ == '__main__':
    with app.app_context():  # Ensure the app context is active
        db.create_all()  # Create all the tables
    app.run(debug=True)