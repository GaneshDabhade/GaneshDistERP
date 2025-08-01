app_name = "ganeshdistapp"
app_title = "Ganesh Distribution"
app_publisher = "Ganesh Dabhade"
app_description = "This ERP app will be used for distribution business"
app_email = "ganeshcdabhade@gmail.com"
app_license = "mit"


# Apps
# ------------------

# required_apps = []

# Each item in the list will be shown as an app in the apps page
# add_to_apps_screen = [
# 	{
# 		"name": "ganeshdistapp",
# 		"logo": "/assets/ganeshdistapp/logo.png",
# 		"title": "Ganesh Distribution",
# 		"route": "/ganeshdistapp",
# 		"has_permission": "ganeshdistapp.api.permission.has_app_permission"
# 	}
# ]

# Includes in <head>
# ------------------

# include js, css files in header of desk.html
# app_include_css = "/assets/ganeshdistapp/css/ganeshdistapp.css"
# app_include_js = "/assets/ganeshdistapp/js/ganeshdistapp.js"

# include js, css files in header of web template
# web_include_css = "/assets/ganeshdistapp/css/ganeshdistapp.css"
# web_include_js = "/assets/ganeshdistapp/js/ganeshdistapp.js"

# include custom scss in every website theme (without file extension ".scss")
# website_theme_scss = "ganeshdistapp/public/scss/website"

# include js, css files in header of web form
# webform_include_js = {"doctype": "public/js/doctype.js"}
# webform_include_css = {"doctype": "public/css/doctype.css"}

# include js in page
# page_js = {"page" : "public/js/file.js"}

# include js in doctype views
# doctype_js = {"doctype" : "public/js/doctype.js"}
# doctype_list_js = {"doctype" : "public/js/doctype_list.js"}
# doctype_tree_js = {"doctype" : "public/js/doctype_tree.js"}
# doctype_calendar_js = {"doctype" : "public/js/doctype_calendar.js"}

# Svg Icons
# ------------------
# include app icons in desk
# app_include_icons = "ganeshdistapp/public/icons.svg"

# Home Pages
# ----------

# application home page (will override Website Settings)
# home_page = "login"

# website user home page (by Role)
# role_home_page = {
# 	"Role": "home_page"
# }

# Generators
# ----------

# automatically create page for each record of this doctype
# website_generators = ["Web Page"]

# Jinja
# ----------

# add methods and filters to jinja environment
# jinja = {
# 	"methods": "ganeshdistapp.utils.jinja_methods",
# 	"filters": "ganeshdistapp.utils.jinja_filters"
# }

# Installation
# ------------

# before_install = "ganeshdistapp.install.before_install"
# after_install = "ganeshdistapp.install.after_install"

# Uninstallation
# ------------

# before_uninstall = "ganeshdistapp.uninstall.before_uninstall"
# after_uninstall = "ganeshdistapp.uninstall.after_uninstall"

# Integration Setup
# ------------------
# To set up dependencies/integrations with other apps
# Name of the app being installed is passed as an argument

# before_app_install = "ganeshdistapp.utils.before_app_install"
# after_app_install = "ganeshdistapp.utils.after_app_install"

# Integration Cleanup
# -------------------
# To clean up dependencies/integrations with other apps
# Name of the app being uninstalled is passed as an argument

# before_app_uninstall = "ganeshdistapp.utils.before_app_uninstall"
# after_app_uninstall = "ganeshdistapp.utils.after_app_uninstall"

# Desk Notifications
# ------------------
# See frappe.core.notifications.get_notification_config

# notification_config = "ganeshdistapp.notifications.get_notification_config"

# Permissions
# -----------
# Permissions evaluated in scripted ways

# permission_query_conditions = {
# 	"Event": "frappe.desk.doctype.event.event.get_permission_query_conditions",
# }
#
# has_permission = {
# 	"Event": "frappe.desk.doctype.event.event.has_permission",
# }

# DocType Class
# ---------------
# Override standard doctype classes

# override_doctype_class = {
# 	"ToDo": "custom_app.overrides.CustomToDo"
# }

# Document Events
# ---------------
# Hook on document methods and events

# doc_events = {
# 	"*": {
# 		"on_update": "method",
# 		"on_cancel": "method",
# 		"on_trash": "method"
# 	}
# }

# Scheduled Tasks
# ---------------

