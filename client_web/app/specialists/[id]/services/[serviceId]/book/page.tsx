"use client";

import { useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";

type FormErrors = {
  name?: string;
  email?: string;
  phone?: string;
  general?: string;
};

function validateName(value: string) {
  const trimmed = value.trim();

  if (!trimmed) {
    return "Įveskite vardą";
  }

  if (trimmed.length < 2) {
    return "Vardas per trumpas";
  }

  const nameRegex = /^[A-Za-zÀ-ž\s'-]+$/;

  if (!nameRegex.test(trimmed)) {
    return "Varde gali būti tik raidės";
  }

  return "";
}

function validateEmail(value: string) {
  const trimmed = value.trim();

  if (!trimmed) {
    return "Įveskite el. paštą";
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(trimmed)) {
    return "Netinkamas el. pašto formatas";
  }

  return "";
}

function validatePhone(value: string) {
  const trimmed = value.trim();

  if (!trimmed) {
    return "";
  }

  const phoneRegex = /^\+?[0-9\s()-]{7,20}$/;

  if (!phoneRegex.test(trimmed)) {
    return "Netinkamas telefono numeris";
  }

  return "";
}

function formatDateLabel(dateString: string | null) {
  if (!dateString) return "-";

  const [year, month, day] = dateString.split("-");
  if (!year || !month || !day) return dateString;

  return `${day}.${month}.${year}`;
}

export default function BookingPage({
  params,
}: {
  params: { id: string; serviceId: string };
}) {
  const searchParams = useSearchParams();

  const date = searchParams.get("date");
  const start = searchParams.get("start");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [notes, setNotes] = useState("");

  const [errors, setErrors] = useState<FormErrors>({});
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const formattedDate = useMemo(() => formatDateLabel(date), [date]);
  const formattedTime = useMemo(() => start?.slice(0, 5) ?? "-", [start]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    const nextErrors: FormErrors = {
      name: validateName(name),
      email: validateEmail(email),
      phone: validatePhone(phone),
      general: "",
    };

    setErrors(nextErrors);

    const hasErrors = Object.values(nextErrors).some((value) => value);

    if (hasErrors) {
      return;
    }

    if (!date || !start) {
      setErrors({
        general: "Trūksta rezervacijos datos arba laiko.",
      });
      return;
    }

    setLoading(true);

    try {
      const appointmentStart = `${date}T${start}`;

      const res = await fetch("http://localhost:8000/public/book", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          business_id: 1,
          specialist_id: Number(params.id),
          service_id: Number(params.serviceId),
          client_full_name: name.trim(),
          client_email: email.trim(),
          client_phone: phone.trim(),
          notes: notes.trim(),
          appointment_start: appointmentStart,
        }),
      });

      if (res.ok) {
        setSuccess(true);
        return;
      }

      let message = "Nepavyko sukurti rezervacijos.";
      try {
        const data = await res.json();
        if (data?.detail) {
          message =
            typeof data.detail === "string"
              ? data.detail
              : "Nepavyko sukurti rezervacijos.";
        }
      } catch {
        // ignore json parse failure
      }

      setErrors({ general: message });
    } catch {
      setErrors({
        general: "Nepavyko susisiekti su serveriu. Bandykite dar kartą.",
      });
    } finally {
      setLoading(false);
    }
  }

  if (success) {
    return (
      <main style={pageStyle}>
        <div style={containerStyle}>
          <div style={successCardStyle}>
            <div style={successBadgeStyle}>✓</div>

            <h2 style={successTitleStyle}>Rezervacija sėkminga!</h2>

            <p style={successTextStyle}>
              Jūsų vizitas užregistruotas.
            </p>

            <div style={summaryCardStyle}>
              <div style={summaryRowStyle}>
                <span style={summaryLabelStyle}>Data</span>
                <span style={summaryValueStyle}>{formattedDate}</span>
              </div>

              <div style={summaryRowStyle}>
                <span style={summaryLabelStyle}>Laikas</span>
                <span style={summaryValueStyle}>{formattedTime}</span>
              </div>

              <div style={summaryRowStyle}>
                <span style={summaryLabelStyle}>Vardas</span>
                <span style={summaryValueStyle}>{name.trim()}</span>
              </div>

              <div style={summaryRowStyle}>
                <span style={summaryLabelStyle}>El. paštas</span>
                <span style={summaryValueStyle}>{email.trim()}</span>
              </div>
            </div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main style={pageStyle}>
      <div style={containerStyle}>
        <h1 style={titleStyle}>Rezervacija</h1>

        <p style={subtitleStyle}>
          Užpildykite formą ir patvirtinkite pasirinktą laiką.
        </p>

        <div style={bookingInfoCardStyle}>
          <div style={bookingInfoRowStyle}>
            <span style={bookingInfoLabelStyle}>Data</span>
            <span style={bookingInfoValueStyle}>{formattedDate}</span>
          </div>

          <div style={bookingInfoRowStyle}>
            <span style={bookingInfoLabelStyle}>Laikas</span>
            <span style={bookingInfoValueStyle}>{formattedTime}</span>
          </div>
        </div>

        <form onSubmit={handleSubmit} style={formCardStyle} noValidate>
          {errors.general ? (
            <div style={generalErrorBoxStyle}>{errors.general}</div>
          ) : null}

          <div style={fieldBlockStyle}>
            <label htmlFor="name" style={labelStyle}>
              Vardas *
            </label>
            <input
              id="name"
              name="name"
              placeholder="Įveskite vardą"
              required
              autoComplete="given-name"
              inputMode="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={inputStyle}
            />
            {errors.name ? <p style={errorStyle}>{errors.name}</p> : null}
          </div>

          <div style={fieldBlockStyle}>
            <label htmlFor="email" style={labelStyle}>
              El. paštas *
            </label>
            <input
              id="email"
              name="email"
              type="email"
              placeholder="pvz. vardas@email.com"
              required
              autoComplete="email"
              inputMode="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={inputStyle}
            />
            {errors.email ? <p style={errorStyle}>{errors.email}</p> : null}
          </div>

          <div style={fieldBlockStyle}>
            <label htmlFor="phone" style={labelStyle}>
              Telefono nr.
            </label>
            <input
              id="phone"
              name="phone"
              type="tel"
              placeholder="pvz. +37060000000"
              autoComplete="tel"
              inputMode="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              style={inputStyle}
            />
            {errors.phone ? <p style={errorStyle}>{errors.phone}</p> : null}
          </div>

          <div style={fieldBlockStyle}>
            <label htmlFor="notes" style={labelStyle}>
              Pastabos
            </label>
            <textarea
              id="notes"
              name="notes"
              placeholder="Papildoma informacija"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              style={textareaStyle}
            />
          </div>

          <button type="submit" style={buttonStyle} disabled={loading}>
            {loading ? "Siunčiama..." : "Rezervuoti"}
          </button>
        </form>
      </div>
    </main>
  );
}

