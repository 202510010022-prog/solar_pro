import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

// Restrict CORS to known domains (S2.1)
const allowedOrigins = [
  "https://solarpro.app",
  "https://admin.solarpro.app",
  "http://localhost:3000",
  "http://localhost:8081",
];

function getCorsHeaders(origin?: string): Record<string, string> {
  const corsOrigin = origin && allowedOrigins.includes(origin) ? origin : "null";
  return {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

const allowedCreatorPermissions = new Set(["diretor", "admin", "owner"]);
const allowedNewPermissions = new Set([
  "assessor_projetos",
  "assessor_daf",
  "diretor",
]);

type InvitePayload = {
  action?: string;
  id?: string;
  name?: string;
  email?: string;
  matricula?: string;
  role?: string;
  permission?: string;
  password?: string;
  active?: boolean;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return jsonResponse({ ok: true });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido." }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return jsonResponse(
        { error: "Variaveis de ambiente do Supabase ausentes." },
        500,
      );
    }

    const token = bearerToken(request);
    if (!token) {
      return jsonResponse({ error: "Token de acesso ausente." }, 401);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const { data: authData, error: authError } =
      await adminClient.auth.getUser(token);
    if (authError || !authData.user) {
      return jsonResponse({ error: "Sessao invalida ou expirada." }, 401);
    }

    const callerId = authData.user.id;
    const { data: callerProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("id, company_id, name, permission, active")
      .eq("id", callerId)
      .single();

    if (profileError || !callerProfile?.active) {
      return jsonResponse({ error: "Perfil do solicitante nao encontrado." }, 403);
    }

    if (!allowedCreatorPermissions.has(`${callerProfile.permission}`)) {
      return jsonResponse(
        { error: "Somente diretor ou admin pode convidar usuarios." },
        403,
      );
    }

    const companyAccessError = await validateCompanyWriteAccess(
      adminClient,
      callerProfile.company_id,
    );
    if (companyAccessError) return companyAccessError;

    const payload = (await request.json().catch(() => ({}))) as InvitePayload;
    const action = `${payload.action || "create_user"}`.trim();
    if (action === "update_user") {
      return await updateTeamUser(adminClient, callerProfile, payload, callerId);
    }
    if (action === "delete_user") {
      return await deleteTeamUser(adminClient, callerProfile, payload, callerId);
    }
    if (action !== "create_user") {
      return jsonResponse({ error: "Acao de equipe invalida." }, 400);
    }

    const normalized = normalizePayload(payload);
    const validationError = validatePayload(normalized);
    if (validationError) {
      return jsonResponse({ error: validationError }, 400);
    }

    const permission = normalized.permission;
    if (!allowedNewPermissions.has(permission)) {
      return jsonResponse({ error: "Permissao do novo usuario invalida." }, 400);
    }

    const limitError = await validateUserLimit(
      adminClient,
      callerProfile.company_id,
    );
    if (limitError) {
      return jsonResponse({ error: limitError }, 403);
    }

    const password = normalized.password || temporaryPassword();
    const { data: created, error: createError } =
      await adminClient.auth.admin.createUser({
        email: normalized.email,
        password,
        email_confirm: true,
        user_metadata: {
          name: normalized.name,
          matricula: normalized.matricula,
          role: normalized.role,
          permission,
        },
      });

    if (createError || !created.user) {
      return jsonResponse(
        { error: friendlyAuthError(createError?.message) },
        createError?.message?.toLowerCase().includes("already") ? 409 : 400,
      );
    }

    const { error: insertProfileError } = await adminClient.from("profiles").insert({
      id: created.user.id,
      company_id: callerProfile.company_id,
      name: normalized.name,
      matricula: normalized.matricula,
      email: normalized.email,
      role: normalized.role,
      permission,
      active: true,
    });

    if (insertProfileError) {
      await adminClient.auth.admin.deleteUser(created.user.id);
      return jsonResponse(
        { error: friendlyProfileError(insertProfileError.message) },
        409,
      );
    }

    return jsonResponse(
      {
        ok: true,
        user: {
          id: created.user.id,
          email: normalized.email,
          name: normalized.name,
          matricula: normalized.matricula,
          role: normalized.role,
          permission,
        },
        temporary_password: payload.password ? null : password,
        message: payload.password
          ? "Usuario criado com a senha informada."
          : "Usuario criado com senha temporaria.",
      },
      201,
    );
  } catch (error) {
    return jsonResponse(
      { error: "Nao foi possivel processar o convite." },
      500,
    );
  }
});