# scheduler_events = {
# 	"all": [
# 		"ganeshdistapp.tasks.all"
# 	],
# 	"daily": [
# 		"ganeshdistapp.tasks.daily"
# 	],
# 	"hourly": [
# 		"ganeshdistapp.tasks.hourly"
# 	],
# 	"weekly": [
# 		"ganeshdistapp.tasks.weekly"
# 	],
# 	"monthly": [
# 		"ganeshdistapp.tasks.monthly"
# 	],
# }

# Testing
# -------

# before_tests = "ganeshdistapp.install.before_tests"

# Overriding Methods
# ------------------------------
#
# override_whitelisted_methods = {
# 	"frappe.desk.doctype.event.event.get_events": "ganeshdistapp.event.get_events"
# }
#
# each overriding function accepts a `data` argument;
# generated from the base implementation of the doctype dashboard,
# along with any modifications made in other Frappe apps
# override_doctype_dashboards = {
# 	"Task": "ganeshdistapp.task.get_dashboard_data"
# }

# exempt linked doctypes from being automatically cancelled
#
# auto_cancel_exempted_doctypes = ["Auto Repeat"]

# Ignore links to specified DocTypes when deleting documents
# -----------------------------------------------------------

# ignore_links_on_delete = ["Communication", "ToDo"]

# Request Events
# ----------------
# before_request = ["ganeshdistapp.utils.before_request"]
# after_request = ["ganeshdistapp.utils.after_request"]

# Job Events
# ----------
# before_job = ["ganeshdistapp.utils.before_job"]
# after_job = ["ganeshdistapp.utils.after_job"]

# User Data Protection
# --------------------

# user_data_fields = [
# 	{
# 		"doctype": "{doctype_1}",
# 		"filter_by": "{filter_by}",
# 		"redact_fields": ["{field_1}", "{field_2}"],
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_2}",
# 		"filter_by": "{filter_by}",
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_3}",
# 		"strict": False,
# 	},
# 	{
# 		"doctype": "{doctype_4}"
# 	}
# ]

# Authentication and authorization
# --------------------------------

# auth_hooks = [
# 	"ganeshdistapp.auth.validate"
# ]

# Automatically update python controller files with type annotations for this app.
# export_python_type_annotations = True

# default_log_clearing_doctypes = {
# 	"Logging DocType Name": 30  # days to retain logs
# }

# fixtures = [
#     {"dt": "Custom Field", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"dt": "Property Setter", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"dt": "Workflow"},
#     {"dt": "Workflow State"},
#     {"dt": "Workflow Action"},
#     {"dt": "Report", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"dt": "Role", "filters": [["custom", "=", 1]]},
#     {"dt": "Print Format", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"dt": "Client Script", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"dt": "Module Profile"},
#     {"dt": "Translation"},
#     {"dt": "Property Setter"},
#     {"dt": "DocType", "filters": [["custom", "=", 1]]}
# ]

# fixtures = [
#     {"doctype": "Custom Field", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"doctype": "Property Setter", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"doctype": "Client Script", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"doctype": "Workflow"},
#     {"doctype": "Workflow State"},
#     {"doctype": "Workflow Action Master"},
#     {"doctype": "Report", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"doctype": "Role"}, 
#     {"doctype": "Print Format", "filters": [["module", "=", "Ganesh Distribution"]]},
#     {"doctype": "Module Profile"},
#     {"doctype": "Translation"},
#     {"doctype": "DocType", "filters": [["custom", "=", 1]]}
# ]

fixtures = [
    {"doctype": "Custom Field"},
    {"doctype": "Property Setter"},
    {"doctype": "Client Script"},
    {"doctype": "Workflow"},
    {"doctype": "Workflow State"},
    {"doctype": "Workflow Action Master"},
    {"doctype": "Report"},
    {"doctype": "Role"},
    {"doctype": "Print Format"},
    {"doctype": "Module Profile"},
    {"doctype": "Translation"},
    {"doctype": "DocType", "filters": [["custom", "=", 1]]}
]

doc_events = {
    "Purchase Receipt": {
        "on_submit": "ganeshdistapp.ganesh_distribution.api.create_invoice_from_pr"
    },
    "Payment Entry": {
        "before_validate": "ganeshdistapp.ganesh_distribution.payment_entry_hooks.auto_fill_upi_reference"
    }
}


