import enum

class DNIStatus(str, enum.Enum):
    """DNI validation status enumeration"""
    PENDIENTE = "pendiente"
    VALIDADO = "validado"
    RECHAZADO = "rechazado"

class UserType(str, enum.Enum):
    """User type enumeration"""
    PARTICULAR = "particular"
    PROFESIONAL = "profesional"
    FINANCIERO = "financiero" # Hito 11
    ADMIN = "admin"           # Explicit Admin
    PROVIDER = "provider"     # External Service Agent

class ServiceType(str, enum.Enum):
    # Compliance & Listing
    ENERGY_CERTIFICATE = "energy_certificate"
    NOTA_SIMPLE_REQUEST = "nota_simple_request"
    PROFESSIONAL_PHOTOGRAPHY = "professional_photography"
    
    # Validation & Financial
    VALUATION = "valuation"
    MORTGAGE_BROKERAGE = "mortgage_brokerage"
    INSURANCE = "insurance"
    
    # Legal & Closing
    NOTARY_ASSIGNMENT = "notary_assignment"
    LEGAL_ADVICE = "legal_advice"
    
    # Post-Sales
    MOVING_SERVICE = "moving_service"
    REFORM_ESTIMATE = "reform_estimate"
    UTILITY_CHANGE = "utility_change" # Hito 16B support

class ServiceStatus(str, enum.Enum):
    REQUESTED = "requested"   # User asked for it
    QUOTED = "quoted"         # Provider sent price
    ASSIGNED = "assigned"     # User accepted provider
    IN_PROGRESS = "in_progress"
    REVIEW_PENDING = "review_pending" # Provider finished, Admin/User checking
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class PropertyType(str, enum.Enum):
    PISO = "piso"
    ATICO = "atico"
    DUPLEX = "duplex"
    CHALET = "chalet"
    CASA_RUSTICA = "casa_rustica"
    CASA_SINGULAR = "casa_singular"
    LOCAL = "local"
    OFICINA = "oficina"
    NAVE = "nave"
    EDIFICIO = "edificio"
    GARAJE = "garaje"
    TERRENO = "terreno"
    FINCA_RUSTICA = "finca_rustica"

class OperationType(str, enum.Enum):
    VENTA = "venta"
    ALQUILER = "alquiler"
    BTR = "btr"  # Build to Rent
    INVERSION = "inversion"

class Orientation(str, enum.Enum):
    NORTE = "norte"
    SUR = "sur"
    ESTE = "este"
    OESTE = "oeste"
    NORESTE = "noreste"
    NOROESTE = "noroeste"
    SURESTE = "sureste"
    SUROESTE = "suroeste"

class PropertyStatus(str, enum.Enum):
    PUBLISHED = "published"
    RESERVED = "reserved" # Hito 8
    SOLD = "sold"

class DocumentType(str, enum.Enum):
    NOTA_SIMPLE = "nota_simple"
    CERTIFICADO_ENERGETICO = "certificado_energetico"
    RECIBO_IBI = "recibo_ibi"
    CERTIFICADO_DEUDA = "certificado_deuda" # Hito 9 Refinement
    ESTATUTOS = "estatutos"
    OTRO = "otro"

class HeatingType(str, enum.Enum):
    GAS_NATURAL = "gas_natural"
    ELECTRICA = "electrica"
    CENTRAL = "central"
    AEROTERMIA = "aerotermia"
    OTRO = "otro"

class ConservationState(str, enum.Enum):
    A_ESTRENAR = "a_estrenar"
    BUEN_ESTADO = "buen_estado"
    A_REFORMAR = "a_reformar"

class EnergyCertification(str, enum.Enum):
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    E = "E"
    F = "F"
    G = "G"
    EXENTO = "exento"
    EN_TRAMITE = "en_tramite"

class ITEStatus(str, enum.Enum):
    PASADA = "pasada"
    PENDIENTE = "pendiente"
    DESFAVORABLE = "desfavorable"
    NO_OBLIGADO = "no_obligado"

class NotaSimpleStatus(str, enum.Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"

class CrimeRate(str, enum.Enum):
    BAJO = "bajo"
    MEDIO = "medio"
    ALTO = "alto"

class MediaType(str, enum.Enum):
    IMAGE = "image"
    VIDEO = "video"
    VIRTUAL_TOUR = "virtual_tour"

class VisitStatus(str, enum.Enum):
    REQUESTED = "requested"
    APPROVED = "approved"
    REJECTED = "rejected"
    # Execution States
    COMPLETED = "completed"
    NO_SHOW = "no_show"
    CANCELLED = "cancelled"

class OfferStatus(str, enum.Enum):
    PENDING = "pending"       # Offer sent, waiting for seller
    ACCEPTED = "accepted"     # Seller accepted
    REJECTED = "rejected"     # Seller rejected
    COUNTER_OFFER = "counter_offer" # Seller made a counter-offer
    SIGNING_PENDING = "signing_pending" # Hito 13: Waiting for signature
    SIGNED = "signed"         # Hito 13: Signed by both parties
    COMPLETED = "completed"   # Hito 15: Transaction Finalized

class NotaryStatus(str, enum.Enum):
    NOT_ASSIGNED = "not_assigned"
    ASSIGNED = "assigned"
    DOSSIER_SENT = "dossier_sent"
    COMPLETED = "completed"