const pageStyle: React.CSSProperties = {
  minHeight: "100vh",
  backgroundColor: "#f5f5f5",
  padding: "16px",
  fontFamily: "Arial, sans-serif",
};

const containerStyle: React.CSSProperties = {
  maxWidth: "480px",
  margin: "0 auto",
};

const titleStyle: React.CSSProperties = {
  marginTop: 0,
  marginBottom: "8px",
  fontSize: "28px",
  color: "#111111",
};

const subtitleStyle: React.CSSProperties = {
  marginTop: 0,
  marginBottom: "16px",
  color: "#555555",
  lineHeight: 1.5,
  fontSize: "15px",
};

const bookingInfoCardStyle: React.CSSProperties = {
  backgroundColor: "#ffffff",
  borderRadius: "14px",
  padding: "16px",
  boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
  marginBottom: "16px",
};

const bookingInfoRowStyle: React.CSSProperties = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  gap: "12px",
};

const bookingInfoLabelStyle: React.CSSProperties = {
  color: "#555555",
  fontSize: "14px",
  fontWeight: 600,
};

const bookingInfoValueStyle: React.CSSProperties = {
  color: "#111111",
  fontSize: "16px",
  fontWeight: 700,
};

const formCardStyle: React.CSSProperties = {
  backgroundColor: "#ffffff",
  borderRadius: "14px",
  padding: "16px",
  boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
};

const fieldBlockStyle: React.CSSProperties = {
  marginBottom: "14px",
};

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: "14px",
  fontWeight: 600,
  marginBottom: "6px",
  color: "#111111",
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  minHeight: "48px",
  padding: "12px 14px",
  borderRadius: "10px",
  border: "1px solid #d9d9d9",
  fontSize: "16px",
  boxSizing: "border-box",
  color: "#111111",
  backgroundColor: "#ffffff",
  outline: "none",
  WebkitAppearance: "none",
};

const textareaStyle: React.CSSProperties = {
  ...inputStyle,
  minHeight: "96px",
  resize: "vertical",
};

const buttonStyle: React.CSSProperties = {
  width: "100%",
  minHeight: "52px",
  padding: "14px",
  borderRadius: "12px",
  border: "none",
  backgroundColor: "#111111",
  color: "#ffffff",
  fontSize: "16px",
  fontWeight: 700,
  marginTop: "6px",
  cursor: "pointer",
};

const errorStyle: React.CSSProperties = {
  color: "#c62828",
  fontSize: "13px",
  marginTop: "6px",
  marginBottom: 0,
  fontWeight: 500,
};

const generalErrorBoxStyle: React.CSSProperties = {
  backgroundColor: "#fdecea",
  color: "#b71c1c",
  borderRadius: "10px",
  padding: "12px",
  marginBottom: "14px",
  fontSize: "14px",
  fontWeight: 600,
};

const successCardStyle: React.CSSProperties = {
  backgroundColor: "#ffffff",
  borderRadius: "16px",
  padding: "24px",
  boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
  textAlign: "center",
};

const successBadgeStyle: React.CSSProperties = {
  width: "56px",
  height: "56px",
  borderRadius: "999px",
  backgroundColor: "#111111",
  color: "#ffffff",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  fontSize: "28px",
  fontWeight: 700,
  margin: "0 auto 16px auto",
};

const successTitleStyle: React.CSSProperties = {
  marginTop: 0,
  marginBottom: "8px",
  color: "#111111",
};

const successTextStyle: React.CSSProperties = {
  marginTop: 0,
  marginBottom: "20px",
  color: "#555555",
};

const summaryCardStyle: React.CSSProperties = {
  textAlign: "left",
  backgroundColor: "#f8f8f8",
  borderRadius: "12px",
  padding: "14px",
};

const summaryRowStyle: React.CSSProperties = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "flex-start",
  gap: "12px",
  marginBottom: "10px",
};

const summaryLabelStyle: React.CSSProperties = {
  color: "#555555",
  fontSize: "14px",
  fontWeight: 600,
};

const summaryValueStyle: React.CSSProperties = {
  color: "#111111",
  fontSize: "14px",
  fontWeight: 700,
  textAlign: "right",
};