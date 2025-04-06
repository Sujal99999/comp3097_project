//
// ShoppersPointApp.swift
//
// Original Author: Sujal Sutariya (ID: 101410300)
// Created on: March 2025
//
// Additional Contributors:
// - Aditya (ID: 101410341) - Added tax calculation functionality
// - Leela (ID: 101396586) - Implemented persistence using UserDefaults
//
// Description: 
// Main application file for ShoppersPoint shopping list app that helps users 
// manage shopping lists with different categories of items and calculate total price with tax.
//

// Code Attribution Notice:
// All code in this project was written entirely by the team members listed below.
// No external code from internet sources or AI tools was used.
// Team Members:
// Name :- Sujal Sutariya ID:- 101410300
// Name:- Aditya ID:- 101410341
// Name :- Leela ID:- 101396586

import SwiftUI

// MARK: - Shopping Item Model
// Author: Sujal Sutariya (ID: 101410300)
// Represents a single item in a shopping list
// Conforms to:
// - Identifiable: Provides unique ID for SwiftUI lists
// - Codable: Enables JSON encoding/decoding for persistence
// - Equatable: Allows comparison between items
struct ShoppingItem: Identifiable, Codable, Equatable {
    var id: UUID          // Unique identifier for the item
    var name: String      // Name of the shopping item
    var category: String  // Category (Food, Medication, Cleaning, Other)
    var price: Double     // Price in dollars
    
    // Default initializer with optional ID parameter
    init(id: UUID = UUID(), name: String, category: String, price: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
    }
}

// MARK: - Shopping List Model
// Author: Sujal Sutariya (ID: 101410300)
// Represents a collection of shopping items grouped under a named list
// Conforms to:
// - Identifiable: Provides unique ID for SwiftUI lists
// - Codable: Enables JSON encoding/decoding for persistence
struct ShoppingList: Identifiable, Codable {
    var id: UUID                // Unique identifier for the list
    var name: String            // Name of the shopping list
    var items: [ShoppingItem]   // Collection of items in this list
    
    // Default initializer with optional ID and empty items array
    init(id: UUID = UUID(), name: String, items: [ShoppingItem] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}

// MARK: - ViewModel
// Author: Aditya (ID: 101410341) and Leela (ID: 101396586)
// This class manages the business logic and state for the shopping list application
// Uses ObservableObject protocol to publish changes to SwiftUI views
class ShoppingViewModel: ObservableObject {
    // Published properties trigger view updates when changed
    @Published var shoppingLists: [ShoppingList] = []
    
    // Tracks the currently selected shopping list
    // Uses property observer to persist selection to UserDefaults
    @Published var selectedListID: UUID? {
        didSet {
            if let selectedID = selectedListID {
                // Save the selected list ID when it changes
                UserDefaults.standard.set(selectedID.uuidString, forKey: "selectedListID")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedListID")
            }
        }
    }
    
    // Tax rate applied to calculate final price
    // Default is 1% (0.01)
    @Published var taxRate: Double = 0.01  // Default 1% tax

    // Initializer loads saved data and configures initial state
    // Author: Leela (ID: 101396586)
    init() {
        // Load saved shopping lists from persistent storage
        loadLists()
        
        // Load saved tax rate or use default 1% if not found
        taxRate = UserDefaults.standard.double(forKey: "taxRate") == 0 ? 0.01 : UserDefaults.standard.double(forKey: "taxRate")
        
        // Load the previously selected list ID
        if let savedIDString = UserDefaults.standard.string(forKey: "selectedListID"),
           let savedID = UUID(uuidString: savedIDString) {
            // Verify the ID exists in our loaded lists
            if shoppingLists.contains(where: { $0.id == savedID }) {
                selectedListID = savedID
            }
        }
        
        // If no list is selected and we have lists, select the first one
        if selectedListID == nil && !shoppingLists.isEmpty {
            selectedListID = shoppingLists[0].id
        }
    }

    // Computed property to get the currently selected shopping list
    // Returns nil if no list is selected
    // Author: Aditya (ID: 101410341)
    var selectedList: ShoppingList? {
        shoppingLists.first(where: { $0.id == selectedListID })
    }

    // MARK: - List Management Functions
    
    // Creates a new shopping list with the given name
    // Automatically selects the newly created list
    // Persists changes to UserDefaults
    // Author: Sujal Sutariya (ID: 101410300)
    func addList(name: String) {
        let newList = ShoppingList(name: name)
        shoppingLists.append(newList)
        selectedListID = newList.id
        saveLists()
    }

    // Add item to the selected shopping list
    // Params:
    //   - name: The name of the item
    //   - category: The category (Food, Medication, Cleaning, Other)
    //   - price: The price of the item in dollars
    // Author: Sujal Sutariya (ID: 101410300)
    func addItem(name: String, category: String, price: Double) {
        guard let index = shoppingLists.firstIndex(where: { $0.id == selectedListID }) else { return }
        shoppingLists[index].items.append(ShoppingItem(name: name, category: category, price: price))
        saveLists()
    }

    // Delete a shopping list
    // Updates the selection if the currently selected list is deleted
    // Params:
    //   - offsets: IndexSet of lists to delete (from SwiftUI onDelete)
    // Author: Leela (ID: 101396586)
    func deleteList(at offsets: IndexSet) {
        // Check if we're deleting the selected list
        let deletingSelected = offsets.contains(where: { shoppingLists[$0].id == selectedListID })
        
        shoppingLists.remove(atOffsets: offsets)
        
        // If we deleted the selected list, select another one if available
        if deletingSelected {
            selectedListID = shoppingLists.first?.id
        }
        
        saveLists()
    }

