-- scripts/setup_database.sql
CREATE DATABASE ai_business_platform;
\c ai_business_platform;

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Subscribers table
CREATE TABLE subscribers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    subscription_tier VARCHAR(20) DEFAULT 'basic',
    subscription_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    renewal_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    payment_method VARCHAR(50)
);

-- Revenue tracking table
CREATE TABLE revenue (
    id SERIAL PRIMARY KEY,
    subscriber_id INTEGER REFERENCES subscribers(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ZAR',
    payment_gateway VARCHAR(50),
    transaction_id VARCHAR(100),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'completed'
);

-- Content table
CREATE TABLE content (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    file_path VARCHAR(500),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    platform VARCHAR(50),
    performance_metrics JSONB
);

-- Payouts table
CREATE TABLE payouts (
    id SERIAL PRIMARY KEY,
    payout_date DATE NOT NULL,
    total_revenue DECIMAL(15,2) NOT NULL,
    owner_fnb DECIMAL(15,2),
    african_bank DECIMAL(15,2),
    reserve_fnb DECIMAL(15,2),
    ai_fnb DECIMAL(15,2),
    reserve_growth DECIMAL(15,2),
    status VARCHAR(20) DEFAULT 'pending'
);

-- Social media posts table
CREATE TABLE social_media_posts (
    id SERIAL PRIMARY KEY,
    content_id INTEGER REFERENCES content(id),
    platform VARCHAR(50) NOT NULL,
    post_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'scheduled',
    post_url VARCHAR(500),
    engagement_metrics JSONB
);

-- Create indexes
CREATE INDEX idx_subscribers_status ON subscribers(status);
CREATE INDEX idx_revenue_date ON revenue(transaction_date);
CREATE INDEX idx_content_created ON content(created_at);
CREATE INDEX idx_payouts_date ON payouts(payout_date);

-- Insert default admin user
INSERT INTO users (username, email, password_hash, role) 
VALUES ('admin', 'admin@aibusiness.com', 'hashed_password_here', 'admin');

-- Create weekly revenue view
CREATE VIEW weekly_revenue AS
SELECT 
    DATE_TRUNC('week', transaction_date) as week_start,
    SUM(amount) as total_revenue,
    COUNT(*) as transaction_count
FROM revenue 
WHERE status = 'completed'
GROUP BY DATE_TRUNC('week', transaction_date);
