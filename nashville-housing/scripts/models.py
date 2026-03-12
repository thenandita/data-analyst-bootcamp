"""SQLModel table for Nashville Housing."""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlmodel import Field, SQLModel

from config import get_table_name


class NashvilleHousing(SQLModel, table=True):
    __tablename__ = get_table_name()

    unique_id: int = Field(primary_key=True)
    parcel_id: Optional[str] = Field(default=None, max_length=50, index=True)
    land_use: Optional[str] = Field(default=None, max_length=255)
    property_address: Optional[str] = None
    sale_date: Optional[datetime] = Field(default=None, index=True)
    sale_price: Optional[Decimal] = Field(default=None, max_digits=14, decimal_places=2)
    legal_reference: Optional[str] = Field(default=None, max_length=100)
    sold_as_vacant: Optional[str] = Field(default=None, max_length=10)
    owner_name: Optional[str] = None
    owner_address: Optional[str] = None
    acreage: Optional[Decimal] = Field(default=None, max_digits=10, decimal_places=4)
    tax_district: Optional[str] = Field(default=None, max_length=255)
    land_value: Optional[Decimal] = Field(default=None, max_digits=14, decimal_places=2)
    building_value: Optional[Decimal] = Field(default=None, max_digits=14, decimal_places=2)
    total_value: Optional[Decimal] = Field(default=None, max_digits=14, decimal_places=2)
    year_built: Optional[int] = None
    bedrooms: Optional[int] = None
    full_bath: Optional[int] = None
    half_bath: Optional[int] = None
