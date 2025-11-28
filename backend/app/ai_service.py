"""
AI Service - Limpo e funcional
"""
import json
from openai import OpenAI
from .config import settings
client = OpenAI(api_key=settings.openai_api_key)

def generate_meal_plan(questionnaire_data: dict, previous_plans: list = None) -> dict:
    """
    Gera plano alimentar usando OpenAI com sistema anti-repetição
    """
    # Extrair dados do questionário e converter para float
    age = int(questionnaire_data.get('age', 30))
    weight = float(questionnaire_data.get('weight', 70))
    height = float(questionnaire_data.get('height', 170))
    target_weight = float(questionnaire_data.get('target_weight', weight))
    activity_level = questionnaire_data.get('activity_level', 'MODERADO')
    objetivo = questionnaire_data.get('objective', 'MANTER PESO')
    restrictions = questionnaire_data.get('restrictions', [])
    preferences = questionnaire_data.get('preferences', [])
    
    # Calcular TMB (Taxa Metabólica Basal)
    tmb = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age)
    
    # Fatores de atividade
    activity_factors = {
        'SEDENTARIO': 1.2,
        'LEVE': 1.375,
        'MODERADO': 1.55,
        'INTENSO': 1.725,
        'MUITO_INTENSO': 1.9
    }
    
    factor = activity_factors.get(activity_level, 1.55)
    calories = int(tmb * factor)
    
    # Ajustar calorias baseado no objetivo
    if objetivo == 'EMAGRECER':
        calories = int(calories * 0.8)  # Déficit de 20%
    elif objetivo == 'GANHAR PESO':
        calories = int(calories * 1.15)  # Superávit de 15%
    
    # Análise de planos anteriores para evitar repetições
    previous_foods_analysis = ""
    if previous_plans:
        print(f"[DEBUG] Analisando {len(previous_plans)} planos anteriores para evitar repetição")
        
        # Extrair alimentos dos planos anteriores
        all_previous_foods = []
        for i, plan in enumerate(previous_plans):
            print(f"[DEBUG] Analisando plano {i+1}: {plan.get('plan_name', 'Sem nome')}")
            plan_data = plan.get('plan_data', {})
            print(f"[DEBUG] Tipo do plan_data: {type(plan_data)}")
            print(f"[DEBUG] Keys do plan_data: {list(plan_data.keys()) if isinstance(plan_data, dict) else 'Não é dict'}")
            
            if 'days' in plan_data:
                print(f"[DEBUG] Encontrou {len(plan_data['days'])} dias no plano")
                for day_idx, day in enumerate(plan_data['days']):
                    if 'meals' in day:
                        print(f"[DEBUG] Dia {day_idx+1} tem {len(day['meals'])} refeições")
                        for meal_idx, meal in enumerate(day['meals']):
                            if 'foods' in meal:
                                print(f"[DEBUG] Refeição {meal_idx+1} tem {len(meal['foods'])} alimentos")
                                for food in meal['foods']:
                                    food_name = food.get('name', '').strip().lower()
                                    if food_name:
                                        all_previous_foods.append(food_name)
                                        print(f"[DEBUG] Alimento extraído: {food_name}")
            else:
                print(f"[DEBUG] Plano não tem chave 'days': {list(plan_data.keys()) if isinstance(plan_data, dict) else plan_data}")
        
        # Contar frequência dos alimentos
        food_frequency = {}
        for food in all_previous_foods:
            food_frequency[food] = food_frequency.get(food, 0) + 1
        
        # Criar lista dos alimentos mais repetidos
        frequent_foods = [food for food, freq in food_frequency.items() if freq >= 2]
        
        print(f"[DEBUG] Total de alimentos nos planos anteriores: {len(all_previous_foods)}")
        print(f"[DEBUG] Alimentos únicos: {len(set(all_previous_foods))}")
        print(f"[DEBUG] Alimentos que repetem 2+ vezes: {len(frequent_foods)}")
        
        if frequent_foods:
            previous_foods_analysis = f"""
🚫 SISTEMA ANTI-REPETIÇÃO ATIVO:
Os seguintes alimentos JÁ foram usados nos últimos planos e devem ser EVITADOS para máxima variedade:
{', '.join(frequent_foods[:20])}  # Limitar a 20 para não sobrecarregar

✅ PRIORIZE alimentos NOVOS e diferentes que ainda NÃO foram usados!
"""
    
    # Textos para restrições e preferências
    restriction_text = ", ".join(restrictions) if restrictions else "Nenhuma"
    preference_text = ", ".join(preferences) if preferences else "Nenhuma"
    
    # Criar prompt para OpenAI
    prompt = f"""Sou o Coach Atlas, um treinador especialista em nutrição brasileira. Crie um plano alimentar personalizado para 1 DIA.

PERFIL DO CLIENTE:
- Peso: {weight}kg | Altura: {height}cm | Idade: {age} anos
- Objetivo: {objetivo} | Meta de peso: {target_weight}kg  
- Atividade: {activity_level} | Calorias: {calories} kcal/dia
- Restrições: {restriction_text}
- Preferências: {preference_text}

{previous_foods_analysis}

INSTRUÇÕES OBRIGATÓRIAS:
1. Todos os alimentos devem ter medidas em GRAMAS (g) ou MILILITROS (ml)
2. Use apenas alimentos brasileiros comuns
3. Varie os alimentos para evitar monotonia
4. Inclua 5-6 refeições: Café da manhã, Lanche manhã, Almoço, Lanche tarde, Jantar, Ceia

Retorne APENAS um JSON válido neste formato:
{{
    "day": 1,
    "meals": [
        {{
            "name": "Café da manhã",
            "time": "07:00",
            "foods": [
                {{"name": "Pão francês", "quantity": "75g"}},
                {{"name": "Ovo mexido", "quantity": "120g"}},
                {{"name": "Suco de laranja", "quantity": "200ml"}}
            ]
        }}
    ]
}}"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000
        )
        
        print(f"[DEBUG] OpenAI respondeu com sucesso")
        
        content = response.choices[0].message.content
        print(f"[DEBUG] Content length: {len(content)}")
        
        result = json.loads(content)
        print(f"[DEBUG] JSON parseado com sucesso. Keys: {list(result.keys())}")
        
        # Converter para estrutura esperada
        if 'day' in result and 'meals' in result:
            compatible_result = {
                "days": [result]
            }
            print(f"[DEBUG] Convertido para estrutura compatível")
            return compatible_result
        
        return result
        
    except Exception as e:
        print(f"[DEBUG] Erro na geração do plano: {e}")
        raise


def get_ai_response(message: str, user_profile: dict = None) -> str:
    """
    Resposta geral do Coach Atlas para chat
    """
    try:
        prompt = f"""Sou o Coach Atlas, um personal trainer brasileiro especialista em fitness e nutrição.

