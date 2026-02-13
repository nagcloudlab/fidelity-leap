MERGE INTO accounts (id, customer_name, customer_email, balance) KEY (customer_email) VALUES
(1, 'John Doe', 'john@example.com', 500.00);

MERGE INTO accounts (id, customer_name, customer_email, balance) KEY (customer_email) VALUES
(2, 'Jane Smith', 'jane@example.com', 1000.00);

MERGE INTO accounts (id, customer_name, customer_email, balance) KEY (customer_email) VALUES
(3, 'Bob Wilson', 'bob@example.com', 250.00);

MERGE INTO accounts (id, customer_name, customer_email, balance) KEY (customer_email) VALUES
(4, 'Alice Brown', 'alice@example.com', 750.00);

MERGE INTO accounts (id, customer_name, customer_email, balance) KEY (customer_email) VALUES
(5, 'Charlie Davis', 'charlie@example.com', 50.00);
