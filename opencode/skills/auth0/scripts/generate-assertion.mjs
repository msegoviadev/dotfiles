import crypto from 'crypto';
import fs from 'fs';

const { PRIVATE_KEY_PATH, AUTH0_KID, AUTH0_CLIENT_ID, AUDIENCE } = process.env;

const b64u = (s) => Buffer.from(s).toString('base64url');

const header = b64u(JSON.stringify({ alg: 'RS256', kid: AUTH0_KID }));
const now = Math.floor(Date.now() / 1000);
const payload = b64u(JSON.stringify({
  iss: AUTH0_CLIENT_ID,
  sub: AUTH0_CLIENT_ID,
  aud: AUDIENCE,
  iat: now,
  exp: now + 60,
  jti: crypto.randomUUID(),
}));

const signingInput = `${header}.${payload}`;
const key = crypto.createPrivateKey(fs.readFileSync(PRIVATE_KEY_PATH, 'utf8'));
const sig = crypto.sign('sha256', Buffer.from(signingInput), {
  key,
  padding: crypto.constants.RSA_PKCS1_PADDING,
});

console.log(`${signingInput}.${sig.toString('base64url')}`);
