from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/users')
def users():
    # Logic to fetch and display user data
    return render_template('users.html')

@app.route('/products')
def products():
    # Logic to fetch and display product data
    return render_template('products.html')

@app.route('/orders')
def orders():
    # Logic to fetch and display order data
    return render_template('orders.html')

if __name__ == '__main__':
    app.run(debug=True)