Mensagem do usuário: {message}

Responda de forma motivadora, técnica quando necessário, e sempre em português brasileiro.
Use emojis e seja encorajador. Mantenha o tom profissional mas amigável."""

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=1000
        )
        
        return response.choices[0].message.content
        
    except Exception as e:
        print(f"[DEBUG] Erro no chat: {e}")
        return "Desculpe, estou com dificuldades técnicas no momento. Tente novamente em instantes! 💪"


def generate_workout_plan(questionnaire_data: dict) -> dict:
    """
    Gera plano de treino usando OpenAI
    """
    # Extrair dados do perfil (se existirem)
    age = questionnaire_data.get('age', 30)
    weight = questionnaire_data.get('weight', 70)
    height = questionnaire_data.get('height', 170)
    activity_level = questionnaire_data.get('activity_level', 'MODERADO')
    objective = questionnaire_data.get('objective', 'MANTER PESO')
    
    # Extrair dados específicos do questionário de treino
    fitness_level = questionnaire_data.get('fitness_level', 'intermediario')
    preferred_exercises = questionnaire_data.get('preferred_exercises', [])
    exercises_to_avoid = questionnaire_data.get('exercises_to_avoid', [])
    workout_type = questionnaire_data.get('workout_type', 'home')
    days_per_week = questionnaire_data.get('days_per_week', 3)
    session_duration = questionnaire_data.get('session_duration', 45)
    available_days = questionnaire_data.get('available_days', [])
    
    # Problemas de saúde
    has_musculoskeletal = questionnaire_data.get('has_musculoskeletal_problems', False)
    has_respiratory = questionnaire_data.get('has_respiratory_problems', False)
    has_cardiac = questionnaire_data.get('has_cardiac_problems', False)
    previous_injuries = questionnaire_data.get('previous_injuries', [])
    
    # Formatar listas para o prompt
    preferred_str = ", ".join(preferred_exercises) if preferred_exercises else "Nenhuma preferência específica"
    avoid_str = ", ".join(exercises_to_avoid) if exercises_to_avoid else "Nenhuma restrição"
    days_str = ", ".join(available_days) if available_days else "Flexível"
    injuries_str = ", ".join(previous_injuries) if previous_injuries else "Nenhuma"
    
    # Restrições de saúde
    health_restrictions = []
    if has_musculoskeletal:
        health_restrictions.append("problemas musculoesqueléticos")
    if has_respiratory:
        health_restrictions.append("problemas respiratórios") 
    if has_cardiac:
        health_restrictions.append("problemas cardíacos")
    health_str = ", ".join(health_restrictions) if health_restrictions else "Nenhuma restrição de saúde"

    # Definir exercícios específicos por tipo
    if workout_type == "home":
        equipment_instructions = """
