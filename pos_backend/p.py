from datetime import datetime
import pytz
from sqlalchemy import Column, Integer, Numeric, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Invoice(Base):
    _tablename_ = 'Invoice'
    invoice_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('User .user_id'), nullable=False)
    customer_id = Column(Integer, ForeignKey('Customer.customer_id'), nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    sub_total = Column(Numeric(10, 2), nullable=False)
    discount_id = Column(Integer, ForeignKey('Coupon.coupon_id'))
    discount_amount = Column(Numeric(10, 2))
    tax_id = Column(Integer, ForeignKey('Tax.tax_id'))
    tax_amount = Column(Numeric(10, 2))
    loyalty_points = Column(Integer)
    
    # Set timezone to IST
    IST = pytz.timezone('Asia/Kolkata')
    
    created_at = Column(DateTime, default=lambda: datetime.now(IST))
    updated_at = Column(DateTime, default=lambda: datetime.now(IST), onupdate=lambda: datetime.now(IST))