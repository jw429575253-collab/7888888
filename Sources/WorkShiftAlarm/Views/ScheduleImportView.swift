import SwiftUI
import SwiftData
import PhotosUI

struct ScheduleImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shifts: [ShiftType]
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var message: String?
    @State private var showReview = false
    @State private var draftPlans: [DayPlanDraft] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("上传排班截图", systemImage: "photo")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

                if isLoading {
                    ProgressView("识别中...")
                }

                if let message {
                    Text(message)
                        .foregroundStyle(.secondary)
                }

                if !draftPlans.isEmpty {
                    Button("进入校对") {
                        showReview = true
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("排班导入")
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await handleImport(item: newItem)
                }
            }
            .sheet(isPresented: $showReview) {
                ManualReviewView(drafts: draftPlans, onConfirm: applyDrafts)
            }
        }
    }

    private func handleImport(item: PhotosPickerItem) async {
        isLoading = true
        message = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                message = "无法读取图片"
                isLoading = false
                return
            }
            let ocr = ScheduleOCRService()
            let result = try await ocr.recognizeSchedule(from: data)
            let mapper = ShiftMappingService(shifts: shifts)
            draftPlans = mapper.mapToDrafts(from: result)
            message = "识别完成，请校对"
        } catch {
            message = "识别失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func applyDrafts(_ drafts: [DayPlanDraft]) {
        let planner = SchedulePlanner(modelContext: modelContext)
        planner.applyMonthPlans(drafts: drafts, shifts: shifts)
    }
}
