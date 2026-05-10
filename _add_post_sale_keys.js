const fs = require('fs');
const path = require('path');

const postSaleKeys = {
  "transaction": {
    "pv_snack_uploaded": "Documento subido correctamente.",
    "pv_error_upload": "Error al subir el documento.",
    "pv_error_save": "Error al guardar el estado del documento.",
    "pv_error_download": "Error al descargar el documento.",
    "pv_snack_downloaded": "Documento descargado con éxito.",
    "pv_seller_banner": "Sube las últimas facturas y justificantes para facilitar el cambio de titularidad al comprador.",
    "pv_elec_label": "Electricidad",
    "pv_elec_sub": "Última factura y código CUPS",
    "pv_elec_na": "No hay contrato de luz",
    "pv_water_label": "Agua",
    "pv_water_sub": "Última factura o recibo",
    "pv_water_na": "No hay contrato de agua",
    "pv_gas_label": "Gas",
    "pv_gas_sub": "Última factura (si aplica)",
    "pv_gas_na": "No hay contrato de gas",
    "pv_ibi_label": "IBI",
    "pv_ibi_sub": "Justificante de pago del año en curso",
    "pv_ibi_na": "Exento de IBI",
    "pv_comm_label": "Comunidad",
    "pv_comm_sub": "Certificado de corriente de pago",
    "pv_comm_na": "No hay comunidad",
    "pv_all_done": "Has completado la entrega de toda la documentación.",
    "pv_buyer_banner": "Aquí puedes descargar la documentación facilitada por el vendedor para tramitar los cambios de nombre.",
    "pv_buyer_elec": "Suministro Eléctrico",
    "pv_buyer_elec_sub": "Pasos para el cambio de titular",
    "pv_buyer_elec_1": "Localiza el código CUPS en la factura.",
    "pv_buyer_elec_2": "Llama a la comercializadora elegida.",
    "pv_buyer_elec_3": "Ten a mano la escritura de compraventa.",
    "pv_buyer_elec_4": "Indica tu cuenta bancaria para los recibos.",
    "pv_buyer_water": "Suministro de Agua",
    "pv_buyer_water_sub": "Pasos para el alta/cambio",
    "pv_buyer_water_1": "Identifica la empresa municipal de agua.",
    "pv_buyer_water_2": "Aporta el boletín si el alta es nueva.",
    "pv_buyer_water_3": "Presenta el DNI y la escritura.",
    "pv_buyer_water_4": "El proceso puede tardar unos días.",
    "pv_buyer_gas": "Suministro de Gas",
    "pv_buyer_gas_sub": "Trámites necesarios",
    "pv_buyer_gas_1": "Verifica si hay contrato activo.",
    "pv_buyer_gas_2": "Necesitarás el certificado de instalación.",
    "pv_buyer_gas_3": "Contacta con la distribuidora de la zona.",
    "pv_buyer_gas_4": "Solicita una revisión de seguridad.",
    "pv_buyer_ibi": "IBI y Tasas",
    "pv_buyer_ibi_sub": "Gestión municipal",
    "pv_buyer_ibi_1": "Acude al ayuntamiento con la escritura.",
    "pv_buyer_ibi_2": "Inscribe la propiedad en el catastro.",
    "pv_buyer_ibi_3": "Domicilia el próximo recibo.",
    "pv_buyer_ibi_4": "Comprueba posibles deudas anteriores.",
    "pv_buyer_comm": "Comunidad de Propietarios",
    "pv_buyer_comm_sub": "Alta como propietario",
    "pv_buyer_comm_1": "Contacta con el administrador.",
    "pv_buyer_comm_2": "Facilita tus datos de contacto.",
    "pv_buyer_comm_3": "Informa de tu cuenta para las cuotas.",
    "pv_buyer_comm_4": "Solicita los estatutos de la finca.",
    "pv_uploading": "Subiendo...",
    "pv_file_uploaded": "Archivo subido",
    "pv_in_person": "Entregado en persona",
    "pv_upload_btn": "Subir Archivo",
    "pv_in_person_btn": "Entregar en mano",
    "pv_not_applicable_btn": "No aplica",
    "pv_doc_available": "Documento disponible",
    "pv_in_person_badge": "En mano / Notaría",
    "pv_not_applicable_badge": "No aplica",
    "pv_pending_seller": "Pendiente del vendedor",
    "pv_download_btn": "Descargar documento",
    "pv_not_applicable_label": "No aplica"
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

  if (!data["transaction"]) data["transaction"] = {};
  for (const [k, v] of Object.entries(postSaleKeys["transaction"])) {
    data["transaction"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Post-sale keys injected.");
