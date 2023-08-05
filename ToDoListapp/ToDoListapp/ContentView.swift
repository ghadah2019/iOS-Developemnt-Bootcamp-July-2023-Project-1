//
//  ContentView.swift
//  ToDoListApp
//
//  Created by Ghada Al on 17/01/1445 AH.
//

import SwiftUI

struct TodoTask: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var priority: Priority
    var status: Status

    enum Priority: String, CaseIterable {
        case high, medium, low
    }
//    enum taskStatus: String {
//        case backlog, todo, inProgress, done
//    }
    
    enum Status: String, CaseIterable {
        case backlog, todo, inProgress, done
    }
}

class TodoListViewModel: ObservableObject {
    @Published var toDoTasks: [TodoTask] = []
    
    func addTodoItem(title: String, description: String, priority: TodoTask.Priority, status: TodoTask.Status) {
        let newItem = TodoTask(title: title, description: description, priority: priority, status: status)
        toDoTasks.append(newItem)
    }
    
    func toggleCompletion(for item: TodoTask) {
        if let index = toDoTasks.firstIndex(where: { $0.id == item.id }) {
            let updatedItem = toggleStatus(for: toDoTasks[index])
            toDoTasks[index] = updatedItem
        }
    }
    
    private func toggleStatus(for item: TodoTask) -> TodoTask {
        var updatedItem = item
        switch item.status {
            case .backlog:
                updatedItem.status = .todo
            case .todo:
                updatedItem.status = .inProgress
            case .inProgress:
                updatedItem.status = .done
            case .done:
                updatedItem.status = .backlog
            
        }
        return updatedItem
    }
    
    func deleteItem(at indices: IndexSet) {
        toDoTasks.remove(atOffsets: indices)
    }
    func editTask(task: TodoTask, updatedTask: TodoTask) {
        if let index = toDoTasks.firstIndex(where: { $0.id == task.id }) {
            toDoTasks[index] = updatedTask
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .font(.system(size: 22))
                .padding(20)
                .cornerRadius(25)
                .background(Color.black.opacity(0.1))
//                .foregroundColor(Color.gray.opacity(0.2))
            Button(action: {
                text = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }
    
        }
   
    }
        
}


struct TodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                
                SearchBar(text: $searchText)
                    .padding(.top)
                List {
                    ForEach(viewModel.toDoTasks.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }) { item in
                        NavigationLink(destination: TodoItemDetailView(item: item, viewModel: viewModel)) {
                            TodoItemView(item: item)
                                .onTapGesture {
                                    viewModel.toggleCompletion(for: item)
                                }
                        }
                    }
                .onDelete(perform: viewModel.deleteItem)            }
            .navigationTitle("List of tasks")
            .navigationBarItems(trailing: AddItemButton(viewModel: viewModel))
        }
    }
}
}

struct TodoItemView: View {
    let item: TodoTask
    
    var body: some View {
        HStack {
            Image(systemName: item.status == .done ? "checkmark.circle.fill" : "circle")
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text("Priority: \(item.priority.rawValue.capitalized)")
                    .font(.subheadline)
            }
        }
    }
}

struct AddItemButton: View {
    @State private var isPresentingAddItemSheet = false
    @ObservedObject var viewModel: TodoListViewModel
    
    var body: some View {
        
        Button(action: {
            
            isPresentingAddItemSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title)
                .foregroundColor(.white)
                .background(Color.blue.opacity(0.7))
                .clipShape(Circle())
                
            
        }
        .sheet(isPresented: $isPresentingAddItemSheet) {
            AddItemView(viewModel: viewModel)
                .background(.gray.opacity(0.3))
        }
    }
}

struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TodoListViewModel
    @State private var  newTask = ""
    @State private var newTaskDescription = ""
    @State private var taskPriority = TodoTask.Priority.medium
    @State private var taskStatus = TodoTask.Status.backlog
    
    var body: some View {
        VStack {
            TextField("Enter a new Task", text: $newTask)
                .textFieldStyle(RoundedBorderTextFieldStyle())
               // .font(.title)
                .foregroundColor(.black)
                .font(.system(size: 20))
                .padding(20)
                .cornerRadius(30)
                .background(.blue.opacity(0.2))
             
            TextField("Enter a description of task", text: $newTaskDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                //.font(.title)
                .foregroundColor(.black)
                .font(.system(size: 20))
                .padding(20)
                .cornerRadius(25)
                .background(.blue.opacity(0.2))
            
         
            
            Picker("Priority", selection: $taskPriority) {
                ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                    Text(priority.rawValue.capitalized)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Picker("Status", selection: $taskStatus) {
                ForEach(TodoTask.Status.allCases, id: \.self) { status in
                    Text(status.rawValue.capitalized)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
         
            
            Button("Add") {
                viewModel.addTodoItem(title: newTask, description: newTaskDescription, priority: taskPriority, status: taskStatus)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(.blue.opacity(0.5))
           // .bold()
            .foregroundColor(.black)
            .cornerRadius(8)
            .font(.system(size: 20))
            .disabled(newTask.isEmpty)
        }
    }
}

struct TodoItemDetailView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State private var editTitle: String
    @State private var editDescription: String
    @State private var editPriority: TodoTask.Priority
    @State private var editStatus: TodoTask.Status
    
    let item: TodoTask
    
    init(item: TodoTask, viewModel: TodoListViewModel) {
        self.item = item
        self.viewModel = viewModel
        

        _editTitle = State(initialValue: item.title)
        _editDescription = State(initialValue: item.description)
        _editPriority = State(initialValue: item.priority)
        _editStatus = State(initialValue: item.status)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $editTitle)
                TextField("Description", text: $editDescription)
            }
            
            Section(header: Text("Priority")) {
                Picker("Priority", selection: $editPriority) {
                    ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized)
                           // .foregroundColor(.green.opacity(0.2))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
               // .foregroundColor(.green.opacity(0.2))
            }
            
            Section(header: Text("Status")) {
                Picker("Status", selection: $editStatus) {
                    ForEach(TodoTask.Status.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
             
            }
        }
        .navigationBarTitle("Edit Task")
        .navigationBarItems(trailing: Button(action: {
         
            viewModel.editTask(task: item, updatedTask: TodoTask(
                title: editTitle,
                description: editDescription,
                priority: editPriority,
                status: editStatus
            ))
        }) {
            Text("Save")
            
        })
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TodoListViewModel()
    
    var body: some View {
        TodoListView(viewModel: viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
