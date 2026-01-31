
from pydantic import BaseModel
from typing import Optional
from datetime import date

class ContractDetailsUpdate(BaseModel):
    """
    Answers to the Legal Questionnaire.
    """
    # 1. Foreign Funds (AML)
    has_foreign_funds: bool = False
    
    # 2. Cuerpo Cierto (Renuncia a reclamación de metros)
    is_cuerpo_cierto: bool = True
    
    # 3. Community / Debts
    community_fees_monthly: float = 0.0
    pending_derramas: float = 0.0 # Derramas pendientes
    
    # 4. Inventory
    include_furniture: bool = False
    inventory_list: Optional[str] = None # Detalles si aplica
    
    # 5. Deadlines
    max_deed_date: Optional[date] = None # Override calculated date
    
    # Extra
    delivery_condition: Optional[str] = "libre de cargas y ocupantes"

class ContractDetailsResponse(ContractDetailsUpdate):
    pass
