// Fivebyte branding for this fork's dashboard (wa.fivebyte.cloud). The copy lives here rather than in the
// locale catalogues so that merging an upstream OpenWA release never conflicts with fork-only strings.
// Product names (Fivebyte, WhatsApp Gateway) are not translated.
import type { SupportedLanguage } from './i18n';

export const BRAND = {
  name: 'Fivebyte',
  product: 'WhatsApp Gateway',
  logo: '/fivebyte-logo.png',
  upstreamUrl: 'https://github.com/rmyndharis/OpenWA',
} as const;

export interface BrandCopy {
  /** The sign-in heading on the form side. */
  title: string;
  subtitle: string;
  /** The brand panel's one-line pitch. */
  headline: string;
  points: [string, string, string];
  poweredBy: string;
}

export const BRAND_COPY: Record<SupportedLanguage, BrandCopy> = {
  en: {
    title: 'Sign in to your dashboard',
    subtitle: 'Use the API key your Fivebyte admin gave you.',
    headline: 'Connect your apps to WhatsApp, from your own server.',
    points: [
      'Messages go out from your own WhatsApp number',
      'Delivery and read receipts arrive by webhook',
      'Every app gets its own scoped API key',
    ],
    poweredBy: 'Powered by OpenWA',
  },
  id: {
    title: 'Masuk ke dashboard',
    subtitle: 'Gunakan kunci API dari admin Fivebyte Anda.',
    headline: 'Hubungkan aplikasi Anda ke WhatsApp, dari server sendiri.',
    points: [
      'Pesan terkirim dari nomor WhatsApp Anda sendiri',
      'Status terkirim dan dibaca dikabarkan lewat webhook',
      'Setiap aplikasi punya kunci API sendiri yang dibatasi',
    ],
    poweredBy: 'Didukung oleh OpenWA',
  },
  de: {
    title: 'Beim Dashboard anmelden',
    subtitle: 'Verwenden Sie den API-Schlüssel von Ihrem Fivebyte-Administrator.',
    headline: 'Verbinden Sie Ihre Apps mit WhatsApp – von Ihrem eigenen Server.',
    points: [
      'Nachrichten gehen von Ihrer eigenen WhatsApp-Nummer aus',
      'Zustell- und Lesebestätigungen kommen per Webhook',
      'Jede App erhält einen eigenen, eingeschränkten API-Schlüssel',
    ],
    poweredBy: 'Basiert auf OpenWA',
  },
  tr: {
    title: 'Panele giriş yapın',
    subtitle: 'Fivebyte yöneticinizin verdiği API anahtarını kullanın.',
    headline: 'Uygulamalarınızı kendi sunucunuzdan WhatsApp’a bağlayın.',
    points: [
      'Mesajlar kendi WhatsApp numaranızdan gönderilir',
      'İletildi ve okundu bilgileri webhook ile gelir',
      'Her uygulamanın kendine ait, kısıtlı bir API anahtarı olur',
    ],
    poweredBy: 'OpenWA altyapısıyla',
  },
  es: {
    title: 'Inicia sesión en tu panel',
    subtitle: 'Usa la clave API que te dio tu administrador de Fivebyte.',
    headline: 'Conecta tus aplicaciones a WhatsApp desde tu propio servidor.',
    points: [
      'Los mensajes salen desde tu propio número de WhatsApp',
      'Las confirmaciones de entrega y lectura llegan por webhook',
      'Cada aplicación tiene su propia clave API con permisos limitados',
    ],
    poweredBy: 'Con la tecnología de OpenWA',
  },
  he: {
    title: 'התחברות ללוח הבקרה',
    subtitle: 'השתמשו במפתח ה-API שקיבלתם ממנהל Fivebyte.',
    headline: 'חברו את האפליקציות שלכם ל-WhatsApp, מהשרת שלכם.',
    points: [
      'ההודעות נשלחות ממספר ה-WhatsApp שלכם',
      'אישורי מסירה וקריאה מגיעים ב-webhook',
      'לכל אפליקציה מפתח API משלה עם הרשאות מוגבלות',
    ],
    poweredBy: 'מבוסס על OpenWA',
  },
  'zh-CN': {
    title: '登录控制台',
    subtitle: '请使用 Fivebyte 管理员提供的 API 密钥。',
    headline: '在自己的服务器上，把你的应用接入 WhatsApp。',
    points: [
      '消息从你自己的 WhatsApp 号码发出',
      '送达和已读回执通过 webhook 推送',
      '每个应用都有独立且受限的 API 密钥',
    ],
    poweredBy: '由 OpenWA 提供支持',
  },
  'zh-HK': {
    title: '登入控制台',
    subtitle: '請使用 Fivebyte 管理員提供的 API 密鑰。',
    headline: '在自己的伺服器上，把你的應用程式接入 WhatsApp。',
    points: [
      '訊息從你自己的 WhatsApp 號碼發出',
      '送達及已讀回條透過 webhook 推送',
      '每個應用程式都有獨立且受限的 API 密鑰',
    ],
    poweredBy: '由 OpenWA 提供技術支援',
  },
  ar: {
    title: 'تسجيل الدخول إلى لوحة التحكم',
    subtitle: 'استخدم مفتاح API الذي زوّدك به مسؤول Fivebyte.',
    headline: 'اربط تطبيقاتك بواتساب من خادمك الخاص.',
    points: [
      'تُرسل الرسائل من رقم واتساب الخاص بك',
      'تصلك إشعارات التسليم والقراءة عبر webhook',
      'لكل تطبيق مفتاح API خاص به بصلاحيات محدودة',
    ],
    poweredBy: 'مدعوم بـ OpenWA',
  },
  te: {
    title: 'డాష్‌బోర్డ్‌కు సైన్ ఇన్ చేయండి',
    subtitle: 'మీ Fivebyte అడ్మిన్ ఇచ్చిన API కీని ఉపయోగించండి.',
    headline: 'మీ సొంత సర్వర్ నుండి మీ యాప్‌లను WhatsAppకు కనెక్ట్ చేయండి.',
    points: [
      'సందేశాలు మీ సొంత WhatsApp నంబర్ నుండి వెళ్తాయి',
      'డెలివరీ మరియు చదివిన రసీదులు webhook ద్వారా వస్తాయి',
      'ప్రతి యాప్‌కు పరిమిత అనుమతులతో దాని సొంత API కీ ఉంటుంది',
    ],
    poweredBy: 'OpenWA ఆధారంగా',
  },
  fr: {
    title: 'Connectez-vous au tableau de bord',
    subtitle: 'Utilisez la clé API fournie par votre administrateur Fivebyte.',
    headline: 'Connectez vos applications à WhatsApp, depuis votre propre serveur.',
    points: [
      'Les messages partent de votre propre numéro WhatsApp',
      'Les accusés de réception et de lecture arrivent par webhook',
      'Chaque application dispose de sa propre clé API restreinte',
    ],
    poweredBy: 'Propulsé par OpenWA',
  },
  it: {
    title: 'Accedi alla dashboard',
    subtitle: 'Usa la chiave API che ti ha fornito l’amministratore Fivebyte.',
    headline: 'Collega le tue app a WhatsApp, dal tuo server.',
    points: [
      'I messaggi partono dal tuo numero WhatsApp',
      'Le conferme di consegna e lettura arrivano tramite webhook',
      'Ogni app ha la propria chiave API con permessi limitati',
    ],
    poweredBy: 'Basato su OpenWA',
  },
  'pt-BR': {
    title: 'Entre no painel',
    subtitle: 'Use a chave de API fornecida pelo administrador da Fivebyte.',
    headline: 'Conecte seus aplicativos ao WhatsApp a partir do seu próprio servidor.',
    points: [
      'As mensagens saem do seu próprio número de WhatsApp',
      'As confirmações de entrega e leitura chegam por webhook',
      'Cada aplicativo tem a própria chave de API com permissões restritas',
    ],
    poweredBy: 'Desenvolvido com OpenWA',
  },
  ko: {
    title: '대시보드에 로그인',
    subtitle: 'Fivebyte 관리자에게 받은 API 키를 사용하세요.',
    headline: '내 서버에서 앱을 WhatsApp에 연결하세요.',
    points: [
      '메시지는 내 WhatsApp 번호로 발송됩니다',
      '전송 및 읽음 확인이 webhook으로 전달됩니다',
      '앱마다 권한이 제한된 전용 API 키를 사용합니다',
    ],
    poweredBy: 'OpenWA 기반',
  },
  hi: {
    title: 'डैशबोर्ड में साइन इन करें',
    subtitle: 'अपने Fivebyte एडमिन से मिली API कुंजी का उपयोग करें।',
    headline: 'अपने ही सर्वर से अपने ऐप्स को WhatsApp से जोड़ें।',
    points: [
      'संदेश आपके अपने WhatsApp नंबर से भेजे जाते हैं',
      'डिलीवरी और पढ़े जाने की सूचना webhook से मिलती है',
      'हर ऐप की अपनी सीमित अनुमतियों वाली API कुंजी होती है',
    ],
    poweredBy: 'OpenWA द्वारा संचालित',
  },
};

export function brandCopy(language: SupportedLanguage): BrandCopy {
  return BRAND_COPY[language] ?? BRAND_COPY.en;
}
