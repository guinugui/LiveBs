from fastapi import APIRouter, HTTPException, Depends, status, Query
from app.schemas import WeightLogCreate, WeightLogResponse, WaterLogCreate, WaterLogResponse, MealLogCreate, MealLogResponse
from app.database import db
from app.routers.auth import get_current_user
from datetime import datetime, timedelta

router = APIRouter(prefix="/logs", tags=["Logs"])

# Weight Logs
@router.post("/weight", response_model=WeightLogResponse, status_code=status.HTTP_201_CREATED)
def log_weight(weight_log: WeightLogCreate, current_user = Depends(get_current_user)):
    """Registra peso"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """INSERT INTO weight_logs (user_id, weight, notes)
               VALUES (%s, %s, %s)
               RETURNING id, weight, logged_at, notes""",
            (user_id, weight_log.weight, weight_log.notes)
        )
        log = cursor.fetchone()
    
    return log

@router.get("/weight", response_model=list[WeightLogResponse])
def get_weight_logs(
    current_user = Depends(get_current_user),
    days: int = Query(30, description="Número de dias para retornar")
):
    """Retorna histórico de peso"""
    user_id = current_user['id']
    date_limit = datetime.utcnow() - timedelta(days=days)
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, weight, logged_at, notes
               FROM weight_logs
               WHERE user_id = %s AND logged_at >= %s
               ORDER BY logged_at DESC""",
            (user_id, date_limit)
        )
        logs = cursor.fetchall()
    
    return logs

# Water Logs
@router.post("/water", response_model=WaterLogResponse, status_code=status.HTTP_201_CREATED)
def log_water(water_log: WaterLogCreate, current_user = Depends(get_current_user)):
    """Registra consumo de água"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """INSERT INTO water_logs (user_id, amount)
               VALUES (%s, %s)
               RETURNING id, amount, logged_at""",
            (user_id, water_log.amount)
        )
        log = cursor.fetchone()
    
    return log

@router.get("/water/today", response_model=dict)
def get_today_water(current_user = Depends(get_current_user)):
    """Retorna total de água consumida hoje"""
    user_id = current_user['id']
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT COALESCE(SUM(amount), 0)
               FROM water_logs
               WHERE user_id = %s AND logged_at >= %s""",
            (user_id, today_start)
        )
        result = cursor.fetchone()
        total = result[0] if result else 0
    
    return {"total_liters": float(total)}

@router.get("/water", response_model=list[WaterLogResponse])
def get_water_logs(
    current_user = Depends(get_current_user),
    days: int = Query(7, description="Número de dias para retornar")
):
    """Retorna histórico de água"""
    user_id = current_user['id']
    date_limit = datetime.utcnow() - timedelta(days=days)
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, amount, logged_at
               FROM water_logs
               WHERE user_id = %s AND logged_at >= %s
               ORDER BY logged_at DESC""",
            (user_id, date_limit)
        )
        logs = cursor.fetchall()
    
    return logs

# Meal Logs
@router.post("/meal", response_model=MealLogResponse, status_code=status.HTTP_201_CREATED)
def log_meal(meal_log: MealLogCreate, current_user = Depends(get_current_user)):
    """Registra refeição consumida"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """INSERT INTO meal_logs (user_id, meal_name, calories, photo_url, notes)
               VALUES (%s, %s, %s, %s, %s)
               RETURNING id, meal_name, calories, photo_url, logged_at, notes""",
            (user_id, meal_log.meal_name, meal_log.calories, 
             meal_log.photo_url, meal_log.notes)
        )
        log = cursor.fetchone()
    
    return log

@router.get("/meal/today", response_model=dict)
def get_today_calories(current_user = Depends(get_current_user)):
    """Retorna total de calorias consumidas hoje"""
    user_id = current_user['id']
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT COALESCE(SUM(calories), 0)
               FROM meal_logs
               WHERE user_id = %s AND logged_at >= %s AND calories IS NOT NULL""",
            (user_id, today_start)
        )
        result = cursor.fetchone()
        total = result[0] if result else 0
    
    return {"total_calories": int(total)}

@router.get("/meal", response_model=list[MealLogResponse])
def get_meal_logs(
    current_user = Depends(get_current_user),
    days: int = Query(7, description="Número de dias para retornar")
):
    """Retorna histórico de refeições"""
    user_id = current_user['id']
    date_limit = datetime.utcnow() - timedelta(days=days)
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, meal_name, calories, photo_url, logged_at, notes
               FROM meal_logs
               WHERE user_id = %s AND logged_at >= %s
               ORDER BY logged_at DESC""",
            (user_id, date_limit)
        )
        logs = cursor.fetchall()
    
    return logs
