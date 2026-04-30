# Booking Platform

Multi-tenant booking platform for service businesses.

The project contains:

- FastAPI backend
- Public booking website
- Flutter app for platform admin, business owner and specialist workflows

## Project structure

```text
booking-platform/
├── backend/        # FastAPI backend
├── client_web/     # Public booking website
├── admin_flutter/  # Flutter admin / owner / specialist app
└── infrastructure/ # Deployment / infrastructure notes
```

## Backend setup

Open PowerShell and run:

```powershell
cd D:\booking-platform\backend

python -m venv venv

venv\Scripts\activate

pip install -r requirements.txt

copy .env.example .env
```

Update `.env` values if needed.

Run backend:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend URL:

```text
http://localhost:8000
```

## Public web setup

Open a new PowerShell window and run:

```powershell
cd D:\booking-platform\client_web

npm install

copy .env.example .env.local

npm run dev
```

Public web URL:

```text
http://localhost:3000
```

## Flutter app setup

Open a new PowerShell window and run:

```powershell
cd D:\booking-platform\admin_flutter

flutter pub get

flutter run
```

The Flutter app currently contains separate flows for:

- platform admin
- business owner
- specialist

## Local test flow

1. Start backend.
2. Start public web.
3. Start Flutter app.
4. Create or verify business, specialist, service and working hours.
5. Open public web.
6. Select specialist.
7. Select service.
8. Select available date and time.
9. Submit booking.
10. Verify that:
   - appointment is created
   - selected slot disappears from public availability
   - appointment appears in the Flutter app
   - appointment status actions work where available
   - appointment cards show service name instead of only service ID

## Current implemented functionality

### Backend

- Local SQLite development database.
- Environment-based configuration.
- Authentication for internal app users.
- Role-based user model:
  - admin
  - owner
  - specialist
- Business, specialist, service, working hours, availability exception and appointment entities.
- Public booking availability flow.
- Appointment creation with backend-side validation.
- Appointment overlap prevention.
- Appointment status update support.
- Public specialist filtering by business.
- Specialist public visibility support through `is_bookable`.
- Admin users are excluded from public booking visibility.

### Public web

- Public booking flow.
- Business ID is passed to public specialist requests.
- API URL is configured through environment settings.
- Booking can be submitted from the public web.
- Booking success state / screen exists.

### Flutter app

The Flutter app is now split into clearer role areas.

#### Platform admin

Platform admin can manage and review platform-level data:

- businesses
- users
- reservations
- working hours
- availability exceptions

Admin pages are intended only for platform administration.

#### Business owner

Business owner has a separate owner area and no longer depends on admin pages for the main workflows.

Business owner can manage:

- own business reservations
- own business specialists
- own business working hours
- own business availability exceptions

Owner pages do not show unnecessary platform-level business filters.

#### Specialist

Specialist can access specialist-specific workflows:

- appointments
- services
- working hours
- availability exceptions
- calendar / availability views

### Appointment cards

Appointment cards now show clearer information:

- status labels are shown in Lithuanian
- action menus include clearer appointment actions
- service name is shown instead of only technical service ID
- fallback remains available if service name cannot be resolved

Examples:

```text
Statusas: Patvirtintas
Paslauga: Kirpimas
```

Instead of:

```text
Statusas: confirmed
Paslaugos ID: 1
```

## Development notes

- Backend uses SQLite for local development.
- Environment files are not committed.
- `.env.example` files are committed as setup templates.
- Public web still uses a temporary local development business selection approach.
- Proper tenant / business resolution for public booking is still planned.
- Alembic migrations are not yet implemented.
- Some local database changes may currently require manual SQLite migration commands during development.
- Flutter app API base URL is centralized in app config.

## Known TODO

- Improve public booking tenant / business resolution instead of relying on temporary local business selection.
- Add Alembic migrations when models stabilize.
- Add automated tests for booking availability and overlap prevention.
- Add more automated backend tests for appointment status rules.
- Improve public web UX and error handling.
- Improve appointment lifecycle rules if stricter status transitions are needed.
- Review whether business owner should also manage services from a dedicated owner services page.
- Prepare deployment configuration when MVP functionality stabilizes.