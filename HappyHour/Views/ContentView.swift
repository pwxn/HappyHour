
import SwiftUI

struct ButtonStyleNoBack: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label.background(Color.clear)
    }
}

struct ListRow: View {
    @EnvironmentObject var model: ItemModel
    @State var editText: String
    var item: ItemModel.Item
    let listKey: ItemModel.ListKeyPath

    init(item: ItemModel.Item, listKey: ItemModel.ListKeyPath) {
        self.item = item
        self.listKey = listKey
        _editText = State(initialValue: item.text)
    }
    
    var body: some View {
        HStack{
            Image(systemName: "arrowtriangle.right.fill")
            TextField("new item", text:self.$editText, onCommit: {
                if self.item.text != self.editText {
                    self.item.text = self.editText
                    print(self.item.text)
                    self.model.save()
                }
            })
                .onExitCommand(perform: { NSApp.keyWindow?.makeFirstResponder(nil) })
                .textFieldStyle(PlainTextFieldStyle())
            Button {
                self.model.moveUp(self.item.id, keyPath:self.listKey)
            } label: {
                Label("Up", systemImage: "arrow.up").labelStyle(IconOnlyLabelStyle())
            }.buttonStyle(ButtonStyleNoBack())
            Button {
                    self.model.moveDown(self.item.id, keyPath:self.listKey)
            } label: {
                Label("Down", systemImage: "arrow.down").labelStyle(IconOnlyLabelStyle())
            }.buttonStyle(ButtonStyleNoBack())
            Button {
                self.model.remove(self.item.id, keyPath:self.listKey)
            } label: {
                Label("Trash", systemImage: "trash").labelStyle(IconOnlyLabelStyle())
            }.buttonStyle(ButtonStyleNoBack())
        }
    }
}

struct List: View {
    @EnvironmentObject var model: ItemModel
    @State var editText: String = ""
    let title: String
    let listKey: ItemModel.ListKeyPath
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).bold()
            ForEach(self.model[keyPath: listKey]) { item in
                ListRow(item: item, listKey:self.listKey)
            }
            TextField("new item", text:self.$editText, onCommit: {
                if self.editText.count > 0 {
                    self.model.add(self.editText, keyPath:self.listKey)
                    print(self.editText)
                    self.editText = ""
                    self.model.save()
                }
            })
                .onExitCommand(perform: { NSApp.keyWindow?.makeFirstResponder(nil) })
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(Edge.Set.horizontal)
    }
}

struct HelpWidget: View {
    @State var helpSheetVisible = false
    
    var body: some View {
        Button(action: { self.helpSheetVisible = true }) {
            Label("Help", systemImage:"questionmark.circle")
        }.popover(isPresented: self.$helpSheetVisible) {
            VStack(alignment: .leading) {
                Text("The Copy action will format the sections suitable for email,")
                Text("and place them on the clipboard")
                Divider()
                Text("You May specify PRs with either of the follwing formats:")
                Text("PR 1234 | PR1234")
                Text("And they will be automatically linked, using the URL set in preferences.")
                Divider()
                Text("Resetting the form clears all sections,")
                Text("except that the contents from tomorrow are moved to planned")
            }.padding()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var model: ItemModel
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        VStack {
            Text(settings.storageFileName).bold()
            List(title:"Planned", listKey: \.planned)
            List(title:"Today", listKey: \.today)
            List(title:"Tomorrow", listKey: \.tomorrow)
            List(title:"QBI", listKey: \.qbi)
            Spacer().layoutPriority(1)
            if settings.showFocusTimer {
                TimerBar()
            }
        }
        .padding()
        .frame(minWidth: 550, maxWidth: .infinity,
               minHeight: 625, maxHeight: .infinity,
               alignment: .topLeading)
        .toolbar {
            HelpWidget()
            Button {
                if let service = NSSharingService(named: NSSharingService.Name.composeEmail) {
                    let today = Date()
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    if settings.standupEmail.count > 0 {
                        service.recipients = [settings.standupEmail]
                    }
                    service.subject = "\(f.string(from: today)) Standup"
                    service.perform(withItems: [self.model.formatted()])
                }
            } label:  {
                Label("Send", systemImage:"paperplane")
            }
            Button { self.model.clear() } label: {
                Label("Reset", systemImage:"repeat")
            }
            Button {
                let text = self.model.formatted()
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([NSPasteboard.PasteboardType.rtf], owner: nil)
                pasteboard.writeObjects([text])
            } label:  {
                Label("Copy", systemImage:"doc.on.doc")
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static func sampleData() -> ItemModel {
        let model = ItemModel()
        model.add("Thing that was planned", keyPath: \.planned)
        model.add("Thing that was done", keyPath: \.today)
        model.add("Another thing done", keyPath: \.today)
        model.add("Something for tomorrow", keyPath: \.tomorrow)
        model.add("A really long thing that was done so that it won't all fit in one line at the default width and need to wrap.", keyPath: \.qbi)
        return model
    }
    
    static var previews: some View {
        ContentView()
            .environmentObject(self.sampleData())
            .environmentObject(TaskTimer())
    }
}
