"""Simple e-commerce web application with order tracking."""

from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = "ecommerce-dev-secret-change-in-production"

PRODUCTS = [
    {"id": 1, "name": "Wireless Headphones", "price": 79.99, "image": "headphones"},
    {"id": 2, "name": "Smart Watch", "price": 199.99, "image": "watch"},
    {"id": 3, "name": "Laptop Stand", "price": 34.99, "image": "stand"},
    {"id": 4, "name": "USB-C Hub", "price": 49.99, "image": "hub"},
    {"id": 5, "name": "Mechanical Keyboard", "price": 129.99, "image": "keyboard"},
    {"id": 6, "name": "Wireless Mouse", "price": 39.99, "image": "mouse"},
]

orders = []
order_counter = 0


def get_product(product_id):
    for product in PRODUCTS:
        if product["id"] == product_id:
            return product
    return None


@app.route("/")
def home():
    return render_template(
        "index.html",
        products=PRODUCTS,
        order_count=order_counter,
    )


@app.route("/order/<int:product_id>", methods=["POST"])
def place_order(product_id):
    global order_counter

    product = get_product(product_id)
    if not product:
        flash("Product not found.", "error")
        return redirect(url_for("home"))

    quantity = request.form.get("quantity", "1")
    try:
        quantity = max(1, int(quantity))
    except ValueError:
        quantity = 1

    order_counter += 1
    total = round(product["price"] * quantity, 2)

    order = {
        "id": order_counter,
        "product_name": product["name"],
        "product_id": product["id"],
        "quantity": quantity,
        "unit_price": product["price"],
        "total": total,
    }
    orders.append(order)

    flash(
        f"Order #{order_counter} placed: {quantity}x {product['name']} (${total:.2f})",
        "success",
    )
    return redirect(url_for("orders_page"))


@app.route("/orders")
def orders_page():
    return render_template(
        "orders.html",
        orders=list(reversed(orders)),
        order_count=order_counter,
        total_revenue=round(sum(o["total"] for o in orders), 2),
    )


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