    // Delete an item from the selected list
    // Params:
    //   - offsets: IndexSet of items to delete (from SwiftUI onDelete)
    // Author: Leela (ID: 101396586)
    func deleteItem(at offsets: IndexSet) {
        guard let index = shoppingLists.firstIndex(where: { $0.id == selectedListID }) else { return }
        shoppingLists[index].items.remove(atOffsets: offsets)
        saveLists()
    }

    // MARK: - Tax Calculation Logic
    
    // Calculates the total price including tax
    // Uses Swift's reduce method to iterate through all items
    // in the selected list, adding up their prices with the tax applied
    // Returns: Double representing total price with tax
    // Author: Aditya (ID: 101410341)
    func calculateTotal() -> Double {
        guard let selectedList = selectedList else { return 0 }
        return selectedList.items.reduce(0) { $0 + $1.price * (1 + taxRate) }
    }
    // MARK: - Persistence Methods
    
    // Saves all shopping lists to UserDefaults
    // Uses JSONEncoder to convert lists to Data format
    // Author: Leela (ID: 101396586)
    func saveLists() {
        if let encoded = try? JSONEncoder().encode(shoppingLists) {
            UserDefaults.standard.set(encoded, forKey: "shoppingLists")
        }
    }
    
    // Loads shopping lists from UserDefaults
    // Uses JSONDecoder to convert Data back to ShoppingList objects
    // Author: Leela (ID: 101396586)
    func loadLists() {
        if let savedData = UserDefaults.standard.data(forKey: "shoppingLists"),
           let decoded = try? JSONDecoder().decode([ShoppingList].self, from: savedData) {
            shoppingLists = decoded
        }
    }
}

// MARK: - Splash Screen View
// Initial view shown when the app launches
// Features:
// - App logo animation with scaling and opacity transitions
// - Automatic transition to main view after 2 seconds
// - Team member credits
// Author: Sujal Sutariya (ID: 101410300)
// Modified by: Aditya (ID: 101410341) - Enhanced animation timing
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            ShoppingListView()
        } else {
            VStack {
                VStack {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("Shoppers Point")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Built by Sujal Aditya & Leela")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

// MARK: - Shopping List View
// Main view of the application displaying shopping lists and their items
// Features:
// - Two-section list showing all shopping lists and items in selected list
// - Visual indication of the currently selected list
// - Total price calculation with tax
// - Buttons to add new lists and items
// Author: Aditya (ID: 101410341)
// Modified by: Leela (ID: 101396586) - Added delete functionality
struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingViewModel()
    @State private var showAddListView = false
    @State private var showAddItemView = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Shopping Lists")) {
                        ForEach(viewModel.shoppingLists) { list in
                            Button(action: { viewModel.selectedListID = list.id }) {
                                HStack {
                                    Text(list.name)
                                    Spacer()
                                    if viewModel.selectedListID == list.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: viewModel.deleteList)
                    }

                    Section(header: Text("Items in \(viewModel.selectedList?.name ?? "List")")) {
                        ForEach(viewModel.selectedList?.items ?? []) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text(item.category)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "$%.2f", item.price))
                                    .bold()
                                    .foregroundColor(.green)
                            }
                        }
                        .onDelete(perform: viewModel.deleteItem)
                    }
                }
                .listStyle(GroupedListStyle())

                Text("Total (incl. \(Int(viewModel.taxRate * 100))% tax): $\(viewModel.calculateTotal(), specifier: "%.2f")")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                    .padding()

                HStack {
                    Button(action: { showAddListView = true }) {
                        Label("New List", systemImage: "folder.badge.plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showAddListView) {
                        AddListView(viewModel: viewModel)
                    }

                    Button(action: { showAddItemView = true }) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showAddItemView) {
                        AddItemView(viewModel: viewModel)
                    }
                    .disabled(viewModel.selectedListID == nil)
                }
            }
            .navigationTitle("Shopping Lists 🛍️")
            .padding()
        }
    }
}

// MARK: - Add List View
// Modal form for creating a new shopping list
// Features:
// - Text field for entering list name
// - Cancel and Save buttons
// - Validation to prevent empty list names
// Author: Sujal Sutariya (ID: 101410300)
struct AddListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ShoppingViewModel
    @State private var listName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
            }
            .navigationTitle("New Shopping List")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if !listName.isEmpty {
                        viewModel.addList(name: listName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}

// MARK: - Add Item View
// Modal form for adding a new item to the selected shopping list
// Features:
// - Fields for item name, price, and category
// - Category picker with predefined options
// - Price validation to ensure numeric input
// Author: Leela (ID: 101396586)
// Modified by: Aditya (ID: 101410341) - Added category selection
struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ShoppingViewModel
    @State private var name: String = ""
    @State private var category: String = "Food"
    @State private var price: String = ""

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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if let priceValue = Double(price), !name.isEmpty {
                        viewModel.addItem(name: name, category: category, price: priceValue)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}

// MARK: - Main App Structure
// Entry point for the SwiftUI application
// Sets up the main window group and initial view
// The @main attribute tells Swift this is the application entry point
// Author: Sujal Sutariya (ID: 101410300)
@main
struct ShoppersPointApp: App {
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
