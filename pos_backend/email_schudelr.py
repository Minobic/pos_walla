import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime, timedelta
import pytz
import schedule
import time
import calendar
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle
from io import BytesIO
from app import app, db, Invoice, InvoicePayment, Customer  # Import your Flask app and models

# Email configuration
EMAIL_ADDRESS = 'mayank04varma@gmail.com'
EMAIL_PASSWORD = 'nbfw ocuq yxrb oqqa'  # Use the app-specific password here
RECIPIENT_EMAIL = 'minobicgaming@gmail.com'

# Timezone
IST = pytz.timezone('Asia/Kolkata')

def send_email(subject, body, pdf_data=None):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = RECIPIENT_EMAIL
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    if pdf_data:
        pdf_attachment = MIMEBase('application', 'octet-stream')
        pdf_attachment.set_payload(pdf_data)
        encoders.encode_base64(pdf_attachment)
        pdf_attachment.add_header('Content-Disposition', f'attachment; filename= {subject}.pdf')
        msg.attach(pdf_attachment)

    try:
        print("Connecting to SMTP server...")
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        print("Logging into email account...")
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        text = msg.as_string()
        print("Sending email...")
        server.sendmail(EMAIL_ADDRESS, RECIPIENT_EMAIL, text)
        server.quit()
        print(f"Email sent successfully: {subject}")
    except Exception as e:
        print(f"Failed to send email: {e}")

def get_transactions(period):
    now = datetime.now(IST)
    if period == 'daily':
        start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == 'weekly':
        start_date = now - timedelta(days=now.weekday())
        start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == 'monthly':
        start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    elif period == 'quarterly':
        current_month = now.month
        quarter_start_month = 3 * ((current_month - 1) // 3) + 1
        start_date = now.replace(month=quarter_start_month, day=1, hour=0, minute=0, second=0, microsecond=0)
    elif period == 'yearly':
        start_date = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
    else:
        return []

    with app.app_context():
        transactions = (
            db.session.query(Invoice, InvoicePayment.payment_method, Customer.customer_name)
            .join(InvoicePayment, Invoice.invoice_id == InvoicePayment.invoice_id)
            .join(Customer, Invoice.customer_id == Customer.customer_id)
            .filter(Invoice.created_at >= start_date)
            .all()
        )

    transactions_list = []
    for invoice, payment_method, customer_name in transactions:
        transactions_list.append({
            'invoice_id': invoice.invoice_id,
            'customer_name': customer_name,
            'total_amount': float(invoice.total_amount),
            'payment_method': payment_method,
            'created_at': invoice.created_at.astimezone(IST).strftime('%d-%m-%Y %H:%M:%S'),
        })

    return transactions_list

def format_transactions_email(transactions, period):
    if not transactions:
        return f"No transactions found for the {period} period."

    body = f"Transaction Report for {period.capitalize()} Period:\n\n"
    for transaction in transactions:
        body += (f"Invoice ID: {transaction['invoice_id']}\n"
                 f"Customer Name: {transaction['customer_name']}\n"
                 f"Total Amount: {transaction['total_amount']}\n"
                 f"Payment Method: {transaction['payment_method']}\n"
                 f"Created At: {transaction['created_at']}\n\n")
    return body

def generate_pdf(transactions, period):
    pdf_buffer = BytesIO()
    doc = SimpleDocTemplate(pdf_buffer, pagesize=letter)
    elements = []

    # Data for the table
    data = [["Invoice ID", "Customer Name", "Total Amount", "Payment Method", "Created At"]]
    for transaction in transactions:
        data.append([
            str(transaction['invoice_id']),
            transaction['customer_name'],
            f"{transaction['total_amount']:.2f}",
            transaction['payment_method'],
            transaction['created_at']
        ])

    # Create the table and set its style
    table = Table(data)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.whitesmoke, colors.lightgrey])
    ]))

    elements.append(table)
    doc.build(elements)

    pdf_buffer.seek(0)
    return pdf_buffer.read()

def send_daily_report():
    print("Sending daily report...")
    transactions = get_transactions('daily')
    body = format_transactions_email(transactions, 'daily')
    pdf_data = generate_pdf(transactions, 'daily')
    send_email("Daily Transaction Report", body, pdf_data)

def send_weekly_report():
    print("Sending weekly report...")
    transactions = get_transactions('weekly')
    body = format_transactions_email(transactions, 'weekly')
    pdf_data = generate_pdf(transactions, 'weekly')
    send_email("Weekly Transaction Report", body, pdf_data)

def send_monthly_report():
    print("Sending monthly report...")
    transactions = get_transactions('monthly')
    body = format_transactions_email(transactions, 'monthly')
    pdf_data = generate_pdf(transactions, 'monthly')
    send_email("Monthly Transaction Report", body, pdf_data)

def send_quarterly_report():
    print("Sending quarterly report...")
    transactions = get_transactions('quarterly')
    body = format_transactions_email(transactions, 'quarterly')
    pdf_data = generate_pdf(transactions, 'quarterly')
    send_email("Quarterly Transaction Report", body, pdf_data)

def send_yearly_report():
    print("Sending yearly report...")
    transactions = get_transactions('yearly')
    body = format_transactions_email(transactions, 'yearly')
    pdf_data = generate_pdf(transactions, 'yearly')
    send_email("Yearly Transaction Report", body, pdf_data)

# Schedule the tasks
schedule.every().day.at("23:59").do(send_daily_report)
schedule.every().monday.at("23:59").do(send_weekly_report)

# Schedule monthly report for the last day of the month
def schedule_monthly_report():
    now = datetime.now(IST)
    last_day_of_month = calendar.monthrange(now.year, now.month)[1]
    if now.day == last_day_of_month:
        schedule.every().day.at("23:59").do(send_monthly_report)

# Schedule quarterly report for the last day of the quarter
def schedule_quarterly_report():
    now = datetime.now(IST)
    quarter_end_months = [3, 6, 9, 12]
    if now.month in quarter_end_months and now.day == calendar.monthrange(now.year, now.month)[1]:
        schedule.every().day.at("23:59").do(send_quarterly_report)

# Schedule yearly report for the last day of the year
def schedule_yearly_report():
    now = datetime.now(IST)
    if now.month == 12 and now.day == 31:
        schedule.every().day.at("23:59").do(send_yearly_report)

# Call the scheduling functions
schedule_monthly_report()
schedule_quarterly_report()
schedule_yearly_report()

if __name__ == "__main__":
    print("Scheduler started. Waiting for scheduled tasks...")
    while True:
        schedule.run_pending()
        time.sleep(1)
