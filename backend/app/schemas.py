from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID

# Auth schemas
class UserRegister(BaseModel):
    email: EmailStr
    password: str  # Min 6 caracteres validado no frontend
    name: str  # Obrigatório

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: UUID
    email: str
    name: Optional[str]
    created_at: datetime

# Profile schemas
class ProfileCreate(BaseModel):
    weight: float
    height: float
    age: int
    gender: str
    target_weight: float
    activity_level: str
    dietary_restrictions: list[str] = []
    dietary_preferences: list[str] = []

class ProfileUpdate(BaseModel):
    weight: Optional[float] = None
    height: Optional[float] = None
    age: Optional[int] = None
    target_weight: Optional[float] = None
    activity_level: Optional[str] = None

class ProfileResponse(BaseModel):
    id: UUID
    user_id: UUID
    weight: float
    height: float
    age: int
    gender: str
    target_weight: float
    activity_level: str
    daily_calories: Optional[int]
    bmi: Optional[float] = None
    dietary_restrictions: list[str] = []
    dietary_preferences: list[str] = []

# Chat schemas
class ChatMessage(BaseModel):
    message: str

class ChatResponse(BaseModel):
    id: UUID
    role: str
    message: str
    created_at: datetime

# Meal Plan schemas
class MealResponse(BaseModel):
    id: UUID
    meal_type: str
    name: str
    calories: Optional[int]
    protein: Optional[float]
    carbs: Optional[float]
    fat: Optional[float]
    recipe: Optional[str]

class MealPlanDayResponse(BaseModel):
    day_number: int
    meals: list[MealResponse]

class MealPlanResponse(BaseModel):
    plan: list[MealPlanDayResponse]

# Saved Meal Plan schemas
class SavedMealPlanSummary(BaseModel):
    id: str
    plan_number: int
    plan_name: str
    created_at: str

class SavedMealPlanDetails(BaseModel):
    id: str
    plan_number: int
    plan_name: str
    plan_data: dict
    created_at: str

class SavedMealPlansResponse(BaseModel):
    plans: list[SavedMealPlanSummary]
    message: Optional[str] = None

# Weight Log schemas
class WeightLogCreate(BaseModel):
    weight: float
    notes: Optional[str] = None

class WeightLogResponse(BaseModel):
    id: UUID
    weight: float
    logged_at: datetime
    notes: Optional[str]

# Water Log schemas
class WaterLogCreate(BaseModel):
    amount: float  # em litros

class WaterLogResponse(BaseModel):
    id: UUID
    amount: float
    logged_at: datetime

# Meal Log schemas
class MealLogCreate(BaseModel):
    meal_name: str
    calories: Optional[int] = None
    photo_url: Optional[str] = None
    notes: Optional[str] = None

class MealLogResponse(BaseModel):
    id: UUID
    meal_name: str
    calories: Optional[int]
    photo_url: Optional[str]
    logged_at: datetime
    notes: Optional[str]
