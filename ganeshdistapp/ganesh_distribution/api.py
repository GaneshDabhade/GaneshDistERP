import frappe
from frappe.utils import nowdate

@frappe.whitelist()
def create_invoice_from_pr(doc, method):
    if not doc.get("supplier"):
        frappe.throw("Supplier is required to create Purchase Invoice.")

    # Optional: skip unless checkbox is checked
    if not getattr(doc, 'custom_create_purchase_invoice', True):
        return

    pi = frappe.new_doc("Purchase Invoice")
    pi.supplier = doc.supplier
    pi.supplier_name = doc.supplier_name
    pi.posting_date = doc.posting_date
    pi.set_posting_time = 1
    pi.bill_no = doc.name  # for traceability
    pi.bill_date = doc.posting_date
    pi.company = doc.company
    pi.buying_price_list = doc.get("buying_price_list") or ""
    pi.currency = doc.currency
    pi.plc_conversion_rate = doc.get("plc_conversion_rate", 1)
    pi.conversion_rate = doc.get("conversion_rate", 1)

    for item in doc.items:
        pi.append("items", {
            "item_code": item.item_code,
            "item_name": item.item_name,
            "qty": item.qty,
            "rate": item.rate,
            "uom": item.uom,
            "warehouse": item.warehouse,
            "purchase_receipt": doc.name,
            "expense_account": item.expense_account,
            "cost_center": item.cost_center,
        })

    pi.insert(ignore_permissions=True)
    pi.submit()

    frappe.db.commit()
    frappe.msgprint(f"Purchase Invoice <a href='/app/purchase-invoice/{pi.name}'>{pi.name}</a> created.")
