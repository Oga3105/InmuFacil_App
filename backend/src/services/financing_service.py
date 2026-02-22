from decimal import Decimal
import random
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from backend.src.models.financing import MortgageProfile, MortgageSimulation, EmploymentStatus
from backend.src.models.users import User

class FinancingService:
    """
    Logic for Mortgage Simulation and Aggregation.
    """
    
    @staticmethod
    def calculate_solvency_score(profile: MortgageProfile) -> int:
        """
        Internal Score (0-100) based on stability and debt ratio.
        """
        score = 50 # Base
        
        # Stability
        if profile.employment_status == EmploymentStatus.FUNCIONARIO:
            score += 30
        elif profile.employment_status == EmploymentStatus.INDEFINIDO:
            score += 20
        elif profile.employment_status == EmploymentStatus.AUTONOMO:
            score += 10 if profile.contract_years > 3 else -5
            
        # Debt Ratio
        monthly_income = float(profile.monthly_net_income)
        if monthly_income > 3000:
            score += 10
        elif monthly_income < 1200:
            score -= 10
            
        return max(0, min(100, score))

    @staticmethod
    def simulate_mortgage(
        db: Session, 
        user_id: int, 
        amount: float,
        years: int = 30
    ) -> MortgageSimulation:
        """
        Generates a simulation with Mock offers.
        """
        profile = db.query(MortgageProfile).filter(MortgageProfile.user_id == user_id).first()
        if not profile:
            raise ValueError("Profile not found")
            
        score = FinancingService.calculate_solvency_score(profile)
        
        # Mock Offers
        offers = FinancingService._fetch_mock_offers(amount, years, score)
        
        import json
        simulation = MortgageSimulation(
            user_id=user_id,
            target_property_value=amount * 1.2, # Assumption 80% LTV
            asked_amount=amount,
            years=years,
            solvency_score=score,
            is_viable_internal=(score > 40),
            offers_snapshot=json.dumps(offers)
        )
        
        db.add(simulation)
        db.commit()
        db.refresh(simulation)
        return simulation

    @staticmethod
    def _fetch_mock_offers(amount: float, years: int, score: int) -> List[Dict[str, Any]]:
        """
        Simulate External APIs (iAhorro, Banks).
        """
        base_euribor = 3.5
        spread = 1.0 if score > 70 else 1.5 if score > 50 else 2.5
        
        offers = []
        
        # 1. Bank Direct (Big Banks)
        offers.append({
            "provider": "Banco Santander",
            "source": "Direct",
            "product_name": "Hipoteca Fija",
            "tin": base_euribor + spread - 0.2,
            "tae": base_euribor + spread + 0.5,
            "monthly_payment": round(amount * 0.005, 2), # Dummy Calc
            "requirements": ["Nomina", "Seguro Hogar"]
        })
        
        offers.append({
            "provider": "BBVA",
            "source": "Direct",
            "product_name": "Hipoteca Variable",
            "tin": base_euribor + 0.5, # Year 1
            "tae": base_euribor + 1.2,
            "monthly_payment": round(amount * 0.0045, 2),
            "requirements": ["Nomina"]
        })
        
        # 2. Aggregators (Best Offers)
        offers.append({
            "provider": "EVO Banco",
            "source": "iAhorro",
            "product_name": "Hipoteca Inteligente",
            "tin": base_euribor + spread - 0.5, # Better rate
            "tae": base_euribor + spread,
            "monthly_payment": round(amount * 0.0048, 2),
            "requirements": ["Nomina", "Seguro Vida"]
        })
        
        return offers
