from decimal import Decimal
from typing import Dict, Any

class CostEstimatorService:
    """
    Hito 16 Part A: Early Cost Intelligence.
    Provides estimated transaction costs based on Spanish regulations.
    IMPORTANT: All outputs are ESTIMATES.
    """
    
    # 2024 Base Rates (Simplified for MVP)
    ITP_RATES = {
        "MADRID": 0.06,
        "CATALONIA": 0.10,
        "ANDALUSIA": 0.07,
        "VALENCIA": 0.10,
        "GALICIA": 0.09,
        "OTHER": 0.08  # National Average fallback
    }
    
    DISCLAIMER_TEXT = (
        "IMPORTANTE: Los importes mostrados son meras estimaciones basadas en tipos generales vigentes "
        "y baremos orientativos. No incluyen bonificaciones específicas (familia numerosa, discapacidad, jóvenes) "
        "ni gastos de gestoría o tasación variables. Esta información NO constituye asesoramiento fiscal vinculante. "
        "Recomendamos encarecidamente consultar con un asesor fiscal o gestor administrativo antes de tomar decisiones económicas."
    )

    @staticmethod
    def calculate_purchase_costs(price: float, region: str, is_new_construction: bool = False) -> Dict[str, Any]:
        """
        Calculates ITP/IVA, Notary, and Registry costs.
        """
        price_dec = Decimal(str(price))
        region_key = region.upper()
        
        # 1. Tax (Impuestos)
        if is_new_construction:
            # IVA 10% (General) + AJD (Actos Jurídicos Documentados) ~1%
            # Simplified: IVA 10% + AJD 1% = 11%
            tax_rate = Decimal("0.11")
            tax_name = "IVA (10%) + AJD (Est. 1%)"
        else:
            # ITP (Impuesto Transmisiones Patrimoniales)
            rate = Decimal(str(CostEstimatorService.ITP_RATES.get(region_key, 0.08)))
            tax_rate = rate
            tax_name = f"ITP ({int(rate*100)}%)"
            
        tax_amount = price_dec * tax_rate
        
        # 2. Notary (Arancel Notarial - RD 1426/1989)
        # Scale is complex, using a conservative estimator for MVP
        # Usually ~600-900 eur for average flats.
        # Logic: Base fee + sliding scale.
        notary_amount = CostEstimatorService._calculate_notary_scale(price_dec)
        
        # 3. Registry (Registro de la Propiedad)
        # Usually ~50% of Notary cost
        registry_amount = CostEstimatorService._calculate_registry_scale(price_dec)
            
        total = tax_amount + notary_amount + registry_amount
        
        return {
            "input_price": float(price_dec),
            "region": region_key,
            "tax_name": tax_name,
            "tax_amount": float(round(tax_amount, 2)),
            "notary_estimated": float(round(notary_amount, 2)),
            "registry_estimated": float(round(registry_amount, 2)),
            "total_estimated_costs": float(round(total, 2)),
            "grand_total": float(round(price_dec + total, 2)),
            "legal_disclaimer": CostEstimatorService.DISCLAIMER_TEXT
        }

    @staticmethod
    def _calculate_notary_scale(price: Decimal) -> Decimal:
        """
        Estimates standard Notary Tariff (Arancel).
        Does not include 'copias', 'folios', or VAT on the notary bill.
        Adding 20% buffer for extras.
        """
        # Simplified Arancel Table
        # Up to 6.010,12 -> 90,15
        # 6.010,12 to 30.050,61 -> 4,5 per 1000
        # 30.050,61 to 60.101,21 -> 1,50 per 1000
        # 60.101,21 to 150.253,03 -> 1,05 per 1000
        # 150.253,03 to 601.012,10 -> 0.5 per 1000
        # Over 601.012,10 -> 0.3 per 1000
        
        # Algorithmic approximation for cleaner MVP code:
        # Base ~850 for 300k.
        
        if price <= 0: return Decimal(0)
        
        fee = Decimal(0)
        remaining = price
        
        # Tramo 1: 0 - 6k
        chunk = min(remaining, Decimal("6010.12"))
        if chunk > 0:
            fee += Decimal("90.15")
            remaining -= chunk
            
        # Tramo 2: 6k - 30k
        chunk = min(remaining, Decimal("24040.49")) # 30050.61 - 6010.12
        if chunk > 0:
            fee += chunk * Decimal("0.0045")
            remaining -= chunk
            
        # Tramo 3: 30k - 60k
        chunk = min(remaining, Decimal("30050.60")) # 60101.21 - 30050.61
        if chunk > 0:
            fee += chunk * Decimal("0.0015")
            remaining -= chunk
            
        # Tramo 4: 60k - 150k
        chunk = min(remaining, Decimal("90151.82")) # 150253.03 - 60101.21
        if chunk > 0:
            fee += chunk * Decimal("0.00105")
            remaining -= chunk
            
        # Tramo 5: 150k - 600k
        chunk = min(remaining, Decimal("450759.07")) # 601012.10 - 150253.03
        if chunk > 0:
            fee += chunk * Decimal("0.0005")
            remaining -= chunk
            
        # Tramo 6: > 600k
        if remaining > 0:
            fee += remaining * Decimal("0.0003")
            
        # Reduction (Arancel may have reductions) or Extras (Copies)
        # We apply a +20% factor for Copies + Timbre + IVA 21% on the bill
        final_fee = fee * Decimal("1.21") # Adding VAT roughly
        
        # Minimum practical
        if final_fee < 400: final_fee = Decimal(400)
        
        return final_fee

    @staticmethod
    def _calculate_registry_scale(price: Decimal) -> Decimal:
        """
        Estimates Property Registry Fee.
        Similar scale to Notary but usually lower (~50-60%).
        """
        # Rule of thumb for MVP: 65% of Notary cost
        notary = CostEstimatorService._calculate_notary_scale(price)
        registry = notary * Decimal("0.65")
        if registry < 250: registry = Decimal(250)
        return registry
