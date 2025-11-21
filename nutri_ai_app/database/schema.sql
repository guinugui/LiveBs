-- Criação do banco de dados LiveBs
-- Execute este script no PostgreSQL

-- Criar o banco (execute separadamente se necessário)
CREATE DATABASE livebs_db;

-- Conectar ao banco livebs_db e executar o restante:
\c livebs_db;

-- Tabela de Usuários
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Perfis
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2), -- kg
    height DECIMAL(5,2), -- cm
    age INTEGER,
    gender VARCHAR(20), -- 'male', 'female', 'other'
    target_weight DECIMAL(5,2),
    activity_level VARCHAR(50), -- 'sedentary', 'light', 'moderate', 'active', 'very_active'
    daily_calories INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Tabela de Restrições Alimentares
CREATE TABLE dietary_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    restriction VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Preferências Alimentares
CREATE TABLE dietary_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    preference VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Mensagens do Chat
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    role VARCHAR(20) NOT NULL, -- 'user' ou 'assistant'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Planos Alimentares
CREATE TABLE meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL, -- 1 a 7
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Refeições
CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE CASCADE,
    meal_type VARCHAR(50) NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
    name VARCHAR(255) NOT NULL,
    calories INTEGER,
    protein DECIMAL(5,2), -- gramas
    carbs DECIMAL(5,2), -- gramas
    fat DECIMAL(5,2), -- gramas
    recipe TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Registro de Peso
CREATE TABLE weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2) NOT NULL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Tabela de Registro de Água
CREATE TABLE water_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(4,2) NOT NULL, -- litros
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Registro de Refeições Consumidas
CREATE TABLE meal_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    meal_name VARCHAR(255) NOT NULL,
    calories INTEGER,
    photo_url TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Índices para melhor performance
CREATE INDEX idx_profiles_user ON profiles(user_id);
CREATE INDEX idx_restrictions_profile ON dietary_restrictions(profile_id);
CREATE INDEX idx_preferences_profile ON dietary_preferences(profile_id);
CREATE INDEX idx_meal_plans_user ON meal_plans(user_id);
CREATE INDEX idx_meals_plan ON meals(meal_plan_id);
CREATE INDEX idx_chat_user_created ON chat_messages(user_id, created_at);
CREATE INDEX idx_weight_user_logged ON weight_logs(user_id, logged_at);
CREATE INDEX idx_water_user_logged ON water_logs(user_id, logged_at);
CREATE INDEX idx_meal_logs_user_logged ON meal_logs(user_id, logged_at);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at BEFORE UPDATE ON meal_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comentários nas tabelas
COMMENT ON TABLE users IS 'Tabela de usuários do sistema LiveBs';
COMMENT ON TABLE profiles IS 'Perfis dos usuários com dados antropométricos';
COMMENT ON TABLE meal_plans IS 'Planos alimentares semanais gerados pela IA';

-- Dados de exemplo (opcional - remova em produção)
-- INSERT INTO users (email, password_hash, name) VALUES 
-- ('teste@livebs.com', 'hash_senha_aqui', 'Usuário Teste');
