import Link from "next/link";
import { fetchAPI } from "@/lib/api";

type AvailabilityResponse = {
  business_id: number;
  specialist_id: number;
  service_id: number;
  target_date: string;
  slots: {
    start_time: string;
    end_time: string;
  }[];
};

type CalendarDay = {
  date: string;
  dayNumber: number;
  inCurrentMonth: boolean;
};

function parseDateParts(dateString: string) {
  const [year, month, day] = dateString.split("-").map(Number);
  return { year, month, day };
}

function formatMonthTitle(dateString: string) {
  const { year, month } = parseDateParts(dateString);
  return `${month.toString().padStart(2, "0")}.${year}`;
}

function buildMonthCalendar(dateString: string): CalendarDay[] {
  const { year, month } = parseDateParts(dateString);

  const firstDay = new Date(Date.UTC(year, month - 1, 1));
  const firstWeekday = (firstDay.getUTCDay() + 6) % 7; // Monday = 0

  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const prevMonthDays = new Date(Date.UTC(year, month - 1, 0)).getUTCDate();

  const calendarDays: CalendarDay[] = [];

  for (let i = firstWeekday - 1; i >= 0; i--) {
    const dayNumber = prevMonthDays - i;
    const prevDate = new Date(Date.UTC(year, month - 2, dayNumber));
    calendarDays.push({
      date: prevDate.toISOString().split("T")[0],
      dayNumber,
      inCurrentMonth: false,
    });
  }

  for (let day = 1; day <= daysInMonth; day++) {
    const currentDate = new Date(Date.UTC(year, month - 1, day));
    calendarDays.push({
      date: currentDate.toISOString().split("T")[0],
      dayNumber: day,
      inCurrentMonth: true,
    });
  }

  while (calendarDays.length % 7 !== 0) {
    const nextDayNumber = calendarDays.length - (firstWeekday + daysInMonth) + 1;
    const nextDate = new Date(Date.UTC(year, month, nextDayNumber));
    calendarDays.push({
      date: nextDate.toISOString().split("T")[0],
      dayNumber: nextDayNumber,
      inCurrentMonth: false,
    });
  }

  return calendarDays;
}

function getTodayString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function isPastDate(dateString: string, todayString: string) {
  return dateString < todayString;
}

async function getAvailabilityForDate(
  businessId: number,
  specialistId: string,
  serviceId: string,
  targetDate: string
): Promise<AvailabilityResponse> {
  return fetchAPI(
    `/public/availability?business_id=${businessId}&specialist_id=${specialistId}&service_id=${serviceId}&target_date=${targetDate}`
  );
}

export default async function ServiceCalendarPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string; serviceId: string }>;
  searchParams: Promise<{ date?: string }>;
}) {
  const { id, serviceId } = await params;
  const resolvedSearchParams = await searchParams;

  const businessId = 1;
  const todayString = getTodayString();
  const requestedDate = resolvedSearchParams.date ?? todayString;
  const targetDate = requestedDate < todayString ? todayString : requestedDate;

  const monthDays = buildMonthCalendar(targetDate);

  const monthAvailabilityResults = await Promise.all(
    monthDays.map((day) =>
      getAvailabilityForDate(businessId, id, serviceId, day.date)
    )
  );

  const monthAvailabilityMap = new Map(
    monthDays.map((day, index) => [day.date, monthAvailabilityResults[index]])
  );

  const weekDays = ["Pr", "An", "Tr", "Kt", "Pn", "Št", "Sk"];

  return (
    <main
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f5f5",
        padding: "16px",
        fontFamily: "Arial, sans-serif",
      }}
    >
      <div
        style={{
          maxWidth: "480px",
          margin: "0 auto",
        }}
      >
        <h1
          style={{
            fontSize: "26px",
            marginBottom: "8px",
          }}
        >
          Pasirinkite datą
        </h1>

        <p
          style={{
            color: "#555",
            marginBottom: "20px",
            lineHeight: 1.5,
          }}
        >
          Pasirinkite dieną, kurioje yra laisvų laikų.
        </p>

        <div
          style={{
            backgroundColor: "#ffffff",
            borderRadius: "16px",
            padding: "16px",
            boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
          }}
        >
          <div
            style={{
              fontSize: "18px",
              fontWeight: 700,
              marginBottom: "16px",
              textAlign: "center",
            }}
          >
            {formatMonthTitle(targetDate)}
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(7, 1fr)",
              gap: "8px",
              marginBottom: "10px",
            }}
          >
            {weekDays.map((dayName) => (
              <div
                key={dayName}
                style={{
                  textAlign: "center",
                  fontSize: "12px",
                  fontWeight: 700,
                  color: "#666",
                }}
              >
                {dayName}
              </div>
            ))}
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(7, 1fr)",
              gap: "8px",
            }}
          >
            {monthDays.map((day) => {
              const availability = monthAvailabilityMap.get(day.date);
              const hasSlots = (availability?.slots?.length ?? 0) > 0;
              const isSelected = day.date === targetDate;
              const isPast = isPastDate(day.date, todayString);

              const baseStyle: React.CSSProperties = {
                minHeight: "44px",
                borderRadius: "10px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "14px",
                fontWeight: 600,
              };

              if (!day.inCurrentMonth) {
                return (
                  <div
                    key={day.date}
                    style={{
                      ...baseStyle,
                      backgroundColor: "#f0f0f0",
                      color: "#bbb",
                    }}
                  >
                    {day.dayNumber}
                  </div>
                );
              }

              if (isPast) {
                return (
                  <div
                    key={day.date}
                    style={{
                      ...baseStyle,
                      backgroundColor: "#e5e5e5",
                      color: "#9a9a9a",
                    }}
                  >
                    {day.dayNumber}
                  </div>
                );
              }

              if (!hasSlots) {
                return (
                  <div
                    key={day.date}
                    style={{
                      ...baseStyle,
                      backgroundColor: "#e5e5e5",
                      color: "#9a9a9a",
                    }}
                  >
                    {day.dayNumber}
                  </div>
                );
              }

              return (
                <Link
                  key={day.date}
                  href={`/specialists/${id}/services/${serviceId}/times?date=${day.date}`}
                  style={{
                    ...baseStyle,
                    textDecoration: "none",
                    backgroundColor: isSelected ? "#111" : "#ffffff",
                    color: isSelected ? "#ffffff" : "#111",
                    boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                  }}
                >
                  {day.dayNumber}
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </main>
  );
}