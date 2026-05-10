const fs = require('fs');
const path = require('path');

const solvencyKeys = {
  "solvency": {
    "loading_error": "Error al cargar tu pasaporte: {error}",
    "retry": "Reintentar",
    "no_passport_title": "Pasaporte de Solvencia",
    "no_passport_desc": "Completa el asistente para generar tu pasaporte. Esto facilitará que los vendedores acepten tus visitas y ofertas.",
    "complete_wizard": "Completar Asistente",
    "passport_title": "PASAPORTE DE SOLVENCIA",
    "level_label": "Nivel: ",
    "level_gold": "ORO",
    "level_silver": "PLATA",
    "level_bronze": "BRONCE",
    "gold": "ORO",
    "silver": "PLATA",
    "bronze": "BRONCE",
    "expires_on": "Expira el ",
    "days": " días",
    "no_expiry": "Sin expiración",
    "valid_status": "VÁLIDO",
    "expiring_soon": "EXPIRA PRONTO",
    "stress_index": "Índice de Estrés Financiero",
    "low_risk": "Riesgo Bajo",
    "medium_risk": "Riesgo Medio",
    "high_risk": "Riesgo Alto",
    "unknown_risk": "Desconocido",
    "debt_ratio": "Ratio de endeudamiento: ",
    "statement_summary": "Resumen de Declaraciones",
    "knows_extra_costs": "Conoce los gastos extra (10-12%)",
    "has_emergency_fund": "Dispone de fondo de emergencia",
    "has_initial_savings": "Tiene ahorros para la entrada (20%)",
    "has_preapproval": "Tiene pre-aprobación bancaria",
    "payment_method": "Método de pago: ",
    "cash": "Al contado",
    "mortgage_approved": "Hipoteca ya aprobada",
    "mortgage_pending": "Hipoteca en trámite",
    "house_to_sell": "Pendiente de vender otra casa",
    "savings_plus_mortgage": "Ahorros + Hipoteca",
    "bridge_mortgage": "Hipoteca puente",
    "savings_only": "Solo ahorros propios",
    "no_process": "Sin iniciar trámites",
    "unspecified_payment": "No especificado",
    "refresh": "Actualizar Datos",
    "go_to_profile": "Ir a mi perfil",
    "passport_visibility_info": "Este pasaporte es visible para los vendedores cuando solicitas una visita o envías una oferta.",
    "save_error": "Error al guardar: {error}",
    "step_counter": "Paso {x} de {y}",
    "step_buyer_type": "Tipo de Compra",
    "step_disclaimer": "Responsabilidad",
    "step_financial_awareness": "Conciencia Financiera",
    "step_declaration": "Declaración",
    "step_financial_dna": "ADN Financiero",
    "get_passport_btn": "Generar Pasaporte",
    "buyer_type_title": "¿Cómo vas a comprar?",
    "buyer_type_desc": "Indica si la compra la realizas tú solo o con otra persona para que el análisis sea preciso.",
    "just_me": "Solo yo",
    "individual_purchase": "Compra individual",
    "with_someone_else": "Con alguien más",
    "joint_purchase": "Compra conjunta (pareja, socio...)",
    "joint_purchase_info": "En una compra conjunta, los datos de ingresos y ahorros deben ser el total de todos los intervinientes.",
    "liability_notice_title": "Aviso de Responsabilidad",
    "read_carefully": "Por favor, lee con atención",
    "liability_notice_body": "InmuFácil no es una entidad financiera. El pasaporte de solvencia se basa exclusivamente en las declaraciones que tú facilitas. Mentir sobre tu capacidad financiera solo te hará perder el tiempo a ti y al vendedor en trámites que el banco acabará rechazando. Al continuar, declaras que la información es veraz.",
    "accept_terms": "Entiendo y acepto que la información facilitada debe ser real.",
    "financial_awareness_subtitle": "Análisis de riesgos y conocimientos",
    "knows_extra_costs_multi": "¿Conocéis los gastos adicionales de la compraventa?",
    "knows_extra_costs_single": "¿Conoces los gastos adicionales de la compraventa?",
    "extra_costs_hint": "Impuestos (ITP/IVA), Notaría, Registro y Gestoría suelen sumar un 10-12% adicional al precio.",
    "monthly_debt_ratio": "Ratio de endeudamiento mensual estimado",
    "debt_ratio_formula": "(Cuota hipoteca + otros préstamos) / Ingresos netos",
    "risk_high": "Riesgo Muy Alto (>38%)",
    "risk_medium": "Riesgo Medio (35-38%)",
    "risk_low": "Riesgo Saludable (<35%)",
    "debt_ratio_warning": "Un ratio superior al 35% suele ser motivo de rechazo por la mayoría de bancos.",
    "has_emergency_fund_multi": "¿Disponéis de un fondo de emergencia tras la compra?",
    "has_emergency_fund_single": "¿Dispones de un fondo de emergencia tras la compra?",
    "emergency_fund_hint": "Se recomienda tener ahorrado el equivalente a 6 meses de gastos tras pagar la entrada.",
    "declaration_title": "Declaración de Solvencia",
    "declaration_subtitle": "Estado actual de tu financiación",
    "how_to_finance": "¿Cómo tienes pensado financiar la compra?",
    "has_initial_savings_multi": "¿Tenéis ahorrado el 20% del precio (la entrada)?",
    "has_initial_savings_single": "¿Tienes ahorrado el 20% del precio (la entrada)?",
    "initial_savings_hint": "La mayoría de bancos solo financian hasta el 80% del valor de tasación/compra.",
    "has_preapproval_multi": "¿Habéis hablado con un banco y tenéis pre-aprobación?",
    "has_preapproval_single": "¿Has hablado con un banco y tienes pre-aprobación?",
    "preapproval_hint": "Un documento de viabilidad de tu banco da mucha confianza al vendedor.",
    "financial_dna_subtitle": "Datos cuantitativos (Opcional)",
    "data_privacy_info": "Estos datos son PRIVADOS. Solo se utilizan para calcular tu nivel de pasaporte (Oro, Plata, Bronce). El vendedor NO verá las cifras exactas.",
    "monthly_income_multi": "Ingresos Netos Mensuales (Total unidad)",
    "monthly_income_single": "Tus Ingresos Netos Mensuales",
    "example_income": "Ej: 2500",
    "total_savings_multi": "Ahorros Totales Disponibles",
    "total_savings_single": "Tus Ahorros Totales",
    "example_savings": "Ej: 45000",
    "monthly_debt_multi": "Otras deudas mensuales (Préstamos, etc)",
    "monthly_debt_single": "Tus deudas mensuales",
    "example_debt": "Ej: 150",
    "optional_fields_hint": "Rellenar estos campos nos permite asignarte un nivel Oro o Plata, lo que te hace un comprador mucho más atractivo.",
    "estimation_label": "ESTIMACIÓN ACTUAL: ",
    "level_gold_title": "Nivel Oro",
    "level_silver_title": "Nivel Plata",
    "level_bronze_title": "Nivel Bronce",
    "gold_preview_desc": "Tu solvencia parece excelente. Tienes muchas posibilidades de éxito.",
    "silver_preview_desc": "Tu perfil es sólido, aunque algunos puntos podrían mejorar.",
    "bronze_preview_desc": "Perfil básico. Te recomendamos revisar tu capacidad de ahorro."
  }
};

const translationsDir = path.join(__dirname, 'frontend/assets/translations');
const langs = ["es-ES", "ca-ES", "va-ES", "en-US", "fr-FR", "eu-ES", "gl-ES"];

for (const lang of langs) {
  const filePath = path.join(translationsDir, `${lang}.json`);
  if (!fs.existsSync(filePath)) continue;

  let fileContent = fs.readFileSync(filePath, 'utf8');
  if (fileContent.charCodeAt(0) === 0xFEFF) fileContent = fileContent.slice(1);
  const data = JSON.parse(fileContent);

  if (!data["solvency"]) data["solvency"] = {};
  for (const [k, v] of Object.entries(solvencyKeys["solvency"])) {
    data["solvency"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Solvency keys injected.");
