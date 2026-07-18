import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '@/constants/theme';
import type { Collaborator, Split, UserProfile } from '@/types';

const demoProfile: UserProfile = {
  name: 'Metro Beats',
  role: 'Producteur',
  email: 'metro@prod.fr',
  sacem: '123456789',
  country: 'France',
  currency: 'EUR',
};

const demoCollaborators: Collaborator[] = [
  {
    id: 'demo-c1',
    name: 'Niska',
    role: 'Parolier',
    email: 'niska@example.fr',
    sacem: '987654321',
    lastUsedAt: new Date().toISOString(),
    splitCount: 2,
  },
  {
    id: 'demo-c2',
    name: 'Metro',
    role: 'Producteur',
    email: 'metro@prod.fr',
    sacem: '123456789',
    lastUsedAt: new Date().toISOString(),
    splitCount: 3,
  },
];

const demoSplits: Split[] = [
  {
    id: 'demo-s1',
    ref: 'SPLIT-DEMO01',
    title: 'Banlieue',
    artist: 'Niska',
    genre: 'Rap FR',
    isrc: '',
    createdAt: new Date().toISOString(),
    splitType: 'master_and_publishing',
    collaborators: [
      {
        id: 'col-1',
        name: 'Metro',
        role: 'Producteur',
        masterShare: 50,
        publishingShare: 30,
        sacem: '123456789',
        email: 'metro@prod.fr',
        signed: true,
      },
      {
        id: 'col-2',
        name: 'Niska',
        role: 'Parolier',
        masterShare: 50,
        publishingShare: 50,
        sacem: '987654321',
        email: '',
        signed: false,
      },
    ],
    clauses: ["Ce split s'applique à toutes les versions du morceau"],
    notes: '',
    status: 'pending',
  },
];

export async function seedDemoData(): Promise<void> {
  await Promise.all([
    AsyncStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(demoProfile)),
    AsyncStorage.setItem(STORAGE_KEYS.collaborators, JSON.stringify(demoCollaborators)),
    AsyncStorage.setItem(STORAGE_KEYS.splits, JSON.stringify(demoSplits)),
  ]);
}
