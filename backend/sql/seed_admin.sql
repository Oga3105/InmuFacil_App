-- Insert Admin User if not exists
INSERT INTO users (
    email, 
    hashed_password, 
    full_name, 
    dni_status, 
    user_type, 
    email_verified, 
    dni_verified, 
    failed_upload_attempts,
    created_at,
    updated_at
)
SELECT 
    'admin@inmufacil.com',
    '$2b$12$v/biTOw8n3UExHjeNpHrTeUjQ7t7qXBxtPfoczuui3SIRQPe09tgS', -- "Admin123!"
    'Super Admin',
    'validado',
    'particular', -- Usamos 'particular' ya que 'admin' no estaba en el Enum de Models
    true,   -- Email verificado
    true,   -- DNI verificado (bypass para admin)
    0,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'admin@inmufacil.com'
);
