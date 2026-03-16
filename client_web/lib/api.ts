export const API_BASE_URL = "http://localhost:8000"

export async function fetchAPI(path: string) {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    cache: "no-store"
  })

  if (!res.ok) {
    const text = await res.text()
    console.error("API error:", text)
    throw new Error("API request failed")
  }

  return res.json()
}