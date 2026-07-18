import type { Split } from '@/types';

export function buildBeatDealSplitUrl(split: Split): string {
  const params = new URLSearchParams();
  params.set('ref', split.ref);
  params.set('title', split.title);
  if (split.artist?.trim()) {
    params.set('artist', split.artist.trim());
  }

  const coProducer = split.collaborators.find(
    (c) =>
      c.role.toLowerCase().includes('co-producteur') ||
      c.role.toLowerCase().includes('producteur')
  );
  const artistCollab = split.collaborators.find(
    (c) => c.role.toLowerCase().includes('artiste') || c.role.toLowerCase().includes('parolier')
  );

  const co = coProducer ?? (split.collaborators.length > 1 ? split.collaborators[1] : undefined);
  if (co && co.name.trim()) {
    params.set('coProducer', co.name.trim());
    params.set('coShare', String(co.masterShare));
  } else if (artistCollab && split.collaborators.length > 1) {
    const prod = split.collaborators[0];
    if (prod && prod.name !== artistCollab.name) {
      params.set('coProducer', prod.name.trim());
      params.set('coShare', String(prod.masterShare));
    }
  }

  return `beatdeal://split?${params.toString()}`;
}
