"""
Middleware para verificar status de assinatura
"""
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
import jwt
from app.config import settings
from app.database import get_db_connection

class SubscriptionMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            request = Request(scope, receive)
            
            # Rotas que não precisam de assinatura ativa
            exempt_paths = [
                "/",
                "/health", 
                "/docs",
                "/openapi.json",
                "/redoc",
                "/auth/register",
                "/auth/login", 
                "/auth/forgot-password",
                "/auth/verify-reset-code",
                "/auth/reset-password",
                "/subscription/create",
                "/subscription/status", 
                "/webhook/mercadopago",
            ]
            
            # Verificar se a rota está isenta
            if any(request.url.path.startswith(path) for path in exempt_paths):
                await self.app(scope, receive, send)
                return
            
            # Verificar token JWT e status de assinatura
            try:
                # Extrair token do header Authorization
                auth_header = request.headers.get("authorization")
                if not auth_header or not auth_header.startswith("Bearer "):
                    raise HTTPException(status_code=401, detail="Token não fornecido")
                
                token = auth_header.split(" ")[1]
                
                # Decodificar JWT
                payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
                user_id = payload.get("sub")
                
                if not user_id:
                    raise HTTPException(status_code=401, detail="Token inválido")
                
                # Verificar status de assinatura no banco
                conn = await get_db_connection()
                user_data = await conn.fetchrow(
                    "SELECT subscription_status FROM users WHERE id = $1", 
                    user_id
                )
                await conn.close()
                
                if not user_data:
                    raise HTTPException(status_code=404, detail="Usuário não encontrado")
                
                subscription_status = user_data["subscription_status"]
                
                # Verificar se assinatura está ativa
                if subscription_status != "active":
                    response = JSONResponse(
                        status_code=402,
                        content={
                            "detail": "Assinatura necessária",
                            "subscription_status": subscription_status,
                            "message": "Para usar esta funcionalidade, você precisa ativar sua assinatura por R$ 39,90/mês"
                        }
                    )
                    await response(scope, receive, send)
                    return
                
            except jwt.ExpiredSignatureError:
                response = JSONResponse(
                    status_code=401,
                    content={"detail": "Token expirado"}
                )
                await response(scope, receive, send)
                return
            except jwt.InvalidTokenError:
                response = JSONResponse(
                    status_code=401,
                    content={"detail": "Token inválido"}
                )
                await response(scope, receive, send)
                return
            except Exception as e:
                response = JSONResponse(
                    status_code=500,
                    content={"detail": f"Erro interno: {str(e)}"}
                )
                await response(scope, receive, send)
                return
        
        await self.app(scope, receive, send)