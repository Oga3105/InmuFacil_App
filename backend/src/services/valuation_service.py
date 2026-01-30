
import random
from datetime import datetime
from decimal import Decimal
from sqlalchemy.orm import Session
from backend.src.models import Property, PropertyValuation, ValuationProvider, ConservationState
from backend.src.schemas.valuation import ValuationResponse

# Mock Base Prices per Zone (EUR/m2)
ZONE_PRICES = {
    "Centro": 3500,
    "Norte": 4200,
    "Sur": 2100,
    "Este": 2800,
    "Oeste": 3100,
    "Default": 2500
}

class ValuationService:
    """
    Service to handle property valuations.
    Combines internal algorithmic estimation with mocked external providers.
    """
    
    @staticmethod
    def _get_base_price(location: str):
        # A simple keyword match for zone simulation
        for zone, price in ZONE_PRICES.items():
            if zone.lower() in location.lower():
                return price
        return ZONE_PRICES["Default"]

    @staticmethod
    def _apply_adjustments(base_value: float, property: Property):
        adj_factor = 1.0
        
        # Adjust by features (if available) - Simple heuristics
        if property.features:
            # Lift adds 10%
            if property.features.has_lift:
                adj_factor += 0.10
            # Exterior/Terrace adds 5%
            if property.features.has_terrace:
                adj_factor += 0.05
                
            # Conservation State
            state = property.features.conservation_state
            if state == ConservationState.A_REFORMAR:
                adj_factor -= 0.20
            elif state == ConservationState.BUEN_ESTADO:
                adj_factor += 0.0
            elif state == ConservationState.A_ESTRENAR:
                adj_factor += 0.15
                
        return base_value * adj_factor

    @staticmethod
    def calculate_valuation(db: Session, property_id: int, provider: ValuationProvider = ValuationProvider.INTERNAL_ALGO) -> PropertyValuation:
        property = db.query(Property).filter(Property.id == property_id).first()
        if not property:
            raise ValueError("Property not found")

        # 1. Base Calculation
        base_price_m2 = ValuationService._get_base_price(property.location)
        raw_value = float(property.surface_area) * base_price_m2
        
        # 2. Adjustments
        final_value = ValuationService._apply_adjustments(raw_value, property)
        
        # 3. Provider Specific Logic (Simulation)
        confidence = 85 # Base confidence
        
        if provider == ValuationProvider.EXTERNAL_MOCK:
            # Simulate a slightly different value from an external "expert" source
            # Variation between -5% to +5%
            variation = random.uniform(0.95, 1.05)
            final_value = final_value * variation
            confidence = 95 # Higher confidence for external
            
        # 4. Create Entry
        valuation = PropertyValuation(
            property_id=property.id,
            estimated_value=Decimal(final_value),
            currency="EUR",
            confidence_score=confidence,
            provider=provider,
            valuation_date=datetime.utcnow()
        )
        
        db.add(valuation)
        db.commit()
        db.refresh(valuation)
        
        return valuation

    @staticmethod
    def get_valuation_history(db: Session, property_id: int):
        return db.query(PropertyValuation).filter(
            PropertyValuation.property_id == property_id
        ).order_by(PropertyValuation.valuation_date.desc()).all()
