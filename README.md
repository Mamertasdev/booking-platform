# Booking Platform

Multi-tenant booking platform for service businesses.

## Project structure

booking-platform/
├── backend/        # FastAPI backend
├── client_web/     # Public booking website
├── admin_flutter/  # Admin / specialist Flutter app
└── infrastructure/ # Deployment / infrastructure notes

## Backend setup

Open PowerShell and run:

cd D:\booking-platform\backend

python -m venv venv

venv\Scripts\activate

pip install -r requirements.txt

copy .env.example .env

Update `.env` values if needed.

Run backend:

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

Backend URL:

http://localhost:8000

## Public web setup

Open a new PowerShell window and run:

cd D:\booking-platform\client_web

npm install

copy .env.example .env.local

npm run dev

Public web URL:

http://localhost:3000

## Flutter admin setup

Open a new PowerShell window and run:

cd D:\booking-platform\admin_flutter

flutter pub get

flutter run

## Local test flow

1. Start backend.
2. Start public web.
3. Start Flutter admin app.
4. Create or verify business, specialist, service and working hours.
5. Open public web.
6. Select specialist.
7. Select service.
8. Select available date and time.
9. Submit booking.
10. Verify that:
   - appointment is created
   - selected slot disappears from public availability
   - appointment appears in Flutter admin app

## Current development notes

- Backend uses SQLite for local development.
- Environment files are not committed.
- `.env.example` files are committed as setup templates.
- Public web currently uses `business_id = 1` as a temporary local development value.
- Owners can currently appear in public booking if they are active and belong to the business.

## Known TODO

- Add `is_bookable` or `show_publicly` flag for specialists.
- Let business owners choose whether they appear in public booking.
- Improve public booking tenant/business resolution instead of hardcoded `business_id = 1`.
- Add Alembic migrations when models stabilize.
- Improve appointment status management in Flutter admin.
- Add automated tests for booking availability and overlap prevention.