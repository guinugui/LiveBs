from openai import OpenAI
from app.config import settings
import json

client = OpenAI(api_key=settings.openai_api_key)

def get_ai_response(messages: list[dict], user_profile: dict = None) -> str:
    """
    Obtém resposta do nutricionista IA

    Args:
        messages: Lista de mensagens no formato [{"role": "user", "content": "..."}]
        user_profile: Dados do perfil do usuário (peso, altura, objetivo, etc)

    Returns:
        Resposta do assistente IA
    """
    system_prompt = """Você é Dr. Nutri, um nutricionista virtual especializado em
    emagrecimento saudável. Você é gentil, motivador e baseado em evidências científicas.
    Sempre considere o perfil do usuário ao dar recomendações."""

    if user_profile:
        system_prompt += f"""

        Perfil do usuário:
        - Peso atual: {user_profile.get('weight')} kg
        - Altura: {user_profile.get('height')} cm
        - Idade: {user_profile.get('age')} anos
        - Peso alvo: {user_profile.get('target_weight')} kg
        - Nível de atividade: {user_profile.get('activity_level')}
        - Calorias diárias: {user_profile.get('daily_calories')} kcal
        """

        if user_profile.get('dietary_restrictions'):
            system_prompt += f"\n- Restrições alimentares: {', '.join(user_profile['dietary_restrictions'])}"

        if user_profile.get('dietary_preferences'):
            system_prompt += f"\n- Preferências: {', '.join(user_profile['dietary_preferences'])}"

    all_messages = [{"role": "system", "content": system_prompt}] + messages

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=all_messages,
        temperature=0.7,
        max_tokens=500
    )

    return response.choices[0].message.content


