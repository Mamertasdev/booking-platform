import Link from "next/link";
import { fetchAPI } from "@/lib/api";

type Specialist = {
  id: number;
  full_name: string;
};

export default async function HomePage() {
  const specialists: Specialist[] = await fetchAPI("/public/specialists");

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
            fontSize: "28px",
            marginBottom: "8px",
          }}
        >
          Pasirinkite specialistą
        </h1>

        <p
          style={{
            color: "#555",
            marginBottom: "24px",
            lineHeight: 1.5,
          }}
        >
          Pasirinkite, pas kurį specialistą norite registruotis.
        </p>

        {specialists.length === 0 ? (
          <p>Specialistų kol kas nėra.</p>
        ) : (
          <div style={{ display: "grid", gap: "12px" }}>
            {specialists.map((specialist) => (
              <Link
                key={specialist.id}
                href={`/specialists/${specialist.id}`}
                style={{
                  display: "block",
                  padding: "16px",
                  backgroundColor: "#ffffff",
                  borderRadius: "12px",
                  textDecoration: "none",
                  color: "#111",
                  boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
                  fontSize: "18px",
                  fontWeight: 600,
                }}
              >
                {specialist.full_name}
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}