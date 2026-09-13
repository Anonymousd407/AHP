const secure = process.env.NEXTAUTH_URL?.startsWith('https://') ?? false;
const prefix = secure ? '__Secure-' : '';
const hostPrefix = secure ? '__Host-' : '';

export const sessionCookieName = `${prefix}a-health-admin.session-token`;

export const authCookies = {
  sessionToken: {
    name: sessionCookieName,
    options: { httpOnly: true, sameSite: 'lax' as const, path: '/', secure },
  },
  callbackUrl: {
    name: `${prefix}a-health-admin.callback-url`,
    options: { httpOnly: true, sameSite: 'lax' as const, path: '/', secure },
  },
  csrfToken: {
    name: `${hostPrefix}a-health-admin.csrf-token`,
    options: { httpOnly: true, sameSite: 'lax' as const, path: '/', secure },
  },
};
