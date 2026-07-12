import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();

const providerKey = defineSecret("AI_PROVIDER_KEY");
const providerUrl = process.env.AI_PROVIDER_URL ?? "";
const providerModel = process.env.AI_PROVIDER_MODEL ?? "";

export const analyzeCv = onCall({secrets: [providerKey]}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const text = String(request.data?.text ?? "").trim();
  if (text.length < 80) {
    throw new HttpsError("invalid-argument", "CV text is too short.");
  }
  if (!providerUrl || !providerModel) {
    throw new HttpsError("failed-precondition", "AI provider is not configured.");
  }

  const response = await fetch(providerUrl, {
    method: "POST",
    headers: {
      "authorization": `Bearer ${providerKey.value()}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: providerModel,
      messages: [{
        role: "user",
        content: `Return JSON with skills, strengths and suggestedRoles for this CV:\n${text}`,
      }],
      response_format: {type: "json_object"},
    }),
  });
  if (!response.ok) throw new HttpsError("internal", "AI analysis failed.");
  const payload = await response.json() as Record<string, unknown>;
  const content = ((payload.choices as Array<Record<string, unknown>>)?.[0]
    ?.message as Record<string, unknown>)?.content;
  const analysis = JSON.parse(String(content ?? "{}"));

  await getFirestore().collection("users").doc(request.auth.uid).set({
    cvAnalysis: analysis,
    cvAnalyzedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return analysis;
});