def generate_meal_plan(user_profile: dict) -> dict:
    """
    Gera plano alimentar de 3 dias personalizado
    
    Args:
        user_profile: Dados do usuário incluindo calorias, restrições, preferências
        
    Returns:
        Dicionário com plano de 3 dias
    """
    
    # Extrair dados do perfil
    calories = user_profile.get('daily_calories', 1800)
    weight = user_profile.get('weight', 70)
    height = user_profile.get('height', 170)
    age = user_profile.get('age', 30)
    target_weight = user_profile.get('target_weight', 65)
    activity_level = user_profile.get('activity_level', 'moderado')
    restrictions = user_profile.get('dietary_restrictions', [])
    preferences = user_profile.get('dietary_preferences', [])
    
    # Determinar objetivo baseado no peso atual vs peso alvo
    if target_weight < weight:
        objetivo = "EMAGRECER"
        objetivo_text = f"deficit calórico para perder {weight - target_weight:.1f}kg"
    elif target_weight > weight:
        objetivo = "GANHAR PESO"
        objetivo_text = f"superavit calórico para ganhar {target_weight - weight:.1f}kg"
    else:
        objetivo = "MANTER PESO"
        objetivo_text = "manutenção do peso atual"
    
    # Construir informações de restrições
    restriction_text = ""
    if restrictions:
        restriction_text = f"EVITE: {', '.join(restrictions)}"
    
    preference_text = ""
    if preferences:
        preference_text = f"PRIORIZE: {', '.join(preferences)}"

    prompt = f"""Crie um PLANO MODELO personalizado para 7 dias com grupos alimentares didáticos e comidas brasileiras comuns.

PERFIL DO CLIENTE:
- Peso atual: {weight}kg
- Altura: {height}cm  
- Idade: {age} anos
- Peso alvo: {target_weight}kg
- Objetivo: {objetivo} ({objetivo_text})
- Nível de atividade: {activity_level}
- Calorias diárias recomendadas: {calories} kcal
- Restrições: {restriction_text if restriction_text else "Nenhuma"}
- Preferências: {preference_text if preference_text else "Nenhuma"}

IMPORTANTE: Ajuste as porções e alimentos baseado no OBJETIVO do cliente ({objetivo}):

MODELO POR REFEIÇÃO PERSONALIZADA (mesmo padrão todos os 7 dias):

CAFÉ DA MANHÃ ({int(calories * 0.2)}-{int(calories * 0.25)} kcal):
- Carboidratos: {"porções menores" if objetivo == "EMAGRECER" else "porções normais" if objetivo == "MANTER PESO" else "porções maiores"}: arroz doce, pão francês, tapioca, aveia, biscoito integral, banana
- Proteínas (PRIORIDADE para {objetivo}): ovos, leite, iogurte natural, queijo minas, requeijão
- Gorduras boas: {"1 col" if objetivo == "EMAGRECER" else "1-2 col"}: azeite, manteiga, castanhas, amendoim
- Frutas: banana, maçã, mamão, laranja, melancia

ALMOÇO ({int(calories * 0.35)}-{int(calories * 0.4)} kcal):
- Carboidratos: {"porções reduzidas" if objetivo == "EMAGRECER" else "porções normais" if objetivo == "MANTER PESO" else "porções aumentadas"}: arroz branco, feijão carioca, batata, macarrão, farinha de mandioca
- Proteínas (ESSENCIAL para {objetivo}): frango grelhado, carne de panela, peixe, ovo cozido
- Gorduras boas: {"1 col" if objetivo == "EMAGRECER" else "1-2 col"}: óleo de soja, azeite de oliva
- Verduras/Legumes (À VONTADE - especialmente para emagrecimento): alface, tomate, cenoura, abobrinha, chuchu, repolho

LANCHE ({int(calories * 0.1)}-{int(calories * 0.15)} kcal):
- Carboidratos: {"evitar se emagrecer" if objetivo == "EMAGRECER" else "moderado"}: biscoito água e sal, pão de forma, fruta
- Proteínas (IMPORTANTE): queijo, iogurte, leite
- Gorduras: {"evitar" if objetivo == "EMAGRECER" else "1 col"}: castanhas, amendoim

JANTAR ({int(calories * 0.25)}-{int(calories * 0.3)} kcal):
- Carboidratos: {"REDUZIR para emagrecimento" if objetivo == "EMAGRECER" else "porções normais"}: arroz, batata cozida, macarrão, pão
- Proteínas (PRIORIDADE no jantar): frango desfiado, ovo, queijo, sardinha
- Gorduras: {"mínimo" if objetivo == "EMAGRECER" else "1 col"}: azeite, óleo
- Verduras/Legumes (AUMENTAR à vontade): salada verde, sopa de legumes, abobrinha refogada

ESTRUTURA JSON:
{{"day":1,"meals":[{{"type":"breakfast","carbs_foods":["arroz doce","pão francês","tapioca","aveia","biscoito integral","banana"],"protein_foods":["ovos","leite","iogurte natural","queijo minas"],"fat_foods":["azeite","manteiga","castanhas","amendoim"],"vegetables":["banana","maçã","mamão","laranja"]}},{{"type":"lunch","carbs_foods":["arroz branco","feijão carioca","batata","macarrão"],"protein_foods":["frango grelhado","carne de panela","peixe","ovo cozido"],"fat_foods":["óleo de soja","azeite"],"vegetables":["alface","tomate","cenoura","abobrinha","chuchu"]}},{{"type":"afternoon_snack","carbs_foods":["biscoito água e sal","pão de forma","fruta"],"protein_foods":["queijo","iogurte","leite"],"fat_foods":["castanhas","amendoim"],"vegetables":[]}},{{"type":"dinner","carbs_foods":["arroz","batata cozida","macarrão","pão"],"protein_foods":["frango desfiado","ovo","queijo","sardinha"],"fat_foods":["azeite","óleo"],"vegetables":["salada verde","sopa de legumes","abobrinha refogada"]}}]}}

REGRAS IMPORTANTES PERSONALIZADAS:
- Use APENAS alimentos brasileiros comuns (arroz, feijão, frango, etc)
- {restriction_text}
- {preference_text}
- OBJETIVO {objetivo}: {"Foque em proteínas e verduras, reduza carboidratos" if objetivo == "EMAGRECER" else "Equilibre todos os grupos" if objetivo == "MANTER PESO" else "Aumente porções de todos os grupos, especialmente carboidratos"}
- ATIVIDADE {activity_level}: {"Mais carboidratos pré e pós treino" if activity_level in ["alto", "muito alto"] else "Carboidratos moderados"}
- IDADE {age} anos: {"Metabolismo mais lento, porções menores" if age > 50 else "Metabolismo normal"}
- Separe por grupos: carbs_foods, protein_foods, fat_foods, vegetables  
- Alimentos específicos, não receitas
- Variedade em cada grupo para escolha do usuário
- Ajuste as quantidades de alimentos baseado no perfil: peso {weight}kg → {target_weight}kg

Retorne APENAS o JSON de 1 dia modelo personalizado, sem explicações."""

    print(f"[DEBUG] Chamando OpenAI com prompt de {len(prompt)} chars")
    
    try:
    
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=4000
        )
        
        print(f"[DEBUG] OpenAI respondeu com sucesso")
        
        import json
        import re
        
        # Pega a resposta
        content = response.choices[0].message.content
        print(f"[DEBUG] Content length: {len(content)}")
        
        # Remove possíveis markdown ou texto extra
        content = re.sub(r'^```json\s*', '', content)
        content = re.sub(r'\s*```$', '', content)
        content = content.strip()
        
        # Tenta fazer parse
        try:
            result = json.loads(content)
            print(f"[DEBUG] JSON parseado com sucesso. Keys: {list(result.keys()) if isinstance(result, dict) else 'Not dict'}")
            
            # Converter para estrutura esperada (compatibilidade com sistema antigo)
            if 'day' in result and 'meals' in result:
                # Nova estrutura: transforma em formato antigo com array de dias
                compatible_result = {
                    "days": [result]  # Coloca o dia único dentro do array esperado
                }
                print(f"[DEBUG] Convertido para estrutura compatível com {len(compatible_result['days'])} dia(s)")
                return compatible_result
            
            return result
        except json.JSONDecodeError as e:
            print(f"[DEBUG] Erro ao parsear JSON: {e}")
            # Se falhar, salva para debug
            with open('error_response.txt', 'w', encoding='utf-8') as f:
                f.write(f"ERRO: {e}\n\n")
                f.write(f"POSIÇÃO: linha {e.lineno}, coluna {e.colno}, char {e.pos}\n\n")
                f.write("RESPOSTA:\n")
                f.write(content)
            raise Exception(f"Erro ao parsear JSON da OpenAI. Detalhes salvos em error_response.txt: {e}")
            
    except Exception as e:
        print(f"[DEBUG] Erro geral na chamada OpenAI: {e}")
        raise