🏠 TREINO EM CASA - EQUIPAMENTOS LIMITADOS:
EXERCÍCIOS PERMITIDOS APENAS:
- Flexões: normal, inclinada, declinada, diamante
- Agachamentos: livre, búlgaro, jump squat, avanço
- Pranchas: normal, lateral, dinâmica
- Abdominais: crunch, bicicleta, mountain climber
- Polichinelos, burpees, lunges, ponte de glúteos
- Rosca direta com halteres leves, desenvolvimento com halteres
- Remada curvada com halteres, elevação lateral

EXERCÍCIOS ABSOLUTAMENTE PROIBIDOS:
❌ Supino (qualquer tipo)
❌ Pull-ups, barra fixa
❌ Leg press, máquinas
❌ Equipamentos pesados
❌ Barras olímpicas
❌ Crucifixo (substitua por flexões)

REGRA CRÍTICA: Se for CASA, use APENAS peso corporal + halteres leves!
"""
    else:
        equipment_instructions = """
🏢 TREINO NA ACADEMIA - EQUIPAMENTOS COMPLETOS:
- Máquinas de musculação profissionais
- Supino livre e máquina
- Leg press, cadeira extensora
- Barras olímpicas, halteres variados
- Cabos, polias, esteiras, bicicletas
- Todos os equipamentos disponíveis
"""

    # Determinar o nome e tipo específico do plano baseado no workout_type
    if workout_type == "home":
        plan_type_name = "Treino em Casa"
        environment_focus = "CASA - SEM EQUIPAMENTOS DE ACADEMIA"
    else:
        plan_type_name = "Treino na Academia"  
        environment_focus = "ACADEMIA - COM EQUIPAMENTOS PROFISSIONAIS"

    prompt = f"""Sou o Coach Atlas, especialista em treinos brasileiros. Crie um plano de treino personalizado para 1 SEMANA.

🎯 TIPO DE TREINO OBRIGATÓRIO: {environment_focus}

📊 PERFIL COMPLETO:
- Idade: {age} anos | Peso: {weight}kg | Altura: {height}cm
- Objetivo: {objective} | Nível de condicionamento: {fitness_level}
- Tipo de treino: {workout_type} ({plan_type_name}) | Dias por semana: {days_per_week}
- Duração por sessão: {session_duration} minutos
- Dias disponíveis: {days_str}

💪 PREFERÊNCIAS E RESTRIÇÕES:
- Exercícios preferidos: {preferred_str}
- Exercícios para evitar: {avoid_str}
- Lesões anteriores: {injuries_str}
- Restrições de saúde: {health_str}

🎯 REGRAS OBRIGATÓRIAS:
1. Treinar TODOS os grupos musculares antes de repetir
2. Respeitar {days_per_week} dias de treino por semana
3. Sessões de {session_duration} minutos cada
4. Alternar grupos musculares adequadamente
5. Incluir exercícios compostos e isolados
6. Adaptar para nível {fitness_level}
7. CRÍTICO: Tipo de treino é "{workout_type}" - RESPEITE RIGOROSAMENTE!

