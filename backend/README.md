# LiveBs Backend API

API REST desenvolvida em FastAPI para o aplicativo LiveBs de emagrecimento com nutricionista IA.

## Tecnologias

- **FastAPI**: Framework web moderno e rápido
- **PostgreSQL**: Banco de dados relacional
- **OpenAI GPT-4**: IA para nutricionista virtual
- **JWT**: Autenticação segura
- **Uvicorn**: Servidor ASGI

## Instalação

1. Criar ambiente virtual:
```bash
python -m venv venv
.\venv\Scripts\activate  # Windows
```

2. Instalar dependências:
```bash
pip install -r requirements.txt
```

3. Configurar `.env`:
```env
DATABASE_URL=postgresql://postgres:guinu02@localhost:5432/livebs_db
SECRET_KEY=sua_chave_secreta
OPENAI_API_KEY=sua_chave_openai
```

4. Banco de dados já criado em `livebs_db`

## Executar

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API disponível em: http://localhost:8000

Documentação interativa: http://localhost:8000/docs

## Endpoints

### Autenticação
- `POST /auth/register` - Registrar usuário
- `POST /auth/login` - Login (retorna JWT)
- `GET /auth/me` - Dados do usuário autenticado

### Perfil
- `POST /profile` - Criar perfil
- `GET /profile` - Buscar perfil
- `PUT /profile` - Atualizar perfil

### Chat IA
- `POST /chat` - Enviar mensagem ao nutricionista IA
- `GET /chat/history` - Histórico de mensagens

### Plano Alimentar
- `POST /meal-plan` - Gerar novo plano com IA
- `GET /meal-plan` - Buscar plano ativo
- `DELETE /meal-plan` - Deletar plano

### Registros
- `POST /logs/weight` - Registrar peso
- `GET /logs/weight` - Histórico de peso
- `POST /logs/water` - Registrar água
- `GET /logs/water` - Histórico de água
- `GET /logs/water/today` - Água consumida hoje
- `POST /logs/meal` - Registrar refeição
- `GET /logs/meal` - Histórico de refeições
- `GET /logs/meal/today` - Calorias consumidas hoje

## Estrutura

```
backend/
├── app/
│   ├── routers/          # Endpoints da API
│   │   ├── auth.py       # Autenticação
│   │   ├── profile.py    # Perfil do usuário
│   │   ├── chat.py       # Chat com IA
│   │   ├── meal_plan.py  # Planos alimentares
│   │   └── logs.py       # Registros (peso, água, refeições)
│   ├── main.py           # App FastAPI principal
│   ├── config.py         # Configurações
│   ├── database.py       # Conexão PostgreSQL
│   ├── schemas.py        # Modelos Pydantic
│   ├── auth.py           # Funções de autenticação
│   └── ai_service.py     # Integração OpenAI
├── requirements.txt
└── .env
```

## Banco de Dados

10 tabelas criadas:
- `users` - Usuários
- `profiles` - Perfis com dados antropométricos
- `dietary_restrictions` - Restrições alimentares
- `dietary_preferences` - Preferências alimentares
- `chat_messages` - Histórico de chat
- `meal_plans` - Planos alimentares
- `meals` - Refeições dos planos
- `weight_logs` - Registro de peso
- `water_logs` - Registro de água
- `meal_logs` - Registro de refeições consumidas
