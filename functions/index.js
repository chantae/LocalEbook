const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

function getNaverConfig() {
  const cfg = functions.config().naver || {};
  return {
    clientId: cfg.client_id || process.env.NAVER_CLIENT_ID,
    clientSecret: cfg.client_secret || process.env.NAVER_CLIENT_SECRET,
  };
}

async function createFirebaseTokenFromAccessToken(accessToken) {
  const response = await axios.get('https://openapi.naver.com/v1/nid/me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const payload = response.data && response.data.response;
  const naverId = payload && payload.id;
  if (!naverId) {
    throw new Error('naver id not found');
  }
  const uid = `naver:${naverId}`;
  const customToken = await admin.auth().createCustomToken(uid, {
    provider: 'naver',
    email: payload.email || '',
    name: payload.name || payload.nickname || '',
  });
  return customToken;
}

exports.verifyNaverToken = functions.https.onCall(async (data) => {
  const accessToken = data && data.accessToken;
  if (!accessToken) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '네이버 액세스 토큰이 필요합니다.'
    );
  }

  try {
    const customToken = await createFirebaseTokenFromAccessToken(accessToken);
    return { firebaseToken: customToken };
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '네이버 토큰 검증에 실패했습니다.'
    );
  }
});

exports.exchangeNaverCode = functions.https.onCall(async (data) => {
  const code = data && data.code;
  const state = data && data.state;
  const redirectUri = data && data.redirectUri;
  if (!code || !redirectUri) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '네이버 인증 코드와 redirectUri가 필요합니다.'
    );
  }
  const { clientId, clientSecret } = getNaverConfig();
  if (!clientId || !clientSecret) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      '네이버 클라이언트 정보가 설정되지 않았습니다.'
    );
  }

  try {
    const tokenResponse = await axios.get(
      'https://nid.naver.com/oauth2.0/token',
      {
        params: {
          grant_type: 'authorization_code',
          client_id: clientId,
          client_secret: clientSecret,
          code,
          state,
          redirect_uri: redirectUri,
        },
      }
    );
    const accessToken = tokenResponse.data && tokenResponse.data.access_token;
    if (!accessToken) {
      throw new Error('naver access token not found');
    }
    const customToken = await createFirebaseTokenFromAccessToken(accessToken);
    return { firebaseToken: customToken };
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '네이버 코드 교환에 실패했습니다.'
    );
  }
});
