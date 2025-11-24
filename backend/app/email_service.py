import smtplib
import random
import string
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings
from app.database import db

class EmailService:
    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.username = settings.mail_username if hasattr(settings, 'mail_username') else ""
        self.password = settings.mail_password if hasattr(settings, 'mail_password') else ""
        self.from_email = settings.mail_from if hasattr(settings, 'mail_from') else ""

    def generate_verification_code(self):
        """Gera um código de 6 dígitos"""
        return ''.join(random.choices(string.digits, k=6))

    def send_password_reset_email(self, email: str, verification_code: str):
        """Envia email com código de recuperação de senha"""
        try:
            # Criar mensagem
            message = MIMEMultipart("alternative")
            message["Subject"] = "Recuperação de Senha - NutriAI"
            message["From"] = self.from_email
            message["To"] = email

            # Corpo do email em HTML
            html_body = f"""
            <html>
              <body>
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #4CAF50;">Recuperação de Senha - NutriAI</h2>
                  <p>Olá!</p>
                  <p>Você solicitou a recuperação da sua senha. Use o código abaixo para redefinir sua senha:</p>
                  <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
                    <h1 style="color: #4CAF50; font-size: 32px; margin: 0; letter-spacing: 5px;">{verification_code}</h1>
                  </div>
                  <p>Este código expira em 15 minutos.</p>
                  <p>Se você não solicitou a recuperação de senha, ignore este email.</p>
                  <br>
                  <p>Atenciosamente,<br>Equipe NutriAI</p>
                </div>
              </body>
            </html>
            """

            # Adicionar HTML ao email
            html_part = MIMEText(html_body, "html")
            message.attach(html_part)

            # Enviar email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.username, self.password)
                server.send_message(message)

            return True
        except Exception as e:
            print(f"Erro ao enviar email: {e}")
            return False

    def store_verification_code(self, email: str, code: str):
        """Armazena código de verificação no banco de dados"""
        with db.get_db_cursor() as cursor:
            # Remove códigos antigos para este email
            cursor.execute(
                "DELETE FROM password_reset_codes WHERE email = %s",
                (email,)
            )
            
            # Adiciona novo código com expiração de 15 minutos
            expiry_time = datetime.now() + timedelta(minutes=15)
            cursor.execute(
                """INSERT INTO password_reset_codes (email, code, expires_at, created_at)
                   VALUES (%s, %s, %s, CURRENT_TIMESTAMP)""",
                (email, code, expiry_time)
            )

    def verify_code(self, email: str, code: str, consume: bool = False) -> bool:
        """Verifica se o código é válido
        
        Args:
            email: Email do usuário
            code: Código de verificação
            consume: Se True, remove o código após verificação (uso final)
        """
        with db.get_db_cursor() as cursor:
            cursor.execute(
                """SELECT code, expires_at FROM password_reset_codes 
                   WHERE email = %s AND code = %s AND expires_at > CURRENT_TIMESTAMP""",
                (email, code)
            )
            result = cursor.fetchone()
            
            if result:
                # Remove o código apenas se consume=True (uso final)
                if consume:
                    cursor.execute(
                        "DELETE FROM password_reset_codes WHERE email = %s AND code = %s",
                        (email, code)
                    )
                return True
            return False

email_service = EmailService()