#!/usr/bin/env python3
import requests
import json

email = "gui@gmail.com"
password = "123123"

# Login
login_response = requests.post(
    "http://localhost:8001/auth/login",
    json={"email": email, "password": password}
)

token = login_response.json()["access_token"]
headers = {"Authorization": f"Bearer {token}"}

# Buscar último plano
saved_response = requests.get(
    "http://localhost:8001/workout-plan/",
    headers=headers
)

if saved_response.status_code == 200:
    plans = saved_response.json()
    if plans:
        latest_plan = plans[0]
        workout_data = json.loads(latest_plan['workout_data'])
        print("ESTRUTURA COMPLETA DO JSON:")
        print(json.dumps(workout_data, indent=2, ensure_ascii=False))