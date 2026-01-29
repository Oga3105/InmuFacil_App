-- InmuFacil Database Schema
-- PostgreSQL 15
-- Tabla: users

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    dni_status VARCHAR(9) NOT NULL DEFAULT 'pendiente',
    user_type VARCHAR(11) NOT NULL DEFAULT 'particular',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    
    -- KYC & Security Fields
    encrypted_dni VARCHAR(500),
    encrypted_phone VARCHAR(500),
    
    -- MFA Email Verification
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verification_token VARCHAR(500),
    token_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- KYC Document Verification
    dni_image_path VARCHAR(500),
    dni_verified BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Security Monitoring
    failed_upload_attempts INTEGER NOT NULL DEFAULT 0,
    
    -- Constraints
    CONSTRAINT chk_dni_status CHECK (dni_status IN ('pendiente', 'validado')),
    CONSTRAINT chk_user_type CHECK (user_type IN ('particular', 'profesional'))
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_dni_status ON users(dni_status);
CREATE INDEX idx_users_user_type ON users(user_type);

-- Comments for documentation
COMMENT ON TABLE users IS 'User accounts with KYC verification and security features';
COMMENT ON COLUMN users.encrypted_dni IS 'AES-256-GCM encrypted DNI number';
COMMENT ON COLUMN users.encrypted_phone IS 'AES-256-GCM encrypted phone number';
COMMENT ON COLUMN users.email_verified IS 'MFA email verification status';
COMMENT ON COLUMN users.dni_verified IS 'Whether DNI document has been verified';
COMMENT ON COLUMN users.failed_upload_attempts IS 'Counter for brute force prevention';