{equipment_instructions}

DISTRIBUIÇÃO BALANCEADA (exemplo):
- Segunda: Peito + Tríceps
- Terça: Pernas + Glúteos
- Quarta: Costas + Bíceps  
- Quinta: Descanso ativo
- Sexta: Ombros + Abdômen
- Sábado: Cardio + Flexibilidade
- Dia 7: Descanso

IMPORTANTE: Use EXATAMENTE a estrutura JSON abaixo com 'days' (não 'workout_schedule'):
- O plan_name DEVE refletir o tipo de treino: "{plan_type_name}"
- O plan_summary DEVE mencionar o ambiente de treino
- NUNCA misture tipos de treino no mesmo plano

{{
    "week": 1,
    "plan_name": "{plan_type_name} - Semana 1",
    "plan_summary": "Plano de {plan_type_name.lower()} personalizado para {days_per_week} dias por semana",
    "workout_type": "{workout_type}",
    "days": [
        {{
            "day": 1,
            "muscle_groups": ["Peito", "Tríceps"],
            "exercises": [
                {{"name": "Flexão de braços", "sets": 3, "reps": "10-12", "rest": "45s"}},
                {{"name": "Flexão diamante", "sets": 3, "reps": "8-10", "rest": "60s"}}
            ]
        }}
    ]
}}"""

    # Adicionar instrução final muito clara e simples
    prompt += f"""

REGRAS CRÍTICAS FINAIS:
1. JSON deve ter 'days', NÃO 'workout_schedule'
2. plan_name deve ser "{plan_type_name} - Semana 1"
3. workout_type deve ser "{workout_type}"
4. TREINO {workout_type.upper()}: {"SEM equipamentos de academia" if workout_type == "home" else "COM equipamentos completos"}

Estrutura JSON OBRIGATÓRIA:
{{"week": 1, "plan_name": "{plan_type_name} - Semana 1", "workout_type": "{workout_type}", "days": [...]}}"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000
        )
        
        content = response.choices[0].message.content
        result = json.loads(content)
        
        # CORREÇÃO: Converter workout_schedule para days se necessário
        if 'workout_schedule' in result and 'days' not in result:
            result['days'] = result.pop('workout_schedule')
            print("[AI_SERVICE] ✅ Convertido 'workout_schedule' para 'days'")
        
        # VALIDAÇÃO E CORREÇÃO AUTOMÁTICA: Garantir tipo e nome corretos
        if workout_type == "home":
            # Sempre corrigir para treino em casa
            result['plan_name'] = f"Treino em Casa - Semana 1"
            result['plan_summary'] = f"Plano de treino em casa personalizado para {days_per_week} dias por semana"
            print(f"[AI_SERVICE] ✅ Nome padronizado para treino em casa")
        else:
            # Sempre corrigir para treino na academia
            result['plan_name'] = f"Treino na Academia - Semana 1" 
            result['plan_summary'] = f"Plano de treino na academia personalizado para {days_per_week} dias por semana"
            print(f"[AI_SERVICE] ✅ Nome padronizado para treino na academia")
        
        # Garantir que workout_type está no resultado
        result['workout_type'] = workout_type
        
        print(f"[AI_SERVICE] 🎯 Plano final: {result['plan_name']} (tipo: {workout_type})")
        
        return result
        
    except Exception as e:
        print(f"[DEBUG] Erro na geração do treino: {e}")
        raise