function bearerToken(request: Request) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? "";
}

async function validateCompanyWriteAccess(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
) {
  const { data: company, error } = await adminClient
    .from("companies")
    .select("active, subscription_status, trial_ends_at")
    .eq("id", companyId)
    .single();

  if (error || !company) {
    return jsonResponse({ error: "Empresa nao encontrada." }, 403);
  }

  if (company.active !== true) {
    return jsonResponse({ error: "Empresa inativa. Regularize o plano para gerenciar equipe." }, 403);
  }

  const status = `${company.subscription_status || "blocked"}`;
  if (status === "active") return null;

  if (status === "trial") {
    const trialEndsAt = `${company.trial_ends_at || ""}`;
    if (!trialEndsAt || new Date(trialEndsAt).getTime() >= Date.now()) {
      return null;
    }
  }

  return jsonResponse({ error: "Empresa bloqueada. Regularize o plano para gerenciar equipe." }, 403);
}

async function updateTeamUser(
  adminClient: ReturnType<typeof createClient>,
  callerProfile: {
    id: string;
    company_id: string;
    name: string;
    permission: string;
    active: boolean;
  },
  payload: InvitePayload,
  callerId: string,
) {
  const userId = `${payload.id || ""}`.trim();
  if (!userId) return jsonResponse({ error: "Usuario invalido." }, 400);

  const { data: target, error: targetError } = await adminClient
    .from("profiles")
    .select("id, company_id, permission, email")
    .eq("id", userId)
    .eq("company_id", callerProfile.company_id)
    .single();

  if (targetError || !target) {
    return jsonResponse({ error: "Usuario nao encontrado nesta empresa." }, 404);
  }

  const normalized = normalizePayload(payload);
  const validationError = validatePayload(normalized, false);
  if (validationError) return jsonResponse({ error: validationError }, 400);

  if (!allowedNewPermissions.has(normalized.permission)) {
    return jsonResponse({ error: "Permissao do usuario invalida." }, 400);
  }

  if (target.permission === "owner" && callerId !== userId) {
    return jsonResponse({ error: "O master da empresa nao pode ser alterado por outro usuario." }, 403);
  }

  const authUpdate: Record<string, unknown> = {
    user_metadata: {
      name: normalized.name,
      matricula: normalized.matricula,
      role: normalized.role,
      permission: normalized.permission,
    },
  };
  if (`${target.email || ""}`.toLowerCase() !== normalized.email) {
    authUpdate.email = normalized.email;
  }
  if (normalized.password) authUpdate.password = normalized.password;

  const { error: authError } = await adminClient.auth.admin.updateUserById(
    userId,
    authUpdate,
  );
  if (authError) {
    return jsonResponse({ error: friendlyAuthError(authError.message) }, 400);
  }

  const { data, error } = await adminClient
    .from("profiles")
    .update({
      name: normalized.name,
      email: normalized.email,
      matricula: normalized.matricula,
      role: normalized.role,
      permission: normalized.permission,
      active: payload.active !== false,
    })
    .eq("id", userId)
    .eq("company_id", callerProfile.company_id)
    .select()
    .single();

  if (error || !data) {
    return jsonResponse({ error: friendlyProfileError(error?.message) }, 409);
  }

  return jsonResponse({ ok: true, user: data, message: "Usuario atualizado." });
}

