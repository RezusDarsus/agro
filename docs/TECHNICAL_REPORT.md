# AgroLens Samegrelo — Technical Report

## Problem and local relevance

Hazelnut growers in Samegrelo need a quick way to triage visible leaf and fruit problems. AgroLens turns an ordinary phone camera into an offline first-pass assistant. It does not replace a certified agronomist.

## MVP scope

The MVP identifies five outcomes: healthy, brown marmorated stink bug damage, fungal spot, fruit rot, and unknown. It returns confidence, a heuristic severity estimate, Georgian guidance, and local history. There is no backend, IoT hardware, account, or paid API.

## Model architecture and training

Training uses ImageNet-pretrained MobileNetV2 without its classifier head. Images are resized to 224×224 and normalized to 0–1. Global average pooling, dropout 0.3, a 128-unit ReLU layer, and a five-unit softmax layer form the classifier. The base is frozen for initial training with Adam at 0.0001 and sparse categorical cross-entropy.

Data should be farmer-relevant, consented, geographically diverse, balanced across classes, and split by orchard rather than near-duplicate image. Augmentation covers modest rotation, zoom, and horizontal flips. Evaluation reports accuracy, per-class precision/recall/F1, and a confusion matrix. A future version should add expert label review, device-level testing, calibration, explainability, and out-of-distribution evaluation.

## Mobile architecture and offline inference

Flutter separates screens, data models, reusable widgets, and services. At launch and analysis time, the app attempts to load the bundled TFLite model and labels. Missing or invalid model assets trigger deterministic mock inference, keeping hackathon demos functional. Images never need to leave the device. SharedPreferences stores serialized diagnosis history locally.

## Decision and severity rules

The highest model probability becomes the class only when it is at least 0.65; otherwise the result is unknown. Severity is `0.7 × confidence + 0.3 × class risk`, with class risk defined in the code. This is a presentation heuristic—not lesion segmentation or a validated measure of crop loss.

## Safety and limitations

Image quality, lighting, occlusion, growth stage, unseen diseases, dataset bias, and look-alike symptoms can cause errors. Recommendations are conservative and avoid pesticide prescriptions. High severity, low confidence, or spreading symptoms should be referred to an agronomist.

## Future work

Add expert-reviewed field data, fine-tuning and calibration, lesion segmentation, agronomist feedback, multilingual accessibility, citrus/tea/blueberry support, and privacy-preserving village-level disease maps.

