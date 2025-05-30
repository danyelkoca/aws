# AWS RDS Setup with Terraform

This project demonstrates two approaches for setting up PostgreSQL RDS in AWS:

## Production Architecture (Not Implemented Here)

Best practice architecture for production environments:

```
Internet -> CloudFront -> ALB -> Application Tier -> RDS
                                (EC2/ECS/Lambda)
```

Components:

- CloudFront: CDN for caching and DDoS protection
- Application Load Balancer (ALB): In public subnets
- Application Tier: In private subnets with NAT Gateway\*
- RDS: In private subnets
- All components except CloudFront in the same VPC

\*Note on NAT Gateway: While traditionally used for internet access from private subnets,
consider cheaper alternatives for AWS services:

- Use VPC Endpoints for AWS services (S3, DynamoDB, etc.)
- Internal package repositories for dependencies
- Only use NAT Gateway for essential external traffic (APIs, updates)

Security Features:

- No direct database access from internet
- Application security groups limiting access
- CloudFront for edge protection
- Private subnets for applications and database

## Development/POC Setup (Implemented Here)

Simplified architecture for testing:

```
Internet -> Public EC2 (Bastion) -> RDS (Private Subnet)
```

Components Created

- VPC with CIDR 10.0.0.0/16
- Two private subnets in different availability zones
- DB subnet group
- Security group allowing PostgreSQL traffic (port 5432)
- PostgreSQL 14 RDS instance (db.t3.micro)

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- Basic understanding of AWS and Terraform

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Review the planned changes:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. After successful creation, Terraform will output:

- RDS endpoint
- RDS port

## Connecting to the Database

You can connect to the database using any PostgreSQL client with these credentials:

- Host: [RDS endpoint from terraform output]
- Port: 5432
- Database: postgres
- Username: demouser
- Password: demopassword123

### Using psql CLI

```bash
psql -h [RDS endpoint] -U demouser -d postgres
```

### Using Python Scripts

1. Install the required Python packages:

```bash
pip install -r requirements.txt
```

2. Set up environment variables:

```bash
export DB_HOST="[RDS endpoint from terraform output]"
export DB_USER="demouser"
export DB_PASSWORD="demopassword123"
```

3. Run the example script:

```bash
python scripts/db_operations.py
```

The script will:

- Create a sample 'users' table
- Insert some example data
- Demonstrate how to query the data

You can also use the functions in `db_operations.py` in your own code:

```python
from scripts.db_operations import add_user, get_users

# Add a new user
new_user = add_user("Test User", "test@example.com")

# Get all users
users = get_users()
```

### Connecting via Bastion Host

1. SSH into the bastion host:

```bash
ssh -i /path/to/MainKey.pem ec2-user@[EC2_PUBLIC_IP]
```

2. Connect to PostgreSQL:

```bash
psql -h demo-postgresql.c9w22oku0dmn.ap-northeast-1.rds.amazonaws.com -U demouser -d myappdb
```

3. Create sample schema:

```sql
-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    amount DECIMAL(10,2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com');

INSERT INTO orders (user_id, amount) VALUES
    (1, 99.99),
    (1, 150.50),
    (2, 75.25),
    (3, 249.99);
```

### Using Python

Here's how to interact with the database using Python and psycopg2:

1. First, install the required packages:

```bash
pip install psycopg2-binary pandas
```

2. Create a Python script (`db_operations.py`):

```python
import psycopg2
import pandas as pd
from contextlib import contextmanager

# Database connection parameters
DB_PARAMS = {
    'dbname': 'myappdb',
    'user': 'demouser',
    'password': 'demopassword123',
    'host': 'demo-postgresql.c9w22oku0dmn.ap-northeast-1.rds.amazonaws.com',
    'port': '5432'
}

@contextmanager
def get_db_connection():
    """Create a database connection context manager"""
    conn = psycopg2.connect(**DB_PARAMS)
    try:
        yield conn
    finally:
        conn.close()

def get_all_orders():
    """Fetch all orders with user information"""
    query = """
    SELECT u.name, o.amount, o.order_date
    FROM users u
    JOIN orders o ON u.id = o.user_id
    ORDER BY o.order_date DESC
    """

    with get_db_connection() as conn:
        # Use pandas to create a nice dataframe
        df = pd.read_sql_query(query, conn)
        return df

def add_new_order(user_id, amount):
    """Add a new order for a user"""
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO orders (user_id, amount) VALUES (%s, %s) RETURNING id",
                (user_id, amount)
            )
            order_id = cur.fetchone()[0]
            conn.commit()
            return order_id

if __name__ == "__main__":
    # Example usage
    print("Current orders:")
    print(get_all_orders())

    # Add a new order
    new_order_id = add_new_order(1, 299.99)
    print(f"\nAdded new order with ID: {new_order_id}")

    print("\nUpdated orders:")
    print(get_all_orders())
```

This script demonstrates:

- Secure connection management using context managers
- Using pandas for easy data manipulation
- Basic CRUD operations
- Error handling best practices

## Security Notes

- For production use:
  - Use AWS Secrets Manager or similar for password management
  - Restrict security group ingress rules
  - Enable encryption at rest
  - Consider using parameter groups for PostgreSQL configuration
  - Set up proper networking with private subnets and NAT gateway

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## VS Code Database Management

1. Install required VS Code extensions:

   - Remote - SSH (`ms-vscode-remote.remote-ssh`)
   - PostgreSQL (`ckolkman.vscode-postgres`)
   - SQLTools (`mtxr.sqltools`)
   - SQLTools PostgreSQL Driver (`mtxr.sqltools-driver-pg`)

2. Connect to EC2:

   - Command Palette (Cmd+Shift+P) -> "Remote-SSH: Connect to Host"
   - Add `ssh -i MainKey.pem ec2-user@<EC2-PUBLIC-IP>`

3. Set up Database Connection:
   - Using PostgreSQL extension:
     - Click PostgreSQL icon in sidebar
     - Add New Connection
     - Host: RDS endpoint
     - Port: 5432
     - Username: demouser
     - Database: myappdb

Features Available:

- Table/Schema Explorer
- Visual Query Editor
- Data viewing/editing in grid format
- Query history
- Result export to CSV/JSON
