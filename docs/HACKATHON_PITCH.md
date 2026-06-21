# AgroLens Samegrelo

**One line:** An offline camera assistant that helps Samegrelo farmers recognize visible hazelnut health problems and act sooner.

## Problem

Hazelnut damage can spread or reduce quality before specialist support is available. Farmers need accessible first-pass guidance in Georgian.

## Solution

Take a phone photo, receive a five-class AI estimate, confidence and severity, read a Georgian recommendation, and save the report—without a backend or paid API.

## Live demo

1. Open app.
2. Pick or take a hazelnut photo.
3. Analyze image.
4. Get diagnosis.
5. See confidence and severity.
6. Read the Georgian recommendation.
7. Save and reopen the report from history.

Mock mode guarantees the demo works today. Exporting the MobileNetV2 model switches the same app to real TFLite inference.

## Innovation and impact

AgroLens combines an efficient mobile vision model, explicit uncertainty handling, offline inference, and local-language actions. It lowers the barrier to early triage while responsibly directing uncertain or serious cases to agronomists.

## Value and roadmap

The immediate social value is faster awareness and better conversations between farmers and specialists. Future versions can cover citrus, tea, and blueberry; learn from agronomist feedback; and support privacy-aware village disease maps. Sustainable paths include extension-service partnerships, cooperatives, and premium expert review—while keeping basic diagnosis accessible.

