import { useEffect } from 'react';
import { Linking } from 'react-native';
import { useRouter } from 'expo-router';

function parseInvoiceUrl(url: string): Record<string, string> | null {
  if (!url.startsWith('beatbill://invoice')) return null;
  try {
    const normalized = url.replace('beatbill://', 'https://beatbill.app/');
    const parsed = new URL(normalized);
    const data: Record<string, string> = {};
    parsed.searchParams.forEach((value, key) => {
      data[key] = value;
    });
    return data;
  } catch {
    return null;
  }
}

export function useBeatDealInvoiceLink() {
  const router = useRouter();

  useEffect(() => {
    const open = (url: string | null) => {
      if (!url) return;
      const params = parseInvoiceUrl(url);
      if (!params) return;

      const amount = params.amount ? parseInt(params.amount, 10) : 0;
      const licenseLabel = params.license?.trim() || 'Licence beat';
      const dealRef = params.dealRef?.trim() ?? '';
      const noteParts = [params.note?.trim(), dealRef ? `Réf. deal : ${dealRef}` : ''].filter(Boolean);
      const items =
        amount > 0
          ? [{ description: licenseLabel, qty: 1, unitPrice: amount, total: amount }]
          : [{ description: licenseLabel, qty: 1, unitPrice: 0, total: 0 }];

      const clientName = params.client ?? '';
      const clientEmail = params.email ?? '';
      const readyForStep2 = Boolean(clientName && clientEmail && amount > 0);

      router.push({
        pathname: '/new-invoice',
        params: {
          import: JSON.stringify({
            clientName,
            clientEmail,
            project: params.project ?? '',
            items,
            notes: noteParts.join('\n'),
            beatDealImport: true,
            startStep: readyForStep2 ? 2 : 1,
          }),
        },
      });
    };

    Linking.getInitialURL().then(open);
    const sub = Linking.addEventListener('url', ({ url }) => open(url));
    return () => sub.remove();
  }, [router]);
}
