import { useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
} from 'react-native';
import { colors, radius, spacing, CURRENCIES } from '@/constants/theme';
import { useCatalog } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import type { CurrencyCode } from '@/constants/theme';
import type { ServiceCatalogItem } from '@/types';

export default function CatalogScreen() {
  const { catalog, saveCatalogItem, deleteCatalogItem } = useCatalog();
  const [description, setDescription] = useState('');
  const [unitPrice, setUnitPrice] = useState('');
  const [category, setCategory] = useState('Production');
  const [currency, setCurrency] = useState<CurrencyCode>('EUR');

  const handleAdd = async () => {
    if (!description.trim() || !unitPrice.trim()) {
      Alert.alert('Champs requis', 'Description et prix obligatoires.');
      return;
    }
    const price = parseFloat(unitPrice.replace(',', '.'));
    if (Number.isNaN(price) || price <= 0) {
      Alert.alert('Prix invalide');
      return;
    }
    await saveCatalogItem({
      id: uuid(),
      description: description.trim(),
      unitPrice: price,
      currency,
      category: category.trim() || 'Autre',
    });
    setDescription('');
    setUnitPrice('');
    Alert.alert('Ajouté', 'Service ajouté au catalogue.');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.intro}>
        Tes prestations récurrentes — réutilisables en un clic lors de la création de factures et devis.
      </Text>

      <View style={styles.form}>
        <Field label="Description *" value={description} onChange={setDescription} placeholder="Mix & master" />
        <Field label="Prix unitaire *" value={unitPrice} onChange={setUnitPrice} placeholder="150" keyboardType="decimal-pad" />
        <Field label="Catégorie" value={category} onChange={setCategory} placeholder="Production" />
        <Text style={styles.label}>Devise</Text>
        <View style={styles.chips}>
          {CURRENCIES.map((c) => (
            <Pressable
              key={c.code}
              style={[styles.chip, currency === c.code && styles.chipActive]}
              onPress={() => setCurrency(c.code)}
            >
              <Text style={[styles.chipText, currency === c.code && styles.chipTextActive]}>{c.code}</Text>
            </Pressable>
          ))}
        </View>
        <Pressable style={styles.addBtn} onPress={handleAdd}>
          <Text style={styles.addBtnText}>Ajouter au catalogue</Text>
        </Pressable>
      </View>

      {catalog.length === 0 ? (
        <Text style={styles.empty}>Catalogue vide</Text>
      ) : (
        catalog.map((item) => (
          <CatalogRow key={item.id} item={item} onDelete={() => deleteCatalogItem(item.id)} />
        ))
      )}
    </ScrollView>
  );
}

function CatalogRow({ item, onDelete }: { item: ServiceCatalogItem; onDelete: () => void }) {
  return (
    <View style={styles.row}>
      <View style={styles.rowInfo}>
        <Text style={styles.rowTitle}>{item.description}</Text>
        <Text style={styles.rowSub}>
          {item.category} · {item.unitPrice.toFixed(2)} {item.currency}
        </Text>
      </View>
      <Pressable onPress={onDelete} hitSlop={8}>
        <Text style={styles.delete}>Suppr.</Text>
      </Pressable>
    </View>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  keyboardType,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'decimal-pad';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  intro: { color: colors.textSecondary, fontSize: 14, marginBottom: spacing.lg, lineHeight: 20 },
  form: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
    gap: spacing.sm,
  },
  field: { marginBottom: spacing.sm },
  label: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.section,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontSize: 13 },
  chipTextActive: { color: colors.background, fontWeight: '600' },
  addBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  addBtnText: { color: colors.background, fontWeight: '700' },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  rowInfo: { flex: 1 },
  rowTitle: { color: colors.text, fontWeight: '600', fontSize: 15 },
  rowSub: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  delete: { color: colors.error, fontSize: 13, fontWeight: '600' },
});
