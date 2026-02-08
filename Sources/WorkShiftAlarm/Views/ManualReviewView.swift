import SwiftUI
import SwiftData

struct ManualReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var shifts: [ShiftType]
    @State private var drafts: [DayPlanDraft]
    @State private var showBatchEdit = false

    let onConfirm: ([DayPlanDraft]) -> Void

    init(drafts: [DayPlanDraft], onConfirm: @escaping ([DayPlanDraft]) -> Void) {
        _drafts = State(initialValue: drafts.sorted(by: { $0.date < $1.date }))
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(drafts.indices, id: \.self) { idx in
                    let draft = drafts[idx]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(draft.date, style: .date)
                            Text(draft.rawText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            ForEach(shifts) { shift in
                                Button(shift.name) {
                                    drafts[idx].shiftName = shift.name
                                }
                            }
                        } label: {
                            Text(drafts[idx].shiftName)
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("校对排班")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("批量修改") { showBatchEdit = true }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("生成闹钟") {
                        onConfirm(drafts)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBatchEdit) {
                BatchEditView(drafts: $drafts, shifts: shifts)
            }
        }
    }
}

struct BatchEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var drafts: [DayPlanDraft]
    let shifts: [ShiftType]
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedShiftName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                Picker("班次", selection: $selectedShiftName) {
                    ForEach(shifts) { shift in
                        Text(shift.name).tag(shift.name)
                    }
                }
            }
            .navigationTitle("批量修改")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        apply()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedShiftName.isEmpty {
                    selectedShiftName = shifts.first?.name ?? ""
                }
            }
        }
    }

    private func apply() {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        for idx in drafts.indices {
            let day = Calendar.current.startOfDay(for: drafts[idx].date)
            if day >= start && day <= end {
                drafts[idx].shiftName = selectedShiftName
            }
        }
    }
}
