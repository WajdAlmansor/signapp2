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
        if fileExtension == "mp3" { //إذا كان الامتداد مكتوبًا كـ "MPEG-4"
            let fileName = fileURL.lastPathComponent // جبت اسم الملف
            self.selectedFile = MediaFile(name: fileName, url: fileURL) // خزنه
            print("\(selectedFile)")
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

        // مدير الملفات اللي يتعامل مع التخزين
//        let fileManager = FileManager.default
//
//        // يروح لمجلد Documents في التطبيق
//        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//
//        // يحط الملف في المسار مع اسم الملف
//        let destinationURL = documentsDirectory.appendingPathComponent(file.url.lastPathComponent)
//
//        do {
//            // إذا الملف موجود بنفس الاسم، نحذفه عشان ما يصير تكرار
//            if fileManager.fileExists(atPath: destinationURL.path) {
//                try fileManager.removeItem(at: destinationURL)
//            }
//            // نسخ الملف لمجلد Documents
//            try fileManager.copyItem(at: file.url, to: destinationURL)
//        } catch {
//            errorMessage = "لم نستطع نسخ الملف \(error.localizedDescription)" // إذا صار خطأ طلع رسالة
//            print(error.localizedDescription,"😇")
//            return
//        }
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent("sds-saudi-driving-school.mp3")

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

        // هنا نبدأ عملية تحويل الصوت إلى نص
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
}