def get_nutri_ai_response(messages: list, user_profile: dict = None) -> str:
    """
    Resposta especializada da Nutri Clara - Nutricionista focada apenas em alimentação
    """
    try:
        # Prompt especializado da Nutri Clara
        system_prompt = """Você é "Nutri Clara", uma nutricionista brasileira formada e especializada em alimentos, nutrientes, composição nutricional e efeitos no organismo.
Seu único objetivo é tirar dúvidas sobre alimentação, alimentos específicos, combinações alimentares, calorias, macronutrientes, micronutrientes e saúde nutricional.

🎯 Função Principal
Responder apenas perguntas relacionadas a nutrição e alimentos.

⚠️ REGRAS OBRIGATÓRIAS (NÃO PODE DESCUMPRIR)
- Só responda perguntas que envolvam alimentos, nutrição, nutrientes ou ingestão alimentar.
- Se a pergunta NÃO for sobre nutrição, responda: "Posso ajudar apenas com dúvidas relacionadas a alimentos e nutrição 😊"
- Não prescreva dietas completas, cardápios fechados ou quantidades exatas personalizadas (consultas exigem avaliação individual).
- Pode dar orientações gerais, explicar funções de alimentos, mitos, verdades, calorias, benefícios e malefícios.
- Não faça diagnóstico médico.
- Mantenha linguagem simples, clara e acolhedora.
- Sempre cheque qual alimento a pessoa está perguntando, quando houver ambiguidade.
- Não opinar sobre temas emocionais, financeiros, psicológicos, treinos, estética ou medicamentos.

🧠 Estilo de Resposta
- Didática e objetiva
- Explicações curtas, diretas e fáceis
- Acolhedora, profissional e gentil
- Sempre com base em nutrição

📌 Exemplos de perguntas adequadas:
"Esse alimento engorda?"
"Qual o melhor horário para comer fruta?"
"Ovo todo dia faz mal?"
"Banana tem muito açúcar?"

🚫 Exemplos de perguntas que devem ser recusadas:
"Devo tomar esse remédio?"
"Como perco 10 kg rápido?"
"Treino A ou B é melhor?"
"Como curo ansiedade?"

Responda sempre em português brasileiro, seja gentil e use emojis quando apropriado."""

        # Adicionar informações do perfil se disponíveis
        profile_info = ""
        if user_profile:
            profile_info = f"""
Informações do usuário:
- Peso: {user_profile.get('weight', 'N/A')} kg
- Altura: {user_profile.get('height', 'N/A')} cm
- Idade: {user_profile.get('age', 'N/A')} anos
- Meta calórica: {user_profile.get('daily_calories', 'N/A')} kcal/dia
- Restrições: {', '.join(user_profile.get('dietary_restrictions', []))}
- Preferências: {', '.join(user_profile.get('dietary_preferences', []))}
"""

        # Preparar mensagens para API
        api_messages = [{"role": "system", "content": system_prompt + profile_info}]
        api_messages.extend(messages)

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=api_messages,
            temperature=0.7,
            max_tokens=800
        )
        
        return response.choices[0].message.content
        
    except Exception as e:
        print(f"[DEBUG] Erro no chat Nutri Clara: {e}")
        return "Desculpe, estou com dificuldades técnicas no momento. Tente novamente em instantes! 😊"


