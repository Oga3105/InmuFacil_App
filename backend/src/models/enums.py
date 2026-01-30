import enum

class DNIStatus(str, enum.Enum):
    """DNI validation status enumeration"""
    PENDIENTE = "pendiente"
    VALIDADO = "validado"

class UserType(str, enum.Enum):
    """User type enumeration"""
    PARTICULAR = "particular"
    PROFESIONAL = "profesional"

class PropertyType(str, enum.Enum):
    PISO = "piso"
    CHALET = "chalet"
    LOCAL = "local"
    OFICINA = "oficina"
    TERRENO = "terreno"
    EDIFICIO = "edificio"

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
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    COUNTERED = "countered"
    PAUSED = "paused" # For when another offer is accepted
