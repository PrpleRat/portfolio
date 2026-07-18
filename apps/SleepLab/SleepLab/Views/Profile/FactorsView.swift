import SwiftUI

struct FactorsView: View {
    var body: some View {
        List {
            ForEach(FactorCategory.allCases, id: \.self) { category in
                Section(category.displayName) {
                    ForEach(factors(for: category), id: \.self) { factor in
                        FactorCatalogRow(factor: factor)
                    }
                }
            }
        }
        .navigationTitle("Facteurs")
        .navigationBarTitleDisplayMode(.large)
    }

    private func factors(for category: FactorCategory) -> [FactorType] {
        FactorType.allCases.filter { $0.category == category }
    }
}

private struct FactorCatalogRow: View {
    let factor: FactorType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: factor.sfSymbol)
                    .foregroundStyle(SleepTheme.accent)
                    .frame(width: 28)
                VStack(alignment: .leading) {
                    Text(factor.displayName)
                    if !factor.defaultUnit.isEmpty {
                        Text("Unité : \(factor.defaultUnit)")
                            .font(.caption2)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }
            }
            if let brief = factor.scienceBrief {
                Text(brief)
                    .font(.caption2)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }
}
