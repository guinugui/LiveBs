-- Migration: Adicionar coluna de status de assinatura
-- Execute este SQL no seu banco PostgreSQL

-- Adicionar coluna subscription_status na tabela users
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'pending';

-- Adicionar coluna subscription_payment_id para rastrear pagamentos
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_payment_id VARCHAR(255);

-- Adicionar coluna subscription_date para quando foi pago
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_date TIMESTAMP;

-- Criar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);

-- Valores possíveis para subscription_status:
-- 'pending' - Aguardando pagamento (padrão)
-- 'active' - Pago e ativo
-- 'expired' - Expirado
-- 'cancelled' - Cancelado

-- Atualizar usuários existentes (opcional - apenas se quiser que usuários atuais tenham acesso)
-- UPDATE users SET subscription_status = 'active' WHERE subscription_status IS NULL;

COMMIT;