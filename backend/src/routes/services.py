from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from backend.src.config.database import get_db
from backend.src.models import User, UserType
from backend.src.models.services import ServiceOrder, ServiceType, ServiceStatus
from backend.src.schemas.services import ServiceOrderCreate, ServiceOrderUpdate, ServiceOrderResponse
from backend.src.utils.security import get_current_active_user
import uuid
import datetime

router = APIRouter(prefix="/services", tags=["Services"])

# ============================================================================
# Helper Functions
# ============================================================================

def generate_ticket_number(service_type: ServiceType) -> str:
    """Generates a ticket like 'VAL-2026-A1B2'"""
    # Simple prefix map
    prefixes = {
        ServiceType.VALUATION: "VAL",
        ServiceType.NOTARY_ASSIGNMENT: "NOT",
        ServiceType.ENERGY_CERTIFICATE: "ENE",
        ServiceType.MORTGAGE_BROKERAGE: "MTG",
        ServiceType.INSURANCE: "INS",
        ServiceType.LEGAL_ADVICE: "LEG",
        ServiceType.MOVING_SERVICE: "MOV",
        ServiceType.REFORM_ESTIMATE: "REF",
    }
    prefix = prefixes.get(service_type, "SRV")
    year = datetime.datetime.now().year
    suffix = uuid.uuid4().hex[:4].upper()
    return f"{prefix}-{year}-{suffix}"

# ============================================================================
# Endpoints
# ============================================================================

@router.post("/request", response_model=ServiceOrderResponse, status_code=status.HTTP_201_CREATED)
async def request_service(
    service_request: ServiceOrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    User requests a specialized service (e.g. Valuation, Moving).
    """
    # Generate Ticket
    ticket = generate_ticket_number(service_request.service_type)
    
    # Create Order
    new_order = ServiceOrder(
        ticket_number=ticket,
        service_type=service_request.service_type,
        requester_id=current_user.id,
        property_id=service_request.property_id,
        offer_id=service_request.offer_id,
        status=ServiceStatus.REQUESTED,
        result_data={"notes": service_request.requester_notes} if service_request.requester_notes else {}
    )
    
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    return new_order


@router.get("/", response_model=List[ServiceOrderResponse])
async def list_service_orders(
    service_type: Optional[ServiceType] = None,
    status: Optional[ServiceStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List service orders with Role-Based Access Control (RBAC).
    - ADMIN: Sees all (can filter).
    - PROVIDER: Sees only orders assigned to them.
    - USER: Sees only orders requested by them.
    """
    query = db.query(ServiceOrder)
    
    # 1. Apply Role Filter
    if current_user.user_type == "admin" or current_user.email == "admin@inmufacil.com":
        pass # Admin sees all
    
    elif current_user.user_type == "provider":
        # Provider sees only ASSIGNED orders to them
        query = query.filter(ServiceOrder.provider_id == current_user.id)
        
    else:
        # User sees only their OWN requests
        query = query.filter(ServiceOrder.requester_id == current_user.id)
    
    # 2. Apply Filters
    if service_type:
        query = query.filter(ServiceOrder.service_type == service_type)
    if status:
        query = query.filter(ServiceOrder.status == status)
        
    return query.order_by(desc(ServiceOrder.created_at)).all()


@router.patch("/{order_id}", response_model=ServiceOrderResponse)
async def update_service_order(
    order_id: int,
    update_data: ServiceOrderUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update a service order (Status, Price, Result, Rating).
    RBAC:
    - ADMIN: Can update everything (Rating, Provider Assign, etc).
    - PROVIDER: Can update Status, Price, Result (only if assigned).
    - USER: Can update Rating (only if completed).
    """
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Service Order not found")
        
    is_admin = (current_user.user_type == "admin" or current_user.email == "admin@inmufacil.com")
    is_provider = (current_user.id == order.provider_id)
    is_requester = (current_user.id == order.requester_id)
    
    # Logic Map
    if is_admin:
        # Admin can edit anything (Assign provider, rate, etc)
        # In a real app we might validate 'provider_category' here before assigning
        for field, value in update_data.dict(exclude_unset=True).items():
            setattr(order, field, value)
            
    elif is_provider:
        # Provider can update workflow fields
        if update_data.rating is not None or update_data.admin_notes is not None:
             raise HTTPException(status_code=403, detail="Providers cannot rate themselves or add admin notes")
        
        if update_data.status:
            order.status = update_data.status
        if update_data.quoted_price:
            order.quoted_price = update_data.quoted_price
        if update_data.final_price:
            order.final_price = update_data.final_price
        if update_data.result_data:
            # Merge or replace? For now replace.
            order.result_data = update_data.result_data
            
    elif is_requester:
        # Requester can mainly Rate when completed
        if update_data.rating:
            if order.status != ServiceStatus.COMPLETED:
                 raise HTTPException(status_code=400, detail="Can only rate completed services")
            order.rating = update_data.rating
            
        # Requester usually doesn't change price/status directly via API (cancellation logic separate)
        
    else:
        raise HTTPException(status_code=403, detail="Access denied")
        
    db.commit()
    db.refresh(order)
    return order
