
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import cm
from datetime import datetime
import io

class ContractGenerator:
    """
    Generates legal contracts in PDF format.
    Uses ReportLab low-level canvas for precise positioning suitable for legal docs.
    """

    @staticmethod
    def generate_arras_draft(
        buyer_name: str, 
        buyer_dni: str,
        seller_name: str,
        seller_dni: str,
        property_address: str,
        property_registry_ref: str,
        price_total: float,
        deposit_amount: float,
        limit_date: datetime
    ) -> bytes:
        """
        Generates a PDF byte stream for 'Arras Penitenciales'.
        """
        buffer = io.BytesIO()
        c = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4

        # --- WATERMARK ---
        c.saveState()
        c.setFont("Helvetica-Bold", 60)
        c.setFillGray(0.85)
        c.translate(width/2, height/2)
        c.rotate(45)
        c.drawCentredString(0, 0, "BORRADOR - NO VÁLIDO")
        c.restoreState()

        # --- HEADER ---
        y_position = height - 2*cm
        c.setFont("Helvetica-Bold", 16)
        c.drawCentredString(width/2, y_position, "CONTRATO DE ARRAS PENITENCIALES")
        y_position -= 1.5*cm

        # --- BODY TEXT ---
        c.setFont("Helvetica", 11)
        line_height = 0.5*cm
        margin_left = 2.5*cm
        text_width = width - 5*cm

        # Date and Place
        fecha_actual = datetime.now().strftime("%d de %B de %Y")
        c.drawString(margin_left, y_position, f"En Madrid, a {fecha_actual}.")
        y_position -= 1.5*cm

        # REUNIDOS
        c.setFont("Helvetica-Bold", 12)
        c.drawString(margin_left, y_position, "R E U N I D O S")
        y_position -= 1*cm
        
        c.setFont("Helvetica", 11)
        # Vendedor
        c.drawString(margin_left, y_position, "DE UNA PARTE (VENDEDOR):")
        y_position -= line_height
        c.drawString(margin_left + 1*cm, y_position, f"D./Dña. {seller_name}, con DNI/NIE {seller_dni}.")
        y_position -= 1*cm

        # Comprador
        c.drawString(margin_left, y_position, "DE OTRA PARTE (COMPRADOR):")
        y_position -= line_height
        c.drawString(margin_left + 1*cm, y_position, f"D./Dña. {buyer_name}, con DNI/NIE {buyer_dni}.")
        y_position -= 1.5*cm

        # MANIFIESTAN
        c.setFont("Helvetica-Bold", 12)
        c.drawString(margin_left, y_position, "M A N I F I E S T A N")
        y_position -= 1*cm

        c.setFont("Helvetica", 11)
        # Clausula 1: Propiedad
        text_lines = [
            f"I. Que la parte VENDEDORA es titular de la vivienda sita en: {property_address}.",
            f"   Con Referencia Catastral: {property_registry_ref}.",
            "",
            "II. Que ambas partes han convenido la compraventa de dicho inmueble.",
            ""
        ]
        
        for line in text_lines:
            c.drawString(margin_left, y_position, line)
            y_position -= line_height
        
        y_position -= 0.5*cm

        # ESTIPULAN
        c.setFont("Helvetica-Bold", 12)
        c.drawString(margin_left, y_position, "E S T I P U L A N")
        y_position -= 1*cm
        
        c.setFont("Helvetica", 11)
        
        clauses = [
            ("PRIMERA.- Objeto", f"El VENDEDOR se compromete a vender y el COMPRADOR a comprar la finca descrita."),
            ("SEGUNDA.- Precio", f"El precio total de la compraventa se fija en {price_total:,.2f} EUROS."),
            ("TERCERA.- Arras", f"En este acto, el COMPRADOR entrega la cantidad de {deposit_amount:,.2f} EUROS en concepto de ARRAS PENITENCIALES (Artículo 1454 del Código Civil)."),
            ("CUARTA.- Plazo", f"La escritura pública se otorgará antes del: {limit_date.strftime('%d/%m/%Y')}."),
        ]

        for title, content in clauses:
            c.setFont("Helvetica-Bold", 11)
            c.drawString(margin_left, y_position, title)
            y_position -= line_height
            c.setFont("Helvetica", 11)
            
            # Simple word wrap simulation for simplicity in MVP
            words = content.split()
            line = ""
            for word in words:
                if c.stringWidth(line + " " + word, "Helvetica", 11) < text_width:
                    line += " " + word
                else:
                    c.drawString(margin_left, y_position, line.strip())
                    y_position -= line_height
                    line = word
            c.drawString(margin_left, y_position, line.strip())
            y_position -= 1.2*cm

        # --- SIGNATURES ---
        y_position = 4*cm
        c.line(margin_left, y_position, margin_left + 6*cm, y_position)
        c.line(width - margin_left - 6*cm, y_position, width - margin_left, y_position)
        
        y_position -= 0.5*cm
        c.drawString(margin_left, y_position, "Fdo: EL VENDEDOR")
        c.drawRightString(width - margin_left, y_position, "Fdo: EL COMPRADOR")

        c.showPage()
        c.save()
        
        buffer.seek(0)
        return buffer.getvalue()
