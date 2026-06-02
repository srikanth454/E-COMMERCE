# E-COMMERCE

A simple Python e-commerce web application built with Flask.

## Features

- Product catalog with 6 items
- Place orders with quantity selection
- **Orders** page with order history, total order count, and revenue
- Order counter badge in the navigation bar

## Setup

```bash
pip install -r requirements.txt
python app.py
```

Open **http://127.0.0.1:5000** in your browser.

## Routes

| Route | Description |
|-------|-------------|
| `/` | Shop — browse and order products |
| `/orders` | View all orders and order statistics |

## Tech Stack

- Python 3
- Flask 3
- In-memory order storage (resets when the server restarts)
