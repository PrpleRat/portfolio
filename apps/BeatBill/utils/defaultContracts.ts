import type { ContractTemplate } from '@/types';

export const DEFAULT_CONTRACTS: ContractTemplate[] = [
  {
    id: 'builtin-beat-lease',
    title: 'Contrat Beat Lease (MP3/WAV)',
    type: 'beat_lease',
    isBuiltin: true,
    body: `CONTRAT DE LICENCE BEAT LEASE

Entre :
Le Producteur : {{producteur}} ({{email_producteur}})
Et :
L'Artiste / Label : {{client}} ({{email_client}})

Objet : Licence non exclusive du beat « {{projet}} ».

1. DROITS ACCORDÉS
Licence non exclusive pour enregistrer, distribuer et monétiser le titre ({{streams}} streams max).

2. CRÉDITS — Production : {{producteur}}

3. INTERDICTIONS — Revente du beat seul, re-licence, sample pack.

4. PRIX — {{montant}} — paiement avant livraison.

Fait le {{date}}`,
  },
  {
    id: 'builtin-exclusive',
    title: 'Contrat Beat Exclusif',
    type: 'exclusive',
    isBuiltin: true,
    body: `CONTRAT DE CESSION EXCLUSIVE — BEAT

Producteur : {{producteur}} ({{email_producteur}})
Artiste : {{client}} ({{email_client}})

Cession exclusive mondiale du beat « {{projet}} ».
Retrait de la vente sous 72h après paiement intégral.
Prix : {{montant}}

Fait le {{date}}`,
  },
  {
    id: 'builtin-session',
    title: 'Contrat Session Studio',
    type: 'session',
    isBuiltin: true,
    body: `CONTRAT DE PRESTATION — SESSION STUDIO

Prestataire : {{producteur}}
Client : {{client}} ({{email_client}})
Prestation : {{projet}} — {{montant}}
Annulation : 48h minimum.

Fait le {{date}}`,
  },
  {
    id: 'builtin-wfh',
    title: 'Work For Hire — Production',
    type: 'work_for_hire',
    isBuiltin: true,
    body: `CONTRAT WORK FOR HIRE

{{producteur}} réalise pour {{client}} : {{projet}}.
En contrepartie de {{montant}}, le Client obtient tous les droits patrimoniaux.

Fait le {{date}}`,
  },
];
