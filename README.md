# PPA_Python_R
A multi-modal machine learning framework combining linguistic and acoustic features for Primary Progressive Aphasia (PPA) variant classification while maintaining explainability via SHAP analysis
---
### DATA PRIVACY NOTICE
- **Data (.cha, .mp3, .mp4, .wav) files and csv files not uploaded to repository to adhere to patient privacy policies and ground rules of TalkBank**
- **Talkbank Datasets used for this project: Depaul, Hopkins, Baycrest, Pitt**
- **Refer to *https://talkbank.org/* on how to request access**
---
## Overview of Repository
*All Colab Notebooks and R Scripts include comments and text boxes that provide in-depth explanations of data analysis*

### Experimental Design Setup (01_PPA_ED_setup.ipynb)
* **Downloaded and Imported Required Libraries**
  * *Libraries & Coding Language:* - Python, Praat-Parselmouth, Librosa, Pandas, Numpy, Imbalanced-learn, SHAP, Scikit-learn, Matplotlib, Seaborn
* **IMPORTANT: Documented Library Versions for Experimental Design. More libraries added as project progressed**
 
### Linguistic Feature Extraction in R & RStudio (02_PPA_linguistic_extraction.Rproj)
**Packages Used: `tidyverse`, `stringr`, `fs`, `udpipe`**
Set up NLP model (**NLP_POS_model**), extracted linguistic features (**linguistic_feature_extraction.txt**) from `.cha` files
* **Depaul: 01_depaul_extract_linguistics.R**
  - **Output: ppa_depaul_linguistic_features.csv**
* **Hopkins: 02_hopkins_extract_linguistics.R**
  - **Output: ppa_hopkins_linguistic_features.csv**
* **Baycrest: 03_baycrest_extract_linguistics.R**
  - **Output: ppa_baycrest_linguistic_features.csv**
* **Pitt: 04_pitt_extract_linguistics.R**
  - **Output: control_pitt_linguistic_features.csv**

### Acoustic Feature Extraction in Python & Google Colab (03_PPA_acoustic_extraction.ipynb)
**Packages Used: `pydub`, `librosa`, `praat-parselmouth`**
Converted `.mp3`, `.mp4` to `.wav` files, and extracted acoustic features from `.wav` files

### Master Data Frame (04_PPA_df_SMOTE_modified.ipynb) 
**Packages Used: `pandas`, `numpy`, `imbalanced-learn`**
Added patient diagnoses to data frame, removed rows that lacked acoustic data or had generic PPA or unknown diagnosis, split data into 70/30, and executed SMOTE analysis to the training set

**Confidentiality Note: patient_id(s) and diagnoses manually typed in code block were removed prior to upload to ensure compliance with TalkBank Rules**

### Machine Learning: Random Forest Classifier (05_PPA_random_forest_shap_metrics.ipynb) 
**Packages Used: `scikit-learn`, `pandas`, `numpy`, `matplotlib`, `seaborn`, `shap`**

Trained and evaluated ML model. Computed learning curve, classification report, confusion matrices, and executed SHAP analysis

### Machine Learning: Logistic Regression (06_PPA_logistic_regression_shap_metrics.ipynb) 
**Packages Used: `scikit-learn`, `pandas`, `numpy`, `matplotlib`, `seaborn`, `shap`**

Trained and evaluated ML model. Computed learning curve, classification report, confusion matrices, and executed SHAP analysis

---

## 4. Code & Manuscript References

* **OSF Project:** https://doi.org/10.17605/OSF.IO/BYZUD
* **OSF Pre-Registration:** https://doi.org/10.17605/OSF.IO/VMN9S
* **Graphical Abstract:** https://doi.org/10.6084/m9.figshare.33322230

---

*Maintained by Vansika Priya Garapati*



