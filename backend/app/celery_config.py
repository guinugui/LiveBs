from celery import Celery
from celery.result import AsyncResult
import os
from datetime import datetime
import json

# Configuração do Celery
celery_app = Celery(
    "livebs_tasks",
    broker=os.getenv('CELERY_BROKER', 'redis://127.0.0.1:6379/1'),
    backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://127.0.0.1:6379/1'),
    include=['app.tasks.ai_tasks', 'app.tasks.meal_plan_tasks']
)

# Configurações do Celery
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='America/Sao_Paulo',
    enable_utc=True,
    task_routes={
        'app.tasks.ai_tasks.*': {'queue': 'ai_processing'},
        'app.tasks.meal_plan_tasks.*': {'queue': 'meal_planning'},
    },
    worker_prefetch_multiplier=1,  # Processar uma task por vez
    task_acks_late=True,
    worker_disable_rate_limits=False,
    task_default_retry_delay=60,   # Retry após 60 segundos
    task_max_retries=3,
)

@celery_app.task(bind=True)
def generate_meal_plan_async(self, user_id: str, user_profile: dict):
    """Task assíncrona para gerar plano alimentar"""
    try:
        from app.ai_service import AIService
        from app.cache_manager import cache_manager
        import asyncio
        
        print(f"[CELERY] 🍽️ Gerando plano alimentar para usuário {user_id}")
        
        # Gerar plano alimentar
        ai_service = AIService()
        meal_plan = ai_service.generate_meal_plan(user_profile)
        
        # Salvar no cache
        async def save_to_cache():
            await cache_manager.set_meal_plan(user_id, meal_plan, "async_generated")
        
        # Executar cache em event loop separado
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        loop.run_until_complete(save_to_cache())
        
        result = {
            'status': 'success',
            'user_id': user_id,
            'generated_at': datetime.now().isoformat(),
            'plan_id': meal_plan.get('id', 'generated'),
            'message': 'Plano alimentar gerado com sucesso'
        }
        
        print(f"[CELERY] ✅ Plano alimentar gerado para usuário {user_id}")
        return result
        
    except Exception as e:
        print(f"[CELERY] ❌ Erro ao gerar plano para usuário {user_id}: {e}")
        
        # Retry automático
        if self.request.retries < self.max_retries:
            raise self.retry(countdown=60, exc=e)
        
        return {
            'status': 'error',
            'user_id': user_id,
            'error': str(e),
            'failed_at': datetime.now().isoformat()
        }

@celery_app.task(bind=True)
def generate_workout_plan_async(self, user_id: str, workout_prompt: str):
    """Task assíncrona para gerar plano de treino"""
    try:
        from app.ai_service import AIService
        from app.cache_manager import cache_manager
        import asyncio
        
        print(f"[CELERY] 🏋️ Gerando plano de treino para usuário {user_id}")
        
        # Gerar plano de treino
        ai_service = AIService()
        workout_plan = ai_service.generate_workout_plan(workout_prompt)
        
        # Salvar no cache
        async def save_to_cache():
            plan_id = f"async_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            await cache_manager.set_workout_plan(user_id, plan_id, workout_plan)
            return plan_id
        
        # Executar cache em event loop separado
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        plan_id = loop.run_until_complete(save_to_cache())
        
        result = {
            'status': 'success',
            'user_id': user_id,
            'plan_id': plan_id,
            'generated_at': datetime.now().isoformat(),
            'message': 'Plano de treino gerado com sucesso'
        }
        
        print(f"[CELERY] ✅ Plano de treino gerado para usuário {user_id}")
        return result
        
    except Exception as e:
        print(f"[CELERY] ❌ Erro ao gerar treino para usuário {user_id}: {e}")
        
        # Retry automático
        if self.request.retries < self.max_retries:
            raise self.retry(countdown=60, exc=e)
        
        return {
            'status': 'error',
            'user_id': user_id,
            'error': str(e),
            'failed_at': datetime.now().isoformat()
        }

def get_task_status(task_id: str) -> dict:
    """Verificar status de uma task"""
    try:
        result = AsyncResult(task_id, app=celery_app)
        
        return {
            'task_id': task_id,
            'status': result.status,
            'result': result.result if result.ready() else None,
            'traceback': result.traceback if result.failed() else None
        }
    except Exception as e:
        return {
            'task_id': task_id,
            'status': 'ERROR',
            'error': str(e)
        }

# Comando para iniciar worker:
# celery -A app.celery_config worker --loglevel=info --queues=ai_processing,meal_planning