# DermaScan AI — Final Presentation / Demo Script

## 🎯 Introduction
"Hello everyone! Today, I am proud to present **DermaScan AI**.
Dermatologists are incredibly scarce compared to the population, leading to delayed diagnoses of critical skin conditions, including cancers.
To solve this, we’ve built an **Offline-First AI Assistant** that brings medical-grade skin lesion screening directly to your smartphone."

## 🔬 The Technology (Showcase the App & Model)
*Action: Open the Mobile App & Website*
"Our solution consists of a **Flutter Mobile App** and a **FastAPI backend**.
The most powerful feature is what’s under the hood: We trained an EfficientNet/YOLOv8 neural network on the **HAM10000 dataset**, achieving **78.4% accuracy**. 
But to make it accessible to everyone—even in remote areas with no internet—we quantized the model down to just **1.43 MB (INT8)** and bundled it *inside* the app. It runs 100% locally."

## 📱 The Live Demo (Showcase the Flow)
*Action: Go to the Landing Screen*
1. **Patient Onboarding**: "We start with a clean landing page where the user enters their basic details."
2. **Bilingual Voice Guidance**: "During the scan, the app uses Text-to-Speech to guide the user in both English and Hindi (*e.g., Please place the lesion in the center...*)."
3. **Smart Skin Validation**: "If someone tries to scan a non-skin object (like a laptop), our `YCbCr` mathematical filter instantly rejects it. However, we've built a **Smart Override** that dynamically detects severe inflammation (Cr > 165) so it never accidentally rejects a critical bleeding ulcer."
4. **The Analysis**: "Once a valid lesion is detected, the AI analyzes it in under 35 milliseconds. We don't just give a result—we provide a **Grad-CAM visual heatmap** that shows *exactly* which part of the skin triggered the AI's decision, making it fully explainable."

## 🏥 Offline Referrals (Showcase the Backend)
*Action: Trigger a 'High Risk' result (e.g., Melanoma)*
"If the AI flags a lesion as **High Risk**, it instantly recommends a specialist. 
What happens if the user has no internet? The app queues the referral locally in a SQLite database. The moment the phone connects to a network, the app's Dynamic Sync Engine fires off the data to our FastAPI backend to secure the appointment."

## 🌐 The Website
*Action: Open the `index.html` Website*
"Finally, to distribute the app seamlessly, we’ve built a fully responsive, modern web landing page. Patients can visit this site, learn about the technology, and download the APK directly to their phones."

## ✅ Conclusion
"DermaScan AI isn't just an app; it's a complete, end-to-end ecosystem designed to save lives by bridging the gap between advanced AI and remote patient care. Thank you!"
