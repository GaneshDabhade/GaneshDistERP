import frappe
from frappe.utils import now, nowdate

def auto_fill_upi_reference(doc, method):
    if doc.mode_of_payment == "UPI":
        if not doc.reference_no:
            doc.reference_no = "UPI-" + now()
        if not doc.reference_date:
            doc.reference_date = nowdate()
