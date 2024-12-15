import SwiftUI
import UniformTypeIdentifiers // يحدد نوع الملفات اللي بنشتغل عليها
import Speech

class FilePickerViewModel: ObservableObject {
    @Published var selectedFile: MediaFile? // يخزن الملف اللي تختاره
    @Published var errorMessage: String? // يخزن رسائل الخطأ لو صار شيء غلط
    @Published var transcriptionResult: String? // يخزن النص الناتج من الصوت

    // هذي الدالة تتأكد إذا الملف اللي اخترته نوعه MPEG-4
    // إذا كان النوع صح تخزنه، وإذا لا تطلع رسالة خطأ
    func processPickedFile(url: URL?) {
        // أول شيء تتأكد إذا فيه ملف أو لا
        guard let fileURL = url else {
            errorMessage = "لم تختر ملف"
            return
        }

        // بعدين تتأكد من نوع الملف
        let fileExtension = fileURL.pathExtension // تتحقق من امتداد الملف كما هو بدون تعديل
        if fileExtension == "m4a" { // إذا كان الامتداد مكتوبًا كـ "MPEG-4"
            let fileName = fileURL.lastPathComponent // جبت اسم الملف
            self.selectedFile = MediaFile(name: fileName, url: fileURL) // خزنه
        } else {
            errorMessage = "الملف الذي اخترته ليس MPEG-4"
        }
    }

    // هذي الدالة تاخذ الملف، تنسخه، وتبدأ تحول الصوت إلى نص
    func transcribeSelectedFile() {
        // أول شيء تتأكد إنك اخترت ملف
        guard let file = selectedFile else {
            errorMessage = "لا يوجد ملف لتحويله إلى نص"
            return
        }

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent("SDS Saudi Driving School.m4a")

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: file.url, to: destinationURL)
        } catch {
            print("Error accessing file: \(error.localizedDescription)")
        }

        // نبدأ نحول الملف الصوتي إلى نص
        let recognizer = SFSpeechRecognizer() // أداة التعرف على الكلام
        let request = SFSpeechURLRecognitionRequest(url: destinationURL) // نطلب التعرف على الملف اللي نسخناه

        recognizer?.recognitionTask(with: request) { result, error in
            if let error = error { // إذا صار خطأ
                DispatchQueue.main.async {
                    self.errorMessage = "فشل التحويل: \(error.localizedDescription)" // طلع رسالة خطأ
                }
                return
            }

            // إذا كل شيء تمام وحصلنا النتيجة النهائية
            if let result = result, result.isFinal {
                DispatchQueue.main.async {
                    self.transcriptionResult = result.bestTranscription.formattedString // خزّن النص الناتج
                }
            }
        }
    }

    
    
    // دالة لتحويل ملف صوتي موجود في الملفات (Bundle) إلى نص
    func transcribeAudioFromBundle() {
        // الحصول على مسار الملف من الـ Bundle
        guard let assetURL = Bundle.main.url(forResource: "audio1", withExtension: "m4a") else {
            errorMessage = "الملف غير موجود في Bundle"
            return
        }

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent("audio1.m4a") // نسخ الملف إلى Documents

        do {
            // إذا الملف موجود بنفس الاسم، نحذفه
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            // نسخ الملف من الـ Bundle إلى Documents
            try fileManager.copyItem(at: assetURL, to: destinationURL)
        } catch {
            errorMessage = "فشل نسخ الملف من Bundle: \(error.localizedDescription)"
            return
        }

        // إعداد أداة التعرف على الكلام مع اللغة العربية
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA")) else {
            errorMessage = "أداة التعرف على النصوص لا تدعم اللغة العربية"
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: destinationURL) // نطلب التعرف على الملف اللي نسخناه

        recognizer.recognitionTask(with: request) { result, error in
            if let error = error { // إذا صار خطأ
                DispatchQueue.main.async {
                    self.errorMessage = "فشل التحويل: \(error.localizedDescription)" // طلع رسالة خطأ
                }
                return
            }

            // إذا كل شيء تمام وحصلنا النتيجة النهائية
            if let result = result, result.isFinal {
                DispatchQueue.main.async {
                    self.transcriptionResult = result.bestTranscription.formattedString // خزّن النص الناتج
                }
            }
        }
    }

}
