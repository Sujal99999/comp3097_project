import SwiftUI

struct ShoppingItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: String
    var price: Double

    init(id: UUID = UUID(), name: String, category: String, price: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
    }
}

class ShoppingViewModel: ObservableObject {
    @Published var items: [ShoppingItem] = []
    @Published var taxRate: Double = 0.01  // Default 1% tax

    init() {
        self.items = loadItems()
        self.taxRate = UserDefaults.standard.double(forKey: "taxRate") == 0 ? 0.01 : UserDefaults.standard.double(forKey: "taxRate")
    }

    func addItem(name: String, category: String, price: Double) {
        let newItem = ShoppingItem(name: name, category: category, price: price)
        items.append(newItem)
        saveItems()
    }

    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func deleteItemById(_ item: ShoppingItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func calculateTotal() -> Double {
        return items.reduce(0) { total, item in
            let totalWithTax = item.price * (1 + taxRate)
            return total + totalWithTax
        }
    }

    func clearAllItems() {
        items.removeAll()
        saveItems()
    }

    func setTaxRate(_ rate: Double) {
        taxRate = rate
        UserDefaults.standard.set(rate, forKey: "taxRate")
    }

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "shoppingItems")
        }
    }

    private func loadItems() -> [ShoppingItem] {
        if let savedData = UserDefaults.standard.data(forKey: "shoppingItems"),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: savedData) {
            return decoded
        }
        return []
    }
}

struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingViewModel()
    @State private var showAddItemView = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.items) { item in
                        NavigationLink(destination: ProductDetailView(viewModel: viewModel, item: item)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(item.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "$%.2f", item.price))
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .onDelete(perform: viewModel.deleteItem)
                }
                .listStyle(PlainListStyle())

                Text("Total (incl. \(Int(viewModel.taxRate * 100))% tax): $\(viewModel.calculateTotal(), specifier: "%.2f")")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                    .padding()

                HStack {
                    Button(action: { showAddItemView = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showAddItemView) {
                        AddItemView(viewModel: viewModel)
                    }

                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Shopping List 🛒")
            .padding()
            .background(Color(UIColor.systemBackground))
        }
    }
}

struct ProductDetailView: View {
    @ObservedObject var viewModel: ShoppingViewModel
    var item: ShoppingItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(item.name)
                .font(.largeTitle)
                .bold()

            Text("Category: \(item.category)")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Price: $\(String(format: "%.2f", item.price))")
                .font(.title)
                .foregroundColor(.green)

            Button(action: {
                viewModel.deleteItemById(item)
                dismiss()
            }) {
                Label("Delete Item", systemImage: "trash.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ShoppingViewModel

    var body: some View {
        Form {
            Section(header: Text("Tax Settings")) {
                Stepper("Tax Rate: \(Int(viewModel.taxRate * 100))%", value: Binding(
                    get: { Int(viewModel.taxRate * 100) },
                    set: { viewModel.setTaxRate(Double($0) / 100) }
                ), in: 0...10)
            }

            Section {
                Button("Clear All Items", role: .destructive) {
                    viewModel.clearAllItems()
                }
            }
        }
        .navigationTitle("Settings ⚙️")
    }
}

struct LaunchView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            if isActive {
                ShoppingListView()
            } else {
                VStack {
                    Text("Shoppers Point")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    Text("By Sujal Aditya Leela")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isActive = true
            }
        }
    }
}

@main
struct ShoppersPointApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}

struct AddItemView: View {
    @ObservedObject var viewModel: ShoppingViewModel
    @State private var name = ""
    @State private var price = ""
    @State private var category = "Food"
    @Environment(\.dismiss) var dismiss

    let categories = ["Food", "Medication", "Cleaning", "Other"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $name)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
            }
            .navigationTitle("Add Item ➕")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let priceValue = Double(price), !name.isEmpty {
                            viewModel.addItem(name: name, category: category, price: priceValue)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
