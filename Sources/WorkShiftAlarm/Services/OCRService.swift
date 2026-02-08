import Foundation
import Vision
import UIKit

struct OCRDayEntry {
    let dateNumber: Int
    let rawText: String
    let confidence: Float
}

struct OCRMonthResult {
    let year: Int
    let month: Int
    let entries: [OCRDayEntry]
}

final class ScheduleOCRService {
    func recognizeSchedule(from data: Data) async throws -> OCRMonthResult {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            throw NSError(domain: "OCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效图片"])
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            throw NSError(domain: "OCR", code: -2, userInfo: [NSLocalizedDescriptionKey: "识别失败"])
        }

        let texts = observations.compactMap { obs -> (text: String, confidence: Float, box: CGRect)? in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            return (candidate.string.trimmingCharacters(in: .whitespacesAndNewlines), candidate.confidence, obs.boundingBox)
        }

        let (year, month) = parseYearMonth(from: texts.map { $0.text })
        let entries = mapTextsToDates(texts: texts)
        return OCRMonthResult(year: year, month: month, entries: entries)
    }

    private func parseYearMonth(from texts: [String]) -> (Int, Int) {
        let pattern = try? NSRegularExpression(pattern: "(\\d{4})\\s*年\\s*(\\d{1,2})\\s*月")
        for text in texts {
            let range = NSRange(text.startIndex..., in: text)
            if let match = pattern?.firstMatch(in: text, range: range), match.numberOfRanges == 3 {
                let year = Int((text as NSString).substring(with: match.range(at: 1))) ?? Calendar.current.component(.year, from: Date())
                let month = Int((text as NSString).substring(with: match.range(at: 2))) ?? Calendar.current.component(.month, from: Date())
                return (year, month)
            }
        }
        let now = Date()
        return (Calendar.current.component(.year, from: now), Calendar.current.component(.month, from: now))
    }

    private func mapTextsToDates(texts: [(text: String, confidence: Float, box: CGRect)]) -> [OCRDayEntry] {
        let dateCandidates = texts.compactMap { item -> (date: Int, box: CGRect, conf: Float)? in
            guard let number = Int(item.text), (1...31).contains(number) else { return nil }
            return (number, item.box, item.confidence)
        }

        guard !dateCandidates.isEmpty else { return [] }

        var results: [OCRDayEntry] = []
        for candidate in dateCandidates {
            let nearby = texts.filter { item in
                guard Int(item.text) == nil else { return false }
                let dx = abs(item.box.midX - candidate.box.midX)
                let dy = item.box.midY - candidate.box.midY
                return dx < 0.08 && dy < -0.01
            }
            let combined = nearby.map { $0.text }.joined(separator: " ")
            results.append(OCRDayEntry(dateNumber: candidate.date, rawText: combined, confidence: candidate.conf))
        }
        return results
    }
}
