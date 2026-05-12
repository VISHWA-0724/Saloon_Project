const asyncHandler = require('express-async-handler');

function clean(value) {
  return String(value || '').trim();
}

function title(value) {
  const text = clean(value).toLowerCase();
  return text ? text[0].toUpperCase() + text.slice(1) : '';
}

function localStyleAdvice({ prompt, age, gender, hairType, faceShape }) {
  const summary = [
    age ? `Age ${age}` : '',
    gender ? title(gender) : '',
    hairType ? `${title(hairType)} hair` : '',
    faceShape ? `${title(faceShape)} face` : '',
  ].filter(Boolean).join(' | ') || 'General recommendation';

  const lower = clean(prompt).toLowerCase();
  const feminine = ['female', 'woman', 'girl'].includes(clean(gender).toLowerCase()) ||
    /\b(female|woman|girl)\b/.test(lower);
  const curly = clean(hairType).toLowerCase() === 'curly' || /\bcurly\b/.test(lower);
  const round = clean(faceShape).toLowerCase() === 'round' || /\bround\b/.test(lower);

  const styles = feminine
    ? ['Long Layers', round ? 'Side Part' : 'Curtain Bangs', curly ? 'Soft Curl Shaping' : 'Glossy Blowout']
    : ['Low Fade', curly ? 'Curly Taper' : 'Textured Crop', round ? 'High-volume Quiff' : 'Side Part'];
  const services = curly
    ? ['Curl Definition Treatment', 'Hair Spa', 'Wash and Styling']
    : ['Haircut Consultation', 'Hair Spa', 'Texture Styling'];
  const grooming = feminine
    ? ['Face-framing finish', 'Hydration treatment']
    : ['Sharp Beard Line-up', 'Light Stubble', 'Short Boxed Beard'];

  return {
    text: [
      'Recommended for you:',
      ...styles.map((item) => `- ${item}`),
      '',
      feminine ? 'Styling add-ons:' : 'Beard and grooming:',
      ...grooming.map((item) => `- ${item}`),
      '',
      'Salon services:',
      ...services.map((item) => `- ${item}`),
      '',
      'Why this fits:',
      '- The recommendation balances face shape, hair texture, and daily maintenance.',
    ].join('\n'),
    detectedSummary: summary,
    source: 'local',
  };
}

function buildPrompt(body) {
  const prompt = clean(body?.prompt);
  const details = [
    body?.age ? `Age: ${body.age}` : '',
    body?.gender ? `Gender: ${body.gender}` : '',
    body?.hairType ? `Hair type: ${body.hairType}` : '',
    body?.faceShape ? `Face shape: ${body.faceShape}` : '',
  ].filter(Boolean).join('\n');

  return [
    details ? `Customer details:\n${details}` : '',
    prompt ? `Customer message:\n${prompt}` : '',
  ].filter(Boolean).join('\n\n');
}

async function askHuggingFace(body) {
  const token = clean(process.env.HF_TOKEN || process.env.HUGGINGFACE_API_TOKEN);
  if (!token) return null;

  const model = clean(process.env.HF_MODEL) || 'openai/gpt-oss-120b:cerebras';
  const baseUrl = clean(process.env.HF_BASE_URL) || 'https://router.huggingface.co/v1/chat/completions';
  const userPrompt = buildPrompt(body);

  const response = await fetch(baseUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: 'system',
          content:
            'You are a salon style advisor. Give concise haircut, beard or styling, and salon service recommendations. Use bullets and avoid medical claims.',
        },
        { role: 'user', content: userPrompt || 'Give a general salon style recommendation.' },
      ],
      max_tokens: 420,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Hugging Face request failed: ${response.status} ${message}`);
  }

  const data = await response.json();
  const text = clean(data?.choices?.[0]?.message?.content);
  if (!text) throw new Error('Hugging Face returned an empty response');
  return {
    text,
    detectedSummary: localStyleAdvice(body).detectedSummary,
    source: 'huggingface',
    model,
  };
}

const getStyleAdvice = asyncHandler(async (req, res) => {
  try {
    const liveAdvice = await askHuggingFace(req.body || {});
    if (liveAdvice) {
      res.json(liveAdvice);
      return;
    }
  } catch (error) {
    const fallback = localStyleAdvice(req.body || {});
    res.json({
      ...fallback,
      warning: error.message,
    });
    return;
  }

  res.json({
    ...localStyleAdvice(req.body || {}),
    warning: 'HF_TOKEN is not configured, so local style advice was used.',
  });
});

module.exports = { getStyleAdvice };
