import type { ProducerProfile } from '@/types';

export function buildLegalFooter(profile: ProducerProfile): string {
  const lines: string[] = [];

  if (profile.legalStatus === 'auto_entrepreneur' || profile.legalStatus === 'micro_entreprise') {
    lines.push('TVA non applicable, art. 293 B du CGI.');
  } else if (profile.vatNumber) {
    lines.push(`N° TVA intracommunautaire : ${profile.vatNumber}`);
  }

  if (profile.latePenaltyEnabled) {
    lines.push(
      'En cas de retard de paiement, seront exigibles une pénalité de retard au taux légal en vigueur et une indemnité forfaitaire de 40 € pour frais de recouvrement (art. L441-10 et D441-5 du Code de commerce).'
    );
  } else if (profile.recoveryIndemnityEnabled) {
    lines.push(
      'Indemnité forfaitaire de 40 € pour frais de recouvrement due en cas de retard de paiement (art. D441-5 du Code de commerce).'
    );
  }

  lines.push('Escompte pour paiement anticipé : néant.');
  lines.push('Conditions de règlement : paiement à réception de facture, sauf accord contraire.');

  if (profile.customLegalFooter?.trim()) {
    lines.push(profile.customLegalFooter.trim());
  }

  return lines.join('\n');
}
