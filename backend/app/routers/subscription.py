"""
Router para sistema de assinatura recorrente com Mercado Pago
Implementa planos de assinatura e pagamentos recorrentes
"""
from fastapi import APIRouter, HTTPException, Depends
from app.schemas import SubscriptionCreate, SubscriptionResponse, WebhookMercadoPago, SubscriptionStatus
from app.database import get_db_connection
from app.routers.auth import get_current_user
import mercadopago
import os
from datetime import datetime, timedelta
import logging
import uuid

router = APIRouter(prefix="/subscription", tags=["subscription"])

# Configurar Mercado Pago
MERCADO_PAGO_ACCESS_TOKEN = os.getenv("MERCADOPAGO_ACCESS_TOKEN", "TEST-3929468103866921-120418-b790a49ac1209cc4f7eedac43bb06b28-594823")
mp = mercadopago.SDK(MERCADO_PAGO_ACCESS_TOKEN)

@router.post("/create-plan")
async def create_subscription_plan(current_user: dict = Depends(get_current_user)):
    """
    Criar plano de assinatura recorrente no Mercado Pago
    """
    try:
        plan_data = {
            "reason": "Assinatura LiveBs Premium - Plano Mensal",
            "auto_recurring": {
                "frequency": 1,
                "frequency_type": "months", 
                "repetitions": 12,  # 12 meses
                "billing_day_proportional": True,
                "transaction_amount": 39.90,
                "currency_id": "BRL"
            },
            "payment_methods_allowed": {
                "payment_types": [
                    {"id": "credit_card"},
                    {"id": "debit_card"},
                    {"id": "pix"}
                ],
                "payment_methods": []
            },
            "back_url": "http://192.168.0.85:8001/subscription/success"
        }
        
        plan_response = mp.preapproval_plan().create(plan_data)
        
        if plan_response["status"] == 201:
            plan = plan_response["response"]
            
            return {
                "success": True,
                "plan_id": plan["id"],
                "plan_data": plan
            }
        else:
            logging.error(f"Erro MP ao criar plano: {plan_response}")
            raise HTTPException(status_code=400, detail="Erro ao criar plano de assinatura")
            
    except Exception as e:
        logging.error(f"Erro ao criar plano: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.post("/create", response_model=SubscriptionResponse) 
async def create_subscription(
    subscription: SubscriptionCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Criar assinatura recorrente no Mercado Pago (sem cartão)
    """
    try:
        # Criar PIX simples para primeira cobrança  
        payment_data = {
            "transaction_amount": subscription.amount,
            "description": f"Assinatura LiveBs - {subscription.plan_type}",
            "payment_method_id": "pix",
            "payer": {
                "email": current_user["email"],
                "first_name": current_user.get("name", "Cliente"),
                "identification": {
                    "type": "CPF",
                    "number": "11144477735"  # CPF de teste
                }
            },
            "notification_url": "http://192.168.0.85:8001/subscription/webhook",
            "external_reference": str(current_user["id"])
        }
        
        payment_response = mp.payment().create(payment_data)
        payment = payment_response["response"]
        
        if payment_response["status"] == 201:
            # Salvar payment_id no usuário
            conn = await get_db_connection()
            await conn.execute(
                """
                UPDATE users 
                SET subscription_payment_id = $1,
                    subscription_status = 'pending'
                WHERE id = $2
                """,
                str(payment["id"]), current_user["id"]
            )
            await conn.close()
            
            return SubscriptionResponse(
                payment_url=payment["point_of_interaction"]["transaction_data"]["ticket_url"],
                payment_id=str(payment["id"]),
                status=payment["status"],
                qr_code=payment["point_of_interaction"]["transaction_data"]["qr_code"]
            )
        else:
            logging.error(f"Erro MP: {payment_response}")
            raise HTTPException(status_code=400, detail="Erro ao criar pagamento PIX")
            
    except Exception as e:
        logging.error(f"Erro ao criar assinatura: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/status", response_model=SubscriptionStatus)
async def get_subscription_status(current_user: dict = Depends(get_current_user)):
    """
    Verificar status da assinatura do usuário
    """
    try:
        conn = await get_db_connection()
        user_data = await conn.fetchrow(
            """
            SELECT subscription_status, subscription_payment_id, subscription_date 
            FROM users 
            WHERE id = $1
            """,
            current_user["id"]
        )
        await conn.close()
        
        if not user_data:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
        return SubscriptionStatus(
            user_id=current_user["id"],
            subscription_status=user_data["subscription_status"],
            subscription_payment_id=user_data["subscription_payment_id"],
            subscription_date=user_data["subscription_date"],
            is_active=user_data["subscription_status"] == "active"
        )
        
    except Exception as e:
        logging.error(f"Erro ao verificar status: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/webhook/test")
async def test_webhook():
    """Endpoint para testar se o webhook está acessível"""
    return {"status": "webhook_accessible", "message": "Webhook funcionando!"}

@router.post("/webhook") 
async def mercadopago_webhook(webhook_data: dict):
    """
    Webhook do Mercado Pago - atualizar status de pagamento
    """
    try:
        print(f"🔔 Webhook recebido: {webhook_data}")
        
        # Verificar se é um evento de pagamento
        if webhook_data.get("type") == "payment":
            payment_id = webhook_data.get("data", {}).get("id")
            
            if payment_id:
                # Buscar informações do pagamento no Mercado Pago
                payment_response = mp.payment().get(payment_id)
                payment = payment_response["response"]
                
                if payment_response["status"] == 200:
                    external_reference = payment.get("external_reference")  # user_id
                    payment_status = payment.get("status")
                    
                    print(f"💳 Payment ID: {payment_id}")
                    print(f"👤 User ID: {external_reference}")
                    print(f"📊 Status: {payment_status}")
                    
                    if external_reference and payment_status == "approved":
                        # Atualizar status da assinatura no banco
                        conn = await get_db_connection()
                        await conn.execute(
                            """
                            UPDATE users 
                            SET subscription_status = 'active',
                                subscription_date = $1
                            WHERE id = $2 AND subscription_payment_id = $3
                            """,
                            datetime.now(), external_reference, str(payment_id)
                        )
                        await conn.close()
                        
                        print(f"✅ Assinatura ativada para usuário {external_reference}")
                    
                    elif external_reference and payment_status in ["cancelled", "rejected"]:
                        # Manter status como pending ou atualizar para cancelled
                        conn = await get_db_connection()
                        await conn.execute(
                            """
                            UPDATE users 
                            SET subscription_status = 'cancelled'
                            WHERE id = $1 AND subscription_payment_id = $2
                            """,
                            external_reference, str(payment_id)
                        )
                        await conn.close()
                        
                        print(f"❌ Pagamento cancelado/rejeitado para usuário {external_reference}")
        
        return {"status": "received", "message": "Webhook processado"}
        
    except Exception as e:
        logging.error(f"Erro no webhook: {e}")
        print(f"❌ Erro no webhook: {e}")
        return {"status": "error", "message": str(e)}