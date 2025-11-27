from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import timedelta
from app.schemas import UserRegister, UserLogin, Token, UserResponse
from app.database import db
from app.auth import verify_password, get_password_hash, create_access_token, decode_access_token
from app.config import settings
from app.email_service import email_service
from uuid import UUID
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Dependency para obter usuário autenticado"""
    token = credentials.credentials
    payload = decode_access_token(token)
    
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado"
        )
    
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido"
        )
    
    with db.get_db_cursor() as cursor:
        cursor.execute(f"SELECT id, email, name, created_at FROM users WHERE id = {db.get_param_placeholder()}", (user_id,))
        user = cursor.fetchone()
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuário não encontrado"
            )
    
    return user

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: UserRegister):
    """Registra novo usuário"""
    # Validações básicas
    if not user.name or len(user.name.strip()) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nome deve ter pelo menos 2 caracteres"
        )
    
    if not user.password or len(user.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Senha deve ter pelo menos 6 caracteres"
        )
    
    with db.get_db_cursor() as cursor:
        # Verifica se email já existe
        cursor.execute(f"SELECT id FROM users WHERE LOWER(email) = LOWER({db.get_param_placeholder()})", (user.email.strip(),))
        existing_user = cursor.fetchone()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email já cadastrado"
            )
        
        # Cria usuário
        password_hash = get_password_hash(user.password)
        cursor.execute(
            f"""INSERT INTO users (email, password_hash, name) 
               VALUES ({db.get_param_placeholder()}, {db.get_param_placeholder()}, {db.get_param_placeholder()}) RETURNING id, email, name, created_at""",
            (user.email.lower().strip(), password_hash, user.name.strip())
        )
        new_user = cursor.fetchone()
    
    return new_user

@router.post("/login", response_model=Token)
def login(credentials: UserLogin):
    """Faz login e retorna token JWT"""
    with db.get_db_cursor() as cursor:
        cursor.execute(
            f"SELECT id, email, password_hash FROM users WHERE email = {db.get_param_placeholder()}",
            (credentials.email,)
        )
        user = cursor.fetchone()
        
        if not user or not verify_password(credentials.password, user['password_hash']):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Email ou senha incorretos"
            )
    
    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    access_token = create_access_token(
        data={"sub": str(user['id'])}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_me(current_user = Depends(get_current_user)):
    """Retorna dados do usuário autenticado"""
    return current_user

@router.post("/forgot-password")
def forgot_password(email: str):
    """Envia código de recuperação de senha por email"""
    with db.get_db_cursor() as cursor:
        # Verifica se email existe
        cursor.execute(f"SELECT id FROM users WHERE email = {db.get_param_placeholder()}", (email,))
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Email não encontrado"
            )
    
    # Gera código de verificação
    verification_code = email_service.generate_verification_code()
    
    # Armazena código no banco
    email_service.store_verification_code(email, verification_code)
    
    # Envia email
    if email_service.send_password_reset_email(email, verification_code):
        return {"message": "Código de recuperação enviado para seu email"}
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao enviar email"
        )

@router.post("/verify-reset-code")
def verify_reset_code(email: str, code: str):
    """Verifica código de recuperação"""
    if email_service.verify_code(email, code):
        return {"message": "Código válido", "valid": True}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código inválido ou expirado"
        )

@router.post("/reset-password")
def reset_password(email: str, code: str, new_password: str):
    """Redefine senha após verificar código"""
    # Verifica código novamente e o consome (remove após verificação)
    if not email_service.verify_code(email, code, consume=True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código inválido ou expirado"
        )
    
    # Valida nova senha
    if len(new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Senha deve ter pelo menos 6 caracteres"
        )
    
    # Atualiza senha
    password_hash = get_password_hash(new_password)
    with db.get_db_cursor() as cursor:
        cursor.execute(
            f"UPDATE users SET password_hash = {db.get_param_placeholder()} WHERE email = {db.get_param_placeholder()}",
            (password_hash, email)
        )
    
    return {"message": "Senha alterada com sucesso"}