async function deleteTeamUser(
  adminClient: ReturnType<typeof createClient>,
  callerProfile: {
    id: string;
    company_id: string;
    name: string;
    permission: string;
    active: boolean;
  },
  payload: InvitePayload,
  callerId: string,
) {
  const userId = `${payload.id || ""}`.trim();
  if (!userId) return jsonResponse({ error: "Usuario invalido." }, 400);
  if (userId === callerId) {
    return jsonResponse({ error: "Voce nao pode excluir seu proprio acesso." }, 400);
  }

  const { data: target, error: targetError } = await adminClient
    .from("profiles")
    .select("id, company_id, permission")
    .eq("id", userId)
    .eq("company_id", callerProfile.company_id)
    .single();

  if (targetError || !target) {
    return jsonResponse({ error: "Usuario nao encontrado nesta empresa." }, 404);
  }
  if (target.permission === "owner") {
    return jsonResponse({ error: "O master da empresa nao pode ser excluido pelo app." }, 403);
  }

  const { error } = await adminClient.auth.admin.deleteUser(userId);
  if (error) return jsonResponse({ error: friendlyAuthError(error.message) }, 400);

  return jsonResponse({ ok: true, message: "Usuario excluido." });
}

function normalizePayload(payload: InvitePayload) {
  const permission = `${payload.permission || "assessor_projetos"}`
    .trim()
    .toLowerCase();
  return {
    name: `${payload.name || ""}`.trim(),
    email: `${payload.email || ""}`.trim().toLowerCase(),
    matricula: `${payload.matricula || ""}`.trim(),
    role: `${payload.role || defaultRole(permission)}`.trim(),
    permission,
    password: `${payload.password || ""}`.trim(),
  };
}

function validatePayload(
  payload: ReturnType<typeof normalizePayload>,
  requirePassword = false,
) {
  if (payload.name.length < 3) return "Informe o nome completo.";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(payload.email)) {
    return "Informe um e-mail valido.";
  }
  if (payload.matricula.length < 3) {
    return "Informe uma matricula ou identificador valido.";
  }
  if (payload.role.length < 3) return "Informe um cargo valido.";
  if (requirePassword && payload.password.length < 8) {
    return "A senha deve ter pelo menos 8 caracteres.";
  }
  if (payload.password && payload.password.length < 8) {
    return "A senha deve ter pelo menos 8 caracteres.";
  }
  return "";
}

async function validateUserLimit(
  adminClient: ReturnType<typeof createClient>,
  companyId: string,
) {
  const { data: billing } = await adminClient
    .from("company_billing_overview")
    .select("max_users, plan_name")
    .eq("company_id", companyId)
    .single();

  const maxUsers = billing?.max_users as number | null | undefined;
  if (maxUsers === null || maxUsers === undefined) return "";

  const { count, error } = await adminClient
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .eq("company_id", companyId)
    .eq("active", true);

  if (error) return "Nao foi possivel validar limite de usuarios.";
  if ((count ?? 0) >= maxUsers) {
    return `Limite de usuarios do plano ${billing?.plan_name ?? ""} atingido.`;
  }
  return "";
}

function temporaryPassword() {
  const bytes = crypto.getRandomValues(new Uint8Array(9));
  const token = btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "A")
    .replaceAll("/", "z")
    .replaceAll("=", "");
  return `SolarPro@${token.slice(0, 10)}`;
}

function defaultRole(permission: string) {
  return switchPermission(permission, {
    assessor_projetos: "Assessor de Projetos",
    assessor_daf: "Assessor DAF",
    diretor: "Diretor",
  });
}

function switchPermission(permission: string, labels: Record<string, string>) {
  return labels[permission] ?? "Assessor de Projetos";
}

function friendlyAuthError(message = "") {
  const normalized = message.toLowerCase();
  if (normalized.includes("already")) return "Este e-mail ja esta cadastrado.";
  if (normalized.includes("password")) return "Senha invalida ou fraca.";
  return message || "Nao foi possivel criar o usuario no Auth.";
}

function friendlyProfileError(message = "") {
  const normalized = message.toLowerCase();
  if (normalized.includes("profiles_company_id_matricula_key")) {
    return "Esta matricula ja existe na empresa.";
  }
  return message || "Nao foi possivel criar o perfil do usuario.";
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}
