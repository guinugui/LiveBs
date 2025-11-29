from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Banco de dados
    database_url: str
    db_host: str = "127.0.0.1"
    db_port: int = 5432
    db_name: str = "livebs_db"
    db_user: str = "postgres"
    db_password: str
    
    # Segurança JWT
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # OpenAI
    openai_api_key: str
    
    # Email
    mail_username: str = ""
    mail_password: str = ""
    mail_from: str = ""
    mail_server: str = "smtp.gmail.com"
    mail_port: int = 587
    
    # Servidor
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    # CORS - Origins permitidas
    allowed_origins: str = "*"
    
    def get_allowed_origins(self) -> List[str]:
        """Converte string de origins em lista"""
        if self.allowed_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.allowed_origins.split(",")]

    class Config:
        env_file = ".env"
        extra = "allow"  # Permitir campos extras do .env

settings = Settings()
