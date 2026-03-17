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

function parseDateParts(dateString: string) {
  const [year, month, day] = dateString.split("-").map(Number);
  return { year, month, day };
}

function formatDateLabel(dateString: string) {
  const { year, month, day } = parseDateParts(dateString);
  return `${day.toString().padStart(2, "0")}.${month
    .toString()
    .padStart(2, "0")}.${year}`;
}

function addDays(dateString: string, daysToAdd: number) {
  const { year, month, day } = parseDateParts(dateString);
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + daysToAdd);
  return date.toISOString().split("T")[0];
}

function getTodayString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export default async function ServiceTimesPage({
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

  const availability: AvailabilityResponse = await fetchAPI(
    `/public/availability?business_id=${businessId}&specialist_id=${id}&service_id=${serviceId}&target_date=${targetDate}`
  );

  const rawPreviousDate = addDays(targetDate, -1);
  const previousDate = rawPreviousDate < todayString ? todayString : rawPreviousDate;
  const nextDate = addDays(targetDate, 1);
  const canGoBack = targetDate > todayString;

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
          Pasirinkite laiką
        </h1>

        <div
          style={{
            backgroundColor: "#111",
            color: "#fff",
            borderRadius: "14px",
            padding: "16px",
            textAlign: "center",
            marginBottom: "16px",
            boxShadow: "0 1px 4px rgba(0,0,0,0.12)",
          }}
        >
          <div
            style={{
              fontSize: "13px",
              opacity: 0.8,
              marginBottom: "4px",
            }}
          >
            Pasirinkta diena
          </div>

          <div
            style={{
              fontSize: "22px",
              fontWeight: 700,
            }}
          >
            {formatDateLabel(targetDate)}
          </div>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr",
            gap: "8px",
            marginBottom: "12px",
          }}
        >
          <Link
            href={`/specialists/${id}/services/${serviceId}?date=${targetDate}`}
            style={{
              display: "block",
              padding: "12px",
              backgroundColor: "#ffffff",
              borderRadius: "12px",
              textDecoration: "none",
              color: "#111",
              textAlign: "center",
              boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
              fontWeight: 600,
            }}
          >
            Grįžti į kalendorių
          </Link>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: "8px",
            marginBottom: "20px",
          }}
        >
          {canGoBack ? (
            <Link
              href={`/specialists/${id}/services/${serviceId}/times?date=${previousDate}`}
              style={{
                display: "block",
                padding: "12px",
                backgroundColor: "#ffffff",
                borderRadius: "12px",
                textDecoration: "none",
                color: "#111",
                textAlign: "center",
                boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                fontWeight: 600,
              }}
            >
              ← Ankstesnė
            </Link>
          ) : (
            <div
              style={{
                display: "block",
                padding: "12px",
                backgroundColor: "#e5e5e5",
                borderRadius: "12px",
                color: "#9a9a9a",
                textAlign: "center",
                fontWeight: 600,
              }}
            >
              ← Ankstesnė
            </div>
          )}

          <Link
            href={`/specialists/${id}/services/${serviceId}/times?date=${nextDate}`}
            style={{
              display: "block",
              padding: "12px",
              backgroundColor: "#ffffff",
              borderRadius: "12px",
              textDecoration: "none",
              color: "#111",
              textAlign: "center",
              boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
              fontWeight: 600,
            }}
          >
            Kita →
          </Link>
        </div>

        {availability.slots.length === 0 ? (
          <div
            style={{
              backgroundColor: "#ffffff",
              borderRadius: "12px",
              padding: "16px",
              boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
            }}
          >
            Laisvų laikų šiai dienai nėra.
          </div>
        ) : (
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(2, 1fr)",
              gap: "12px",
            }}
          >
            {availability.slots.map((slot) => (
              <Link
                key={`${slot.start_time}-${slot.end_time}`}
                href={`/specialists/${id}/services/${serviceId}/book?date=${availability.target_date}&start=${slot.start_time}`}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  height: "64px",
                  backgroundColor: "#ffffff",
                  borderRadius: "12px",
                  textDecoration: "none",
                  color: "#111",
                  boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                  fontWeight: 600,
                  fontSize: "20px",
                }}
              >
                {slot.start_time.slice(0, 5)}
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}