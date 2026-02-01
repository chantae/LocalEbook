const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.verifyNaverToken = functions.https.onCall(async (data) => {
  const accessToken = data && data.accessToken;
  if (!accessToken) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '네이버 액세스 토큰이 필요합니다.'
    );
  }

  try {
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
    return { firebaseToken: customToken };
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '네이버 토큰 검증에 실패했습니다.'
    );
  }
});
