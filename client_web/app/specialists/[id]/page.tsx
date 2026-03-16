import Link from "next/link";
import { fetchAPI } from "@/lib/api";

type Service = {
  id: number;
  name: string;
  duration_minutes: number;
  price: number;
};

export default async function SpecialistPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const businessId = 1;

  const services: Service[] = await fetchAPI(
    `/public/services?business_id=${businessId}`
  );

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
            marginBottom: "16px",
          }}
        >
          Pasirinkite paslaugą
        </h1>

        <div style={{ display: "grid", gap: "12px" }}>
          {services.map((service) => (
            <Link
              key={service.id}
              href={`/specialists/${id}/services/${service.id}`}
              style={{
                display: "block",
                padding: "16px",
                backgroundColor: "#ffffff",
                borderRadius: "12px",
                textDecoration: "none",
                color: "#111",
                boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
              }}
            >
              <div style={{ fontWeight: 600, fontSize: "18px" }}>
                {service.name}
              </div>

              <div
                style={{
                  marginTop: "6px",
                  color: "#555",
                  fontSize: "14px",
                }}
              >
                {service.duration_minutes} min • {service.price} €
              </div>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}