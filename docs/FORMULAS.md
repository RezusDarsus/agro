# AgroLens formulas

## Pixel normalization

`x' = x / 255` converts each 8-bit color value from 0–255 to 0–1.

## CNN convolution

`Y(i,j) = Σ X(i+m, j+n) × K(m,n) + b` slides a learned kernel across an image to detect local patterns.

## ReLU

`ReLU(x) = max(0, x)` keeps positive signals and replaces negative values with zero.

## Softmax

`P(y=i|x) = exp(z_i) / Σ exp(z_j)` converts output scores into probabilities totaling one.

## Cross-entropy

`L = -Σ y_i log(ŷ_i)` penalizes confident wrong classifications.

## Severity

`SeverityScore = 0.7 × Confidence + 0.3 × ClassRisk`. Low is below 0.35, medium is 0.35–0.70, and high is 0.70 or above. A confident healthy result is forced to low.

## Evaluation

- `Accuracy = Correct Predictions / Total Predictions`
- `Precision = TP / (TP + FP)`
- `Recall = TP / (TP + FN)`
- `F1 = 2 × Precision × Recall / (Precision + Recall)`

