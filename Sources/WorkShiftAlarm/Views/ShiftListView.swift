import SwiftUI
import SwiftData

struct ShiftListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShiftType.name) private var shifts: [ShiftType]
    @State private var showingEditor = false
    @State private var editingShift: ShiftType?

    var body: some View {
        NavigationStack {
            List {
                ForEach(shifts) { shift in
                    Button {
                        editingShift = shift
                        showingEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(shift.name) 班")
                                .font(.headline)
                            Text("\(shift.startTime) - \(shift.endTime)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("班次类型")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingShift = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ShiftEditorView(shift: editingShift)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { shifts[$0] }.forEach(modelContext.delete)
    }
}

struct ShiftEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var startTime: String
    @State private var endTime: String
    @State private var keywords: String
    @State private var templates: [AlarmTemplate]

    private let shift: ShiftType?

    init(shift: ShiftType?) {
        self.shift = shift
        _name = State(initialValue: shift?.name ?? "")
        _startTime = State(initialValue: shift?.startTime ?? "09:00")
        _endTime = State(initialValue: shift?.endTime ?? "18:00")
        _keywords = State(initialValue: shift?.keywordRules.joined(separator: ",") ?? "")
        _templates = State(initialValue: shift?.alarmTemplates.map { $0.copy() } ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("班次") {
                    TextField("名称", text: $name)
                    TextField("开始时间", text: $startTime)
                    TextField("结束时间", text: $endTime)
                }
                Section("关键词映射") {
                    TextField("例如: A班,A", text: $keywords)
                        .textInputAutocapitalization(.never)
                }
                Section("闹钟模板") {
                    if templates.isEmpty {
                        Text("暂无模板，可添加")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(templates.indices, id: \.self) { idx in
                        AlarmTemplateRow(template: $templates[idx])
                    }
                    .onDelete { offsets in
                        templates.remove(atOffsets: offsets)
                    }
                    Button("添加闹钟") {
                        templates.append(AlarmTemplate(label: "新闹钟", anchor: .start, offsetMinutes: 0, enabled: true))
                    }
                }
            }
            .navigationTitle(shift == nil ? "新增班次" : "编辑班次")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let rules = keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let shift {
            shift.name = name
            shift.startTime = startTime
            shift.endTime = endTime
            shift.keywordRules = rules
            shift.alarmTemplates = templates.map { $0.copy() }
        } else {
            let newShift = ShiftType(name: name, startTime: startTime, endTime: endTime, keywordRules: rules)
            newShift.alarmTemplates = templates.map { $0.copy() }
            modelContext.insert(newShift)
        }
    }
}

struct AlarmTemplateRow: View {
    @Binding var template: AlarmTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("名称", text: $template.label)
            HStack {
                Picker("基准", selection: $template.anchorRaw) {
                    Text("上班").tag(AlarmAnchor.start.rawValue)
                    Text("下班").tag(AlarmAnchor.end.rawValue)
                }
                .pickerStyle(.segmented)
            }
            HStack {
                TextField("偏移(分钟)", value: $template.offsetMinutes, format: .number)
                    .keyboardType(.numbersAndPunctuation)
                Toggle("启用", isOn: $template.enabled)
            }
        }
    }
}