def get_personal_ai_response(messages: list[dict], user_profile: dict = None) -> str:
    """Gera resposta do Personal Trainer Virtual (Coach Leo) usando OpenAI"""
    
    # Prompt especializado para Personal Trainer
    system_prompt = """Você é "Coach Leo", um Personal Trainer brasileiro, especialista em:

- Emagrecimento saudável
- Ganho de massa muscular
- Alongamentos e mobilidade
- Treinos em casa (com ou sem equipamentos)
- Treinos de cardio (caminhada, corrida, bike, HIIT, elíptico, escada, etc.)
- Organização de rotina de treinos para leigos e intermediários

Seu objetivo é orientar, tirar dúvidas e sugerir treinos gerais, SEM substituir acompanhamento médico ou presencial.

🎯 MISSÃO DO AGENTE
Ajudar a pessoa a:
- Emagrecer com segurança
- Ganhar massa muscular
- Melhorar condicionamento físico
- Aumentar flexibilidade e reduzir dores posturais leves
- Criar uma rotina de treinos possível de seguir

Sempre adaptar as respostas ao contexto da pessoa:
- Objetivo principal (emagrecer, ganhar massa, saúde, condicionamento, voltar a treinar, etc.)
- Nível atual (iniciante, intermediário)
- Local (academia / casa / condomínio)
- Equipamentos disponíveis
- Tempo disponível por dia/semana

⚠️ REGRAS OBRIGATÓRIAS (NÃO PODE DESCUMPRIR):

1. Só responda perguntas relacionadas a treinos, exercícios físicos, rotina de treino, alongamentos, cardio e condicionamento físico.

2. Se a pergunta NÃO for sobre treinos/exercícios/rotina física, responda apenas:
   "Posso te ajudar somente com dúvidas sobre treinos, exercícios físicos e rotina de atividade física 💪"

3. Nunca faça diagnóstico médico ou prometa cura de doenças.

4. Sempre que a pessoa citar dor forte, lesão recente, problema cardíaco, pressão alta, diabetes, cirurgia recente → Responder que ela precisa falar com um médico antes de seguir qualquer treino.

5. Não prescreva remédios, suplementos, hormônios ou esteroides.

6. Pode sugerir tipos de treino, divisões, frequência, exemplos de exercícios, mas sempre como orientação geral, não como prescrição profissional fechada.

7. Em caso de dúvida entre segurança x intensidade, priorize segurança.

8. Não incentive exageros do tipo "treinar até não aguentar" ou "dor extrema".

9. Não faça comentários ofensivos sobre peso, corpo ou aparência. Seja acolhedor e respeitoso.

🧩 COLETA DE CONTEXTO:
Sempre que a pessoa pedir ajuda com treinos, pergunte (se ainda não souber):
- Objetivo principal: "Você quer focar mais em emagrecer, ganhar massa, melhorar condicionamento ou tudo junto?"
- Nível atual: "Você se considera iniciante, intermediário ou avançado nos treinos?"
- Local de treino: "Você treina em academia, em casa ou em outro lugar?"
- Equipamentos disponíveis: "Você tem halteres, elástico, banco, esteira, bike, ou vai treinar só com o peso do corpo?"
- Tempo disponível: "Quantos dias por semana e quantos minutos por dia você consegue treinar de verdade?"
- Possíveis limitações: "Você tem alguma dor, lesão, cirurgia recente ou recomendação médica específica?"

🧠 ESTILO DE RESPOSTA:
- Linguagem simples, brasileira, direta e motivadora
- Nada de termos muito técnicos sem explicar
- Sempre mostrar que é possível começar do nível da pessoa
- Trazer segurança: evitar radicalismos e promessas milagrosas
- No final das respostas mais longas, dar um mini resumo prático
- Exemplo de tom: "Beleza, dá pra gente montar um plano bem pé no chão pra você, sem loucura. Vamos começar simples e ir evoluindo."

🚫 COISAS QUE NÃO PODE FAZER:
- Prescrever medicamentos, suplementos, hormônios, anabolizantes
- Prometer resultados específicos (ex: "você vai perder 10 kg em 1 mês")  
- Resolver questões emocionais, financeiras, de relacionamento, trabalho etc.
- Dar conselhos médicos

Se o usuário pedir algo assim, responder:
"Isso foge do meu papel como Personal Trainer. Nesse caso o ideal é você conversar com um médico ou outro profissional especializado nisso."

💪 LEMBRE-SE: Você é o Coach Leo que vai ajudar de forma segura e motivadora!"""

    if user_profile:
        system_prompt += f"""
        
👤 PERFIL DO SEU ALUNO:
- Peso: {user_profile.get('weight', 'não informado')} kg
- Altura: {user_profile.get('height', 'não informada')} cm  
- Idade: {user_profile.get('age', 'não informada')} anos
- Meta de peso: {user_profile.get('target_weight', 'não informada')} kg
- Nível de atividade: {user_profile.get('activity_level', 'não informado')}
"""

    # Prepara mensagens para OpenAI
    openai_messages = [{"role": "system", "content": system_prompt}]
    openai_messages.extend(messages)
    
    try:
        print(f"[PERSONAL] 🔄 Chamando OpenAI com {len(openai_messages)} mensagens...")
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=openai_messages,
            max_tokens=500,
            temperature=0.7
        )
        
        ai_content = response.choices[0].message.content
        print(f"[PERSONAL] 🎯 OpenAI respondeu: {ai_content[:50]}...")
        return ai_content
        
    except Exception as e:
        print(f"[PERSONAL] ❌ ERRO ao gerar resposta do Personal: {e}")
        return "Desculpe, tive um problema técnico! 😅 Mas não desista do seu treino! 💪 Tente novamente em alguns segundos!"