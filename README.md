# LiveBs - App de Emagrecimento com IA

Aplicativo mobile de emagrecimento com nutricionista virtual baseado em IA, desenvolvido em Flutter com backend Python FastAPI.

## 🚀 Tecnologias

### Frontend (Flutter)
- **Flutter 3.38.2** - Framework mobile
- **Riverpod 2.6.1** - State management
- **GoRouter 14.8.1** - Navegação
- **Dio 5.9.0** - HTTP client
- **FL Chart 0.69.2** - Gráficos
- **Material Design 3** - UI/UX

### Backend (Python)
- **FastAPI** - Framework web
- **PostgreSQL 18** - Banco de dados
- **OpenAI GPT-4** - IA nutricionista
- **JWT** - Autenticação
- **Bcrypt** - Criptografia de senhas

## 📱 Funcionalidades

- ✅ Autenticação (registro e login)
- ✅ Perfil do usuário com cálculo de IMC e calorias
- ✅ Chat com nutricionista IA
- ✅ Geração de plano alimentar personalizado (7 dias)
- ✅ Registro de peso, água e refeições
- ✅ Gráficos de progresso
- ✅ Dashboard com resumo diário

## 🎨 Design

- Tema: Verde (#4CAF50) e Branco
- Logo: Ícone de coração
- Bottom Navigation com 4 seções
- Material Design 3

## 🛠️ Instalação

### Backend

```bash
cd backend

# Instalar dependências
pip install -r requirements.txt

# Configurar .env
DATABASE_URL=postgresql://postgres:guinu02@localhost:5432/livebs_db
SECRET_KEY=livebs_secret_key_change_in_production_2024
OPENAI_API_KEY=your_openai_api_key_here

# Rodar servidor
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd nutri_ai_app

# Instalar dependências
flutter pub get

# Rodar app
flutter run
```

## 📊 Banco de Dados

### Tabelas
- `users` - Usuários
- `profiles` - Perfis com dados antropométricos
- `dietary_restrictions` - Restrições alimentares
- `dietary_preferences` - Preferências
- `chat_messages` - Histórico de chat
- `meal_plans` - Planos alimentares
- `meals` - Refeições
- `weight_logs` - Registro de peso
- `water_logs` - Registro de água
- `meal_logs` - Registro de refeições consumidas

### Criação do banco
```bash
# O schema está em database/schema.sql
psql -U postgres -d livebs_db -f database/schema.sql
```

## 🔑 API Endpoints

### Autenticação
- `POST /auth/register` - Registrar usuário
- `POST /auth/login` - Login (JWT)
- `GET /auth/me` - Usuário atual

### Perfil
- `POST /profile` - Criar perfil
- `GET /profile` - Buscar perfil
- `PUT /profile` - Atualizar perfil

### Chat
- `POST /chat` - Enviar mensagem
- `GET /chat/history` - Histórico

### Plano Alimentar
- `POST /meal-plan` - Gerar plano
- `GET /meal-plan` - Buscar plano ativo
- `DELETE /meal-plan` - Deletar plano

### Logs
- `POST /logs/weight` - Registrar peso
- `GET /logs/weight` - Histórico de peso
- `POST /logs/water` - Registrar água
- `GET /logs/water/today` - Água de hoje
- `POST /logs/meal` - Registrar refeição
- `GET /logs/meal/today` - Calorias de hoje

Documentação interativa: http://localhost:8000/docs

## 📁 Estrutura do Projeto

```
APP Emagrecimento/
├── backend/
│   ├── app/
│   │   ├── routers/          # Endpoints
│   │   │   ├── auth.py
│   │   │   ├── profile.py
│   │   │   ├── chat.py
│   │   │   ├── meal_plan.py
│   │   │   └── logs.py
│   │   ├── main.py           # FastAPI app
│   │   ├── config.py         # Configurações
│   │   ├── database.py       # PostgreSQL
│   │   ├── schemas.py        # Pydantic models
│   │   ├── auth.py           # JWT/Bcrypt
│   │   └── ai_service.py     # OpenAI
│   ├── requirements.txt
│   └── .env
│
└── nutri_ai_app/
    ├── lib/
    │   ├── core/
    │   │   ├── theme/
    │   │   ├── router/
    │   │   ├── network/
    │   │   │   ├── api_service.dart
    │   │   │   ├── supabase_service.dart
    │   │   │   └── openai_service.dart
    │   │   └── constants/
    │   ├── features/
    │   │   ├── auth/
    │   │   │   └── presentation/pages/
    │   │   │       ├── login_page.dart
    │   │   │       └── register_page.dart
    │   │   ├── profile/
    │   │   │   └── presentation/pages/
    │   │   │       ├── onboarding_page.dart
    │   │   │       └── profile_page.dart
    │   │   ├── home/
    │   │   ├── chat/
    │   │   ├── meal_plan/
    │   │   └── progress/
    │   └── main.dart
    └── pubspec.yaml
```

## 🧪 Testes

```bash
# Backend
cd backend
python test_api.py
```

## 📝 Status do Desenvolvimento

### ✅ Concluído
- Estrutura do projeto Flutter
- Todas as páginas UI
- Backend API completo
- Banco de dados PostgreSQL
- Autenticação JWT
- Integração OpenAI
- Cálculo automático de calorias/IMC

### 🔄 Em Desenvolvimento
- Conectar todas as páginas ao backend
- Upload de fotos
- Notificações push
- Modo offline

## 🌐 Deploy

### Backend (Railway/Render)
1. Criar projeto no Railway
2. Conectar repositório Git
3. Adicionar PostgreSQL addon
4. Configurar variáveis de ambiente
5. Deploy automático

### App (Google Play)
```bash
flutter build apk --release
```

## 👤 Autor

Desenvolvido por Guilherme

## 📄 Licença

Este projeto está sob licença MIT.
