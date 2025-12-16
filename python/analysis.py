from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional


@dataclass
class Recommendation:
    title: str
    reason: str
    priority: str  # one of: high, medium, low

    def to_dict(self) -> Dict[str, str]:
        return {"title": self.title, "reason": self.reason, "priority": self.priority}


def get_field(fields: Dict[str, Any], *keys: str, default: Optional[Any] = None) -> Any:
    """Safely get a nested field using possible key aliases.

    Example: get_field(fields, "total", "amount_total") returns the first present value.
    """
    for key in keys:
        if key in fields and fields[key] not in (None, ""):
            return fields[key]
    return default


def analyze_pdf(fields: Dict[str, Any]) -> Dict[str, Any]:
    """Generate fixed-rule recommendations for blood test (kan tahlili) values.

    Expected input: a dict of extracted lab values from a PDF.
    Keys are flexible with common aliases, units assumed as noted:
    - glucose (mg/dL), hba1c (%), ldl/hdl/total_cholesterol (mg/dL), triglycerides (mg/dL)
    - hemoglobin (g/dL), hematocrit (%), wbc (10^3/µL), platelets (10^3/µL)
    - alt/ast (U/L), creatinine (mg/dL), egfr (mL/min/1.73m^2), crp (mg/L)
    - sex: "male"/"female" optional
    """
    recommendations: List[Recommendation] = []

    # Canonical lab values with aliases
    sex = str(get_field(fields, "sex", "cinsiyet", default="")).lower() or None
    age = int(get_field(fields, "age", "yas", default=0) or 0)
    is_adult = age >= 18 if age else True
    glucose = float(get_field(fields, "glucose", "glukoz", "fasting_glucose", "aclik_glukozu", default=0) or 0)
    hba1c = float(get_field(fields, "hba1c", "hbA1c", "hba1c_%", default=0) or 0)
    ldl = float(get_field(fields, "ldl", "ldl_cholesterol", default=0) or 0)
    hdl = float(get_field(fields, "hdl", "hdl_cholesterol", default=0) or 0)
    tg = float(get_field(fields, "triglycerides", "trigliserid", "tg", default=0) or 0)
    total_chol = float(get_field(fields, "total_cholesterol", "cholesterol_total", default=0) or 0)
    hemoglobin = float(get_field(fields, "hemoglobin", "hgb", default=0) or 0)
    hematocrit = float(get_field(fields, "hematocrit", "hct", default=0) or 0)
    wbc = float(get_field(fields, "wbc", "lökosit", "lokosit", default=0) or 0)
    platelets = float(get_field(fields, "platelets", "plt", "trombosit", default=0) or 0)
    alt = float(get_field(fields, "alt", default=0) or 0)
    ast = float(get_field(fields, "ast", default=0) or 0)
    creatinine = float(get_field(fields, "creatinine", "kreatinin", default=0) or 0)
    egfr = float(get_field(fields, "egfr", "glomeruler_filtrasyon_hizi", default=0) or 0)
    crp = float(get_field(fields, "crp", default=0) or 0)

    # Glucose / HbA1c
    if glucose >= 126:
        recommendations.append(Recommendation(title="Yüksek açlık glukozu", reason=f"Glukoz {glucose} mg/dL.", priority="high"))
    elif 100 <= glucose <= 125:
        recommendations.append(Recommendation(title="Prediyabet aralığı (glukoz)", reason=f"Glukoz {glucose} mg/dL.", priority="medium"))

    if hba1c >= 6.5:
        recommendations.append(Recommendation(title="HbA1c diyabet aralığı", reason=f"HbA1c {hba1c}%.", priority="high"))
    elif 5.7 <= hba1c < 6.5:
        recommendations.append(Recommendation(title="HbA1c prediyabet aralığı", reason=f"HbA1c {hba1c}%.", priority="medium"))

    # Lipids
    if is_adult:
        if ldl >= 160:
            recommendations.append(Recommendation(title="LDL yüksek", reason=f"LDL {ldl} mg/dL.", priority="high"))
        elif 130 <= ldl < 160:
            recommendations.append(Recommendation(title="LDL sınırda/orta yüksek", reason=f"LDL {ldl} mg/dL.", priority="medium"))
    else:
        if ldl >= 130:
            recommendations.append(Recommendation(title="LDL yüksek (pediatrik)", reason=f"LDL {ldl} mg/dL.", priority="high"))
        elif 110 <= ldl < 130:
            recommendations.append(Recommendation(title="LDL sınırda (pediatrik)", reason=f"LDL {ldl} mg/dL.", priority="medium"))

    if is_adult:
        hdl_low_threshold = 50 if sex == "female" else 40
    else:
        hdl_low_threshold = 45
    if hdl and hdl < hdl_low_threshold:
        recommendations.append(Recommendation(title="Düşük HDL", reason=f"HDL {hdl} mg/dL.", priority="medium"))

    if is_adult:
        if tg >= 200:
            recommendations.append(Recommendation(title="Trigliserid yüksek", reason=f"TG {tg} mg/dL.", priority="high"))
        elif 150 <= tg < 200:
            recommendations.append(Recommendation(title="Trigliserid hafif yüksek", reason=f"TG {tg} mg/dL.", priority="medium"))
    else:
        if tg >= 130:
            recommendations.append(Recommendation(title="Trigliserid yüksek (pediatrik)", reason=f"TG {tg} mg/dL.", priority="high"))
        elif 90 <= tg < 130:
            recommendations.append(Recommendation(title="Trigliserid sınırda (pediatrik)", reason=f"TG {tg} mg/dL.", priority="medium"))

    if is_adult:
        if total_chol >= 240:
            recommendations.append(Recommendation(title="Total kolesterol yüksek", reason=f"Total {total_chol} mg/dL.", priority="high"))
        elif 200 <= total_chol < 240:
            recommendations.append(Recommendation(title="Total kolesterol sınırda", reason=f"Total {total_chol} mg/dL.", priority="medium"))
    else:
        if total_chol >= 200:
            recommendations.append(Recommendation(title="Total kolesterol yüksek (pediatrik)", reason=f"Total {total_chol} mg/dL.", priority="high"))
        elif 170 <= total_chol < 200:
            recommendations.append(Recommendation(title="Total kolesterol sınırda (pediatrik)", reason=f"Total {total_chol} mg/dL.", priority="medium"))

    # Blood counts
    if is_adult:
        if sex == "male":
            hb_low, hb_high = 13.5, 17.5
        elif sex == "female":
            hb_low, hb_high = 12.0, 16.0
        else:
            hb_low, hb_high = 12.5, 17.0
    else:
        hb_low, hb_high = 11.5, 15.5

    if hemoglobin and hemoglobin < hb_low:
        recommendations.append(Recommendation(title="Anemi olası", reason=f"Hemoglobin {hemoglobin} g/dL.", priority="medium"))
    elif hemoglobin and hemoglobin > hb_high:
        recommendations.append(Recommendation(title="Yüksek hemoglobin", reason=f"Hemoglobin {hemoglobin} g/dL.", priority="medium"))

    if wbc and wbc > 11:
        recommendations.append(Recommendation(title="Lökositoz", reason=f"WBC {wbc} x10^3/µL.", priority="medium"))
    elif wbc and wbc < 4:
        recommendations.append(Recommendation(title="Lökopeni", reason=f"WBC {wbc} x10^3/µL.", priority="medium"))

    if platelets and platelets < 150:
        recommendations.append(Recommendation(title="Trombositopeni", reason=f"PLT {platelets} x10^3/µL.", priority="high"))
    elif platelets and platelets > 450:
        recommendations.append(Recommendation(title="Trombositoz", reason=f"PLT {platelets} x10^3/µL.", priority="medium"))

    # Liver/kidney/inflammation
    if alt and alt > 40:
        recommendations.append(Recommendation(title="ALT yüksek", reason=f"ALT {alt} U/L.", priority="medium"))
    if ast and ast > 40:
        recommendations.append(Recommendation(title="AST yüksek", reason=f"AST {ast} U/L.", priority="medium"))

    if sex == "male":
        creat_high = 1.4
    elif sex == "female":
        creat_high = 1.2
    else:
        creat_high = 1.3
    if creatinine and creatinine > creat_high:
        recommendations.append(Recommendation(title="Kreatinin yüksek", reason=f"Kreatinin {creatinine} mg/dL.", priority="medium"))

    if egfr and egfr < 60:
        recommendations.append(Recommendation(title="Azalmış böbrek fonksiyonu", reason=f"eGFR {egfr} mL/min/1.73m².", priority="high"))

    if crp and crp > 5:
        recommendations.append(Recommendation(title="CRP yüksek (inflamasyon)", reason=f"CRP {crp} mg/L.", priority="medium"))

    return {
        "summary": {
            "sex": sex,
            "age": age,
            "glucose": glucose,
            "hba1c": hba1c,
            "ldl": ldl,
            "hdl": hdl,
            "triglycerides": tg,
            "total_cholesterol": total_chol,
            "hemoglobin": hemoglobin,
            "hematocrit": hematocrit,
            "wbc": wbc,
            "platelets": platelets,
            "alt": alt,
            "ast": ast,
            "creatinine": creatinine,
            "egfr": egfr,
            "crp": crp,
        },
        "recommendations": [rec.to_dict() for rec in recommendations],
    }


__all__ = ["analyze_pdf", "Recommendation"]


