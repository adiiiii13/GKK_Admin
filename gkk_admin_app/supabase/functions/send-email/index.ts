import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Base64 encode for SMTP AUTH
function base64Encode(str: string): string {
  return btoa(str);
}

// Read response lines from SMTP server
async function readResponse(reader: ReadableStreamDefaultReader<Uint8Array>): Promise<string> {
  const { value } = await reader.read();
  if (!value) return "";
  return new TextDecoder().decode(value);
}

// Send a command to SMTP server
async function sendCommand(writer: WritableStreamDefaultWriter<Uint8Array>, command: string): Promise<void> {
  await writer.write(new TextEncoder().encode(command + "\r\n"));
}

async function sendEmailViaSMTP(to: string, subject: string, body: string): Promise<void> {
  const hostname = "smtp.gmail.com";
  const port = 465;
  const username = "gharkakhanasupport@gmail.com";
  const password = "tfkq jmwv dzoh rxrd";
  const from = "Ghar Ka Khana <gharkakhanasupport@gmail.com>";

  // Connect with TLS
  const conn = await Deno.connectTls({ hostname, port });

  const reader = conn.readable.getReader();
  const writer = conn.writable.getWriter();

  // Read greeting
  await readResponse(reader);

  // EHLO
  await sendCommand(writer, `EHLO localhost`);
  await readResponse(reader);

  // AUTH LOGIN
  await sendCommand(writer, `AUTH LOGIN`);
  await readResponse(reader);

  // Username
  await sendCommand(writer, base64Encode(username));
  await readResponse(reader);

  // Password
  await sendCommand(writer, base64Encode(password));
  await readResponse(reader);

  // MAIL FROM
  await sendCommand(writer, `MAIL FROM:<${username}>`);
  await readResponse(reader);

  // RCPT TO
  await sendCommand(writer, `RCPT TO:<${to}>`);
  await readResponse(reader);

  // DATA
  await sendCommand(writer, `DATA`);
  await readResponse(reader);

  // Email content
  const emailContent = [
    `From: ${from}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    `MIME-Version: 1.0`,
    `Content-Type: text/plain; charset=UTF-8`,
    ``,
    body,
    `.`,
  ].join("\r\n");

  await sendCommand(writer, emailContent);
  await readResponse(reader);

  // QUIT
  await sendCommand(writer, `QUIT`);

  try {
    reader.releaseLock();
    writer.releaseLock();
    conn.close();
  } catch (_) {
    // Connection may already be closed
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { to, subject, body } = await req.json();

    if (!to || !subject || !body) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: to, subject, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await sendEmailViaSMTP(to, subject, body);

    return new Response(
      JSON.stringify({ success: true, message: `Email sent to ${to}` }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Email error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
